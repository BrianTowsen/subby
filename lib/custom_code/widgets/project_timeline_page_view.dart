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

import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// ProjectTimelinePageView — Construction Programme (Gantt) TEMPLATE.
///
/// The app owns the phase scaffold + scheduling; the user owns the durations.
/// High-level sections are in WEEKS, sub-tasks in WORKING DAYS, all scheduled
/// on a 5-day working week. Phases link to each other (After / Overlap % /
/// Parallel / From start) with optional buffer.
class ProjectTimelinePageView extends StatefulWidget {
  const ProjectTimelinePageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ProjectTimelinePageView> createState() =>
      _ProjectTimelinePageViewState();
}

class _ProjectTimelinePageViewState extends State<ProjectTimelinePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _band = Color(0xFFF2F5F6);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _green = Color(0xFF5D737E);
  static const Color _selTint = Color(0xFFE7EDF0);
  static const Color _danger = Color(0xFF93A3AC);
  static const Color _dash = Color(0xFFCBD8DD);
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const String _kActiveProjectPath = 'subby_active_project_path';

  static const double _leftW = 150;
  static const double _dayPx = 7; // px per working day
  static const double _weekPx = 35; // px per working week (5 days)
  static const double _secRowH = 52;
  static const double _childRowH = 44;
  static const double _headH = 30;

  static const List<String> _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  final Map<String, Color> _groupColor = const {
    'struct': Color(0xFF29343A),
    'services': Color(0xFF5D737E),
    'finish': Color(0xFF6E8791),
    'external': Color(0xFF93A3AC),
  };

  final Map<String, _ModeMeta> _modeMeta = const {
    'after': _ModeMeta(Icons.south_east_rounded, 'After', 'after'),
    'overlap': _ModeMeta(Icons.percent_rounded, 'Overlap', ''),
    'with': _ModeMeta(Icons.call_split_rounded, 'Parallel', 'parallel'),
    'start': _ModeMeta(Icons.flag_rounded, 'From start', 'start'),
  };

  DateTime _start = DateTime(2026, 2, 2); // Mon 2 Feb 2026
  String _projectName = 'Project';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _programmeRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _progSub;
  Timer? _saveTimer;
  bool _isOwner = true;
  bool _readOnly = false;
  String _visibility = 'private';
  bool _remoteLoaded = false;

  late List<_Section> _sections;
  int _selSi = 12; // Plumbing & Drainage
  int _selCi = -1;
  bool _inspectorOpen = true;

  final TextEditingController _nameCtl = TextEditingController();
  final ScrollController _vCtl = ScrollController();

  @override
  void initState() {
    super.initState();
    _sections = _defaultSections();
    _syncNameCtl();
    _loadActiveProject();
  }

  @override
  void dispose() {
    _projSub?.cancel();
    _progSub?.cancel();
    _saveTimer?.cancel();
    _nameCtl.dispose();
    _vCtl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;
    final ref = FirebaseFirestore.instance.doc(path);
    _projectRef = ref;
    _programmeRef = ref.collection('programme').doc('plan');

    _projSub = ref.snapshots().listen((snap) {
      final raw = snap.data();
      final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final name =
          (data['name'] ?? data['projectName'] ?? data['title'] ?? 'Project')
              .toString();
      final sd = data['startDate'];
      final ownerRef = data['ownerRef'];
      final isOwner = ownerRef is DocumentReference &&
          currentUserReference != null &&
          ownerRef.path == currentUserReference!.path;
      if (!mounted) return;
      setState(() {
        _projectName = name;
        if (sd is Timestamp) _start = sd.toDate();
        _isOwner = isOwner;
        _readOnly = !isOwner;
      });
    });

    _progSub = _programmeRef!.snapshots().listen(_onRemoteProgramme);
  }

  // Apply a remote programme snapshot (real-time sync across devices).
  void _onRemoteProgramme(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      _remoteLoaded = true;
      if (_isOwner) _saveNow(); // seed the template to the cloud on first open
      return;
    }
    if (_saveTimer?.isActive ?? false) return; // don't clobber pending edits
    final vis = (data['visibility'] ?? 'private').toString();
    final list = data['sections'];
    if (!mounted) return;
    setState(() {
      if (list is List) {
        final parsed = list
            .whereType<Map>()
            .map<_Section>((e) =>
                _sectionFromMap(e.map((k, v) => MapEntry(k.toString(), v))))
            .toList();
        if (parsed.isNotEmpty) _sections = parsed;
      }
      _visibility = vis == 'shared' ? 'shared' : 'private';
      _remoteLoaded = true;
      if (_selSi >= _sections.length) {
        _selSi = _sections.length - 1;
        _selCi = -1;
      }
    });
    _syncNameCtl();
  }

  Map<String, dynamic> _sectionToMap(_Section s) => {
        'name': s.name,
        'group': s.group,
        'mode': s.mode,
        'buffer': s.buffer,
        'overlapPct': s.overlapPct,
        'weeks': s.weeks,
        'expanded': s.expanded,
        'children': s.children
            .map((c) => {
                  'name': c.name,
                  'mode': c.mode,
                  'buffer': c.buffer,
                  'overlapPct': c.overlapPct,
                  'days': c.days,
                })
            .toList(),
      };

  _Section _sectionFromMap(Map<String, dynamic> m) {
    int gi(dynamic v, int d) => v is num ? v.toInt() : d;
    final kids = (m['children'] is List)
        ? (m['children'] as List).whereType<Map>().map<_Child>((e) {
            final c = e.map((k, v) => MapEntry(k.toString(), v));
            return _Child(
              name: (c['name'] ?? 'Sub-task').toString(),
              mode: (c['mode'] ?? 'after').toString(),
              buffer: gi(c['buffer'], 0),
              overlapPct: gi(c['overlapPct'], 50),
              days: gi(c['days'], 3),
            );
          }).toList()
        : <_Child>[];
    return _Section(
      name: (m['name'] ?? 'Section').toString(),
      group: (m['group'] ?? 'external').toString(),
      mode: (m['mode'] ?? 'after').toString(),
      buffer: gi(m['buffer'], 0),
      overlapPct: gi(m['overlapPct'], 50),
      weeks: gi(m['weeks'], 2),
      expanded: m['expanded'] == true,
      children: kids,
    );
  }

  // Debounced save so stepping a value doesn't spam Firestore.
  void _persist() {
    if (_readOnly || _programmeRef == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _saveNow() async {
    final ref = _programmeRef;
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

  // =================================================================
  // Default programme (template scaffold)
  // =================================================================
  List<_Section> _defaultSections() {
    _Section s(String name, String group, String mode, int weeks,
            {int buffer = 0, int overlapPct = 50}) =>
        _Section(
            name: name,
            group: group,
            mode: mode,
            weeks: weeks,
            buffer: buffer,
            overlapPct: overlapPct);
    return [
      s('Professional Fees', 'external', 'start', 2),
      s('Preliminaries & General', 'external', 'after', 1),
      s('Site Preparation', 'external', 'after', 1),
      s('Site Establishment', 'external', 'after', 1),
      s('Earthworks & Excavation', 'struct', 'after', 2),
      s('Concrete Works (Foundations)', 'struct', 'after', 2),
      s('Brickwork & Blockwork', 'struct', 'after', 5),
      s('Damp Proofing & Waterproofing', 'struct', 'overlap', 1,
          overlapPct: 60),
      s('Structural Steel Works', 'struct', 'with', 1),
      s('Roofing & Trusses', 'struct', 'after', 3),
      s('Windows & Door Frames', 'struct', 'overlap', 1),
      s('Glazing', 'struct', 'after', 1),
      _Section(
        name: 'Plumbing & Drainage',
        group: 'services',
        mode: 'with',
        weeks: 3,
        expanded: true,
        children: [
          _Child(name: 'First fix (rough-in)', mode: 'start', days: 6),
          _Child(name: 'Drainage & sewer connections', mode: 'after', days: 4),
          _Child(name: 'Second fix', mode: 'after', days: 5),
          _Child(name: 'Testing & commissioning', mode: 'after', days: 2),
        ],
      ),
      s('Sanitary Fittings', 'services', 'after', 1),
      s('Electrical Works', 'services', 'with', 2),
      s('Electrical Fittings', 'services', 'after', 1),
      s('Plastering & Screeds', 'finish', 'after', 3),
      s('Ceilings & Partitioning', 'finish', 'overlap', 2),
      s('Internal Carpentry & Joinery', 'finish', 'after', 2),
      s('Kitchen (Built-in Units)', 'finish', 'after', 1),
      s('Built-in Cupboards', 'finish', 'with', 1),
      s('Tiling', 'finish', 'after', 2),
      s('Floor Covering', 'finish', 'after', 1),
      s('Special Items', 'finish', 'with', 1),
      s('Painting & Decorating', 'finish', 'overlap', 3, overlapPct: 60),
      s('Balustrades & Railings', 'finish', 'after', 1),
      s('External Site Works', 'external', 'after', 2),
      s('Landscaping', 'external', 'with', 2),
      s('Cleaning & Handover', 'external', 'after', 1),
    ];
  }

  // =================================================================
  // Schedule (working days)
  // =================================================================
  _Schedule _schedule() {
    final secStart = <double>[];
    final secEnd = <double>[];
    final kidStarts = <List<double>?>[];
    for (var si = 0; si < _sections.length; si++) {
      final sec = _sections[si];
      double ss;
      if (si == 0) {
        ss = sec.buffer * 5.0;
      } else {
        final pS = secStart[si - 1];
        final pE = secEnd[si - 1];
        final pDur = pE - pS;
        switch (sec.mode) {
          case 'start':
            ss = sec.buffer * 5.0;
            break;
          case 'with':
            ss = pS + sec.buffer * 5.0;
            break;
          case 'overlap':
            ss = pS + pDur * (sec.overlapPct / 100.0);
            break;
          default:
            ss = pE + sec.buffer * 5.0;
        }
      }
      if (ss < 0) ss = 0;
      secStart.add(ss);
      if (sec.children.isNotEmpty) {
        final cs = <double>[];
        for (var ci = 0; ci < sec.children.length; ci++) {
          final c = sec.children[ci];
          double x;
          if (ci == 0) {
            x = ss + c.buffer.toDouble();
          } else {
            final pcs = cs[ci - 1];
            final pcd = sec.children[ci - 1].days.toDouble();
            switch (c.mode) {
              case 'with':
                x = pcs + c.buffer.toDouble();
                break;
              case 'overlap':
                x = pcs + pcd * (c.overlapPct / 100.0);
                break;
              default:
                x = pcs + pcd + c.buffer.toDouble();
            }
          }
          if (x < ss) x = ss;
          cs.add(x);
        }
        kidStarts.add(cs);
        double e = ss;
        for (var ci = 0; ci < sec.children.length; ci++) {
          final end = cs[ci] + sec.children[ci].days;
          if (end > e) e = end;
        }
        secEnd.add(e);
      } else {
        kidStarts.add(null);
        secEnd.add(ss + sec.weeks * 5.0);
      }
    }
    return _Schedule(secStart, secEnd, kidStarts);
  }

  DateTime _wd(double idx) {
    final i = idx.round();
    final wk = i ~/ 5;
    final dow = i % 5;
    return _start.add(Duration(days: wk * 7 + dow));
  }

  String _short(DateTime d) => DateFormat('d MMM').format(d);
  String _long(DateTime d) => DateFormat('d MMM yyyy').format(d);

  // =================================================================
  // Mutations
  // =================================================================
  _Section get _selSec => _sections[_selSi];
  bool get _selIsChild => _selCi >= 0;

  void _syncNameCtl() {
    final node = _selIsChild ? _selSec.children[_selCi].name : _selSec.name;
    _nameCtl.value = TextEditingValue(
      text: node,
      selection: TextSelection.collapsed(offset: node.length),
    );
  }

  void _select(int si, int ci) {
    setState(() {
      _selSi = si;
      _selCi = ci;
      _inspectorOpen = true;
    });
    _syncNameCtl();
  }

  void _closeInspector() => setState(() => _inspectorOpen = false);
  void _toggleExpand(int si) {
    setState(() => _sections[si].expanded = !_sections[si].expanded);
    _persist();
  }

  void _setName(String v) {
    setState(() {
      if (_selIsChild) {
        _selSec.children[_selCi].name = v;
      } else {
        _selSec.name = v;
      }
    });
    _persist();
  }

  void _setMode(String m) {
    setState(() {
      if (_selIsChild) {
        _selSec.children[_selCi].mode = m;
      } else {
        _selSec.mode = m;
      }
    });
    _persist();
  }

  void _durStep(int d) {
    setState(() {
      if (_selIsChild) {
        final c = _selSec.children[_selCi];
        c.days = (c.days + d).clamp(1, 999);
      } else if (_selSec.children.isEmpty) {
        _selSec.weeks = (_selSec.weeks + d).clamp(1, 999);
      }
    });
    _persist();
  }

  void _bufStep(int d) {
    setState(() {
      if (_selIsChild) {
        final c = _selSec.children[_selCi];
        c.buffer = (c.buffer + d).clamp(0, 999);
      } else {
        _selSec.buffer = (_selSec.buffer + d).clamp(0, 999);
      }
    });
    _persist();
  }

  void _ovStep(int d) {
    setState(() {
      if (_selIsChild) {
        final c = _selSec.children[_selCi];
        c.overlapPct = (c.overlapPct + d).clamp(10, 90);
      } else {
        _selSec.overlapPct = (_selSec.overlapPct + d).clamp(10, 90);
      }
    });
    _persist();
  }

  void _addSection() {
    setState(() {
      _sections.add(_Section(
          name: 'New section', group: 'external', mode: 'after', weeks: 2));
      _selSi = _sections.length - 1;
      _selCi = -1;
      _inspectorOpen = true;
    });
    _syncNameCtl();
    _persist();
  }

  void _addChild() {
    setState(() {
      final sec = _selSec;
      sec.expanded = true;
      sec.children.add(_Child(
          name: 'New sub-task',
          mode: sec.children.isEmpty ? 'start' : 'after',
          days: 3));
      _selCi = sec.children.length - 1;
      _inspectorOpen = true;
    });
    _syncNameCtl();
    _persist();
  }

  void _deleteSel() {
    setState(() {
      if (_selIsChild) {
        _selSec.children.removeAt(_selCi);
        _selCi = -1;
      } else {
        _sections.removeAt(_selSi);
        _selSi = (_selSi - 1).clamp(0, _sections.length - 1);
        _selCi = -1;
      }
    });
    _syncNameCtl();
    _persist();
  }

  // =================================================================
  // BUILD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    final sch = _schedule();
    double totalDays = 0;
    for (final e in sch.secEnd) {
      if (e > totalDays) totalDays = e;
    }
    final totalCeil = totalDays.ceil();
    final weeksCount = (totalCeil / 5).ceil().clamp(1, 9999);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(totalCeil),
          Expanded(
            child: SingleChildScrollView(
              controller: _vCtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legend(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                    child: Column(
                      children: [
                        _board(sch, weeksCount),
                        if (!_readOnly) const SizedBox(height: 12),
                        if (!_readOnly) _addSectionButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_inspectorOpen && !_readOnly) _inspector(sch),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- hero
  Widget _hero(int totalCeil) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: _ink,
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circleBtn(Icons.arrow_back_ios_new_rounded, () {
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
              }),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(_projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                      const SizedBox(height: 2),
                      Text('CONSTRUCTION PROGRAMME',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
              _isOwner ? _visBtn() : _viewOnlyPill(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROGRAMME DURATION',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: _paper.withOpacity(0.55))),
                  const SizedBox(height: 4),
                  Text('${(totalCeil / 5).round()} weeks',
                      style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: _paper,
                          height: 1.0)),
                ],
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$totalCeil working days',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.6))),
                    const SizedBox(height: 2),
                    Text(
                        '${_long(_start)} → ${_long(_wd(totalCeil.toDouble()))}',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.45))),
                  ],
                ),
              ),
            ],
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
                color: _paper.withOpacity(0.12), shape: BoxShape.circle),
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

  // ----------------------------------------------------------------- legend
  Widget _legend() {
    Widget item(String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _inkMute)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          item('Structure', _groupColor['struct']!),
          item('Services', _groupColor['services']!),
          item('Finishes', _groupColor['finish']!),
          item('Site & admin', _groupColor['external']!),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- board
  Widget _board(_Schedule sch, int weeksCount) {
    final timelineW = weeksCount * _weekPx;

    // flatten rows
    final leftCells = <Widget>[];
    final lanes = <Widget>[];
    for (var si = 0; si < _sections.length; si++) {
      final sec = _sections[si];
      final isParent = sec.children.isNotEmpty;
      final ss = sch.secStart[si];
      final se = sch.secEnd[si];
      final dur = se - ss;
      final selHere = _inspectorOpen && si == _selSi && _selCi < 0;
      final color = _groupColor[sec.group] ?? _ink;
      final meta = _modeMeta[sec.mode] ?? _modeMeta['after']!;

      leftCells.add(_leftCell(
        height: _secRowH,
        indent: 10,
        name: sec.name,
        nameSize: 12,
        nameWeight: FontWeight.w800,
        durLabel: isParent
            ? '${(dur / 5).toStringAsFixed(dur % 5 == 0 ? 0 : 1)}w'
            : '${sec.weeks}w',
        ruleIcon: si == 0 ? Icons.flag_rounded : meta.icon,
        ruleColor: selHere ? _green : const Color(0xFFB7C2C7),
        ruleLabel: si == 0
            ? 'start'
            : (sec.mode == 'overlap' ? '${sec.overlapPct}%' : meta.short),
        selected: selHere,
        hasChevron: isParent,
        expanded: sec.expanded,
        onToggle: () => _toggleExpand(si),
        onSelect: () => _select(si, -1),
      ));
      lanes.add(_lane(
        height: _secRowH,
        weeksCount: weeksCount,
        barLeft: ss * _dayPx,
        barWidth: (dur * _dayPx).clamp(_dayPx, 99999).toDouble(),
        color: color,
        barH: isParent ? 8 : 20,
        barText: isParent ? '' : '${sec.weeks}w',
        opacity: isParent ? 0.85 : 1,
        ring: selHere,
      ));

      if (isParent && sec.expanded) {
        for (var ci = 0; ci < sec.children.length; ci++) {
          final c = sec.children[ci];
          final cs = sch.kidStarts[si]![ci];
          final cmeta = _modeMeta[c.mode] ?? _modeMeta['after']!;
          final selC = _inspectorOpen && si == _selSi && ci == _selCi;
          leftCells.add(_leftCell(
            height: _childRowH,
            indent: 24,
            name: c.name,
            nameSize: 11,
            nameWeight: FontWeight.w600,
            durLabel: '${c.days}d',
            ruleIcon:
                ci == 0 ? Icons.subdirectory_arrow_right_rounded : cmeta.icon,
            ruleColor: selC ? _green : const Color(0xFFB7C2C7),
            ruleLabel: ci == 0
                ? 'with section'
                : (c.mode == 'overlap' ? '${c.overlapPct}%' : cmeta.short),
            selected: selC,
            childBg: true,
            onSelect: () => _select(si, ci),
          ));
          lanes.add(_lane(
            height: _childRowH,
            weeksCount: weeksCount,
            barLeft: cs * _dayPx,
            barWidth: (c.days * _dayPx).clamp(_dayPx, 99999).toDouble(),
            color: color,
            barH: 18,
            barText: '${c.days}d',
            opacity: 0.92,
            ring: selC,
          ));
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // frozen left column
                SizedBox(
                  width: _leftW,
                  child: Column(
                    children: [
                      _cornerCell(),
                      ...leftCells,
                    ],
                  ),
                ),
                // scrollable timeline
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: timelineW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _monthHeader(weeksCount),
                          ...lanes,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_readOnly)
            _addRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'Add section',
              color: _green,
              onTap: _addSection,
            ),
        ],
      ),
    );
  }

  Widget _cornerCell() => Container(
        width: _leftW,
        height: _headH,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: _band,
          border: Border(
            right: BorderSide(color: _hairlineOnSurface),
            bottom: BorderSide(color: _border),
          ),
        ),
        child: const Text('PHASE',
            style: TextStyle(
                fontFamily: _body,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _faint)),
      );

  Widget _monthHeader(int weeksCount) {
    // group weeks into calendar months
    final segs = <_MonthSeg>[];
    String? curKey;
    int curStart = 0;
    DateTime curDate = _start;
    for (var w = 0; w < weeksCount; w++) {
      final d = _start.add(Duration(days: w * 7));
      final key = '${d.year}-${d.month}';
      if (key != curKey) {
        if (curKey != null) {
          segs.add(_MonthSeg(_months[curDate.month - 1], w - curStart));
        }
        curKey = key;
        curStart = w;
        curDate = d;
      }
    }
    segs.add(_MonthSeg(_months[curDate.month - 1], weeksCount - curStart));

    return SizedBox(
      height: _headH,
      child: Row(
        children: [
          for (var i = 0; i < segs.length; i++)
            Container(
              width: segs[i].weeks * _weekPx,
              height: _headH,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: i.isEven ? _paper : const Color(0xFFFAFBFC),
                border: const Border(
                  right: BorderSide(color: _line),
                  bottom: BorderSide(color: _border),
                ),
              ),
              child: Text(segs[i].label,
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _inkMute)),
            ),
        ],
      ),
    );
  }

  Widget _leftCell({
    required double height,
    required double indent,
    required String name,
    required double nameSize,
    required FontWeight nameWeight,
    required String durLabel,
    required IconData ruleIcon,
    required Color ruleColor,
    required String ruleLabel,
    required bool selected,
    bool hasChevron = false,
    bool expanded = false,
    bool childBg = false,
    VoidCallback? onToggle,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: _leftW,
        height: height,
        padding: EdgeInsets.fromLTRB(indent, 6, 8, 6),
        decoration: BoxDecoration(
          color: selected
              ? _selTint
              : (childBg ? const Color(0xFFFBFCFD) : _paper),
          border: const Border(
            top: BorderSide(color: _line),
            right: BorderSide(color: _hairlineOnSurface),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasChevron)
                  GestureDetector(
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(
                          expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.chevron_right_rounded,
                          size: 16,
                          color: _faint),
                    ),
                  ),
                Expanded(
                  child: Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: nameSize,
                          fontWeight: nameWeight,
                          height: 1.15,
                          color: _ink)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(durLabel,
                    style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _inkMute)),
                const SizedBox(width: 5),
                Icon(ruleIcon, size: 11, color: ruleColor),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(ruleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _faint)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lane({
    required double height,
    required int weeksCount,
    required double barLeft,
    required double barWidth,
    required Color color,
    required double barH,
    required String barText,
    required double opacity,
    required bool ring,
  }) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Stack(
        children: [
          // week gridlines
          Row(
            children: [
              for (var w = 0; w < weeksCount; w++)
                Container(
                  width: _weekPx,
                  height: height,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: _line)),
                  ),
                ),
            ],
          ),
          Positioned(
            left: barLeft,
            top: (height - barH) / 2,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: barWidth,
                height: barH,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barH >= 18 ? 6 : 4),
                  border: ring ? Border.all(color: _green, width: 2) : null,
                ),
                child: barText.isEmpty
                    ? null
                    : Text(barText,
                        maxLines: 1,
                        style: TextStyle(
                            fontFamily: _display,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _paper.withOpacity(0.92))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addRow({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _addSectionButton() => InkWell(
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
                      color: _inkMute)),
            ],
          ),
        ),
      );

  // ----------------------------------------------------------------- inspector
  Widget _inspector(_Schedule sch) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final sec = _selSec;
    final isChild = _selIsChild;
    final isParent = !isChild && sec.children.isNotEmpty;
    final node = isChild ? sec.children[_selCi] : null;
    final mode = isChild ? node!.mode : sec.mode;
    final overlapPct = isChild ? node!.overlapPct : sec.overlapPct;
    final buffer = isChild ? node!.buffer : sec.buffer;
    final color = _groupColor[sec.group] ?? _ink;
    final isFirst = isChild ? _selCi == 0 : _selSi == 0;

    final nStart =
        isChild ? sch.kidStarts[_selSi]![_selCi] : sch.secStart[_selSi];
    final nDur = isChild
        ? node!.days.toDouble()
        : (isParent
            ? (sch.secEnd[_selSi] - sch.secStart[_selSi])
            : sec.weeks * 5.0);

    List<String> modeKeys;
    if (isChild) {
      modeKeys = isFirst ? ['start'] : ['after', 'overlap', 'with'];
    } else {
      modeKeys = isFirst ? ['start'] : ['after', 'overlap', 'with', 'start'];
    }

    String linkHeading;
    if (isChild) {
      linkHeading = isFirst
          ? 'STARTS WITH THE SECTION'
          : 'RELATIVE TO “${sec.children[_selCi - 1].name.toUpperCase()}”';
    } else if (isFirst) {
      linkHeading = 'THIS SECTION STARTS THE PROGRAMME';
    } else {
      linkHeading = 'RELATIVE TO “${_sections[_selSi - 1].name.toUpperCase()}”';
    }

    final showBuffer = !isFirst && mode != 'overlap';
    final showOverlap = !isFirst && mode == 'overlap';

    return Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: _surface)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F19232D), blurRadius: 30, offset: Offset(0, -10)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(18, 8, 18, bottom + 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // grab handle (close)
          GestureDetector(
            onTap: _closeInspector,
            behavior: HitTestBehavior.opaque,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 2, bottom: 9),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFCBD8DD),
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(right: 9),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: TextField(
                  controller: _nameCtl,
                  onChanged: _setName,
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Name',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                    '${_short(_wd(nStart))} – ${_short(_wd(nStart + nDur))}',
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _faint)),
              ),
              InkWell(
                onTap: _deleteSel,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.delete_outline_rounded,
                      size: 19, color: _danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isParent)
                _stepperBox(
                  label: isChild ? 'DURATION (DAYS)' : 'DURATION (WEEKS)',
                  value: isChild ? '${node!.days}d' : '${sec.weeks}w',
                  onMinus: () => _durStep(-1),
                  onPlus: () => _durStep(1),
                ),
              if (isParent)
                Expanded(
                  flex: 14,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: _band, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('SUMMARY TASK',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: _faint)),
                        const SizedBox(height: 3),
                        Text(
                            'Spans ${((sch.secEnd[_selSi] - sch.secStart[_selSi]) / 5).toStringAsFixed(1)}w · ${sec.children.length} sub-tasks',
                            style: const TextStyle(
                                fontFamily: _display,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                      ],
                    ),
                  ),
                ),
              if (showBuffer) ...[
                const SizedBox(width: 9),
                _stepperBox(
                  label: 'BUFFER',
                  value: '+$buffer${isChild ? 'd' : 'w'}',
                  onMinus: () => _bufStep(-1),
                  onPlus: () => _bufStep(1),
                ),
              ],
              if (showOverlap) ...[
                const SizedBox(width: 9),
                _stepperBox(
                  label: 'START AT',
                  value: '$overlapPct%',
                  onMinus: () => _ovStep(-10),
                  onPlus: () => _ovStep(10),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(linkHeading,
              style: const TextStyle(
                  fontFamily: _body,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: _faint)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < modeKeys.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _modeBtn(modeKeys[i], mode, isFirst)),
              ],
            ],
          ),
          if (!isChild) ...[
            const SizedBox(height: 9),
            InkWell(
              onTap: _addChild,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _dash),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_rounded, size: 16, color: _green),
                    SizedBox(width: 6),
                    Text('Add sub-task',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _green)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepperBox({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Expanded(
      flex: 10,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
            color: _band, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: _faint)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _roundStep(Icons.remove_rounded, false, onMinus),
                Text(value,
                    style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                _roundStep(Icons.add_rounded, true, onPlus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundStep(IconData icon, bool solid, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: solid ? _ink : _paper,
            shape: BoxShape.circle,
            border: solid ? null : Border.all(color: _hairlineOnSurface),
          ),
          child: Icon(icon, size: 15, color: solid ? _paper : _ink),
        ),
      );

  Widget _modeBtn(String key, String current, bool isFirst) {
    final mm = _modeMeta[key]!;
    final active = current == key || (isFirst && key == 'start');
    return InkWell(
      onTap: () => _setMode(key),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
        decoration: BoxDecoration(
          color: active ? _ink : _paper,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? _ink : _hairlineOnSurface),
        ),
        child: Column(
          children: [
            Icon(mm.icon, size: 15, color: active ? _paper : _inkMute),
            const SizedBox(height: 1),
            Text(mm.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: active ? _paper : _inkMute)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Models
// ============================================================================
class _ModeMeta {
  final IconData icon;
  final String label;
  final String short;
  const _ModeMeta(this.icon, this.label, this.short);
}

class _MonthSeg {
  final String label;
  final int weeks;
  const _MonthSeg(this.label, this.weeks);
}

class _Schedule {
  final List<double> secStart;
  final List<double> secEnd;
  final List<List<double>?> kidStarts;
  const _Schedule(this.secStart, this.secEnd, this.kidStarts);
}

class _Child {
  String name;
  String mode; // start | after | overlap | with
  int buffer; // working days
  int overlapPct;
  int days;
  _Child({
    required this.name,
    this.mode = 'after',
    this.buffer = 0,
    this.overlapPct = 50,
    this.days = 3,
  });
}

class _Section {
  String name;
  String group; // struct | services | finish | external
  String mode;
  int buffer; // weeks
  int overlapPct;
  int weeks;
  bool expanded;
  List<_Child> children;
  _Section({
    required this.name,
    required this.group,
    this.mode = 'after',
    this.buffer = 0,
    this.overlapPct = 50,
    this.weeks = 2,
    this.expanded = false,
    List<_Child>? children,
  }) : children = children ?? [];
}
