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

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// ProjectCostView — Financial Control Module.
///
/// Three connected tabs sharing one project spine: • Cost Estimate — the
/// budget baseline (trade sections × line items). • Payments      — supplier
/// payment claims allocated to a section/line, with a Received → Approved →
/// Paid status. • Cost Control  — Budget vs Actual + Cost to Complete, rolled
/// up live.
///
/// The app owns the STRUCTURE and the ARITHMETIC. The user owns the NUMBERS.
/// The section list is built in Cost Estimate and flows automatically into
/// Payments (allocation targets) and Cost Control (budget baselines).
class ProjectCostView extends StatefulWidget {
  const ProjectCostView({
    super.key,
    this.width,
    this.height,

    /// ✅ Project reference (passed by ProjectDetailPageView / FF page param)
    this.projectRef,
  });

  final double? width;
  final double? height;

  final DocumentReference? projectRef;

  @override
  State<ProjectCostView> createState() => _ProjectCostViewState();
}

class _ProjectCostViewState extends State<ProjectCostView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _header = Color(0xFF455861);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _band = Color(0xFFF2F5F6);
  static const Color _border = Color(0xFFECF0F2);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _green = Color(0xFF5D737E);
  static const Color _danger = Color(0xFF93A3AC);
  static const Color _warn = Color(0xFFAC0C0C); // over-budget / destructive
  static const Color _dash = Color(0xFFCBD8DD);
  static const Color _hairline = Color(0xFFDCE3E6);
  static const Color _zero = Color(0xFFB7C2C7);
  static const Color _startBg = Color(0xFFF5F8F9);
  static const Color _tabIdle = Color(0xFFAEBAC0);
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  // Brand yellow — module accent (ported from ProjectDetailPageView).
  static const Color _brandYellow = Color(0xFFE7E247); // featured tile
  static const Color _brandYellowPale = Color(0xFFF4F2D2); // standard tile
  static const Color _brandYellowBorder = Color(0xFFE4DE94);
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

  static const List<String> _subTypes = [
    'Supply and Fit',
    'Material',
    'Labour',
    'Equipment',
    'Specialist',
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
    'pc',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Payment status vocabulary.
  static const Map<String, String> _statusLabel = {
    'received': 'Received',
    'approved': 'Approved',
    'paid': 'Paid',
  };
  static const List<String> _statusOrder = ['received', 'approved', 'paid'];

  static const int _vatPct = 15;

  // ── State ──────────────────────────────────────────────────────────
  final List<_EstSection> _sections = [];
  final List<_Payment> _payments = [];

  num _contingencyPct = 10;
  final TextEditingController _contCtl = TextEditingController(text: '10');

  int _tab = 0; // 0 = Cost Estimate, 1 = Payments, 2 = Cost Control
  bool _manage = false; // manage-sections overlay
  int? _paymentFilter; // null = all; otherwise section index
  String? _editingPaymentId; // full-screen payment editor when non-null

  // Payment-editor controllers (synced to the edited payment).
  final TextEditingController _paySupplierCtl = TextEditingController();
  final TextEditingController _payAmountCtl = TextEditingController();

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _estimateRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _estSub;
  Timer? _saveTimer;
  bool _isOwner = true;
  bool _readOnly = false;
  String _visibility = 'private';
  bool _remoteLoaded = false;
  int _lastSaveMs = 0;
  String _projectName = 'Project';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _baseSections.length; i++) {
      _sections.add(_EstSection(name: _baseSections[i]));
    }
  }

  bool _resolvedRef = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedRef) return;
    _resolvedRef = true;

    final fromRoute =
        widget.projectRef ?? _readRefFromRoute('projectRef', 'projects');
    if (fromRoute != null) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_kActiveProjectPath, fromRoute.path));
      _bindProject(FirebaseFirestore.instance.doc(fromRoute.path));
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
    _contCtl.dispose();
    _paySupplierCtl.dispose();
    _payAmountCtl.dispose();
    for (final s in _sections) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;
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
      String vis = 'private';
      final mv = data['moduleVisibility'];
      if (mv is Map && mv['projectCost'] != null) {
        vis = mv['projectCost'].toString() == 'shared' ? 'shared' : 'private';
      }
      if (!mounted) return;
      setState(() {
        _projectName = name;
        _isOwner = isOwner;
        _readOnly = !isOwner;
        _visibility = vis;
      });
    });

    _estSub =
        _estimateRef!.snapshots().listen(_onRemoteEstimate, onError: (_) {});
  }

  // ─── Estimate sync ─────────────────────────────────────────────────
  void _onRemoteEstimate(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      _remoteLoaded = true;
      if (_isOwner) _saveNow();
      return;
    }
    if (_saveTimer?.isActive ?? false) return;
    if (_editingPaymentId != null) return; // don't clobber an open editor
    if (DateTime.now().millisecondsSinceEpoch - _lastSaveMs < 2000) {
      _remoteLoaded = true;
      return;
    }
    final cp = data['contingencyPct'];
    if (cp is num) {
      _contingencyPct = cp;
      final t =
          cp == cp.roundToDouble() ? cp.toInt().toString() : cp.toString();
      if (_contCtl.text != t) _contCtl.text = t;
    }
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
    final pl = data['payments'];
    if (pl is List) {
      _payments
        ..clear()
        ..addAll(pl.whereType<Map>().map((e) =>
            _paymentFromMap(e.map((k, v) => MapEntry(k.toString(), v)))));
    }
    setState(() => _remoteLoaded = true);
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

  void _persist() {
    if (_readOnly || _estimateRef == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _saveNow() async {
    final ref = _estimateRef;
    if (ref == null || _readOnly) return;
    _lastSaveMs = DateTime.now().millisecondsSinceEpoch;
    try {
      await ref.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'contingencyPct': _contingencyPct,
        'sections': _sections.map(_sectionToMap).toList(),
        'payments': _payments.map(_paymentToMap).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ─── Payments (persisted on estimate/plan alongside sections, so they
  //     inherit the exact same Firestore rules that already work) ──────
  Map<String, dynamic> _paymentToMap(_Payment p) => {
        'id': p.id,
        'supplier': p.supplier,
        'secIndex': p.secIndex,
        'allocSub': p.allocSub,
        'allocLine': p.allocLine,
        'date': p.date,
        'amount': p.amount,
        'status': p.status,
        'attachmentUrl': p.attachmentUrl,
        'attachmentName': p.attachmentName,
      };

  _Payment _paymentFromMap(Map<String, dynamic> m) => _Payment(
        id: (m['id'] ?? '').toString(),
        supplier: (m['supplier'] ?? '').toString(),
        secIndex: (m['secIndex'] is num) ? (m['secIndex'] as num).toInt() : 0,
        allocSub: (m['allocSub'] is num) ? (m['allocSub'] as num).toInt() : -2,
        allocLine:
            (m['allocLine'] is num) ? (m['allocLine'] as num).toInt() : 0,
        date: (m['date'] ?? '').toString(),
        amount: (m['amount'] ?? '').toString(),
        status: _statusLabel.containsKey((m['status'] ?? '').toString())
            ? (m['status']).toString()
            : 'received',
        attachmentUrl: (m['attachmentUrl'] ?? '').toString(),
        attachmentName: (m['attachmentName'] ?? '').toString(),
      );

  // ─── Cost-module privacy (shared with ProjectDetailPageView) ───────
  void _toggleVisibility() {
    final ref = _projectRef;
    final next = _visibility == 'shared' ? 'private' : 'shared';
    setState(() => _visibility = next);
    if (ref == null || _readOnly) return;
    ref.set(<String, dynamic>{
      'moduleVisibility': <String, dynamic>{'projectCost': next},
    }, SetOptions(merge: true)).catchError((_) {});
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  // ─── Manage sections (reorder / rename / delete / add) ─────────────
  Widget _manageScreen() {
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: _startBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: _header,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 16),
            child: Row(
              children: [
                _circleBtn(Icons.chevron_left_rounded,
                    () => setState(() => _manage = false),
                    iconSize: 24),
                const Expanded(
                  child: Column(
                    children: [
                      Text('Manage sections',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                      SizedBox(height: 2),
                      Text('EDIT & REORDER',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: Color(0x80FFFFFF))),
                    ],
                  ),
                ),
                const SizedBox(width: 38, height: 38),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: EdgeInsets.fromLTRB(14, 14, 14, bottom + 40),
              itemCount: _sections.length + 1,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex >= _sections.length) return;
                setState(() {
                  if (newIndex > _sections.length) newIndex = _sections.length;
                  if (newIndex > oldIndex) newIndex -= 1;
                  final it = _sections.removeAt(oldIndex);
                  _sections.insert(newIndex, it);
                });
                _persist();
              },
              itemBuilder: (context, i) {
                if (i == _sections.length) {
                  return Padding(
                    key: const ValueKey('mng-actions'),
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        if (!_readOnly)
                          InkWell(
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
                                  Icon(Icons.add_rounded,
                                      size: 19, color: _inkMute),
                                  SizedBox(width: 8),
                                  Text('Add section',
                                      style: TextStyle(
                                          fontFamily: _body,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _inkMute)),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _manage = false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: _header,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_rounded,
                                    size: 18, color: _paper),
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
                      ],
                    ),
                  );
                }
                final s = _sections[i];
                return Container(
                  key: ValueKey('mng-sec-$i'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.drag_indicator_rounded,
                              size: 20, color: _zero),
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        height: 20,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _header,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontFamily: _body,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: s.nameCtl,
                          readOnly: _readOnly,
                          textInputAction: TextInputAction.done,
                          onChanged: (v) {
                            setState(() => s.name = v);
                            _persist();
                          },
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Section name',
                            hintStyle: TextStyle(color: _faint),
                          ),
                        ),
                      ),
                      if (!_readOnly)
                        InkWell(
                          onTap: () => _removeSection(s),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.delete_outline_rounded,
                                size: 18, color: _faint),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Centered destructive confirm for removing an invoice attachment.
  Future<void> _confirmRemoveInvoice() async {
    final p = _editingPayment;
    if (p == null) return;
    final name = p.attachmentName.trim().isEmpty
        ? 'This invoice'
        : '\u201C${p.attachmentName.trim()}\u201D';
    FocusScope.of(context).unfocus();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(14),
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
                const Text('Delete this invoice?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _display,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: _ink,
                    )),
                const SizedBox(height: 8),
                Text(
                    '$name will be removed from this payment. This can\u2019t be undone.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: _inkMute,
                    )),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeInvoice();
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
                      child: const Text('Delete invoice',
                          style: TextStyle(
                            fontFamily: _body,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _paper,
                          )),
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
                      child: const Text('Cancel',
                          style: TextStyle(
                            fontFamily: _body,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          )),
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

  // ─── Estimate mutations ────────────────────────────────────────────
  void _toggleSection(_EstSection s) {
    setState(() => s.expanded = !s.expanded);
    _persist();
  }

  void _onContingencyChanged(String v) {
    final cleaned = v.replaceAll(RegExp(r'[^0-9.]'), '');
    setState(() =>
        _contingencyPct = cleaned.isEmpty ? 0 : (num.tryParse(cleaned) ?? 0));
    _persist();
  }

  void _toggleAll() {
    final allOpen = _sections.every((s) => s.expanded);
    setState(() {
      for (final s in _sections) {
        s.expanded = !allOpen;
      }
    });
    _persist();
  }

  Future<void> _addLine(_EstSection s) async {
    if (_readOnly) return;
    setState(() {
      s.expanded = true;
      s.lines.add(_EstLine());
    });
    await _saveNow();
    final si = _sections.indexOf(s);
    if (!mounted || si < 0) return;
    _openEditLine(si, -1, s.lines.length - 1);
  }

  Future<void> _addSubLine(_EstSection s, _EstSub sb) async {
    if (_readOnly) return;
    setState(() {
      s.expanded = true;
      sb.expanded = true;
      sb.lines.add(_EstLine());
    });
    await _saveNow();
    final si = _sections.indexOf(s);
    final subI = s.subs.indexOf(sb);
    if (!mounted || si < 0 || subI < 0) return;
    _openEditLine(si, subI, sb.lines.length - 1);
  }

  void _addSub(_EstSection s, String name) {
    setState(() {
      s.expanded = true;
      s.subs.add(_EstSub(name: name));
    });
    _persist();
  }

  void _removeSub(_EstSection s, _EstSub sb) {
    setState(() {
      s.subs.remove(sb);
      sb.dispose();
    });
    _persist();
  }

  // Line editor is its own route (EditProjectCostPage) — native push/pop.
  void _openEditLine(int si, int subIndex, int li) {
    final ref = _projectRef;
    if (ref == null) return;
    _saveTimer?.cancel();
    _saveNow();
    context.pushNamed(
      'EditProjectCostPage',
      queryParameters: {
        'projectRef': serializeParam(ref, ParamType.DocumentReference),
        'secIndex': si.toString(),
        'subIndex': subIndex.toString(),
        'lineIndex': li.toString(),
      }.withoutNulls,
    );
  }

  void _addSection() {
    setState(() {
      final s = _EstSection(name: '', custom: true);
      s.expanded = true;
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

  // ─── Payment mutations ─────────────────────────────────────────────
  void _addPayment() {
    if (_readOnly) return;
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final p = _Payment(
      id: id,
      supplier: '',
      secIndex: _paymentFilter ?? 0,
      allocSub: -2,
      allocLine: 0,
      date: today,
      amount: '',
      status: 'received',
    );
    setState(() => _payments.add(p));
    _saveNow();
    _openPayment(p.id);
  }

  void _openPayment(String id) {
    final p =
        _payments.firstWhere((x) => x.id == id, orElse: () => _Payment.empty());
    _paySupplierCtl.text = p.supplier;
    _payAmountCtl.text = p.amount;
    setState(() => _editingPaymentId = id);
  }

  void _closePayment() {
    _saveTimer?.cancel();
    _saveNow();
    setState(() => _editingPaymentId = null);
  }

  _Payment? get _editingPayment {
    final id = _editingPaymentId;
    if (id == null) return null;
    for (final p in _payments) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _editPayment(void Function(_Payment) fn) {
    final p = _editingPayment;
    if (p == null) return;
    setState(() => fn(p));
    _persist();
  }

  // Centered destructive confirm — shared "delete warning" module
  // (matches DocumentUploadPageView: clay accent, 322-wide card, icon disc).
  Future<void> _confirmDeletePayment() async {
    final p = _editingPayment;
    if (p == null) return;
    final name = p.supplier.trim().isEmpty
        ? 'This payment'
        : '\u201C${p.supplier.trim()}\u201D';
    FocusScope.of(context).unfocus();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(14),
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
                  'Delete this payment?',
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
                  '$name will be removed from this project. This can\u2019t be undone.',
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
                      _deletePayment();
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
                        'Delete payment',
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

  void _deletePayment() {
    final p = _editingPayment;
    if (p == null) return;
    setState(() {
      _payments.removeWhere((x) => x.id == p.id);
      _editingPaymentId = null;
    });
    _saveNow();
  }

  // ─── Invoice attachment (photo/scan → Firebase Storage) ────────────
  // Picks an image, uploads it under the project, and keeps the download
  // URL on the payment. Requires the image_picker & firebase_storage
  // packages (already present in any FlutterFlow app that does uploads).
  Future<void> _attachInvoice() async {
    final p = _editingPayment;
    final proj = _projectRef;
    if (p == null || proj == null || _readOnly) return;
    try {
      final picker = ImagePicker();
      final XFile? file =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final safeName = file.name.isEmpty ? 'invoice.jpg' : file.name;
      final storageRef = FirebaseStorage.instance
          .ref('${proj.path}/documents/payments/${p.id}/$safeName');
      final snap = await storageRef.putData(bytes);
      final url = await snap.ref.getDownloadURL();
      _editPayment((x) {
        x.attachmentUrl = url;
        x.attachmentName = safeName;
      });
    } catch (_) {}
  }

  void _removeInvoice() {
    _editPayment((x) {
      x.attachmentUrl = '';
      x.attachmentName = '';
    });
  }

  // ─── Derived numbers ───────────────────────────────────────────────
  double _sectionBudget(_EstSection s) {
    double b = 0;
    for (final l in s.lines) {
      b += l.amount;
    }
    for (final sb in s.subs) {
      for (final l in sb.lines) {
        b += l.amount;
      }
    }
    return b;
  }

  double _paymentAmount(_Payment p) => double.tryParse(p.amount.trim()) ?? 0;

  double _sectionInvoiced(int i) {
    double v = 0;
    for (final p in _payments) {
      if (p.secIndex == i) v += _paymentAmount(p);
    }
    return v;
  }

  double _sectionPaid(int i) {
    double v = 0;
    for (final p in _payments) {
      if (p.secIndex == i && p.status == 'paid') v += _paymentAmount(p);
    }
    return v;
  }

  // ─── Formatting ────────────────────────────────────────────────────
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

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '—';
    final p = iso.split('-');
    if (p.length != 3) return iso;
    final mi = (int.tryParse(p[1]) ?? 1) - 1;
    return '${int.tryParse(p[2]) ?? p[2]} '
        '${(mi >= 0 && mi < 12) ? _months[mi] : ''} ${p[0]}';
  }

  // Human label for a payment's allocation (section · line).
  String _allocLabel(_Payment p) {
    final sec = (p.secIndex >= 0 && p.secIndex < _sections.length)
        ? _sections[p.secIndex]
        : null;
    final secName = sec?.name.trim().isNotEmpty == true ? sec!.name : 'Section';
    if (sec == null || p.allocSub == -2) return secName;
    if (p.allocSub == -1) {
      if (p.allocLine >= 0 && p.allocLine < sec.lines.length) {
        final d = sec.lines[p.allocLine].desc.text.trim();
        return '$secName · ${d.isEmpty ? 'line ${p.allocLine + 1}' : d}';
      }
      return secName;
    }
    if (p.allocSub >= 0 && p.allocSub < sec.subs.length) {
      final sb = sec.subs[p.allocSub];
      if (p.allocLine >= 0 && p.allocLine < sb.lines.length) {
        final d = sb.lines[p.allocLine].desc.text.trim();
        return '$secName · ${sb.name}: ${d.isEmpty ? 'line ${p.allocLine + 1}' : d}';
      }
      return '$secName · ${sb.name}';
    }
    return secName;
  }

  // =================================================================
  // BUILD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _tab == 0 ? _paper : _startBg,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.035),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_tab),
                    child: _activeScreen(),
                  ),
                ),
              ),
              _tabBar(),
            ],
          ),
          if (_editingPaymentId != null && _editingPayment != null)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                key: ValueKey<String>(_editingPaymentId!),
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 28),
                    child: child,
                  ),
                ),
                child: _paymentEditor(_editingPayment!),
              ),
            ),
          if (_manage) Positioned.fill(child: _manageScreen()),
        ],
      ),
    );
  }

  Widget _activeScreen() {
    switch (_tab) {
      case 1:
        return _paymentsScreen();
      case 2:
        return _costControlScreen();
      default:
        return _estimateScreen();
    }
  }

  // ─── Shared header ─────────────────────────────────────────────────
  Widget _moduleHeader(String subtitle) {
    final topInset = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: Row(
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
                    subtitle,
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
    );
  }

  Widget _capLabel(String t) => Text(t,
      style: TextStyle(
        fontFamily: _body,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: _paper.withOpacity(0.55),
      ));

  Widget _bigNumber(String t) => Text(t,
      style: const TextStyle(
        fontFamily: _display,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
        color: _paper,
        height: 1.0,
      ));

  Widget _heroSub(String t) => Text(t,
      style: TextStyle(
        fontFamily: _body,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: _paper.withOpacity(0.6),
      ));

  // ─── TAB BAR ───────────────────────────────────────────────────────
  Widget _tabBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: _border)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Row(
        children: [
          _tabItem(0, Icons.checklist_rounded, 'Cost Estimate'),
          _tabItem(1, Icons.receipt_long_rounded, 'Payments'),
          _tabItem(2, Icons.insights_rounded, 'Cost Control'),
        ],
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label) {
    final active = _tab == index;
    final color = active ? _ink : _tabIdle;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 9, 0, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: color),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: _body,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // COST ESTIMATE SCREEN
  // ===================================================================
  Widget _estimateScreen() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
      for (final sb in sec.subs) {
        for (final l in sb.lines) {
          net += l.amount;
          items++;
          if (l.hasData) filled = true;
        }
      }
      if (filled) started++;
    }
    final contAmount = net * _contingencyPct / 100.0;
    final subExcl = net + contAmount;
    final vat = subExcl * _vatPct / 100.0;
    final total = subExcl + vat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: _header,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _moduleHeader('COST ESTIMATE'),
              const SizedBox(height: 16),
              _capLabel('YOUR TOTAL INCL. VAT'),
              const SizedBox(height: 4),
              _bigNumber(_money(total)),
              const SizedBox(height: 10),
              _heroSub(
                  '$started of ${_sections.length} sections started · $items items'),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + bottomInset),
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
              const SizedBox(height: 14),
              _breakdownCard(net, contAmount, vat, total),
              const SizedBox(height: 14),
              _savedCue(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionsHeaderRow() {
    final allOpen = _sections.every((s) => s.expanded);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sections',
                  style: TextStyle(
                    fontFamily: _display,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  )),
              const SizedBox(width: 8),
              if (!_readOnly)
                InkWell(
                  onTap: () => setState(() => _manage = true),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _brandYellow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.tune_rounded, size: 14, color: _ink),
                        SizedBox(width: 4),
                        Text('Edit list',
                            style: TextStyle(
                              fontFamily: _body,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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

  Widget _sectionBlock(int index, _EstSection s) {
    double sub = 0;
    for (final l in s.lines) {
      sub += l.amount;
    }
    for (final sb in s.subs) {
      for (final l in sb.lines) {
        sub += l.amount;
      }
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
                color: sub > 0 ? _green : _zero,
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
                child: TextField(
                  controller: s.nameCtl,
                  readOnly: _readOnly,
                  textInputAction: TextInputAction.done,
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
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
        if (s.expanded) ...[
          if (s.lines.isEmpty && s.subs.isEmpty)
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
          for (var k = 0; k < s.subs.length; k++)
            _subBlock(index, s, k, s.subs[k]),
          for (var j = 0; j < s.lines.length; j++)
            _lineRow('${index + 1}.${s.subs.length + j + 1}', s.lines[j],
                () => _openEditLine(index, -1, j)),
          if (!_readOnly) _addSubRow(s),
          if (!_readOnly) _addLineRow(s),
        ],
      ],
    );
  }

  Widget _subBlock(int si, _EstSection s, int subIdx, _EstSub sb) {
    final subNum = '${si + 1}.${subIdx + 1}';
    double ss = 0;
    for (final l in sb.lines) {
      ss += l.amount;
    }
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFCFD),
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  height: 18,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  margin: const EdgeInsets.only(right: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EDF0),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(subNum,
                      style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _inkMute,
                      )),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _readOnly
                        ? null
                        : () => setState(() => sb.pick = !sb.pick),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            sb.name.trim().isEmpty ? 'Sub-section' : sb.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                        if (!_readOnly) const SizedBox(width: 4),
                        if (!_readOnly)
                          const Icon(Icons.expand_more_rounded,
                              size: 16, color: _faint),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() => sb.expanded = !sb.expanded);
                    _persist();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_money(ss),
                          style: TextStyle(
                            fontFamily: _display,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ss > 0 ? _green : _zero,
                          )),
                      AnimatedRotation(
                        turns: sb.expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.expand_more_rounded,
                            size: 20, color: _faint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (sb.pick && !_readOnly) _subTypePicker(s, sb),
          if (sb.expanded) ...[
            for (var li = 0; li < sb.lines.length; li++)
              _lineRow('$subNum.${li + 1}', sb.lines[li],
                  () => _openEditLine(si, subIdx, li),
                  leftPad: 20),
            if (!_readOnly)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: InkWell(
                  onTap: () => _addSubLine(s, sb),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 12, 10),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            size: 16, color: _green),
                        SizedBox(width: 7),
                        Text('Add line item',
                            style: TextStyle(
                              fontFamily: _body,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _green,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _addSubRow(_EstSection s) {
    final used = s.subs.map((x) => x.name).toSet();
    final avail = _subTypes.where((n) => !used.contains(n)).toList();
    if (avail.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUB-TITLE',
              style: TextStyle(
                fontFamily: _body,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: _faint,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final n in avail)
                InkWell(
                  onTap: () => _addSub(s, n),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _dash, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 14, color: _inkMute),
                        const SizedBox(width: 5),
                        Text(n,
                            style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _inkMute,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subTypePicker(_EstSection s, _EstSub sb) {
    final usedByOthers =
        s.subs.where((x) => x != sb).map((x) => x.name).toSet();
    final opts = _subTypes.where((n) => !usedByOthers.contains(n)).toList();
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHANGE TYPE',
              style: TextStyle(
                fontFamily: _body,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: _faint,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final n in opts)
                InkWell(
                  onTap: () {
                    setState(() {
                      sb.name = n;
                      sb.pick = false;
                    });
                    _persist();
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: sb.name == n ? _ink : _paper,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: sb.name == n ? _ink : _dash, width: 1.2),
                    ),
                    child: Text(n,
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: sb.name == n ? _paper : _inkMute,
                        )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _removeSub(s, sb),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.delete_outline_rounded, size: 15, color: _danger),
                  SizedBox(width: 6),
                  Text('Delete sub-section',
                      style: TextStyle(
                        fontFamily: _body,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _danger,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(String numLabel, _EstLine l, VoidCallback onTap,
      {double leftPad = 12}) {
    final desc = l.desc.text.trim();
    final qty = l.qty.text.trim();
    final rate = l.rate.text.trim();
    final hasNums = qty.isNotEmpty || rate.isNotEmpty;
    final sub = hasNums
        ? '${qty.isEmpty ? '0' : qty} ${l.unit} × ${rate.isEmpty ? 'R 0' : 'R ${_fmt(double.tryParse(rate) ?? 0)}'}'
        : 'Tap to add quantity & rate';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(leftPad, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: leftPad > 12 ? 36 : 28,
              child: Text(numLabel,
                  style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _zero,
                  )),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc.isEmpty ? 'Item description' : desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _body,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: desc.isEmpty ? _faint : _ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _faint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_money(l.amount),
                style: TextStyle(
                  fontFamily: _display,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: l.amount > 0 ? _ink : _zero,
                )),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _faint),
          ],
        ),
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
          if (!_readOnly)
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

  Widget _breakdownCard(double net, double cont, double vat, double total) {
    return Container(
      decoration: BoxDecoration(
        color: _brandYellowPale,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _breakdownRow('Net total — trades', _money(net)),
          _contingencyRow(cont),
          _breakdownRow('VAT @ $_vatPct%', _money(vat)),
          const SizedBox(height: 6),
          Container(height: 1, color: _surface),
          Padding(
            padding: const EdgeInsets.only(top: 9, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total incl. VAT',
                    style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    )),
                Text(_money(total),
                    style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contingencyRow(double cont) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Contingency @ ',
                    style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _inkMute,
                    )),
                SizedBox(
                  width: 44,
                  height: 30,
                  child: TextField(
                    controller: _contCtl,
                    readOnly: _readOnly,
                    onChanged: _onContingencyChanged,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      filled: true,
                      fillColor: const Color(0xFFF7F9FA),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: _dash, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: _green, width: 1.4),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
                const Text(' %',
                    style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _inkMute,
                    )),
              ],
            ),
            Text(_money(cont),
                style: const TextStyle(
                  fontFamily: _display,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                )),
          ],
        ),
      );

  Widget _savedCue() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
      );

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

  // ===================================================================
  // PAYMENTS SCREEN
  // ===================================================================
  Widget _paymentsScreen() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    double invoiced = 0, paid = 0;
    for (final p in _payments) {
      invoiced += _paymentAmount(p);
      if (p.status == 'paid') paid += _paymentAmount(p);
    }

    final shown = _paymentFilter == null
        ? _payments
        : _payments.where((p) => p.secIndex == _paymentFilter).toList();

    final secsWithPay =
        (_payments.map((p) => p.secIndex).toSet().toList()..sort());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: _header,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _moduleHeader('PAYMENTS'),
              const SizedBox(height: 16),
              _capLabel('PAYMENTS TO DATE'),
              const SizedBox(height: 4),
              _bigNumber(_money(invoiced)),
              const SizedBox(height: 10),
              _heroSub('${_payments.length} payments · ${_money(paid)} paid'),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + bottomInset),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _paymentFilter == null
                        ? (shown.length == 1
                            ? '1 payment'
                            : '${shown.length} payments')
                        : '${shown.length} ${shown.length == 1 ? 'payment' : 'payments'} · ${_sections[_paymentFilter!].name}',
                    style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  if (!_readOnly)
                    InkWell(
                      onTap: _addPayment,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _brandYellow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, size: 15, color: _ink),
                            SizedBox(width: 5),
                            Text('New payment',
                                style: TextStyle(
                                  fontFamily: _body,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // section filter chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All', _payments.length, _paymentFilter == null,
                        () => setState(() => _paymentFilter = null)),
                    for (final i in secsWithPay)
                      Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: _filterChip(
                          _sections[i].name,
                          _payments.where((p) => p.secIndex == i).length,
                          _paymentFilter == i,
                          () => setState(() => _paymentFilter = i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 30, 14, 30),
                  child: Center(
                    child: Text('No payments in this section yet.',
                        style: TextStyle(
                          fontFamily: _body,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _faint,
                        )),
                  ),
                )
              else
                for (final p in shown) ...[
                  _paymentCard(p),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int count, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _ink : const Color(0xFFE4EAED),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontFamily: _body,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: active ? _paper : _inkMute,
                )),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                  fontFamily: _body,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active ? _paper.withOpacity(0.55) : _zero,
                )),
          ],
        ),
      ),
    );
  }

  Widget _paymentCard(_Payment p) {
    final st = p.status;
    final Color sBg = st == 'paid'
        ? _ink
        : (st == 'approved' ? _green.withOpacity(0.15) : _band);
    final Color sFg =
        st == 'paid' ? _paper : (st == 'approved' ? _green : _inkMute);
    final IconData sIcon = st == 'paid'
        ? Icons.check_circle_rounded
        : (st == 'approved' ? Icons.task_alt_rounded : Icons.schedule_rounded);

    return InkWell(
      onTap: () => _openPayment(p.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.supplier.trim().isEmpty
                            ? 'Unnamed supplier'
                            : p.supplier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _allocLabel(p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _faint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_money(_paymentAmount(p)),
                        style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        )),
                    const SizedBox(height: 3),
                    Text(_fmtDate(p.date),
                        style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _zero,
                        )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: sBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sIcon, size: 13, color: sFg),
                      const SizedBox(width: 4),
                      Text(_statusLabel[st] ?? 'Received',
                          style: TextStyle(
                            fontFamily: _body,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: sFg,
                          )),
                    ],
                  ),
                ),
                const Spacer(),
                if (p.attachmentUrl.trim().isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.attach_file_rounded,
                        size: 15, color: _faint),
                  ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: _dash),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // COST CONTROL SCREEN
  // ===================================================================
  Widget _costControlScreen() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Budget baseline is grossed up to the estimate's Total incl. VAT:
    // net × (1 + contingency%) × (1 + VAT%). Cost to complete is measured
    // against that full figure, not the bare trade net.
    final gross = (1 + _contingencyPct / 100.0) * (1 + _vatPct / 100.0);
    double budget = 0, invoiced = 0, paid = 0, forecast = 0, ctc = 0;
    final rows = <Widget>[];
    for (var i = 0; i < _sections.length; i++) {
      final b = _sectionBudget(_sections[i]) * gross;
      final inv = _sectionInvoiced(i);
      final pd = _sectionPaid(i);
      budget += b;
      invoiced += inv;
      paid += pd;
      forecast += b > inv ? b : inv;
      ctc += (b - inv) > 0 ? (b - inv) : 0;
      if (b > 0 || inv > 0)
        rows.add(_costSectionRow(_sections[i].name, b, inv, pd));
    }
    final variance = budget - forecast; // negative = over
    final fbase = forecast > 0 ? forecast : 1;
    final pctSpent = budget > 0 ? (invoiced / budget * 100).round() : 0;
    final over = variance < -0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: _header,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _moduleHeader('COST CONTROL'),
              const SizedBox(height: 16),
              _capLabel('COST TO COMPLETE'),
              const SizedBox(height: 4),
              _bigNumber(_money(ctc)),
              const SizedBox(height: 10),
              _heroSub(
                  '$pctSpent% of budget in payments · forecast ${_money(forecast)}'),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 24 + bottomInset),
            children: [
              _costSummaryCard(budget, invoiced, paid, ctc, fbase.toDouble()),
              const SizedBox(height: 12),
              _varianceBanner(over, variance, forecast, budget),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 0, 2, 10),
                child: Text('By trade section',
                    style: TextStyle(
                      fontFamily: _display,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    )),
              ),
              for (final r in rows) ...[r, const SizedBox(height: 10)],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline_rounded, size: 13, color: _green),
                  SizedBox(width: 5),
                  Text('Cost to complete = total incl. VAT − payments to date',
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
        ),
      ],
    );
  }

  Widget _costSummaryCard(
      double budget, double invoiced, double paid, double ctc, double fbase) {
    final paidW = (paid / fbase).clamp(0.0, 1.0);
    final invUnpaidW = ((invoiced - paid) / fbase).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (paidW * 1000).round().clamp(0, 1000),
                    child: Container(color: _ink),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: (invUnpaidW * 1000).round().clamp(0, 1000),
                    child: Container(color: _green),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: ((1 - paidW - invUnpaidW) * 1000)
                        .round()
                        .clamp(0, 1000),
                    child: Container(color: _band),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _legend(_ink, 'Paid'),
              _legend(_green, 'Unpaid'),
              _legend(const Color(0xFFE4EAED), 'To complete'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _statCell('BUDGET', _money(budget), _ink)),
              Expanded(child: _statCell('PAYMENTS', _money(invoiced), _ink)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCell('PAID', _money(paid), _ink)),
              Expanded(child: _statCell('TO COMPLETE', _money(ctc), _green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration:
                BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(t,
              style: const TextStyle(
                fontFamily: _body,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _inkMute,
              )),
        ],
      );

  Widget _statCell(String label, String value, Color valueColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: _body,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _faint,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontFamily: _display,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: valueColor,
              )),
        ],
      );

  Widget _varianceBanner(
      bool over, double variance, double forecast, double budget) {
    final Color c = over ? _warn : _green;
    final title = over
        ? '${_money(-variance)} over budget'
        : (variance > 0.5 ? '${_money(variance)} under budget' : 'On budget');
    return Container(
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: over ? c : c.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(over ? Icons.bolt_rounded : Icons.verified_rounded,
                size: 19, color: over ? _paper : c),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: _body,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c,
                    )),
                const SizedBox(height: 1),
                Text(
                    'Forecast final cost ${_money(forecast)} vs budget ${_money(budget)}',
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _inkMute,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _costSectionRow(String name, double b, double inv, double pd) {
    final over = inv > b;
    final remain = b - inv;
    final base = b > 0 ? b : 1;
    final invW = (inv / base).clamp(0.0, 1.0);
    final paidW = (pd / base).clamp(0.0, 1.0);
    final Color barColor = over ? _warn : _green;
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    )),
              ),
              const SizedBox(width: 10),
              Text(
                  over
                      ? '${_money(-remain)} over'
                      : '${_money(remain)} to spend',
                  style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: over ? _warn : _green,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            return SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: _band, borderRadius: BorderRadius.circular(999)),
                  ),
                  Container(
                    width: (w * invW).clamp(0.0, w),
                    decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  Container(
                    width: (w * paidW).clamp(0.0, w),
                    decoration: BoxDecoration(
                        color: _ink, borderRadius: BorderRadius.circular(999)),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget ${_money(b)}',
                  style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _faint,
                  )),
              Text('Payments ${_money(inv)}',
                  style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _faint,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // PAYMENT EDITOR (full-screen push-in page)
  // ===================================================================
  Widget _paymentEditor(_Payment p) {
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final sec = (p.secIndex >= 0 && p.secIndex < _sections.length)
        ? _sections[p.secIndex]
        : null;

    return Container(
      color: _startBg,
      child: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            color: _header,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 16),
            child: Row(
              children: [
                _circleBtn(Icons.chevron_left_rounded, _closePayment,
                    iconSize: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                            p.supplier.trim().isEmpty
                                ? 'New payment'
                                : p.supplier.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: _body,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                        const SizedBox(height: 2),
                        Text('PAYMENT',
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
                  _circleBtn(
                      Icons.delete_outline_rounded, _confirmDeletePayment,
                      iconSize: 18, bg: _paper.withOpacity(0.10))
                else
                  const SizedBox(width: 38, height: 38),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 16, 18, bottom + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _editorLabel('SUPPLIER'),
                  const SizedBox(height: 8),
                  _cardField(
                    child: TextField(
                      controller: _paySupplierCtl,
                      readOnly: _readOnly,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => _editPayment((x) => x.supplier = v),
                      style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _ink),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Supplier / subcontractor',
                        hintStyle: TextStyle(color: _faint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editorLabel('PAYMENT AMOUNT'),
                  const SizedBox(height: 8),
                  _cardField(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
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
                            controller: _payAmountCtl,
                            readOnly: _readOnly,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.done,
                            textAlign: TextAlign.right,
                            onChanged: (v) => _editPayment((x) => x.amount =
                                v.replaceAll(RegExp(r'[^0-9.]'), '')),
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
                  ),
                  const SizedBox(height: 16),
                  _editorLabel('DATE'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _readOnly ? null : () => _pickDate(p),
                    borderRadius: BorderRadius.circular(14),
                    child: _cardField(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtDate(p.date),
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: _faint),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _editorLabel('STATUS'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < _statusOrder.length; i++) ...[
                        if (i > 0) const SizedBox(width: 7),
                        Expanded(
                          child: _statusChip(p, _statusOrder[i]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _editorLabel('INVOICE DOCUMENT'),
                  const SizedBox(height: 8),
                  _attachmentField(p),
                  const SizedBox(height: 16),
                  _editorLabel('ALLOCATE TO SECTION'),
                  const SizedBox(height: 8),
                  _sectionDropdown(p),
                  const SizedBox(height: 10),
                  _lineDropdown(p, sec),
                  const SizedBox(height: 20),
                  if (!_readOnly)
                    InkWell(
                      onTap: _confirmDeletePayment,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                            color: _paper,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: _faint),
                            SizedBox(width: 7),
                            Text('Delete payment',
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
                  InkWell(
                    onTap: _closePayment,
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
      ),
    );
  }

  Widget _editorLabel(String t) => Text(t,
      style: const TextStyle(
        fontFamily: _body,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: _faint,
      ));

  Widget _cardField({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      );

  Widget _statusChip(_Payment p, String v) {
    final active = p.status == v;
    return InkWell(
      onTap: _readOnly ? null : () => _editPayment((x) => x.status = v),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _ink : const Color(0xFFE4EAED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(_statusLabel[v] ?? v,
            style: TextStyle(
              fontFamily: _body,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? _paper : _inkMute,
            )),
      ),
    );
  }

  Widget _attachmentField(_Payment p) {
    final has = p.attachmentUrl.trim().isNotEmpty;
    if (!has) {
      return InkWell(
        onTap: _readOnly ? null : _attachInvoice,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _dash, width: 1.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.attach_file_rounded, size: 18, color: _green),
              SizedBox(width: 7),
              Text('Attach invoice',
                  style: TextStyle(
                    fontFamily: _body,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  )),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.description_rounded, size: 18, color: _green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _viewInvoice(p),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.attachmentName.trim().isEmpty
                        ? 'Invoice attached'
                        : p.attachmentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text('Tap to view',
                      style: TextStyle(
                        fontFamily: _body,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _green,
                      )),
                ],
              ),
            ),
          ),
          if (!_readOnly) ...[
            InkWell(
              onTap: _attachInvoice,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.autorenew_rounded, size: 18, color: _faint),
              ),
            ),
            InkWell(
              onTap: _confirmRemoveInvoice,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, size: 18, color: _danger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewInvoice(_Payment p) {
    final url = p.attachmentUrl.trim();
    if (url.isEmpty) return;
    try {
      launchURL(url);
    } catch (_) {}
  }

  Widget _sectionDropdown(_Payment p) {
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: p.secIndex,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: _faint),
          style: const TextStyle(
              fontFamily: _body,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink),
          onChanged: _readOnly
              ? null
              : (v) {
                  if (v == null) return;
                  _editPayment((x) {
                    x.secIndex = v;
                    x.allocSub = -2;
                    x.allocLine = 0;
                  });
                },
          items: [
            for (var i = 0; i < _sections.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text('${i + 1}. ${_sections[i].name}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lineDropdown(_Payment p, _EstSection? sec) {
    // Encoded values: 'w' whole section, 's{k}_{li}' sub line, 'd{j}' direct.
    String current = 'w';
    if (p.allocSub == -1) {
      current = 'd${p.allocLine}';
    } else if (p.allocSub >= 0) {
      current = 's${p.allocSub}_${p.allocLine}';
    }
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'w', child: Text('Whole section')),
    ];
    if (sec != null) {
      for (var k = 0; k < sec.subs.length; k++) {
        final sb = sec.subs[k];
        for (var li = 0; li < sb.lines.length; li++) {
          final d = sb.lines[li].desc.text.trim();
          items.add(DropdownMenuItem(
            value: 's${k}_$li',
            child: Text('${sb.name}: ${d.isEmpty ? 'line ${li + 1}' : d}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ));
        }
      }
      for (var j = 0; j < sec.lines.length; j++) {
        final d = sec.lines[j].desc.text.trim();
        items.add(DropdownMenuItem(
          value: 'd$j',
          child: Text(d.isEmpty ? 'line ${j + 1}' : d,
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ));
      }
    }
    // Guard against a stale value no longer present.
    if (!items.any((it) => it.value == current)) current = 'w';

    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: _faint),
          style: const TextStyle(
              fontFamily: _body,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _inkMute),
          onChanged: _readOnly
              ? null
              : (v) {
                  if (v == null) return;
                  _editPayment((x) {
                    if (v == 'w') {
                      x.allocSub = -2;
                      x.allocLine = 0;
                    } else if (v.startsWith('s')) {
                      final parts = v.substring(1).split('_');
                      x.allocSub = int.tryParse(parts[0]) ?? -2;
                      x.allocLine =
                          parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                    } else if (v.startsWith('d')) {
                      x.allocSub = -1;
                      x.allocLine = int.tryParse(v.substring(1)) ?? 0;
                    }
                  });
                },
          items: items,
        ),
      ),
    );
  }

  Future<void> _pickDate(_Payment p) async {
    DateTime init = DateTime.now();
    final parts = p.date.split('-');
    if (parts.length == 3) {
      init = DateTime(int.tryParse(parts[0]) ?? init.year,
          int.tryParse(parts[1]) ?? 1, int.tryParse(parts[2]) ?? 1);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final iso = '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    _editPayment((x) => x.date = iso);
  }

  // ─── Small shared widgets ──────────────────────────────────────────
  Widget _circleBtn(IconData icon, VoidCallback onTap,
          {double iconSize = 16, Color? bg}) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg ?? _paper.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: _paper),
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
  final TextEditingController nameCtl;
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
        subs = subs ?? [],
        nameCtl = TextEditingController(text: name);

  void dispose() {
    nameCtl.dispose();
    for (final l in lines) {
      l.dispose();
    }
    for (final s in subs) {
      s.dispose();
    }
  }
}

class _EstSub {
  String name;
  bool expanded;
  bool pick = false;
  final List<_EstLine> lines;

  _EstSub({required this.name, this.expanded = true, List<_EstLine>? lines})
      : lines = lines ?? [];

  void dispose() {
    for (final l in lines) {
      l.dispose();
    }
  }
}

// A supplier payment claim, allocated to a section (and optionally one line).
//   allocSub: -2 = whole section · -1 = a direct line · >=0 = a sub-section
//   allocLine: index of the line within that list (ignored when allocSub == -2)
class _Payment {
  String id;
  String supplier;
  int secIndex;
  int allocSub;
  int allocLine;
  String date; // yyyy-MM-dd
  String amount;
  String status; // received | approved | paid
  String attachmentUrl;
  String attachmentName;

  _Payment({
    required this.id,
    required this.supplier,
    required this.secIndex,
    required this.allocSub,
    required this.allocLine,
    required this.date,
    required this.amount,
    required this.status,
    this.attachmentUrl = '',
    this.attachmentName = '',
  });

  factory _Payment.empty() => _Payment(
        id: '',
        supplier: '',
        secIndex: 0,
        allocSub: -2,
        allocLine: 0,
        date: '',
        amount: '',
        status: 'received',
      );
}
