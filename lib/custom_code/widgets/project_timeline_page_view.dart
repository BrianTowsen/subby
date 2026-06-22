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

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

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
  // Synced with DashboardPageView / AddProjectsPageView (flat teal system).
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374); // text, chrome, accent
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  static const Color _tealTint = Color(0xFFE3F4F2);
  // Status
  static const Color _live = Color(0xFFE5771E); // orange — completed
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;
  static const double _gap = 12;
  static const double _contentHPad = _hPad;

  static const double _phaseTimelineRailW = 2.0;
  static const double _phaseTimelineGutter = 24.0;
  static const double _phaseTileGap = 12.0;

  bool _loadingProjects = true;
  List<_ProjectOption> _projectOptions = [];
  DocumentReference? _selectedProjectRef;

  final Set<String> _expandedPhaseKeys = {};

  late List<_Phase> _phases;

  final Map<String, double> _taskProgress = {};
  final Map<String, int> _taskWorkingDays = {};
  final Map<String, int> _taskBufferDays = {};
  final Map<String, DateTime> _taskStartDates = {};

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Color _timelineColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).timelineColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY (flat teal system)
  // =========================================================
  TextStyle _pageTitle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        color: _ink,
        fontWeight: FontWeight.w900,
        fontSize: 30,
        lineHeight: 1.05,
        letterSpacing: -0.5,
      );

  TextStyle _pageSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  TextStyle _uLabel(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      );

  TextStyle _rowTitleStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: _ink,
      );

  TextStyle _rowMetaStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  @override
  void initState() {
    super.initState();
    _phases = List<_Phase>.from(_mockPhases());

    for (final p in _phases) {
      for (int i = 0; i < p.tasks.length; i++) {
        final id = '${p.key}::task::$i';
        _taskProgress[id] =
            _taskProgress[id] ?? _statusDefaultProgress(p.tasks[i].status);
        _taskWorkingDays[id] = _taskWorkingDays[id] ?? 3 + (i % 3);
        _taskBufferDays[id] = _taskBufferDays[id] ?? 1;
        _taskStartDates[id] = _taskStartDates[id] ??
            p.start.add(Duration(days: (i * 2).clamp(0, 999)));
      }
    }

    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);

    final owner = currentUserReference;
    if (owner == null) {
      setState(() {
        _projectOptions = [];
        _selectedProjectRef = null;
        _loadingProjects = false;
      });
      return;
    }

    try {
      final qs = await FirebaseFirestore.instance
          .collection('projects')
          .where('ownerRef', isEqualTo: owner)
          .get();

      final opts = <_ProjectOption>[];
      for (final d in qs.docs) {
        final data = d.data();
        if (data['archived'] == true) continue;
        final nameRaw = data['name'];
        final name = (nameRaw is String && nameRaw.trim().isNotEmpty)
            ? nameRaw.trim()
            : 'Untitled project';
        DateTime? updatedAt;
        final ua = data['updatedAt'];
        if (ua is Timestamp) updatedAt = ua.toDate();
        DateTime? createdAt;
        final ca = data['createdAt'];
        if (ca is Timestamp) createdAt = ca.toDate();
        opts.add(_ProjectOption(
            ref: d.reference,
            name: name,
            updatedAt: updatedAt,
            createdAt: createdAt));
      }

      opts.sort((a, b) {
        final aT = a.updatedAt ?? a.createdAt;
        final bT = b.updatedAt ?? b.createdAt;
        if (aT != null && bT != null) return bT.compareTo(aT);
        if (aT != null) return -1;
        if (bT != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      DocumentReference? selected = _selectedProjectRef;
      if (selected == null || !opts.any((o) => o.ref == selected)) {
        selected = opts.isNotEmpty ? opts.first.ref : null;
      }

      if (!mounted) return;
      setState(() {
        _projectOptions = opts;
        _selectedProjectRef = selected;
        _loadingProjects = false;
        _expandedPhaseKeys.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _projectOptions = [];
        _selectedProjectRef = null;
        _loadingProjects = false;
      });
    }
  }

  // -----------------------------
  // Mock data (timeline UI)
  // -----------------------------
  List<_Phase> _mockPhases() {
    return [
      _Phase(
        key: 'planning',
        title: 'Planning & Permits',
        icon: Icons.description_outlined,
        status: _PhaseStatus.completed,
        start: DateTime(2026, 1, 3),
        end: DateTime(2026, 1, 10),
        progress: 1.0,
        tasks: const [
          _Task('Site survey & scope', _PhaseStatus.completed),
          _Task('Architect drawings', _PhaseStatus.completed),
          _Task('Permits submitted', _PhaseStatus.completed),
        ],
      ),
      _Phase(
        key: 'site',
        title: 'Site Prep',
        icon: Icons.construction_outlined,
        status: _PhaseStatus.inProgress,
        start: DateTime(2026, 1, 11),
        end: DateTime(2026, 1, 18),
        progress: 0.55,
        tasks: const [
          _Task('Clear site', _PhaseStatus.completed),
          _Task('Set out & pegs', _PhaseStatus.inProgress),
          _Task('Temporary fencing', _PhaseStatus.notStarted),
        ],
      ),
      _Phase(
        key: 'foundations',
        title: 'Foundations',
        icon: Icons.foundation_outlined,
        status: _PhaseStatus.inProgress,
        start: DateTime(2026, 1, 19),
        end: DateTime(2026, 2, 2),
        progress: 0.32,
        tasks: const [
          _Task('Excavation', _PhaseStatus.inProgress),
          _Task('Formwork', _PhaseStatus.notStarted),
          _Task('Concrete pour', _PhaseStatus.notStarted),
        ],
      ),
      _Phase(
        key: 'structure',
        title: 'Framing & Structure',
        icon: Icons.account_tree_outlined,
        status: _PhaseStatus.upcoming,
        start: DateTime(2026, 2, 3),
        end: DateTime(2026, 2, 20),
        progress: 0.0,
        tasks: const [
          _Task('Brickwork / framing', _PhaseStatus.notStarted),
          _Task('Slab / level checks', _PhaseStatus.notStarted),
          _Task('Lintels & beams', _PhaseStatus.notStarted),
        ],
      ),
      _Phase(
        key: 'roof',
        title: 'Roofing',
        icon: Icons.house_outlined,
        status: _PhaseStatus.notStarted,
        start: DateTime(2026, 2, 21),
        end: DateTime(2026, 3, 5),
        progress: 0.0,
        tasks: const [
          _Task('Roof structure', _PhaseStatus.notStarted),
          _Task('Roof covering', _PhaseStatus.notStarted),
          _Task('Insulation', _PhaseStatus.notStarted),
        ],
      ),
    ];
  }

  String _fmtDate(DateTime d) => DateFormat('d MMM').format(d);
  String _fmtRange(DateTime start, DateTime end) =>
      '${_fmtDate(start)} – ${_fmtDate(end)}';
  String _fmtDurationDays(DateTime start, DateTime end) =>
      '${end.difference(start).inDays + 1} days';
  String _pct(double v) => '${(v.clamp(0.0, 1.0) * 100).round()}%';

  double _statusDefaultProgress(_PhaseStatus s) {
    switch (s) {
      case _PhaseStatus.completed:
        return 1.0;
      case _PhaseStatus.inProgress:
        return 0.5;
      case _PhaseStatus.upcoming:
      case _PhaseStatus.notStarted:
        return 0.0;
    }
  }

  DateTime _taskStart(String taskId) =>
      _taskStartDates[taskId] ?? DateTime.now();

  DateTime _taskEnd(String taskId) {
    final start = _taskStart(taskId);
    final wd = (_taskWorkingDays[taskId] ?? 0).clamp(0, 999);
    final buf = (_taskBufferDays[taskId] ?? 0).clamp(0, 999);
    final total = (wd + buf).clamp(1, 999);
    return start.add(Duration(days: total - 1));
  }

  DateTime _phaseDerivedStart(_Phase p) {
    if (p.tasks.isEmpty) return p.start;
    DateTime? minD;
    for (int i = 0; i < p.tasks.length; i++) {
      final s = _taskStart('${p.key}::task::$i');
      minD = (minD == null || s.isBefore(minD)) ? s : minD;
    }
    return minD ?? p.start;
  }

  DateTime _phaseDerivedEnd(_Phase p) {
    if (p.tasks.isEmpty) return p.end;
    DateTime? maxD;
    for (int i = 0; i < p.tasks.length; i++) {
      final e = _taskEnd('${p.key}::task::$i');
      maxD = (maxD == null || e.isAfter(maxD)) ? e : maxD;
    }
    return maxD ?? p.end;
  }

  double _phaseProgressFromTasks(_Phase p) {
    if (p.tasks.isEmpty) return p.progress;
    double sum = 0;
    for (int i = 0; i < p.tasks.length; i++) {
      final id = '${p.key}::task::$i';
      sum += (_taskProgress[id] ?? _statusDefaultProgress(p.tasks[i].status));
    }
    return (sum / p.tasks.length).clamp(0.0, 1.0);
  }

  // -----------------------------
  // Shared bits (flat teal)
  // -----------------------------
  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _hairline),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _inkMute),
          ),
        ),
      );

  Widget _flatCard(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(14)}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        child: child,
      );

  Widget _softPill(String text, {required Color fg, required Color bg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ).copyWith(color: fg)),
      );

  Widget _progressBar(double value, Color fill) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: v,
          backgroundColor: _surface,
          valueColor: AlwaysStoppedAnimation<Color>(fill),
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _hairlineOnSurface);

  // In Progress = teal accent; Completed = orange; neutral = faint.
  Color _statusColor(_PhaseStatus s) {
    switch (s) {
      case _PhaseStatus.completed:
        return _live;
      case _PhaseStatus.inProgress:
        return _teal;
      case _PhaseStatus.upcoming:
      case _PhaseStatus.notStarted:
        return _faint;
    }
  }

  Color _statusTint(_PhaseStatus s) {
    switch (s) {
      case _PhaseStatus.completed:
        return const Color(0x1FE5771E); // orange @ ~12%
      case _PhaseStatus.inProgress:
        return _tealTint;
      case _PhaseStatus.upcoming:
      case _PhaseStatus.notStarted:
        return _surface;
    }
  }

  String _statusLabel(_PhaseStatus s) {
    switch (s) {
      case _PhaseStatus.completed:
        return 'Completed';
      case _PhaseStatus.inProgress:
        return 'In Progress';
      case _PhaseStatus.upcoming:
        return 'Upcoming';
      case _PhaseStatus.notStarted:
        return 'Not Started';
    }
  }

  // Timeline node
  Widget _buildTimelineNode(_PhaseStatus status) {
    final c = _statusColor(status);
    if (status == _PhaseStatus.inProgress) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: _paper,
          shape: BoxShape.circle,
          border: Border.all(color: c, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        ),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: _paper, width: 2),
      ),
    );
  }

  // -----------------------------
  // Project selector (WIRED) — flat
  // -----------------------------
  Widget _buildProjectSelector(FlutterFlowTheme theme) {
    final disabled = _loadingProjects || _projectOptions.isEmpty;
    final selectedName = () {
      final ref = _selectedProjectRef;
      if (ref == null) return 'No projects';
      final match = _projectOptions.where((o) => o.ref == ref).toList();
      return match.isNotEmpty ? match.first.name : 'Select project';
    }();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _flatCard(
        Row(
          children: [
            const Icon(Icons.folder_open_rounded, color: _teal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROJECT', style: _uLabel(theme)),
                  const SizedBox(height: 2),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<DocumentReference>(
                      value: disabled ? null : _selectedProjectRef,
                      isExpanded: true,
                      isDense: true,
                      hint: Text(
                        _loadingProjects ? 'Loading projects…' : selectedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _rowTitleStyle(theme)
                            .copyWith(color: disabled ? _faint : _ink),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _faint),
                      items: _projectOptions
                          .map((p) => DropdownMenuItem<DocumentReference>(
                                value: p.ref,
                                child: Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _rowTitleStyle(theme)),
                              ))
                          .toList(),
                      onChanged: disabled
                          ? null
                          : (ref) {
                              if (ref == null) return;
                              setState(() {
                                _selectedProjectRef = ref;
                                _expandedPhaseKeys.clear();
                              });
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Overview card (flat)
  // -----------------------------
  Widget _buildSummaryCard(FlutterFlowTheme theme, List<_Phase> phases) {
    double overall = 0;
    for (final p in phases) {
      overall += _phaseProgressFromTasks(p);
    }
    overall = phases.isEmpty ? 0 : overall / phases.length;

    DateTime? minS;
    DateTime? maxE;
    for (final p in phases) {
      final s = _phaseDerivedStart(p);
      final e = _phaseDerivedEnd(p);
      minS = (minS == null || s.isBefore(minS)) ? s : minS;
      maxE = (maxE == null || e.isAfter(maxE)) ? e : maxE;
    }
    final rangeText = (minS != null && maxE != null)
        ? '${_fmtRange(minS, maxE)} · ${_fmtDurationDays(minS, maxE)}'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _flatCard(
        padding: const EdgeInsets.all(16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(_pct(overall),
                    style: theme.titleLarge.override(
                      fontFamily: _displayFont,
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.5,
                    )),
                const SizedBox(width: 8),
                Text('overall progress',
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _faint)),
              ],
            ),
            const SizedBox(height: 6),
            Text(rangeText, style: _rowMetaStyle(theme)),
            const SizedBox(height: 12),
            _progressBar(overall, _teal),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Phase list with rail (draggable)
  // -----------------------------
  Widget _buildPhaseTimelineList(FlutterFlowTheme theme) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _phases.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _phases.removeAt(oldIndex);
          _phases.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final p = _phases[index];
        return Padding(
          key: ValueKey('phase::${p.key}'),
          padding:
              EdgeInsets.only(bottom: index == _phases.length - 1 ? 0 : _gap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _phaseTimelineGutter,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: (_phaseTimelineGutter / 2) -
                            (_phaseTimelineRailW / 2),
                        child: Container(
                          width: _phaseTimelineRailW,
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.30),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: _buildTimelineNode(p.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _phaseTileGap),
                Expanded(child: _buildPhaseCard(theme, p, index)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhaseCard(FlutterFlowTheme theme, _Phase p, int indexInList) {
    final isExpanded = _expandedPhaseKeys.contains(p.key);
    final c = _statusColor(p.status);
    final phaseProg = _phaseProgressFromTasks(p);
    final derivedStart = _phaseDerivedStart(p);
    final derivedEnd = _phaseDerivedEnd(p);

    return _flatCard(
      padding: EdgeInsets.zero,
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedPhaseKeys.remove(p.key);
              } else {
                _expandedPhaseKeys.add(p.key);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _softPill(_statusLabel(p.status),
                        fg: c, bg: _statusTint(p.status)),
                    const Spacer(),
                    ReorderableDragStartListener(
                      index: indexInList,
                      child: const Icon(Icons.drag_handle_rounded,
                          size: 20, color: Color(0xFFCBD3DB)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: _rowTitleStyle(theme)),
                      const SizedBox(height: 3),
                      Text(
                        '${_fmtRange(derivedStart, derivedEnd)} · ${_fmtDurationDays(derivedStart, derivedEnd)}',
                        style: _rowMetaStyle(theme),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _progressBar(phaseProg, c)),
                    const SizedBox(width: 10),
                    Text(_pct(phaseProg),
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _faint)),
                    const SizedBox(width: 6),
                    Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _faint),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 14),
                  _divider(),
                  const SizedBox(height: 12),
                  Column(
                    children: List.generate(p.tasks.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: i == p.tasks.length - 1 ? 0 : 10),
                        child: _buildInnerTaskCard(
                            theme, p.tasks[i], '${p.key}::task::$i'),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerTaskCard(
      FlutterFlowTheme theme, _Task task, String taskId) {
    final v = (_taskProgress[taskId] ?? _statusDefaultProgress(task.status))
        .clamp(0.0, 1.0);
    final wd = (_taskWorkingDays[taskId] ?? 3).clamp(0, 999);
    final buf = (_taskBufferDays[taskId] ?? 1).clamp(0, 999);
    final c = _statusColor(task.status);
    final sDate = _taskStart(taskId);
    final eDate = _taskEnd(taskId);

    Widget dateChip(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: _bodyFont, fontSize: 11, color: _faint)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _hairline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _softPill(_statusLabel(task.status),
                  fg: c, bg: _statusTint(task.status)),
              const Spacer(),
              Text(_pct(v),
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _teal)),
            ],
          ),
          const SizedBox(height: 10),
          Text(task.title,
              style: const TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 12),
          Text('DATES', style: _uLabel(theme)),
          const SizedBox(height: 8),
          Row(
            children: [
              dateChip('Start', _fmtDate(sDate)),
              const SizedBox(width: 10),
              dateChip('End', _fmtDate(eDate)),
            ],
          ),
          const SizedBox(height: 14),
          _divider(),
          const SizedBox(height: 12),
          Text('EFFORT', style: _uLabel(theme)),
          const SizedBox(height: 8),
          _miniStepper(theme,
              label: 'Working days',
              value: wd,
              onMinus: () => setState(
                  () => _taskWorkingDays[taskId] = (wd - 1).clamp(0, 999)),
              onPlus: () => setState(
                  () => _taskWorkingDays[taskId] = (wd + 1).clamp(0, 999))),
          const SizedBox(height: 10),
          _miniStepper(theme,
              label: 'Buffer',
              value: buf,
              onMinus: () => setState(
                  () => _taskBufferDays[taskId] = (buf - 1).clamp(0, 999)),
              onPlus: () => setState(
                  () => _taskBufferDays[taskId] = (buf + 1).clamp(0, 999))),
          const SizedBox(height: 14),
          _divider(),
          const SizedBox(height: 12),
          Text('COMPLETION', style: _uLabel(theme)),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _teal,
              inactiveTrackColor: _surface,
              thumbColor: _teal,
              overlayColor: _teal.withOpacity(0.14),
              trackHeight: 4,
            ),
            child: Slider(
              value: v,
              min: 0,
              max: 1,
              onChanged: (nv) =>
                  setState(() => _taskProgress[taskId] = nv.clamp(0.0, 1.0)),
            ),
          ),
          Text('Slide to update completion.', style: _rowMetaStyle(theme)),
        ],
      ),
    );
  }

  Widget _miniStepper(FlutterFlowTheme theme,
      {required String label,
      required int value,
      required VoidCallback onMinus,
      required VoidCallback onPlus}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _rowMetaStyle(theme)),
                const SizedBox(height: 2),
                Text('$value',
                    style: const TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _stepBtn(Icons.remove_rounded, onMinus),
          const SizedBox(width: 6),
          _stepBtn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _hairlineOnSurface),
          ),
          child: Icon(icon, size: 18, color: _ink),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(top: _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _minBack(),
                    const SizedBox(height: 18),
                    Text('Project Timeline', style: _pageTitle(theme)),
                    const SizedBox(height: 8),
                    Text('Build phases and milestones',
                        style: _pageSubtitle(theme)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
                  children: [
                    _buildProjectSelector(theme),
                    const SizedBox(height: 14),
                    _buildSummaryCard(theme, _phases),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          _contentHPad, 22, _contentHPad, 10),
                      child: Text('PHASES', style: _uLabel(theme)),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: _contentHPad),
                      child: _buildPhaseTimelineList(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Project option model (wired)
// ============================================================================
class _ProjectOption {
  final DocumentReference ref;
  final String name;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  const _ProjectOption({
    required this.ref,
    required this.name,
    this.updatedAt,
    this.createdAt,
  });
}

// ============================================================================
// Mock models (UI only)
// ============================================================================
enum _PhaseStatus { completed, inProgress, upcoming, notStarted }

class _Task {
  final String title;
  final _PhaseStatus status;
  const _Task(this.title, this.status);
}

class _Phase {
  final String key;
  final String title;
  final IconData icon;
  final _PhaseStatus status;
  final DateTime start;
  final DateTime end;
  final double progress;
  final List<_Task> tasks;
  const _Phase({
    required this.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.start,
    required this.end,
    required this.progress,
    required this.tasks,
  });
}
