// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// ProjectTimelinePageView — Construction Programme (Gantt) TEMPLATE.
///
/// Three screens managed internally: START (first-run template chooser) →
/// VIEW (minimal read-only Gantt) → EDIT (slide-in editor for one phase).
///
/// The app owns the phase scaffold + scheduling; the user owns the durations.
/// High-level sections are in WEEKS, sub-tasks in WORKING DAYS, all scheduled
/// on a 5-day working week. Phases link to each other (After / Overlap % /
/// Parallel / From start) with optional buffer.
///
/// Bar colours are two-tone: DARK INK = phase (section) time, LIGHTER SLATE =
/// sub-task time.
class ProjectTimelinePageView extends StatefulWidget {
  const ProjectTimelinePageView({
    super.key,
    this.width,
    this.height,
    this.projectRef,
  });

  final double? width;
  final double? height;
  final DocumentReference? projectRef;

  @override
  State<ProjectTimelinePageView> createState() =>
      _ProjectTimelinePageViewState();
}

class _ProjectTimelinePageViewState extends State<ProjectTimelinePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _band = Color(0xFFF2F5F6);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _green = Color(0xFF4E504F);
  static const Color _selTint = Color(0xFFE7EDF0);
  static const Color _danger = Color(0xFF93A3AC);
  static const Color _dash = Color(0xFFCBD8DD);
  static const Color _ruleIdle = Color(0xFFB7C2C7);
  static const Color _childBg = Color(0xFFFBFCFD);
  static const Color _startBg = Color(0xFFF5F8F9);
  static const Color _header = Color(0xFF2F3A4C); // hero header ink

  // Two-tone bar colours
  static const Color _phaseColor = Color(0xFF1E282E); // dark ink = phase
  static const Color _subColor = Color(0xFF8497A0); // lighter = sub-task
  static const Color _barYellow = Color(0xFFE7E247); // leaf phase bar (yellow)

  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kLocalProgramme = 'subby_local_programme';
  static const String _kLocalStarted = 'subby_local_started';
  static const String _kLocalStart = 'subby_local_start_date';

  static const double _leftW = 150;
  static const double _dayPx = 7; // px per working day
  static const double _weekPx = 35; // px per working week (5 days)
  static const double _secRowH = 46;
  static const double _childRowH = 38;
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
  String _activePath = ''; // active project doc path — scopes the local cache

  late List<_Section> _sections;
  int _selSi = 0;
  int _selCi = -1;

  // 'start' | 'view' | 'edit'
  String _screen = 'start';
  bool _showBanner = false;

  // 'days' | 'weeks' | 'months'  — horizontal axis density
  String _zoom = 'weeks';
  Timer? _progressTimer;

  final TextEditingController _nameCtl = TextEditingController();
  final ScrollController _vCtl = ScrollController();
  final ScrollController _editScrollCtl = ScrollController();
  // Board horizontal scroll: body drives, header follows (pinned date row).
  final ScrollController _hBody = ScrollController();
  final ScrollController _hHead = ScrollController();
  bool _hSyncing = false;

  @override
  void initState() {
    super.initState();
    _sections = buildProgramme('gf'); // harmless placeholder behind START
    _syncNameCtl();
    _hBody.addListener(() {
      if (_hSyncing || !_hHead.hasClients) return;
      _hSyncing = true;
      final max = _hHead.position.maxScrollExtent;
      _hHead.jumpTo(_hBody.offset.clamp(0.0, max));
      _hSyncing = false;
    });
    // NOTE: project resolution happens in didChangeDependencies (route
    // reading needs context).
  }

  bool _resolvedRef = false; // resolve projectRef once
  DocumentReference? _incomingRef; // widget param, else route query param

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedRef) return;
    _resolvedRef = true;

    // Resolution order: widget param, then route query param
    // passed by ProjectDetailPageView, then shared-prefs fallback
    // (handled inside _loadLocal / _loadActiveProject).
    _incomingRef =
        widget.projectRef ?? _readRefFromRoute('projectRef', 'projects');
    if (_incomingRef != null) {
      // Persist so downstream views inherit it and survive cold start.
      SharedPreferences.getInstance()
          .then((p) => p.setString(_kActiveProjectPath, _incomingRef!.path));
    }
    _loadLocal();
    _loadActiveProject();
  }

  // Reads a serialized DocumentReference query param — same logic as
  // SnagListPageView — and turns it into a DocumentReference.
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
    _progSub?.cancel();
    _saveTimer?.cancel();
    _progressTimer?.cancel();
    _nameCtl.dispose();
    _vCtl.dispose();
    _editScrollCtl.dispose();
    _hBody.dispose();
    _hHead.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    // Prefer the project reference passed into the widget; fall back to the
    // shared-prefs "active project" path only when none was provided.
    DocumentReference<Map<String, dynamic>>? ref;
    if (_incomingRef != null) {
      ref = FirebaseFirestore.instance.doc(_incomingRef!.path);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
      if (path.isEmpty) return;
      ref = FirebaseFirestore.instance.doc(path);
    }
    _activePath = ref.path;
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
      // Timeline privacy lives on projects.moduleVisibility['timeline'] so it
      // stays in sync with ProjectDetailPageView.
      String vis = 'shared';
      final mv = data['moduleVisibility'];
      if (mv is Map && mv['timeline'] != null) {
        vis = mv['timeline'].toString() == 'private' ? 'private' : 'shared';
      }
      if (!mounted) return;
      setState(() {
        _projectName = name;
        if (sd is Timestamp) _start = sd.toDate();
        _isOwner = isOwner;
        // Team members may adjust the timeline; owner-only actions (privacy)
        // gate on _isOwner instead of _readOnly.
        _readOnly = false;
        _visibility = vis;
      });
    });

    _progSub = _programmeRef!.snapshots().listen(_onRemoteProgramme);
  }

  // ── Local device persistence (fallback + instant restore) ──
  // Keeps the chosen programme on the device so a relaunch restores it even
  // when no cloud project is active. Firestore overrides this when present.
  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = _incomingRef != null
          ? _incomingRef!.path
          : (prefs.getString(_kActiveProjectPath) ?? '').trim();
      _activePath = path;
      final scope = path.isEmpty ? 'standalone' : path;
      final started = prefs.getBool('$_kLocalStarted::$scope') ?? false;
      if (!started) return; // brand-new project → keep the START chooser
      final raw = prefs.getString('$_kLocalProgramme::$scope');
      final startMs = prefs.getInt('$_kLocalStart::$scope');
      if (!mounted) return;
      setState(() {
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            _sections = decoded
                .whereType<Map>()
                .map<_Section>((e) =>
                    _sectionFromMap(e.map((k, v) => MapEntry(k.toString(), v))))
                .toList();
          }
        }
        if (startMs != null)
          _start = DateTime.fromMillisecondsSinceEpoch(startMs);
        _screen = 'view'; // already started → skip the chooser
        if (_selSi >= _sections.length) {
          _selSi = _sections.isEmpty ? 0 : _sections.length - 1;
          _selCi = -1;
        }
      });
      _syncNameCtl();
    } catch (_) {}
  }

  Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = _activePath.isEmpty ? 'standalone' : _activePath;
      await prefs.setBool('$_kLocalStarted::$scope', true);
      await prefs.setInt(
          '$_kLocalStart::$scope', _start.millisecondsSinceEpoch);
      await prefs.setString('$_kLocalProgramme::$scope',
          jsonEncode(_sections.map(_sectionToMap).toList()));
    } catch (_) {}
  }

  // Apply a remote programme snapshot (real-time sync across devices).
  void _onRemoteProgramme(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      // No saved programme yet → leave the user on the START chooser.
      _remoteLoaded = true;
      return;
    }
    if (_saveTimer?.isActive ?? false) return; // don't clobber pending edits
    final list = data['sections'];
    if (!mounted) return;
    setState(() {
      if (list is List) {
        final parsed = list
            .whereType<Map>()
            .map<_Section>((e) =>
                _sectionFromMap(e.map((k, v) => MapEntry(k.toString(), v))))
            .toList();
        if (parsed.isNotEmpty) {
          _sections = parsed;
          // A returning project already has a programme → skip the chooser.
          if (_screen == 'start') _screen = 'view';
        }
      }
      _remoteLoaded = true;
      if (_selSi >= _sections.length) {
        _selSi = _sections.isEmpty ? 0 : _sections.length - 1;
        _selCi = -1;
      }
    });
    _syncNameCtl();
    _syncProgress();
  }

  Map<String, dynamic> _sectionToMap(_Section s) => {
        'name': s.name,
        'group': s.group,
        'mode': s.mode,
        'buffer': s.buffer,
        'overlapPct': s.overlapPct,
        'days': s.days,
        'pct': s.pct,
        'expanded': s.expanded,
        'children': s.children
            .map((c) => {
                  'name': c.name,
                  'mode': c.mode,
                  'buffer': c.buffer,
                  'overlapPct': c.overlapPct,
                  'days': c.days,
                  'pct': c.pct,
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
              pct: gi(c['pct'], c['done'] == true ? 100 : 0),
            );
          }).toList()
        : <_Child>[];
    return _Section(
      name: (m['name'] ?? 'Section').toString(),
      group: (m['group'] ?? 'external').toString(),
      mode: (m['mode'] ?? 'after').toString(),
      buffer: gi(m['buffer'], 0),
      overlapPct: gi(m['overlapPct'], 50),
      days: gi(m['days'],
          (m['weeks'] is num ? (m['weeks'] as num).toInt() * 5 : 10)),
      expanded: m['expanded'] == true,
      pct: gi(m['pct'], m['done'] == true ? 100 : 0),
      children: kids,
    );
  }

  // Debounced save so stepping a value doesn't spam Firestore.
  void _persist() {
    _saveLocal(); // local mirror is instant + always on
    if (_readOnly || _programmeRef == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _saveNow() async {
    final ref = _programmeRef;
    if (ref == null || _readOnly) return;
    try {
      await ref.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'sections': _sections.map(_sectionToMap).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
    _syncProgress();
  }

  // Timeline privacy → projects.moduleVisibility['timeline'] (shared with
  // ProjectDetailPageView; the project-doc listener flips our icon back).
  void _toggleVisibility() {
    if (!_isOwner) return; // only the project owner may change privacy
    final ref = _projectRef;
    final next = _visibility == 'shared' ? 'private' : 'shared';
    setState(() => _visibility = next); // optimistic
    if (ref == null) return;
    ref.set(<String, dynamic>{
      'moduleVisibility': <String, dynamic>{'timeline': next},
    }, SetOptions(merge: true)).catchError((_) {});
  }

  // Chart-derived progress → projects.progress (drives Completion on the
  // detail page). Progress = share of working-days actually marked done.
  void _syncProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(milliseconds: 800), () async {
      final ref = _projectRef;
      if (ref == null || _readOnly) return;
      final p = _completionFrac();
      try {
        await ref.set(<String, dynamic>{
          'progress': p,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    });
  }

  // Completion = working-days weighted by each task's % complete.
  double _completionFrac() {
    double totalW = 0, doneW = 0;
    for (final sec in _sections) {
      if (sec.children.isNotEmpty) {
        for (final c in sec.children) {
          totalW += c.days;
          doneW += c.days * (c.pct / 100.0);
        }
      } else {
        totalW += sec.days;
        doneW += sec.days * (sec.pct / 100.0);
      }
    }
    return totalW > 0 ? (doneW / totalW).clamp(0.0, 1.0) : 0.0;
  }

  // % complete of a section (leaf: own pct; parent: day-weighted child avg).
  int _pctOf(_Section sec) {
    if (sec.children.isEmpty) return sec.pct;
    double t = 0, d = 0;
    for (final c in sec.children) {
      t += c.days;
      d += c.days * (c.pct / 100.0);
    }
    return t > 0 ? (d / t * 100).round() : 0;
  }

  int _completionPct() => (_completionFrac() * 100).round();
  bool _hasWork() {
    for (final sec in _sections) {
      if (sec.children.isNotEmpty) return true;
      if (sec.days > 0) return true;
    }
    return false;
  }

  void _setPct(int v) {
    final p = v.clamp(0, 100);
    setState(() {
      if (_selIsChild) {
        _selSec.children[_selCi].pct = p;
      } else if (_selSec.children.isEmpty) {
        _selSec.pct = p;
      }
    });
    _persist();
  }

  void _setChildPct(int ci, int v) {
    setState(() => _selSec.children[ci].pct = v.clamp(0, 100));
    _persist();
  }

  // Working-day index of the real current date, relative to _start.
  int _todayIndex(int total) {
    final now = DateTime.now();
    final s = DateTime(_start.year, _start.month, _start.day);
    final n = DateTime(now.year, now.month, now.day);
    if (n.isBefore(s)) return 0;
    int wd = 0;
    var d = s;
    while (d.isBefore(n)) {
      if (d.weekday <= 5) wd++;
      d = d.add(const Duration(days: 1));
    }
    return wd > total ? total : wd;
  }

  // =================================================================
  // Template generator — scales the trade sequence per floor config
  // =================================================================
  List<_Section> buildProgramme(String key) {
    if (key == 'scratch') return <_Section>[];

    // Trade sequence per floor config — durations are in WORKING DAYS.
    _Section p(String name, String group, String mode, int days,
            {int buffer = 0, int overlapPct = 50}) =>
        _Section(
            name: name,
            group: group,
            mode: mode,
            days: days,
            buffer: buffer,
            overlapPct: overlapPct);

    switch (key) {
      case 'gf': // Ground Floor
        return <_Section>[
          p('Professional Services', 'external', 'start', 20),
          p('Site Preparation', 'external', 'after', 2),
          p('Site Establishment', 'external', 'after', 2),
          p('Earthworks & Excavation', 'struct', 'after', 5),
          p('Brickwork & Concrete', 'struct', 'after', 20),
          p('Structural Steel Works', 'external', 'overlap', 8),
          p('Suspended Roof Slab', 'external', 'after', 10),
          p('Roofing', 'external', 'after', 10),
          p('Plumbing & Drainage', 'external', 'with', 10),
          p('Electrical Works', 'external', 'with', 10),
          p('Plastering & Screeds', 'finish', 'overlap', 15),
          p('Windows & Door Frames', 'struct', 'overlap', 5),
          p('Waterproofing', 'external', 'after', 5),
          p('Ceilings & Partitioning', 'finish', 'overlap', 5),
          p('Joinery & Carpentry', 'finish', 'after', 5),
          p('Painting & Wall Covering', 'finish', 'overlap', 21,
              overlapPct: 60),
          p('Tiling', 'finish', 'with', 10),
          p('Kitchen (Built-in Units)', 'finish', 'overlap', 7, overlapPct: 30),
          p('Built-in Cupboards', 'finish', 'with', 7),
          p('Sanitary Fittings', 'services', 'after', 5),
          p('Floor Covering', 'finish', 'after', 10),
          p('Electrical Fittings', 'services', 'overlap', 5),
          p('External Site Works', 'external', 'overlap', 10),
          p('Cleaning & Handover', 'external', 'overlap', 5),
        ];
      case 'gf1': // Ground + First
        return <_Section>[
          p('Professional Services', 'external', 'start', 20),
          p('Site Preparation', 'external', 'after', 2),
          p('Site Establishment', 'external', 'after', 2),
          p('Earthworks & Excavation', 'struct', 'after', 5),
          p('Brickwork & Concrete', 'struct', 'after', 15),
          p('Structural Steel Works', 'external', 'overlap', 5),
          p('Suspended Floor Slab', 'struct', 'after', 10),
          p('Brickwork & Concrete', 'external', 'after', 15),
          p('Structural Steel Works', 'external', 'after', 5),
          p('Suspended Roof Slab', 'external', 'with', 10),
          p('Roofing', 'external', 'after', 10),
          p('Plumbing & Drainage', 'external', 'with', 10),
          p('Electrical Works', 'external', 'with', 10),
          p('Plastering & Screeds', 'finish', 'overlap', 15),
          p('Windows & Door Frames', 'struct', 'overlap', 5),
          p('Waterproofing', 'external', 'after', 5),
          p('Ceilings & Partitioning', 'finish', 'overlap', 5),
          p('Joinery & Carpentry', 'finish', 'after', 5),
          p('Painting & Wall Covering', 'finish', 'overlap', 21,
              overlapPct: 60),
          p('Tiling', 'finish', 'with', 10),
          p('Balustrades & Railings', 'external', 'after', 5),
          p('Kitchen (Built-in Units)', 'finish', 'with', 7),
          p('Built-in Cupboards', 'finish', 'with', 7),
          p('Sanitary Fittings', 'services', 'after', 5),
          p('Floor Covering', 'finish', 'after', 10),
          p('Electrical Fittings', 'services', 'overlap', 5),
          p('External Site Works', 'external', 'overlap', 10),
          p('Cleaning & Handover', 'external', 'overlap', 5),
        ];
      case 'lgfgf': // Lower Ground + Ground
        return <_Section>[
          p('Professional Services', 'external', 'start', 20),
          p('Site Preparation', 'external', 'after', 2),
          p('Site Establishment', 'external', 'after', 2),
          p('Earthworks & Excavation', 'struct', 'after', 5),
          p('Shoring & Retaining Walls', 'struct', 'after', 10),
          p('Brickwork & Concrete', 'struct', 'after', 10),
          p('Structural Steel Works', 'external', 'overlap', 5),
          p('Suspended Floor Slab', 'struct', 'after', 10),
          p('Brickwork & Concrete', 'external', 'after', 15),
          p('Structural Steel Works', 'external', 'after', 5),
          p('Suspended Roof Slab', 'external', 'with', 10),
          p('Roofing', 'external', 'after', 10),
          p('Plumbing & Drainage', 'external', 'with', 10),
          p('Electrical Works', 'external', 'with', 10),
          p('Plastering & Screeds', 'finish', 'overlap', 15),
          p('Windows & Door Frames', 'struct', 'overlap', 5),
          p('Waterproofing', 'external', 'after', 5),
          p('Ceilings & Partitioning', 'finish', 'overlap', 5),
          p('Joinery & Carpentry', 'finish', 'after', 5),
          p('Painting & Wall Covering', 'finish', 'overlap', 21,
              overlapPct: 60),
          p('Tiling', 'finish', 'with', 10),
          p('Balustrades & Railings', 'external', 'after', 5),
          p('Kitchen (Built-in Units)', 'finish', 'with', 7),
          p('Built-in Cupboards', 'finish', 'with', 7),
          p('Sanitary Fittings', 'services', 'after', 5),
          p('Floor Covering', 'finish', 'after', 10),
          p('Electrical Fittings', 'services', 'overlap', 5),
          p('External Site Works', 'external', 'overlap', 10),
          p('Cleaning & Handover', 'external', 'overlap', 5),
        ];
      case 'lgfgf1': // Lower Ground + Ground + First
      default:
        return <_Section>[
          p('Professional Services', 'external', 'start', 20),
          p('Site Preparation', 'external', 'after', 2),
          p('Site Establishment', 'external', 'after', 2),
          p('Earthworks & Excavation', 'struct', 'after', 5),
          p('Shoring & Retaining Walls', 'struct', 'after', 10),
          p('Brickwork & Concrete', 'struct', 'after', 10),
          p('Structural Steel Works', 'external', 'overlap', 5),
          p('Suspended Floor Slab 1', 'struct', 'after', 10),
          p('Brickwork & Concrete', 'external', 'after', 15),
          p('Structural Steel Works', 'external', 'after', 5),
          p('Suspended Floor Slab 2', 'struct', 'with', 10),
          p('Brickwork & Concrete', 'external', 'after', 15),
          p('Structural Steel Works', 'struct', 'after', 5),
          p('Suspended Roof Slab', 'external', 'with', 10),
          p('Roofing', 'external', 'after', 10),
          p('Plumbing & Drainage', 'external', 'with', 10),
          p('Electrical Works', 'external', 'with', 10),
          p('Plastering & Screeds', 'finish', 'overlap', 15),
          p('Windows & Door Frames', 'struct', 'overlap', 5),
          p('Waterproofing', 'external', 'after', 5),
          p('Ceilings & Partitioning', 'finish', 'overlap', 5),
          p('Joinery & Carpentry', 'finish', 'after', 5),
          p('Painting & Wall Covering', 'finish', 'overlap', 21,
              overlapPct: 60),
          p('Tiling', 'finish', 'with', 10),
          p('Balustrades & Railings', 'external', 'after', 5),
          p('Kitchen (Built-in Units)', 'finish', 'with', 7),
          p('Built-in Cupboards', 'finish', 'with', 7),
          p('Sanitary Fittings', 'services', 'after', 5),
          p('Floor Covering', 'finish', 'after', 10),
          p('Electrical Fittings', 'services', 'overlap', 5),
          p('External Site Works', 'external', 'overlap', 10),
          p('Cleaning & Handover', 'external', 'overlap', 5),
        ];
    }
  }

  void _pickTemplate(String key) {
    setState(() {
      _sections = buildProgramme(key);
      _selSi = 0;
      _selCi = -1;
      _screen = 'view';
      _showBanner = true;
    });
    _syncNameCtl();
    _saveLocal();
    _saveNow();
  }

  void _startScratch() {
    setState(() {
      _sections = <_Section>[];
      _selSi = 0;
      _selCi = -1;
      _screen = 'view';
      _showBanner = false;
    });
    _saveLocal();
    _saveNow();
  }

  void _dismissBanner() => setState(() => _showBanner = false);
  void _setZoom(String z) => setState(() => _zoom = z);

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
        ss = sec.buffer.toDouble();
      } else {
        final pS = secStart[si - 1];
        final pE = secEnd[si - 1];
        final pDur = pE - pS;
        switch (sec.mode) {
          case 'start':
            ss = sec.buffer.toDouble();
            break;
          case 'with':
            ss = pS + sec.buffer.toDouble();
            break;
          case 'overlap':
            ss = pS + pDur * (sec.overlapPct / 100.0);
            break;
          default:
            ss = pE + sec.buffer.toDouble();
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
        secEnd.add(ss + sec.days);
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
  String _fmtDur(double days) {
    final w = days / 5;
    return (days % 5 == 0 ? w.round().toString() : w.toStringAsFixed(1)) + 'w';
  }

  // =================================================================
  // Mutations
  // =================================================================
  _Section get _selSec => _sections[_selSi];
  bool get _selIsChild => _selCi >= 0;

  void _syncNameCtl() {
    if (_sections.isEmpty) {
      _nameCtl.value = const TextEditingValue(text: '');
      return;
    }
    final si = _selSi.clamp(0, _sections.length - 1);
    final sec = _sections[si];
    final node = (_selCi >= 0 && _selCi < sec.children.length)
        ? sec.children[_selCi].name
        : sec.name;
    _nameCtl.value = TextEditingValue(
      text: node,
      selection: TextSelection.collapsed(offset: node.length),
    );
  }

  void _openEdit(int si, int ci) {
    if (_readOnly) return;
    final ref = _projectRef;
    if (ref == null) return;
    // The node editor is its own route now (EditProjectTimelinePage) so it gets
    // native push/pop + swipe-back. Pass the project + the node to edit; the
    // edit page saves to the shared programme doc, which this view streams.
    context.pushNamed(
      'EditProjectTimelinePage',
      queryParameters: {
        'projectRef': serializeParam(ref, ParamType.DocumentReference),
        'secIndex': si.toString(),
        'childIndex': ci.toString(),
      }.withoutNulls,
    );
  }

  void _back() {
    setState(() {
      if (_screen == 'edit') {
        _screen = 'view';
      }
    });
  }

  // Left-to-right swipe closes the in-widget EDIT layer (the native iOS
  // edge-swipe can't animate this state-driven layer, so we handle the fling).
  Widget _swipeToClose({required Widget child, required VoidCallback onClose}) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 250) onClose(); // fling right → dismiss
      },
      child: child,
    );
  }

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
        _selSec.days = (_selSec.days + d).clamp(1, 999);
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

  Future<void> _addSection() async {
    if (_readOnly) return;
    final ref = _projectRef;
    setState(() {
      _sections.add(_Section(
          name: 'New section', group: 'external', mode: 'after', days: 10));
      _selSi = _sections.length - 1;
      _selCi = -1;
    });
    _syncNameCtl();
    await _saveNow(); // land the new section in the shared doc before editing
    if (!mounted || ref == null) return;
    context.pushNamed(
      'EditProjectTimelinePage',
      queryParameters: {
        'projectRef': serializeParam(ref, ParamType.DocumentReference),
        'secIndex': (_sections.length - 1).toString(),
        'childIndex': '-1',
      }.withoutNulls,
    );
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
    });
    _syncNameCtl();
    _persist();
  }

  void _moveSel(int dir) {
    setState(() {
      if (_selIsChild) {
        final kids = _selSec.children;
        final j = _selCi + dir;
        if (j < 0 || j >= kids.length) return;
        final tmp = kids[_selCi];
        kids[_selCi] = kids[j];
        kids[j] = tmp;
        _selCi = j;
      } else {
        final j = _selSi + dir;
        if (j < 0 || j >= _sections.length) return;
        final tmp = _sections[_selSi];
        _sections[_selSi] = _sections[j];
        _sections[j] = tmp;
        _selSi = j;
      }
    });
    _persist();
  }

  // offset 0 = above, 1 = below
  void _insertRel(int offset) {
    setState(() {
      if (_selIsChild) {
        final kids = _selSec.children;
        final at = _selCi + offset;
        if (at == 0 && kids.isNotEmpty && kids[0].mode == 'start') {
          kids[0].mode = 'after';
        }
        kids.insert(
            at,
            _Child(
                name: 'New sub-task',
                mode: at == 0 ? 'start' : 'after',
                days: 3));
        _selCi = at;
      } else {
        final at = _selSi + offset;
        _sections.insert(
            at,
            _Section(
                name: 'New section',
                group: 'external',
                mode: at == 0 ? 'start' : 'after',
                days: 10));
        _selSi = at;
        _selCi = -1;
      }
    });
    _syncNameCtl();
    _persist();
  }

  void _deleteSel() {
    final bool isChild = _selIsChild;
    final String nm = isChild ? _selSec.children[_selCi].name : _selSec.name;
    _showDeleteDialog(
      title: isChild ? 'Delete sub-task?' : 'Delete section?',
      message:
          '“$nm” will be permanently removed from the programme. This can’t be undone.',
      confirmLabel: isChild ? 'Delete sub-task' : 'Delete section',
      onConfirm: _performDeleteSel,
    );
  }

  // Shared destructive-confirm module — full-width centred card (matches the
  // delete sheets across the app). Uses the app's red accent.
  Future<void> _showDeleteDialog({
    required String title,
    required String message,
    required String confirmLabel,
    VoidCallback? onConfirm,
  }) async {
    const Color red = Color(0xFFAC0C0C);
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
              borderRadius: BorderRadius.circular(10),
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
                    color: red.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: red.withOpacity(0.22), width: 1),
                  ),
                  child: const Icon(Icons.delete_rounded, color: red, size: 30),
                ),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: _ink)),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: _inkMute)),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (onConfirm != null) onConfirm();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: red, borderRadius: BorderRadius.circular(10)),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _paper)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFCBD8DD), width: 1.4),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
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

  void _performDeleteSel() {
    setState(() {
      if (_selIsChild) {
        _selSec.children.removeAt(_selCi);
        _selCi = -1;
      } else {
        _sections.removeAt(_selSi);
        if (_sections.isEmpty) {
          _selSi = 0;
          _screen = 'view';
        } else {
          _selSi = (_selSi - 1).clamp(0, _sections.length - 1);
          _screen = 'view';
        }
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
    const dur = Duration(milliseconds: 300);
    const curve = Curves.easeOutCubic;

    // VIEW sits underneath; START sits on top and slides off once chosen. The
    // node editor is now its own route (EditProjectTimelinePage), so there is
    // no in-widget EDIT layer here and this page pops back natively.
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: _viewScreen()),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _screen != 'start',
                child: AnimatedSlide(
                  duration: dur,
                  curve: curve,
                  offset:
                      _screen == 'start' ? Offset.zero : const Offset(-1, 0),
                  child: _startScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================================================================
  // START / FIRST-RUN SCREEN
  // =================================================================
  Widget _startScreen() {
    final top = MediaQuery.of(context).viewPadding.top;
    final defs = <List<String>>[
      ['gf', 'Ground Floor', 'Single-storey new build'],
      ['gf1', 'Ground Floor + First Floor', 'Two-storey new build'],
      ['lgfgf', 'Lower Ground + Ground Floor', 'Basement & ground level'],
      ['lgfgf1', 'Lower Ground + Ground + First', 'Full three-level build'],
    ];
    final floorViz = <String, List<bool>>{
      // top-down: true = above ground (solid), false = below ground (dashed)
      'gf': [true],
      'gf1': [true, true],
      'lgfgf': [true, false],
      'lgfgf1': [true, true, false],
    };

    return Container(
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ink header
          Container(
            width: double.infinity,
            color: _header,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _circleBtn(Icons.arrow_back_ios_new_rounded, () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                }),
                const SizedBox(height: 16),
                Text('PROGRAMME',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: _paper.withOpacity(0.5))),
                const SizedBox(height: 10),
                const Text('Start a new\nprogramme',
                    style: TextStyle(
                        fontFamily: _display,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.05,
                        color: _paper)),
                const SizedBox(height: 9),
                Text(
                    'Pick a template to load the standard trade sequence — or build your own from scratch.',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: _paper.withOpacity(0.6))),
              ],
            ),
          ),
          // body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHOOSE A TEMPLATE',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _faint)),
                  const SizedBox(height: 10),
                  for (final d in defs)
                    _templateCard(d[0], d[1], d[2], floorViz[d[0]]!),
                  // divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Divider(color: _hairlineOnSurface)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OR',
                              style: TextStyle(
                                  fontFamily: _body,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: _ruleIdle)),
                        ),
                        const Expanded(
                            child: Divider(color: _hairlineOnSurface)),
                      ],
                    ),
                  ),
                  // scratch
                  _scratchCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(
      String key, String title, String sub, List<bool> floors) {
    final secs = buildProgramme(key);
    // compute est. weeks
    final saved = _sections;
    _sections = secs;
    final sch = _schedule();
    _sections = saved;
    double td = 0;
    for (final e in sch.secEnd) {
      if (e > td) td = e;
    }
    final weeks = (td.ceil() / 5).round();
    final meta = '${secs.length} phases · ≈$weeks weeks';

    return InkWell(
      onTap: () => _pickTemplate(key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // floor-stack glyph
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F4),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < floors.length; i++) ...[
                    if (i > 0) const SizedBox(height: 3),
                    Container(
                      height: 7,
                      decoration: BoxDecoration(
                        color: floors[i] ? _ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: floors[i]
                            ? null
                            : Border.all(
                                color: _faint,
                                width: 1.5,
                                style: BorderStyle.solid),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: _display,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: _ink)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _faint)),
                  const SizedBox(height: 5),
                  Text(meta,
                      style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: _green)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _dash),
          ],
        ),
      ),
    );
  }

  Widget _scratchCard() => InkWell(
        onTap: _startScratch,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _dash, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F4),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_rounded, size: 24, color: _green),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Start from scratch',
                        style: TextStyle(
                            fontFamily: _display,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    SizedBox(height: 2),
                    Text('Empty timeline — add every phase yourself',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _faint)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: _dash),
            ],
          ),
        ),
      );

  // =================================================================
  // VIEW SCREEN
  // =================================================================
  Widget _viewScreen() {
    final sch = _schedule();
    double totalDays = 0;
    for (final e in sch.secEnd) {
      if (e > totalDays) totalDays = e;
    }
    final totalCeil = totalDays.ceil();
    final weeksCount = (totalCeil / 5).ceil().clamp(1, 9999);
    final hasRows = _sections.isNotEmpty;

    final parts = hasRows ? _board(sch, weeksCount) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(totalCeil),
        Expanded(
          child: CustomScrollView(
            controller: _vCtl,
            slivers: [
              if (_showBanner && !_readOnly)
                SliverToBoxAdapter(child: _banner()),
              SliverToBoxAdapter(child: _overviewCard(totalCeil)),
              if (hasRows) SliverToBoxAdapter(child: _tapHint()),
              if (hasRows) SliverToBoxAdapter(child: _zoomRow()),
              if (hasRows)
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (hasRows)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _BoardHeaderDelegate(
                        extent: _headH + 1, child: parts!.header),
                  ),
                ),
              if (hasRows)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    child: parts!.body,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    child: _emptyState(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // White overview card — programme duration + completion (matches
  // ProjectDetailPageView's _rOverviewCard treatment).
  Widget _overviewCard(int totalCeil) {
    final weeks = (totalCeil / 5).round();
    final pct = _completionPct();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROGRAMME',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: _inkMute)),
                    const SizedBox(height: 6),
                    Text('$weeks weeks',
                        style: const TextStyle(
                            fontFamily: _display,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                            height: 0.95,
                            color: _ink)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('DURATION',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: _faint)),
                      const SizedBox(height: 3),
                      Text('$totalCeil days',
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                color: _surface,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _completionFrac(),
                    child: Container(
                      decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: _line),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.event_rounded, size: 16, color: _faint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${_long(_start)} → ${_long(_wd(totalCeil.toDouble()))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _inkMute)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: _faint),
              const SizedBox(width: 8),
              Text('$pct% complete · $totalCeil working days',
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _inkMute)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _zoomRow() {
    if (_sections.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: _surface, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _zoomSegLight('days', 'Day'),
              _zoomSegLight('weeks', 'Week'),
              _zoomSegLight('months', 'Month'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomSegLight(String k, String label) {
    final active = _zoom == k;
    return GestureDetector(
      onTap: () => _setZoom(k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _paper : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 3,
                      offset: Offset(0, 1))
                ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: _body,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? _ink : _inkMute)),
      ),
    );
  }

  Widget _banner() => Container(
        width: double.infinity,
        color: const Color(0xFFEDF1F3),
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Row(
          children: [
            const Icon(Icons.bookmark_added_rounded, size: 17, color: _green),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                  'Template loaded — adjust durations & links to your project',
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: _inkMute)),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _dismissBanner,
              child: const Icon(Icons.close_rounded, size: 17, color: _faint),
            ),
          ],
        ),
      );

  Widget _tapHint() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Row(
          children: const [
            Icon(Icons.touch_app_outlined, size: 14, color: _faint),
            SizedBox(width: 6),
            Text('Tap any phase to edit its duration & links',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _faint)),
          ],
        ),
      );

  Widget _emptyState() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(22, 44, 22, 44),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_note_rounded, size: 36, color: _dash),
            const SizedBox(height: 10),
            const Text('No phases yet',
                style: TextStyle(
                    fontFamily: _display,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
            const SizedBox(height: 6),
            const SizedBox(
              width: 230,
              child: Text(
                  'Add your first phase to start building the programme from scratch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: _faint)),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _addSection,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                    color: _ink, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, size: 17, color: _paper),
                    SizedBox(width: 7),
                    Text('Add phase',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _paper)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // ----------------------------------------------------------------- hero
  Widget _hero(int totalCeil) {
    final top = MediaQuery.of(context).viewPadding.top;
    return Container(
      width: double.infinity,
      color: _header,
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 14),
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
                      Text('PROGRAMME',
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
        ],
      ),
    );
  }

  // Scrolls away with the page — the dark colour continues seamlessly below
  // the pinned _hero bar. Holds the duration stat, completion bar and zoom.
  Widget _heroLower(int totalCeil) {
    return Container(
      width: double.infinity,
      color: _header,
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (_hasWork()) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: _paper.withOpacity(0.16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _completionFrac(),
                          child: Container(
                            decoration: BoxDecoration(
                                color: _paper,
                                borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Text('${_completionPct()}% done',
                    style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _paper)),
              ],
            ),
          ],
          if (_sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: _paper.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _zoomSeg('days', 'Day'),
                    _zoomSeg('weeks', 'Week'),
                    _zoomSeg('months', 'Month'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _zoomSeg(String k, String label) {
    final active = _zoom == k;
    return GestureDetector(
      onTap: () => _setZoom(k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: active ? _paper : Colors.transparent,
            borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: TextStyle(
                fontFamily: _body,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? _ink : _paper.withOpacity(0.7))),
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

  // Team members can edit the timeline but not its privacy — show the
  // owner-set visibility as a locked, non-tappable chip.
  Widget _viewOnlyPill() => Container(
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
      );

  // ----------------------------------------------------------------- board
  _BoardParts _board(_Schedule sch, int weeksCount) {
    double totalDays = 0;
    for (final e in sch.secEnd) {
      if (e > totalDays) totalDays = e;
    }
    final totalCeil = totalDays.ceil() < 1 ? 1 : totalDays.ceil();
    final pxPerDay = _zoom == 'days' ? 16.0 : (_zoom == 'months' ? 3.2 : 7.0);
    final timelineW = totalCeil * pxPerDay;

    // Month bands measured in WORKING DAYS (so they align at any zoom).
    final monthSegs = <_DaySeg>[];
    {
      String? curKey;
      int curMonth = _start.month - 1, count = 0;
      for (var i = 0; i < totalCeil; i++) {
        final d = _wd(i.toDouble());
        final key = '${d.year}-${d.month}';
        if (key != curKey) {
          if (curKey != null) monthSegs.add(_DaySeg(_months[curMonth], count));
          curKey = key;
          curMonth = d.month - 1;
          count = 0;
        }
        count++;
      }
      monthSegs.add(_DaySeg(_months[curMonth], count));
    }

    // Vertical gridlines (granularity follows the zoom).
    final gridXs = <double>[];
    if (_zoom == 'days') {
      for (var i = 1; i < totalCeil; i++) {
        gridXs.add(i * pxPerDay);
      }
    } else if (_zoom == 'months') {
      double acc = 0;
      for (var m = 0; m < monthSegs.length - 1; m++) {
        acc += monthSegs[m].days * pxPerDay;
        gridXs.add(acc);
      }
    } else {
      for (var i = 5; i < totalCeil; i += 5) {
        gridXs.add(i * pxPerDay);
      }
    }

    // TODAY marker.
    final todayIdx = _todayIndex(totalCeil);
    final todayShow = todayIdx >= 0 && todayIdx <= totalCeil;
    final todayX = todayIdx * pxPerDay;

    final leftCells = <Widget>[];
    final lanes = <Widget>[];
    for (var si = 0; si < _sections.length; si++) {
      final sec = _sections[si];
      final isParent = sec.children.isNotEmpty;
      final ss = sch.secStart[si];
      final se = sch.secEnd[si];
      final dur = se - ss;

      leftCells.add(_leftCell(
        height: _secRowH,
        indent: 12,
        name: sec.name,
        nameSize: 12,
        nameWeight: FontWeight.w800,
        hasChevron: isParent,
        expanded: sec.expanded,
        childBg: false,
        onToggle: () => _toggleExpand(si),
        onSelect: () => _openEdit(si, -1),
      ));
      lanes.add(_lane(
        height: _secRowH,
        barLeft: ss * pxPerDay,
        barWidth: (dur * pxPerDay).clamp(pxPerDay, 99999).toDouble(),
        color: isParent ? _phaseColor : _barYellow,
        textColor: isParent ? _paper : _ink,
        barH: isParent ? 8 : 20,
        barText: isParent ? '' : '${sec.days}d',
        opacity: isParent ? 0.85 : 1,
        fillFrac: _pctOf(sec) / 100.0,
      ));

      if (isParent && sec.expanded) {
        for (var ci = 0; ci < sec.children.length; ci++) {
          final c = sec.children[ci];
          final cs = sch.kidStarts[si]![ci];
          leftCells.add(_leftCell(
            height: _childRowH,
            indent: 26,
            name: c.name,
            nameSize: 11,
            nameWeight: FontWeight.w600,
            hasChevron: false,
            expanded: false,
            childBg: true,
            onToggle: () {},
            onSelect: () => _openEdit(si, ci),
          ));
          lanes.add(_lane(
            height: _childRowH,
            barLeft: cs * pxPerDay,
            barWidth: (c.days * pxPerDay).clamp(pxPerDay, 99999).toDouble(),
            color: _subColor,
            barH: 18,
            barText: '${c.days}d',
            opacity: 1,
            fillFrac: c.pct / 100.0,
          ));
        }
      }
    }

    final headerInner = SizedBox(
      height: _headH,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < monthSegs.length; i++)
                Container(
                  width: monthSegs[i].days * pxPerDay,
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
                  child: Text(monthSegs[i].label,
                      style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _inkMute)),
                ),
            ],
          ),
          if (todayShow)
            Positioned(
              left: todayX,
              top: 5,
              child: FractionalTranslation(
                translation: const Offset(-0.5, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFAC0C0C),
                      borderRadius: BorderRadius.circular(999)),
                  child: const Text('TODAY',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: _paper)),
                ),
              ),
            ),
        ],
      ),
    );

    final lanesInner = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                for (final gx in gridXs)
                  Positioned(
                    left: gx,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: _line),
                  ),
              ],
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: lanes),
        if (todayShow)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    left: todayX - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                        width: 2,
                        color: const Color(0xFFAC0C0C).withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final header = Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(
          top: BorderSide(color: _border),
          left: BorderSide(color: _border),
          right: BorderSide(color: _border),
        ),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _cornerCell(),
          Expanded(
            child: SingleChildScrollView(
              controller: _hHead,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(width: timelineW, child: headerInner),
            ),
          ),
        ],
      ),
    );

    final body = Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(
          left: BorderSide(color: _border),
          right: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _leftW,
                  child: Column(children: leftCells),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hBody,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: timelineW, child: lanesInner),
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

    return _BoardParts(header: header, body: body);
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
    required bool hasChevron,
    required bool expanded,
    required bool childBg,
    required VoidCallback onToggle,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: _leftW,
        height: height,
        padding: EdgeInsets.fromLTRB(indent, 0, 6, 0),
        decoration: BoxDecoration(
          color: childBg ? _childBg : _paper,
          border: const Border(
            top: BorderSide(color: _line),
            right: BorderSide(color: _hairlineOnSurface),
          ),
        ),
        child: Row(
          children: [
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
            if (hasChevron)
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.chevron_right_rounded,
                    size: 19,
                    color: _green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lane({
    required double height,
    required double barLeft,
    required double barWidth,
    required Color color,
    required double barH,
    required String barText,
    required double opacity,
    double fillFrac = 0,
    Color textColor = _paper,
  }) {
    final showCheck = fillFrac >= 1.0 && barH >= 18;
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: barLeft,
            top: (height - barH) / 2,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: barWidth,
                height: barH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barH >= 18 ? 6 : 4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (fillFrac > 0)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: fillFrac.clamp(0.0, 1.0),
                          child: Container(color: textColor.withOpacity(0.22)),
                        ),
                      ),
                    Positioned.fill(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showCheck) ...[
                              Icon(Icons.check_rounded,
                                  size: 12, color: textColor),
                              const SizedBox(width: 3),
                            ],
                            if (barText.isNotEmpty)
                              Text(barText,
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontFamily: _display,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: textColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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

  // =================================================================
  // EDIT SCREEN (slide-in)
  // =================================================================
  Widget _editScreen() {
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    if (_sections.isEmpty) {
      // safety — nothing to edit
      return Container(color: _startBg);
    }
    final sch = _schedule();
    final sec = _selSec;
    final isChild = _selIsChild;
    final isParent = !isChild && sec.children.isNotEmpty;
    final node = isChild ? sec.children[_selCi] : null;
    final mode = isChild ? node!.mode : sec.mode;
    final overlapPct = isChild ? node!.overlapPct : sec.overlapPct;
    final buffer = isChild ? node!.buffer : sec.buffer;
    final isFirst = isChild ? _selCi == 0 : _selSi == 0;

    final nStart =
        isChild ? sch.kidStarts[_selSi]![_selCi] : sch.secStart[_selSi];
    final nDur = isChild
        ? node!.days.toDouble()
        : (isParent
            ? (sch.secEnd[_selSi] - sch.secStart[_selSi])
            : sec.days.toDouble());
    final nEnd = nStart + nDur;

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

    final idx = isChild ? _selCi : _selSi;
    final len = isChild ? sec.children.length : _sections.length;
    final canUp = idx > 0;
    final canDown = idx < len - 1;

    final editColor = isChild ? _subColor : _phaseColor;

    double totalDays = 0;
    for (final e in sch.secEnd) {
      if (e > totalDays) totalDays = e;
    }
    final total = totalDays.ceil().clamp(1, 999999).toDouble();

    // preview segments (neighbours faint + current bold)
    final segs = <_TrackSeg>[];
    void addSeg(double start, double dur, bool current) {
      segs.add(_TrackSeg(
        leftFrac: start / total,
        widthFrac: (dur / total).clamp(0.025, 1),
        current: current,
      ));
    }

    if (isChild) {
      final starts = sch.kidStarts[_selSi]!;
      final kids = sec.children;
      if (_selCi - 1 >= 0) {
        addSeg(starts[_selCi - 1], kids[_selCi - 1].days.toDouble(), false);
      }
      if (_selCi + 1 < kids.length) {
        addSeg(starts[_selCi + 1], kids[_selCi + 1].days.toDouble(), false);
      }
      addSeg(starts[_selCi], kids[_selCi].days.toDouble(), true);
    } else {
      if (_selSi - 1 >= 0) {
        addSeg(sch.secStart[_selSi - 1],
            sch.secEnd[_selSi - 1] - sch.secStart[_selSi - 1], false);
      }
      if (_selSi + 1 < _sections.length) {
        addSeg(sch.secStart[_selSi + 1],
            sch.secEnd[_selSi + 1] - sch.secStart[_selSi + 1], false);
      }
      addSeg(sch.secStart[_selSi], sch.secEnd[_selSi] - sch.secStart[_selSi],
          true);
    }

    final durChip = isChild
        ? '${node!.days} working days'
        : (isParent ? '${_fmtDur(nDur)} span' : '${sec.days} working days');

    return Container(
      color: _paper,
      child: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            color: _header,
            padding: EdgeInsets.fromLTRB(14, top + 14, 14, 16),
            child: Row(
              children: [
                _circleBtn(Icons.chevron_left_rounded, _back),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(isChild ? node!.name : sec.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: _body,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                        const SizedBox(height: 2),
                        Text(
                            isChild
                                ? 'EDIT SUB-TASK'
                                : (isParent
                                    ? 'EDIT SUMMARY TASK'
                                    : 'EDIT SECTION'),
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _deleteSel,
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
                ),
              ],
            ),
          ),
          // body
          Expanded(
            child: SingleChildScrollView(
              controller: _editScrollCtl,
              padding: EdgeInsets.fromLTRB(18, 16, 18, bottom + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border)),
                    child: Row(
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              color: editColor,
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _nameCtl,
                            onChanged: _setName,
                            textInputAction: TextInputAction.done,
                            style: const TextStyle(
                                fontFamily: _display,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _ink),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Name',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // scheduled preview
                  _previewCard(nStart, nEnd, durChip, segs, editColor, total),
                  const SizedBox(height: 16),
                  // duration / summary
                  if (!isParent) ...[
                    Text(
                        isChild
                            ? 'DURATION (WORKING DAYS)'
                            : 'DURATION (WORKING DAYS)',
                        style: _capLabel),
                    const SizedBox(height: 8),
                    _bigStepper(
                      value: isChild ? '${node!.days}d' : '${sec.days}d',
                      onMinus: () => _durStep(-1),
                      onPlus: () => _durStep(1),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F4),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_rounded,
                              size: 22, color: _green),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SUMMARY TASK', style: _capLabel),
                              const SizedBox(height: 2),
                              Text(
                                  'Spans ${((sch.secEnd[_selSi] - sch.secStart[_selSi]) / 5).toStringAsFixed(1)}w · ${sec.children.length} sub-tasks · ${_pctOf(sec)}% done',
                                  style: const TextStyle(
                                      fontFamily: _display,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _ink)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // completion slider (leaf phase or sub-task)
                  if (!isParent) ...[
                    _pctSlider(isChild ? node!.pct : sec.pct),
                    const SizedBox(height: 16),
                  ],
                  // linking
                  Text(linkHeading, style: _capLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < modeKeys.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: _modeBtn(modeKeys[i], mode, isFirst)),
                      ],
                    ],
                  ),
                  if (showBuffer) ...[
                    const SizedBox(height: 16),
                    _linkStepper(
                      title: 'BUFFER BEFORE START',
                      sub: 'Gap after the linked phase',
                      value: '+${buffer}d',
                      onMinus: () => _bufStep(-1),
                      onPlus: () => _bufStep(1),
                    ),
                  ],
                  if (showOverlap) ...[
                    const SizedBox(height: 16),
                    _linkStepper(
                      title: 'START AT',
                      sub: '% into the linked phase',
                      value: '$overlapPct%',
                      onMinus: () => _ovStep(-10),
                      onPlus: () => _ovStep(10),
                    ),
                  ],
                  // position & order
                  const SizedBox(height: 18),
                  const Text('POSITION & ORDER', style: _capLabel),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _posBtn(Icons.arrow_upward_rounded, 'Move up',
                            canUp, () => _moveSel(-1)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _posBtn(Icons.arrow_downward_rounded,
                            'Move down', canDown, () => _moveSel(1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _insertBtn('Insert above', () => _insertRel(0))),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              _insertBtn('Insert below', () => _insertRel(1))),
                    ],
                  ),
                  // sub-tasks list
                  if (!isChild && sec.children.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('SUB-TASKS', style: _capLabel),
                    const SizedBox(height: 8),
                    for (var ci = 0; ci < sec.children.length; ci++)
                      _childRow(sec.children[ci], _selSi, ci),
                  ],
                  // add sub-task
                  if (!isChild) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _addChild,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _dash, width: 1.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_rounded, size: 18, color: _green),
                            SizedBox(width: 7),
                            Text('Add sub-task',
                                style: TextStyle(
                                    fontFamily: _body,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _green)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // delete
                  const SizedBox(height: 22),
                  InkWell(
                    onTap: _deleteSel,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                          color: _paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 18, color: _faint),
                          const SizedBox(width: 7),
                          Text(isChild ? 'Delete sub-task' : 'Delete section',
                              style: const TextStyle(
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: _ink, borderRadius: BorderRadius.circular(10)),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _capLabel = TextStyle(
      fontFamily: _body,
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: _faint);

  Widget _previewCard(double nStart, double nEnd, String durChip,
      List<_TrackSeg> segs, Color color, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SCHEDULED IN PROGRAMME', style: _capLabel),
              Text(durChip,
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _green)),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_short(_wd(nStart)),
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _ink)),
              const SizedBox(width: 7),
              const Icon(Icons.arrow_forward_rounded,
                  size: 15, color: _ruleIdle),
              const SizedBox(width: 7),
              Text(_short(_wd(nEnd)),
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _ink)),
            ],
          ),
          const SizedBox(height: 12),
          // mini programme track
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 22,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: _band,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    for (final sg in segs)
                      Positioned(
                        left: (sg.leftFrac * w).clamp(0, w - 4).toDouble(),
                        top: sg.current ? 3 : 6,
                        width: (sg.widthFrac * w).clamp(4, w).toDouble(),
                        height: sg.current ? 16 : 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withOpacity(sg.current ? 1 : 0.28),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_short(_start),
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _ruleIdle)),
              Text(_short(_wd(total)),
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

  Widget _bigStepper({
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _roundStep(Icons.remove_rounded, false, onMinus, 38),
          Text(value,
              style: const TextStyle(
                  fontFamily: _display,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _ink)),
          _roundStep(Icons.add_rounded, true, onPlus, 38),
        ],
      ),
    );
  }

  Widget _linkStepper({
    required String title,
    required String sub,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _capLabel),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _faint)),
              ],
            ),
          ),
          _roundStep(Icons.remove_rounded, false, onMinus, 32),
          const SizedBox(width: 12),
          SizedBox(
            width: 46,
            child: Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _display,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _ink)),
          ),
          const SizedBox(width: 12),
          _roundStep(Icons.add_rounded, true, onPlus, 32),
        ],
      ),
    );
  }

  Widget _roundStep(IconData icon, bool solid, VoidCallback onTap, double sz) =>
      InkWell(
        onTap: onTap,
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

  Widget _modeBtn(String key, String current, bool isFirst) {
    final mm = _modeMeta[key]!;
    final active = current == key || (isFirst && key == 'start');
    return InkWell(
      onTap: () => _setMode(key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? _ink : _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _ink : _hairlineOnSurface),
        ),
        child: Column(
          children: [
            Icon(mm.icon, size: 19, color: active ? _paper : _inkMute),
            const SizedBox(height: 4),
            Text(mm.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: active ? _paper : _inkMute)),
          ],
        ),
      ),
    );
  }

  Widget _posBtn(
      IconData icon, String label, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(10),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
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

  Widget _childRow(_Child c, int si, int ci) {
    return InkWell(
      onTap: () => _openEdit(si, ci),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border)),
        child: Row(
          children: [
            Expanded(
              child: Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
            ),
            Text('${c.days}d',
                style: const TextStyle(
                    fontFamily: _display,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _faint)),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text('${c.pct}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: _display,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: c.pct >= 100
                          ? _green
                          : (c.pct > 0 ? _inkMute : _faint))),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _dash),
          ],
        ),
      ),
    );
  }

  Widget _pctSlider(int pct) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('COMPLETION', style: _capLabel),
              Text('$pct%',
                  style: const TextStyle(
                      fontFamily: _display,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: _ink)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: const Color(0xFFE7E247),
              inactiveTrackColor: _hairlineOnSurface,
              thumbColor: const Color(0xFFE7E247),
              overlayColor: const Color(0xFFE7E247).withOpacity(0.14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: pct.toDouble(),
              min: 0,
              max: 100,
              onChanged: (v) => _setPct(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Not started',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _ruleIdle)),
                Text('Complete',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _ruleIdle)),
              ],
            ),
          ),
        ],
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

class _BoardParts {
  final Widget header;
  final Widget body;
  _BoardParts({required this.header, required this.body});
}

// Pinned board header (PHASE label + month/date row) — stays visible while
// the phase rows scroll under it.
class _BoardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;
  _BoardHeaderDelegate({required this.extent, required this.child});

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: extent, child: child);
  @override
  bool shouldRebuild(covariant _BoardHeaderDelegate oldDelegate) => true;
}

class _DaySeg {
  final String label;
  final int days;
  const _DaySeg(this.label, this.days);
}

class _TrackSeg {
  final double leftFrac;
  final double widthFrac;
  final bool current;
  const _TrackSeg(
      {required this.leftFrac, required this.widthFrac, required this.current});
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
  int pct; // % complete 0..100
  _Child({
    required this.name,
    this.mode = 'after',
    this.buffer = 0,
    this.overlapPct = 50,
    this.days = 3,
    this.pct = 0,
  });
}

class _Section {
  String name;
  String group; // struct | services | finish | external
  String mode;
  int buffer; // working days
  int overlapPct;
  int days;
  bool expanded;
  int pct; // % complete 0..100 (leaf phases)
  List<_Child> children;
  _Section({
    required this.name,
    required this.group,
    this.mode = 'after',
    this.buffer = 0,
    this.overlapPct = 50,
    this.days = 10,
    this.expanded = false,
    this.pct = 0,
    List<_Child>? children,
  }) : children = children ?? [];
}
