// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// EditProjectCostPageView — single-line editor for the Building Cost Estimate.
///
/// Its own route (EditProjectCostPage), so it gets native push/pop + swipe-back.
/// ProjectCostView passes the project + which line to edit (secIndex/lineIndex);
/// this page streams the shared `estimate/plan` doc, edits that one line, and
/// saves back — the cost view reflects the change on return.
class EditProjectCostPageView extends StatefulWidget {
  const EditProjectCostPageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Project reference (passed by ProjectCostView / route query param)
    this.projectRef,
  });

  final double? width;
  final double? height;

  final DocumentReference? projectRef;

  @override
  State<EditProjectCostPageView> createState() =>
      _EditProjectCostPageViewState();
}

class _EditProjectCostPageViewState extends State<EditProjectCostPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _band = Color(0xFFF2F5F6);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _green = Color(0xFF5D737E);
  static const Color _danger = Color(0xFF93A3AC);
  // Warning / destructive accent — clay (shared "delete warning" module).
  static const Color _warn = Color(0xFFB53F1A);
  static const Color _dash = Color(0xFFCBD8DD);
  static const Color _ruleIdle = Color(0xFFB7C2C7);
  static const Color _startBg = Color(0xFFF5F8F9);
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const String _kActiveProjectPath = 'subby_active_project_path';

  // Standard residential trade sections (the template scaffold behind a load).
  static const List<String> _baseSections = [
    'Professional Fees',
    'Preliminaries & General',
    'Site Preparation',
    'Site Establishment',
    'Earthworks & Excavation',
    'Concrete Works (Foundations)',
    'Brickwork & Blockwork',
    'Damp Proofing & Waterproofing',
    'Structural Steel Works',
    'Roofing & Trusses',
    'Windows & Door Frames',
    'Glazing',
    'Plumbing & Drainage',
    'Sanitary Fittings',
    'Electrical Works',
    'Electrical Fittings',
    'Plastering & Screeds',
    'Ceilings & Partitioning',
    'Internal Carpentry & Joinery',
    'Kitchen (Built-in Units)',
    'Built-in Cupboards',
    'Tiling',
    'Floor Covering',
    'Special Items',
    'Painting & Decorating',
    'Balustrades & Railings',
    'External Site Works',
    'Landscaping',
    'Cleaning & Handover',
  ];

  static const List<String> _units = [
    'Sum',
    'no',
    'm',
    'm²',
    'm³',
    'kg',
    'ton',
    'point',
    'load',
    'hour',
    'day',
    'month',
    'item',
    'lot',
    'roll',
    'bundle',
    '5L',
    '20L',
    '%',
    'pct',
  ];

  final List<_EstSection> _sections = [];

  int _selSi = 0;
  int _selSub = -1; // -1 = a direct line; >= 0 = index into the section's subs
  int _selLi = 0;
  bool _ready = false;

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _estimateRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _estSub;
  Timer? _saveTimer;
  bool _isOwner = true;
  bool _readOnly = false;
  String _projectName = 'Project';

  final TextEditingController _descCtl = TextEditingController();
  final TextEditingController _qtyCtl = TextEditingController();
  final TextEditingController _rateCtl = TextEditingController();
  final ScrollController _scrollCtl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Placeholder scaffold behind the load (never saved before _ready).
    for (final name in _baseSections) {
      _sections.add(_EstSection(name: name));
    }
    if (_sections.isNotEmpty) _sections[0].lines.add(_EstLine());
  }

  bool _resolvedRef = false;
  DocumentReference? _incomingRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedRef) return;
    _resolvedRef = true;

    // Seed the node to edit from the route query params.
    final qp = GoRouterState.of(context).uri.queryParameters;
    _selSi = int.tryParse((qp['secIndex'] ?? '').trim()) ?? 0;
    _selSub = int.tryParse((qp['subIndex'] ?? '').trim()) ?? -1;
    _selLi = int.tryParse((qp['lineIndex'] ?? '').trim()) ?? 0;

    // Never spin forever if the estimate genuinely never loads.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_ready) setState(() => _ready = true);
    });

    _incomingRef =
        widget.projectRef ?? _readRefFromRoute('projectRef', 'projects');
    if (_incomingRef != null) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_kActiveProjectPath, _incomingRef!.path));
      _bindProject(FirebaseFirestore.instance.doc(_incomingRef!.path));
    } else {
      _loadActiveProject();
    }
  }

  DocumentReference? _readRefFromRoute(String key, String fallbackCollection) {
    try {
      final qp = GoRouterState.of(context).uri.queryParameters;
      var s = (qp[key] ?? '').trim();
      if (s.isEmpty) return null;
      s = s.replaceAll('"', '');
      if (s.startsWith('{')) {
        final m = RegExp(r'([A-Za-z0-9_]+/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)')
            .firstMatch(s);
        if (m != null) s = m.group(1)!;
      }
      if (s.contains('/')) return FirebaseFirestore.instance.doc(s);
      return FirebaseFirestore.instance.collection(fallbackCollection).doc(s);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _projSub?.cancel();
    _estSub?.cancel();
    _saveTimer?.cancel();
    _descCtl.dispose();
    _qtyCtl.dispose();
    _rateCtl.dispose();
    _scrollCtl.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    _bindProject(FirebaseFirestore.instance.doc(path));
  }

  void _bindProject(DocumentReference<Map<String, dynamic>> ref) {
    _projectRef = ref;
    _estimateRef = ref.collection('estimate').doc('plan');

    _projSub = ref.snapshots().listen((snap) {
      final raw = snap.data();
      final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final name =
          (data['name'] ?? data['projectName'] ?? data['title'] ?? 'Project')
              .toString();
      final ownerRef = data['ownerRef'];
      final isOwner = ownerRef is DocumentReference &&
          currentUserReference != null &&
          ownerRef.path == currentUserReference!.path;
      if (!mounted) return;
      setState(() {
        _projectName = name;
        _isOwner = isOwner;
        _readOnly = !isOwner;
      });
    });

    _estSub =
        _estimateRef!.snapshots().listen(_onRemoteEstimate, onError: (_) {});
  }

  void _onRemoteEstimate(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      if (mounted) setState(() => _ready = true);
      return;
    }
    if (_saveTimer?.isActive ?? false) return; // don't clobber pending edits
    final list = data['sections'];
    if (!mounted) return;
    if (list is List) {
      final parsed = <_EstSection>[];
      for (final e in list) {
        if (e is Map) {
          parsed
              .add(_sectionFromMap(e.map((k, v) => MapEntry(k.toString(), v))));
        }
      }
      if (parsed.isNotEmpty) {
        for (final s in _sections) {
          s.dispose();
        }
        _sections
          ..clear()
          ..addAll(parsed);
      }
    }
    _clampSel();
    setState(() => _ready = true);
    _syncCtls();
  }

  Map<String, dynamic> _lineToMap(_EstLine l) => {
        'desc': l.desc.text,
        'unit': l.unit,
        'qty': l.qty.text,
        'rate': l.rate.text,
      };

  Map<String, dynamic> _sectionToMap(_EstSection s) => {
        'name': s.name,
        'custom': s.custom,
        'expanded': s.expanded,
        'lines': s.lines.map(_lineToMap).toList(),
        'subs': s.subs
            .map((sb) => {
                  'name': sb.name,
                  'expanded': sb.expanded,
                  'lines': sb.lines.map(_lineToMap).toList(),
                })
            .toList(),
      };

  _EstLine _lineFromMap(Map m) => _EstLine(
        d: (m['desc'] ?? '').toString(),
        q: (m['qty'] ?? '').toString(),
        r: (m['rate'] ?? '').toString(),
        unit: (m['unit'] ?? 'Sum').toString(),
      );

  _EstSection _sectionFromMap(Map<String, dynamic> m) {
    final lines = <_EstLine>[];
    if (m['lines'] is List) {
      for (final e in (m['lines'] as List)) {
        if (e is Map) lines.add(_lineFromMap(e));
      }
    }
    final subs = <_EstSub>[];
    if (m['subs'] is List) {
      for (final e in (m['subs'] as List)) {
        if (e is Map) {
          final sm = e.map((k, v) => MapEntry(k.toString(), v));
          final sl = <_EstLine>[];
          if (sm['lines'] is List) {
            for (final le in (sm['lines'] as List)) {
              if (le is Map) sl.add(_lineFromMap(le));
            }
          }
          subs.add(_EstSub(
            name: (sm['name'] ?? '').toString(),
            expanded: sm['expanded'] == true,
            lines: sl,
          ));
        }
      }
    }
    return _EstSection(
      name: (m['name'] ?? '').toString(),
      custom: m['custom'] == true,
      expanded: m['expanded'] == true,
      lines: lines,
      subs: subs,
    );
  }

  // -----------------------------------------------------------------
  // Selection helpers
  // -----------------------------------------------------------------
  void _clampSel() {
    if (_sections.isEmpty) {
      _selSi = 0;
      _selSub = -1;
      _selLi = -1;
      return;
    }
    _selSi = _selSi.clamp(0, _sections.length - 1);
    final sec = _sections[_selSi];
    if (_selSub >= sec.subs.length) _selSub = -1;
    final list = _curList;
    _selLi = list.isEmpty ? -1 : _selLi.clamp(0, list.length - 1);
  }

  _EstSection get _selSec => _sections[_selSi];
  _EstSub? get _selSubObj => (_selSub >= 0 && _selSub < _selSec.subs.length)
      ? _selSec.subs[_selSub]
      : null;
  // The list the selected line lives in — a sub-section's lines, or the
  // section's own direct lines.
  List<_EstLine> get _curList => _selSubObj?.lines ?? _selSec.lines;
  _EstLine? get _selLine =>
      (_selLi >= 0 && _selLi < _curList.length) ? _curList[_selLi] : null;

  void _syncCtls() {
    final l = _selLine;
    _descCtl.text = l?.desc.text ?? '';
    _qtyCtl.text = l?.qty.text ?? '';
    _rateCtl.text = l?.rate.text ?? '';
  }

  // -----------------------------------------------------------------
  // Persistence (debounced) — writes the whole sections array back.
  // -----------------------------------------------------------------
  void _persist() {
    if (_readOnly || _estimateRef == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _saveNow() async {
    final ref = _estimateRef;
    if (ref == null || _readOnly) return;
    try {
      await ref.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'sections': _sections.map(_sectionToMap).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _flushSave() {
    _saveTimer?.cancel();
    _saveNow();
  }

  void _back() {
    _flushSave();
    context.safePop();
  }

  // -----------------------------------------------------------------
  // Mutations (on the selected line)
  // -----------------------------------------------------------------
  void _setUnit(String u) {
    final l = _selLine;
    if (l == null) return;
    setState(() => l.unit = u);
    _persist();
  }

  void _qtyStep(int d) {
    final l = _selLine;
    if (l == null) return;
    final v = (double.tryParse(l.qty.text.trim()) ?? 0) + d;
    final clamped = v < 0 ? 0.0 : v;
    final text =
        clamped % 1 == 0 ? clamped.toInt().toString() : clamped.toString();
    setState(() {
      l.qty.text = text;
      _qtyCtl.text = text;
    });
    _persist();
  }

  void _moveLine(int dir) {
    final lines = _curList;
    final j = _selLi + dir;
    if (j < 0 || j >= lines.length) return;
    setState(() {
      final tmp = lines[_selLi];
      lines[_selLi] = lines[j];
      lines[j] = tmp;
      _selLi = j;
    });
    _syncCtls();
    _persist();
  }

  // offset 0 = above, 1 = below
  void _insertLine(int offset) {
    setState(() {
      final at = (_selLi < 0 ? 0 : _selLi) + offset;
      _curList.insert(at, _EstLine());
      _selLi = at;
    });
    _syncCtls();
    _persist();
  }

  void _deleteLineNow() {
    final l = _selLine;
    if (l != null) {
      setState(() {
        _curList.removeAt(_selLi);
        l.dispose();
        _selLi = -1;
      });
    }
    _flushSave();
    context.safePop();
  }

  // Centered destructive confirm — shared "delete warning" module
  // (matches DocumentUploadPageView: clay accent, 322-wide card, icon disc).
  Future<void> _confirmDeleteLine() async {
    final l = _selLine;
    final desc = (l?.desc.text.trim() ?? '');
    final name = desc.isEmpty ? 'This line item' : '“$desc”';
    FocusScope.of(context).unfocus();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          child: Container(
            width: 322,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 54,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _warn.withOpacity(0.22), width: 1),
                  ),
                  child:
                      const Icon(Icons.delete_rounded, color: _warn, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete this line item?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _display,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$name will be removed from “${_selSec.name}”. This can’t be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteLineNow();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _warn,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Delete line item',
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _dash, width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Formatting
  // -----------------------------------------------------------------
  String _fmt(num v) {
    final n = v.round();
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '${n < 0 ? '-' : ''}$b';
  }

  String _money(num v) => 'R ${_fmt(v)}';

  // =================================================================
  // BUILD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _startBg,
      child: (!_ready) ? _loading() : _editScreen(),
    );
  }

  Widget _loading() {
    final top = MediaQuery.of(context).viewPadding.top;
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _ink,
          padding: EdgeInsets.fromLTRB(14, top + 14, 14, 16),
          child: Row(
            children: [
              _circleBtn(Icons.chevron_left_rounded, () => context.safePop()),
              const Expanded(
                child: Center(
                  child: Text('EDIT LINE ITEM',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0x80FFFFFF))),
                ),
              ),
              const SizedBox(width: 38, height: 38),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Loading…',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _faint)),
          ),
        ),
      ],
    );
  }

  Widget _editScreen() {
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    _clampSel();
    final l = _selLine;
    if (l == null) {
      // The line went away (deleted/synced out) — bail back to the estimate.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.safePop();
      });
      return Container(color: _startBg);
    }

    final sec = _selSec;
    final subObj = _selSubObj;
    final list = _curList;
    final amount = l.amount;
    // Section share is measured against the whole section (direct lines +
    // every sub-section), so the roll-up reads true.
    final flat = <_EstLine>[...sec.lines];
    for (final sb in sec.subs) {
      flat.addAll(sb.lines);
    }
    double subtotal = 0;
    for (final x in flat) {
      subtotal += x.amount;
    }
    final share = subtotal > 0 ? amount / subtotal : 0.0;
    final canUp = _selLi > 0;
    final canDown = _selLi < list.length - 1;
    final contextLabel = subObj != null
        ? 'IN ${sec.name.toUpperCase()} · ${subObj.name.trim().isEmpty ? 'SUB-SECTION' : subObj.name.toUpperCase()}'
        : 'IN SECTION · ${sec.name}';

    return Column(
      children: [
        // header
        Container(
          width: double.infinity,
          color: _ink,
          padding: EdgeInsets.fromLTRB(14, top + 14, 14, 16),
          child: Row(
            children: [
              _circleBtn(Icons.chevron_left_rounded, _back),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                          l.desc.text.trim().isEmpty
                              ? 'New line item'
                              : l.desc.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                      const SizedBox(height: 2),
                      Text('EDIT LINE ITEM',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: _paper.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
              if (!_readOnly)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _confirmDeleteLine,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _paper.withOpacity(0.10),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: _paper),
                    ),
                  ),
                )
              else
                const SizedBox(width: 38, height: 38),
            ],
          ),
        ),
        // body
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtl,
            padding: EdgeInsets.fromLTRB(18, 16, 18, bottom + 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // section context
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    Flexible(
                      child: Text(contextLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: _faint)),
                    ),
                    const SizedBox(width: 6),
                    Text('· line ${_selLi + 1} of ${list.length}',
                        style: const TextStyle(
                            fontFamily: _body,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: _ruleIdle)),
                  ],
                ),
                const SizedBox(height: 12),
                // name card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border)),
                  child: Row(
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _descCtl,
                          readOnly: _readOnly,
                          onChanged: (v) {
                            l.desc.text = v;
                            setState(() {});
                            _persist();
                          },
                          style: const TextStyle(
                              fontFamily: _display,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _ink),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Item description',
                            hintStyle: TextStyle(color: _faint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // amount preview card
                _amountCard(l, amount, subtotal, share),
                const SizedBox(height: 16),
                // unit
                const Text('UNIT OF MEASURE', style: _capLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [for (final u in _units) _unitChip(u, l.unit)],
                ),
                const SizedBox(height: 16),
                // quantity
                const Text('QUANTITY', style: _capLabel),
                const SizedBox(height: 8),
                _qtyStepper(l),
                const SizedBox(height: 16),
                // rate
                Text('RATE (PER ${l.unit.toUpperCase()})', style: _capLabel),
                const SizedBox(height: 8),
                _rateCard(l),
                // position & order
                const SizedBox(height: 20),
                const Text('POSITION & ORDER', style: _capLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: _posBtn(Icons.arrow_upward_rounded, 'Move up',
                            canUp, () => _moveLine(-1))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _posBtn(Icons.arrow_downward_rounded,
                            'Move down', canDown, () => _moveLine(1))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child:
                            _insertBtn('Insert above', () => _insertLine(0))),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _insertBtn('Insert below', () => _insertLine(1))),
                  ],
                ),
                // delete
                const SizedBox(height: 22),
                InkWell(
                  onTap: _confirmDeleteLine,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: _faint),
                        SizedBox(width: 7),
                        Text('Delete line item',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _faint)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // done
                InkWell(
                  onTap: _back,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: _ink, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_rounded, size: 18, color: _paper),
                        SizedBox(width: 7),
                        Text('Done',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_done_outlined, size: 13, color: _green),
                    SizedBox(width: 5),
                    Text('Changes saved automatically',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _faint)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const TextStyle _capLabel = TextStyle(
      fontFamily: _body,
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: _faint);

  // ----------------------------------------------------------------- amount
  Widget _amountCard(_EstLine l, double amount, double subtotal, double share) {
    final qNum = double.tryParse(l.qty.text.trim()) ?? 0;
    final rNum = double.tryParse(l.rate.text.trim()) ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LINE AMOUNT', style: _capLabel),
              Text(subtotal > 0 ? '${(share * 100).round()}% of section' : '—',
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _green)),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(amount),
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: _ink)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                    '${qNum % 1 == 0 ? qNum.toInt() : qNum} ${l.unit} × R ${_fmt(rNum)}',
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _faint)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // mini section track — this line bold, neighbours faint
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final segs = <Widget>[];
              if (subtotal > 0) {
                double acc = 0;
                final flat = <_EstLine>[..._selSec.lines];
                for (final sb in _selSec.subs) {
                  flat.addAll(sb.lines);
                }
                final selLine = _selLine;
                for (var i = 0; i < flat.length; i++) {
                  final frac = flat[i].amount / subtotal;
                  final cur = identical(flat[i], selLine);
                  segs.add(Positioned(
                    left: (acc * w).clamp(0, w - 4).toDouble(),
                    top: cur ? 3 : 6,
                    width: (frac * w).clamp(3, w).toDouble(),
                    height: cur ? 16 : 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _green.withOpacity(cur ? 1 : 0.26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ));
                  acc += frac;
                }
              }
              return SizedBox(
                height: 22,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: _band, borderRadius: BorderRadius.circular(6)),
                    ),
                    ...segs,
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('R 0',
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _ruleIdle)),
              Text('${_money(subtotal)} section',
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _ruleIdle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitChip(String u, String current) {
    final active = current == u;
    return InkWell(
      onTap: _readOnly ? null : () => _setUnit(u),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _ink : _paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? _ink : _hairlineOnSurface),
        ),
        child: Text(u,
            style: TextStyle(
                fontFamily: _body,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? _paper : _inkMute)),
      ),
    );
  }

  Widget _qtyStepper(_EstLine l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
      child: Row(
        children: [
          _roundStep(Icons.remove_rounded, false, () => _qtyStep(-1), 38),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _qtyCtl,
                    readOnly: _readOnly,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    onChanged: (v) {
                      l.qty.text = v;
                      setState(() {});
                      _persist();
                    },
                    style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _ink),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: _faint),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 40,
                  child: Text(l.unit,
                      style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _faint)),
                ),
              ],
            ),
          ),
          _roundStep(Icons.add_rounded, true, () => _qtyStep(1), 38),
        ],
      ),
    );
  }

  Widget _rateCard(_EstLine l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
      child: Row(
        children: [
          const Text('R',
              style: TextStyle(
                  fontFamily: _display,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _faint)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _rateCtl,
              readOnly: _readOnly,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              onChanged: (v) {
                l.rate.text = v;
                setState(() {});
                _persist();
              },
              style: const TextStyle(
                  fontFamily: _display,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: _faint),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundStep(IconData icon, bool solid, VoidCallback onTap, double sz) =>
      InkWell(
        onTap: _readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: sz,
          height: sz,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: solid ? _ink : _paper,
            shape: BoxShape.circle,
            border: solid ? null : Border.all(color: _hairlineOnSurface),
          ),
          child: Icon(icon, size: sz * 0.5, color: solid ? _paper : _ink),
        ),
      );

  Widget _posBtn(
      IconData icon, String label, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _green),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _insertBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: _readOnly ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _dash, width: 1.2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 17, color: _green),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _green)),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _paper.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _paper),
          ),
        ),
      );
}

// ============================================================================
// Editable models (own their TextEditingControllers)
// ============================================================================
class _EstLine {
  final TextEditingController desc;
  final TextEditingController qty;
  final TextEditingController rate;
  String unit;

  _EstLine({String d = '', String q = '', String r = '', this.unit = 'Sum'})
      : desc = TextEditingController(text: d),
        qty = TextEditingController(text: q),
        rate = TextEditingController(text: r);

  double get amount {
    final q = double.tryParse(qty.text.trim()) ?? 0;
    final r = double.tryParse(rate.text.trim()) ?? 0;
    return q * r;
  }

  void dispose() {
    desc.dispose();
    qty.dispose();
    rate.dispose();
  }
}

class _EstSection {
  String name;
  final bool custom;
  bool expanded;
  final List<_EstLine> lines;
  final List<_EstSub> subs;

  _EstSection({
    required this.name,
    this.custom = false,
    this.expanded = false,
    List<_EstLine>? lines,
    List<_EstSub>? subs,
  })  : lines = lines ?? [],
        subs = subs ?? [];

  void dispose() {
    for (final l in lines) {
      l.dispose();
    }
    for (final s in subs) {
      s.dispose();
    }
  }
}

// A sub-section: a named heading inside a section that groups line items.
class _EstSub {
  String name;
  bool expanded;
  final List<_EstLine> lines;

  _EstSub({required this.name, this.expanded = true, List<_EstLine>? lines})
      : lines = lines ?? [];

  void dispose() {
    for (final l in lines) {
      l.dispose();
    }
  }
}
