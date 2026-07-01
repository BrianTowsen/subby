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

/// ProjectCostView — Building Cost Estimate TEMPLATE.
///
/// The app owns the STRUCTURE (trade sections) and the ARITHMETIC
/// (qty × rate → subtotals → contingency → VAT → total). The user owns the
/// NUMBERS — their own quotes and rates. Nothing is auto-estimated.
class ProjectCostView extends StatefulWidget {
  const ProjectCostView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ProjectCostView> createState() => _ProjectCostViewState();
}

class _ProjectCostViewState extends State<ProjectCostView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Ported from the estimate template · ink + sage-green system.
  static const Color _ink = Color(0xFF39454B);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _band = Color(0xFFF4F6F8); // section header band
  static const Color _border = Color(0xFFE7EBEF); // sheet outline
  static const Color _line = Color(0xFFF2F4F6); // row separators
  static const Color _green = Color(0xFF166341); // accent / filled subtotal
  static const Color _danger = Color(0xFFC6A29B); // delete
  static const Color _dash = Color(0xFFCDD6E2); // add-section border
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const String _kActiveProjectPath = 'subby_active_project_path';

  // Standard residential trade sections (the template scaffold).
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
    'ton',
    'point',
    'load',
    'month',
    'item',
    'lot',
    '%',
  ];

  static const int _contingencyPct = 10;
  static const int _vatPct = 15;

  final List<_EstSection> _sections = [];
  bool _breakdownOpen = false;

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _estimateRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _estSub;
  Timer? _saveTimer;
  bool _isOwner = true;
  bool _readOnly = false;
  String _visibility = 'private';
  bool _remoteLoaded = false;
  String _projectName = 'Project';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _baseSections.length; i++) {
      final sec = _EstSection(name: _baseSections[i]);
      if (i == 0) {
        sec.expanded = true;
        sec.lines.add(_EstLine());
      }
      _sections.add(sec);
    }
    _loadActiveProject();
  }

  @override
  void dispose() {
    _projSub?.cancel();
    _estSub?.cancel();
    _saveTimer?.cancel();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;
    final ref = FirebaseFirestore.instance.doc(path);
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

  // Apply a remote estimate snapshot (real-time sync across devices).
  void _onRemoteEstimate(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      _remoteLoaded = true;
      if (_isOwner) _saveNow(); // seed the template on first open
      return;
    }
    if (_saveTimer?.isActive ?? false) return; // don't clobber pending edits
    final vis = (data['visibility'] ?? 'private').toString();
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
    setState(() {
      _visibility = vis == 'shared' ? 'shared' : 'private';
      _remoteLoaded = true;
    });
  }

  Map<String, dynamic> _sectionToMap(_EstSection s) => {
        'name': s.name,
        'custom': s.custom,
        'expanded': s.expanded,
        'lines': s.lines
            .map((l) => {
                  'desc': l.desc.text,
                  'unit': l.unit,
                  'qty': l.qty.text,
                  'rate': l.rate.text,
                })
            .toList(),
      };

  _EstSection _sectionFromMap(Map<String, dynamic> m) {
    final lines = <_EstLine>[];
    if (m['lines'] is List) {
      for (final e in (m['lines'] as List)) {
        if (e is Map) {
          lines.add(_EstLine(
            d: (e['desc'] ?? '').toString(),
            q: (e['qty'] ?? '').toString(),
            r: (e['rate'] ?? '').toString(),
            unit: (e['unit'] ?? 'Sum').toString(),
          ));
        }
      }
    }
    return _EstSection(
      name: (m['name'] ?? '').toString(),
      custom: m['custom'] == true,
      expanded: m['expanded'] == true,
      lines: lines,
    );
  }

  // Debounced save so typing doesn't spam Firestore.
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
        'visibility': _visibility,
        'updatedAt': FieldValue.serverTimestamp(),
        'sections': _sections.map(_sectionToMap).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _toggleVisibility() {
    setState(
        () => _visibility = _visibility == 'shared' ? 'private' : 'shared');
    _saveNow();
  }

  void _edited() {
    setState(() {});
    _persist();
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  // -----------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------
  void _toggleSection(_EstSection s) {
    setState(() => s.expanded = !s.expanded);
    _persist();
  }

  void _toggleBreakdown() => setState(() => _breakdownOpen = !_breakdownOpen);

  void _toggleAll() {
    final allOpen = _sections.every((s) => s.expanded);
    setState(() {
      for (final s in _sections) {
        s.expanded = !allOpen;
      }
    });
    _persist();
  }

  void _addLine(_EstSection s) {
    setState(() {
      s.expanded = true;
      s.lines.add(_EstLine());
    });
    _persist();
  }

  void _removeLine(_EstSection s, _EstLine l) {
    setState(() {
      s.lines.remove(l);
      l.dispose();
    });
    _persist();
  }

  void _addSection() {
    setState(() {
      final s = _EstSection(name: '', custom: true);
      s.expanded = true;
      s.lines.add(_EstLine());
      _sections.add(s);
    });
    _persist();
  }

  void _removeSection(_EstSection s) {
    setState(() {
      _sections.remove(s);
      s.dispose();
    });
    _persist();
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
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    // Totals (roll up from the user's own numbers).
    double net = 0;
    int items = 0;
    int started = 0;
    for (final sec in _sections) {
      var filled = false;
      for (final l in sec.lines) {
        net += l.amount;
        items++;
        if (l.hasData) filled = true;
      }
      if (filled) started++;
    }
    final contAmount = net * _contingencyPct / 100.0;
    final subExcl = net + contAmount;
    final vat = subExcl * _vatPct / 100.0;
    final total = subExcl + vat;

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(topInset, total, started, items),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _sectionsHeaderRow(),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < _sections.length; i++)
                        _sectionBlock(i, _sections[i]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_readOnly) _addSectionButton(),
              ],
            ),
          ),
          _bottomBar(bottomInset, net, contAmount, vat),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Hero
  // -----------------------------------------------------------------
  Widget _hero(double topInset, double total, int started, int items) {
    return Container(
      width: double.infinity,
      color: _ink,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circleBtn(Icons.arrow_back_ios_new_rounded, _handleBack),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        _projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _paper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BUILDING COST ESTIMATE',
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: _paper.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _isOwner ? _visBtn() : _viewOnlyPill(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'YOUR TOTAL INCL. VAT',
            style: TextStyle(
              fontFamily: _body,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: _paper.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(total),
            style: const TextStyle(
              fontFamily: _display,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: _paper,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$started of ${_sections.length} sections started · $items items',
            style: TextStyle(
              fontFamily: _body,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _paper.withOpacity(0.6),
            ),
          ),
        ],
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
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );

  Widget _visBtn() => GestureDetector(
        onTap: _toggleVisibility,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _paper.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  _visibility == 'shared'
                      ? Icons.visibility_outlined
                      : Icons.lock_outline_rounded,
                  size: 14,
                  color: _paper),
              const SizedBox(width: 5),
              Text(_visibility == 'shared' ? 'Shared' : 'Private',
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _paper)),
            ],
          ),
        ),
      );

  Widget _viewOnlyPill() => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: _paper.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.visibility_outlined, size: 14, color: _paper),
            SizedBox(width: 5),
            Text('View only',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _paper)),
          ],
        ),
      );

  // -----------------------------------------------------------------
  // Sections header row (title + expand/collapse all)
  // -----------------------------------------------------------------
  Widget _sectionsHeaderRow() {
    final allOpen = _sections.every((s) => s.expanded);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Sections',
              style: TextStyle(
                fontFamily: _display,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _ink,
              )),
          InkWell(
            onTap: _toggleAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    allOpen
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    size: 15,
                    color: _green),
                const SizedBox(width: 5),
                Text(allOpen ? 'Collapse' : 'Expand all',
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Section block (header band + editable lines)
  // -----------------------------------------------------------------
  Widget _sectionBlock(int index, _EstSection s) {
    double sub = 0;
    for (final l in s.lines) {
      sub += l.amount;
    }

    final trailing = InkWell(
      onTap: () => _toggleSection(s),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_money(sub),
              style: TextStyle(
                fontFamily: _display,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sub > 0 ? _green : const Color(0xFFB4BDC7),
              )),
          AnimatedRotation(
            turns: s.expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child:
                const Icon(Icons.expand_more_rounded, size: 22, color: _faint),
          ),
        ],
      ),
    );

    return Column(
      children: [
        // header band
        Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          decoration: const BoxDecoration(
            color: _band,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                height: 20,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('${index + 1}',
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _paper,
                    )),
              ),
              Expanded(
                child: s.custom
                    ? TextField(
                        controller: s.nameCtl,
                        readOnly: _readOnly,
                        onChanged: (v) {
                          setState(() => s.name = v);
                          _persist();
                        },
                        style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Section name',
                          hintStyle: TextStyle(color: _faint),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _toggleSection(s),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: _body,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
        // body
        if (s.expanded) ...[
          if (s.lines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _line)),
              ),
              child: const Text(
                'No items yet. Add the first line for this trade.',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _faint),
              ),
            ),
          for (var j = 0; j < s.lines.length; j++)
            _lineRow(index, j, s, s.lines[j]),
          if (!_readOnly) _addLineRow(s),
        ],
      ],
    );
  }

  Widget _lineRow(int si, int li, _EstSection s, _EstLine l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('${si + 1}.${li + 1}',
                      style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB4BDC7),
                      )),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: l.desc,
                  readOnly: _readOnly,
                  onChanged: (_) => _edited(),
                  style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.35,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Item description',
                    hintStyle: TextStyle(color: _faint),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(_money(l.amount),
                    style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                _unitPicker(l),
                const SizedBox(width: 6),
                _numPill(label: 'QTY', ctl: l.qty, fieldWidth: 40),
                const SizedBox(width: 6),
                const Text('×',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB4BDC7))),
                const SizedBox(width: 6),
                Expanded(
                    child: _numPill(label: 'R', ctl: l.rate, expand: true)),
                if (!_readOnly) const SizedBox(width: 2),
                if (!_readOnly)
                  InkWell(
                    onTap: () => _removeLine(s, l),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: _danger),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitPicker(_EstLine l) {
    return PopupMenuButton<String>(
      enabled: !_readOnly,
      onSelected: (v) {
        setState(() => l.unit = v);
        _persist();
      },
      padding: EdgeInsets.zero,
      itemBuilder: (_) => _units
          .map((u) => PopupMenuItem<String>(
                value: u,
                height: 40,
                child: Text(u,
                    style: const TextStyle(
                        fontFamily: _body, fontSize: 13, color: _ink)),
              ))
          .toList(),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.unit,
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _inkMute)),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: _faint),
          ],
        ),
      ),
    );
  }

  Widget _numPill({
    required String label,
    required TextEditingController ctl,
    double? fieldWidth,
    bool expand = false,
  }) {
    final field = TextField(
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      readOnly: _readOnly,
      onChanged: (_) => _edited(),
      style: const TextStyle(
        fontFamily: _display,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: '0',
        hintStyle: TextStyle(color: _faint),
      ),
    );
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: _body,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: _faint,
              )),
          const SizedBox(width: 5),
          expand
              ? Expanded(child: field)
              : SizedBox(width: fieldWidth ?? 40, child: field),
        ],
      ),
    );
  }

  Widget _addLineRow(_EstSection s) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _addLine(s),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Row(
                  children: const [
                    Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: _green),
                    SizedBox(width: 7),
                    Text('Add line item',
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        )),
                  ],
                ),
              ),
            ),
          ),
          if (s.custom)
            InkWell(
              onTap: () => _removeSection(s),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(14, 11, 14, 11),
                child: Text('Remove section',
                    style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addSectionButton() {
    return InkWell(
      onTap: _addSection,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _dash, width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_rounded, size: 19, color: _inkMute),
            SizedBox(width: 8),
            Text('Add custom section',
                style: TextStyle(
                  fontFamily: _body,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _inkMute,
                )),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Bottom bar (breakdown + saved cue)
  // -----------------------------------------------------------------
  Widget _bottomBar(double bottomInset, double net, double cont, double vat) {
    return Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: _surface)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A19232D),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_breakdownOpen) ...[
            _breakdownRow('Net total — trades', _money(net)),
            _breakdownRow('Contingency @ $_contingencyPct%', _money(cont)),
            _breakdownRow('VAT @ $_vatPct%', _money(vat)),
            const SizedBox(height: 6),
            Container(height: 1, color: _surface),
          ],
          InkWell(
            onTap: _toggleBreakdown,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 18, color: _inkMute),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text('Estimate breakdown',
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        )),
                  ),
                  Text(_breakdownOpen ? 'Hide' : 'Show',
                      style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _inkMute,
                      )),
                  AnimatedRotation(
                    turns: _breakdownOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_less_rounded,
                        size: 20, color: _faint),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: const [
              Icon(Icons.cloud_done_outlined, size: 13, color: _green),
              SizedBox(width: 5),
              Text('Changes saved automatically',
                  style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _faint,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: _body,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _inkMute,
                )),
            Text(value,
                style: const TextStyle(
                  fontFamily: _display,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                )),
          ],
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

  bool get hasData =>
      desc.text.trim().isNotEmpty ||
      qty.text.trim().isNotEmpty ||
      rate.text.trim().isNotEmpty;

  void dispose() {
    desc.dispose();
    qty.dispose();
    rate.dispose();
  }
}

class _EstSection {
  String name;
  final bool custom;
  final TextEditingController? nameCtl;
  bool expanded;
  final List<_EstLine> lines;

  _EstSection({
    required this.name,
    this.custom = false,
    this.expanded = false,
    List<_EstLine>? lines,
  })  : lines = lines ?? [],
        nameCtl = custom ? TextEditingController(text: name) : null;

  void dispose() {
    nameCtl?.dispose();
    for (final l in lines) {
      l.dispose();
    }
  }
}
