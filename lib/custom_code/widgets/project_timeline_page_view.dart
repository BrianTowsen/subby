// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
  static const double _gap = 12;

  // ✅ subtle sliver breathing room (no clipping)
  static const double _sliverSidePad = 2;
  static const double _sliverTopGap = 8;

  // ✅ content padding moved INSIDE containers so scrollbar can sit on the edge
  static const double _contentHPad = _hPad + _sliverSidePad;

  // ===========================================================================
  // ✅ PHASE TIMELINE (MAIN TILE) VISUALS
  // - Applies ONLY to the main phase tiles (draggable)
  // - Inner expanded tasks: no rail, not draggable
  // ===========================================================================
  static const double _phaseTimelineRailW = 3.0; // thicker so it shows
  static const double _phaseNodeOuter = 18.0;
  static const double _phaseNodeInner = 8.0;
  static const double _phaseTimelineGutter =
      26.0; // reserved space for rail+node
  static const double _phaseTileGap = 14.0;

  // ===========================================================================
  // ✅ PROJECT WIRING (projects collection)
  // - loads user's projects where ownerRef == currentUserReference
  // - ignores archived == true (if field exists)
  // - dropdown value is DocumentReference (stable + safe)
  // ===========================================================================
  bool _loadingProjects = true;
  List<_ProjectOption> _projectOptions = [];
  DocumentReference? _selectedProjectRef;

  // Expanded state per phase (Timeline)
  final Set<String> _expandedPhaseKeys = {};

  // ✅ PHASE ORDER (draggable) (still mock UI for now)
  late List<_Phase> _phases;

  // Task-level state (per task) + phase derived progress
  final Map<String, double> _taskProgress = {}; // 0..1
  final Map<String, int> _taskWorkingDays = {}; // >= 0
  final Map<String, int> _taskBufferDays = {}; // >= 0

  // ✅ Task dates
  // Start date is stable per task, End date is derived from working+buffer.
  final Map<String, DateTime> _taskStartDates = {};

  // -----------------------------
  // Back navigation (safe)
  // -----------------------------
  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  // -----------------------------
  // Theme helpers
  // -----------------------------
  Color _timelineColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).timelineColour as Color?;
      return c ?? theme.primary;
    } catch (_) {
      return theme.primary;
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY (CONSISTENT: token + explicit family)
  // =========================================================
  TextStyle _titleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _subtitleStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: theme.bodySmallFamily,
      color: theme.secondaryText,
    );
  }

  TextStyle _sectionTitleStyle(FlutterFlowTheme theme) {
    return theme.titleSmall.override(
      fontFamily: theme.titleSmallFamily,
      fontWeight: FontWeight.w800,
      color: theme.primaryText,
    );
  }

  TextStyle _rowTitleStyle(FlutterFlowTheme theme) {
    return theme.bodyMedium.override(
      fontFamily: theme.bodyMediumFamily,
      fontWeight: FontWeight.w800,
      color: theme.primaryText,
    );
  }

  TextStyle _rowMetaStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: theme.bodySmallFamily,
      color: theme.secondaryText,
    );
  }

  TextStyle _pillTextStyle(FlutterFlowTheme theme) {
    return theme.labelSmall.override(
      fontFamily: theme.labelSmallFamily,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
  }

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

        // ✅ seed stable task start dates (simple stagger within phase)
        _taskStartDates[id] = _taskStartDates[id] ??
            p.start.add(Duration(
              days: (i * 2).clamp(0, 999),
            ));
      }
    }

    // ✅ wire projects
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
      // NOTE: no orderBy to avoid missing-field errors in early data.
      final qs = await FirebaseFirestore.instance
          .collection('projects')
          .where('ownerRef', isEqualTo: owner)
          .get();

      final opts = <_ProjectOption>[];

      for (final d in qs.docs) {
        final data = d.data();
        final archived = (data['archived'] == true);
        if (archived) continue;

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

        opts.add(
          _ProjectOption(
            ref: d.reference,
            name: name,
            updatedAt: updatedAt,
            createdAt: createdAt,
          ),
        );
      }

      // Sort newest-first (updatedAt -> createdAt -> name)
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
  // Mock data models (timeline UI)
  // -----------------------------
  List<_Phase> _mockPhases() {
    return [
      _Phase(
        key: 'planning',
        title: 'Planning & Permits',
        icon: Icons.description_rounded,
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
        icon: Icons.construction_rounded,
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
        icon: Icons.foundation_rounded,
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
        icon: Icons.account_tree_rounded,
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
        icon: Icons.house_siding_rounded,
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

  // -----------------------------
  // Helpers: formatting
  // -----------------------------
  String _fmtDate(DateTime d) => DateFormat('d MMM').format(d);

  String _fmtRange(DateTime start, DateTime end) =>
      '${_fmtDate(start)} – ${_fmtDate(end)}';

  String _fmtDurationDays(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return '$days days';
  }

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

  DateTime _taskStart(String taskId) {
    return _taskStartDates[taskId] ?? DateTime.now();
  }

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
      final id = '${p.key}::task::$i';
      final s = _taskStart(id);
      minD = (minD == null || s.isBefore(minD)) ? s : minD;
    }
    return minD ?? p.start;
  }

  DateTime _phaseDerivedEnd(_Phase p) {
    if (p.tasks.isEmpty) return p.end;

    DateTime? maxD;
    for (int i = 0; i < p.tasks.length; i++) {
      final id = '${p.key}::task::$i';
      final e = _taskEnd(id);
      maxD = (maxD == null || e.isAfter(maxD)) ? e : maxD;
    }
    return maxD ?? p.end;
  }

  // ---------------------------------------
  // ✅ Subby card shell (baseline styling)
  // ---------------------------------------
  Widget _subbyCardShell({
    required FlutterFlowTheme theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: theme.alternate.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  // ---------------------------------------
  // Pills + progress
  // ---------------------------------------
  Widget _pill(
    FlutterFlowTheme theme, {
    required String text,
    required Color bg,
    required Color fg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(text, style: _pillTextStyle(theme).copyWith(color: fg)),
        ],
      ),
    );
  }

  Widget _progressBar(
    FlutterFlowTheme theme, {
    required double value,
    required Color fillColor,
  }) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: v,
          backgroundColor: theme.alternate.withOpacity(0.55),
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      ),
    );
  }

  // -----------------------------
  // Status helpers
  // -----------------------------
  Color _statusColor(FlutterFlowTheme theme, Color accent, _PhaseStatus s) {
    switch (s) {
      case _PhaseStatus.completed:
        return theme.success;
      case _PhaseStatus.inProgress:
        return accent;
      case _PhaseStatus.upcoming:
        return theme.tertiary;
      case _PhaseStatus.notStarted:
        return theme.secondaryText;
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

  // ===========================================================================
  // ✅ TIMELINE NODE
  // ===========================================================================
  Widget _buildTimelineNode({
    required FlutterFlowTheme theme,
    required Color statusColor,
    required _PhaseStatus status,
  }) {
    final outer = _phaseNodeOuter;
    final inner = _phaseNodeInner;

    if (status == _PhaseStatus.inProgress) {
      return Container(
        width: outer,
        height: outer,
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          shape: BoxShape.circle,
          border: Border.all(color: statusColor, width: 2.2),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    final dotColor = status == _PhaseStatus.completed
        ? statusColor
        : statusColor.withOpacity(0.55);

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryBackground,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Project selector (WIRED) ✅ settings icon removed
  // -----------------------------
  Widget _buildProjectSelector(FlutterFlowTheme theme, Color accent) {
    final disabled = _loadingProjects || _projectOptions.isEmpty;

    final selectedName = () {
      final ref = _selectedProjectRef;
      if (ref == null) return 'No projects';
      final match = _projectOptions.where((o) => o.ref == ref).toList();
      return match.isNotEmpty ? match.first.name : 'Select project';
    }();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.folder_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project', style: _rowMetaStyle(theme)),
                  const SizedBox(height: 2),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<DocumentReference>(
                      value: disabled ? null : _selectedProjectRef,
                      isExpanded: true,
                      hint: Text(
                        _loadingProjects ? 'Loading projects…' : selectedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _rowTitleStyle(theme).copyWith(
                          color: disabled
                              ? theme.secondaryText
                              : theme.primaryText,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.secondaryText,
                      ),
                      items: _projectOptions
                          .map(
                            (p) => DropdownMenuItem<DocumentReference>(
                              value: p.ref,
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _rowTitleStyle(theme),
                              ),
                            ),
                          )
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
  // Overview card (progress only)
  // -----------------------------
  Widget _buildSummaryCard(
    FlutterFlowTheme theme,
    Color accent,
    List<_Phase> phases,
  ) {
    double overall = 0;
    for (final p in phases) {
      overall += _phaseProgressFromTasks(p);
    }
    overall = phases.isEmpty ? 0 : overall / phases.length;

    // global timeline range derived from tasks/phases
    DateTime? minS;
    DateTime? maxE;
    for (final p in phases) {
      final s = _phaseDerivedStart(p);
      final e = _phaseDerivedEnd(p);
      minS = (minS == null || s.isBefore(minS)) ? s : minS;
      maxE = (maxE == null || e.isAfter(maxE)) ? e : maxE;
    }

    final rangeText = (minS != null && maxE != null)
        ? '${_fmtRange(minS, maxE)} • ${_fmtDurationDays(minS, maxE)}'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: _sectionTitleStyle(theme)),
                  const SizedBox(height: 6),
                  Text('Overall progress • ${_pct(overall)}',
                      style: _rowMetaStyle(theme)),
                  const SizedBox(height: 8),
                  Text(rangeText, style: _rowMetaStyle(theme)),
                  const SizedBox(height: 10),
                  _progressBar(theme, value: overall, fillColor: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Phase progress derived from tasks
  // -----------------------------
  double _phaseProgressFromTasks(_Phase p) {
    if (p.tasks.isEmpty) return p.progress;

    double sum = 0;
    for (int i = 0; i < p.tasks.length; i++) {
      final id = '${p.key}::task::$i';
      sum += (_taskProgress[id] ?? _statusDefaultProgress(p.tasks[i].status));
    }
    return (sum / p.tasks.length).clamp(0.0, 1.0);
  }

  // ===========================================================================
  // ✅ MAIN PHASE LIST (Timeline) (draggable + ALWAYS VISIBLE RAIL)
  // ===========================================================================
  Widget _buildPhaseTimelineList({
    required FlutterFlowTheme theme,
    required Color accent,
  }) {
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
        final statusColor = _statusColor(theme, accent, p.status);

        return Padding(
          key: ValueKey('phase::${p.key}'),
          padding:
              EdgeInsets.only(bottom: index == _phases.length - 1 ? 0 : _gap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ GUTTER WITH RAIL (accent colour)
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
                            color: accent.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _buildTimelineNode(
                            theme: theme,
                            statusColor: statusColor,
                            status: p.status,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _phaseTileGap),

                // Tile
                Expanded(
                  child: _buildPhaseCard(
                    theme: theme,
                    accent: accent,
                    p: p,
                    indexInList: index,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ✅ PHASE TILE: Timeline (expanded tasks + drag handle)
  // ===========================================================================
  Widget _buildPhaseCard({
    required FlutterFlowTheme theme,
    required Color accent,
    required _Phase p,
    required int indexInList,
  }) {
    final isExpanded = _expandedPhaseKeys.contains(p.key);
    final statusColor = _statusColor(theme, accent, p.status);
    final phaseProg = _phaseProgressFromTasks(p);

    final derivedStart = _phaseDerivedStart(p);
    final derivedEnd = _phaseDerivedEnd(p);

    return _subbyCardShell(
      theme: theme,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
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
                  _pill(
                    theme,
                    text: _statusLabel(p.status),
                    bg: statusColor.withOpacity(0.14),
                    fg: statusColor,
                  ),
                  const Spacer(),
                  ReorderableDragStartListener(
                    index: indexInList,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.primaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: theme.alternate.withOpacity(0.9)),
                      ),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 20,
                        color: theme.secondaryText,
                      ),
                    ),
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
                    const SizedBox(height: 4),
                    Text(
                      '${_fmtRange(derivedStart, derivedEnd)} • ${_fmtDurationDays(derivedStart, derivedEnd)}',
                      style: _rowMetaStyle(theme),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _progressBar(
                      theme,
                      value: phaseProg,
                      fillColor: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _pct(phaseProg),
                    style: theme.bodySmall.override(
                      fontFamily: theme.bodySmallFamily,
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.secondaryText,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                _divider(theme),
                const SizedBox(height: 10),
                Column(
                  children: List.generate(p.tasks.length, (i) {
                    final t = p.tasks[i];
                    final id = '${p.key}::task::$i';
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i == p.tasks.length - 1 ? 0 : 10),
                      child: _buildInnerTaskCard(
                        theme: theme,
                        accent: accent,
                        task: t,
                        taskId: id,
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ✅ INNER TASK TILE (NOT draggable)
  // ===========================================================================
  Widget _buildInnerTaskCard({
    required FlutterFlowTheme theme,
    required Color accent,
    required _Task task,
    required String taskId,
  }) {
    final v = (_taskProgress[taskId] ?? _statusDefaultProgress(task.status))
        .clamp(0.0, 1.0);
    final wd = (_taskWorkingDays[taskId] ?? 3).clamp(0, 999);
    final buf = (_taskBufferDays[taskId] ?? 1).clamp(0, 999);

    final statusColor = _statusColor(theme, accent, task.status);
    final sDate = _taskStart(taskId);
    final eDate = _taskEnd(taskId);

    Widget infoChip(String label, String value, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.alternate.withOpacity(0.9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: theme.secondaryText),
              const SizedBox(width: 6),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _rowMetaStyle(theme)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w900,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget sectionTitle(String t) {
      return Text(
        t,
        style: theme.labelMedium.override(
          fontFamily: theme.labelMediumFamily,
          fontWeight: FontWeight.w900,
          color: theme.secondaryText,
          letterSpacing: 0.2,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: theme.alternate.withOpacity(0.9)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Status pill (left) + % (right)
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.22)),
                ),
                child: Text(
                  _statusLabel(task.status),
                  style: theme.labelSmall.override(
                    fontFamily: theme.labelSmallFamily,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(),
              _pill(
                theme,
                text: _pct(v),
                bg: accent.withOpacity(0.12),
                fg: accent,
              ),
            ],
          ),

          // Task name
          const SizedBox(height: 10),
          Text(
            task.title,
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              fontWeight: FontWeight.w900,
              color: theme.primaryText,
            ),
          ),

          const SizedBox(height: 10),
          _divider(theme),
          const SizedBox(height: 10),

          // Dates section
          sectionTitle('Dates'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              infoChip('Start', _fmtDate(sDate),
                  icon: Icons.play_arrow_rounded),
              infoChip('End', _fmtDate(eDate), icon: Icons.flag_rounded),
            ],
          ),

          const SizedBox(height: 12),
          _divider(theme),
          const SizedBox(height: 10),

          // Effort section
          sectionTitle('Effort'),
          const SizedBox(height: 8),
          _miniStepper(
            theme: theme,
            label: 'Working days',
            value: wd,
            onMinus: () => setState(() {
              _taskWorkingDays[taskId] = (wd - 1).clamp(0, 999);
            }),
            onPlus: () => setState(() {
              _taskWorkingDays[taskId] = (wd + 1).clamp(0, 999);
            }),
          ),
          const SizedBox(height: 10),
          _miniStepper(
            theme: theme,
            label: 'Buffer',
            value: buf,
            onMinus: () => setState(() {
              _taskBufferDays[taskId] = (buf - 1).clamp(0, 999);
            }),
            onPlus: () => setState(() {
              _taskBufferDays[taskId] = (buf + 1).clamp(0, 999);
            }),
          ),

          const SizedBox(height: 12),
          _divider(theme),
          const SizedBox(height: 10),

          // Completion section
          sectionTitle('Completion'),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: theme.alternate.withOpacity(0.55),
              thumbColor: accent,
              overlayColor: accent.withOpacity(0.18),
              trackHeight: 3.2,
            ),
            child: Slider(
              value: v,
              min: 0,
              max: 1,
              onChanged: (nv) {
                setState(() {
                  _taskProgress[taskId] = nv.clamp(0.0, 1.0);
                });
              },
            ),
          ),
          Text(
            'Slide to update completion.',
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStepper({
    required FlutterFlowTheme theme,
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.alternate.withOpacity(0.9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _rowMetaStyle(theme)),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w900,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _stepBtn(theme, Icons.remove_rounded, onMinus),
          const SizedBox(width: 6),
          _stepBtn(theme, Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _stepBtn(FlutterFlowTheme theme, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.alternate.withOpacity(0.9)),
        ),
        child: Icon(icon, size: 18, color: theme.primaryText),
      ),
    );
  }

  Widget _divider(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      height: 1.5,
      color: theme.alternate.withOpacity(0.75),
    );
  }

  // -----------------------------
  // Build page (NO TABS, NO GANTT)
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _timelineColor(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: theme.primaryBackground,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _handleBack,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.alternate.withOpacity(0.9),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: const Icon(
                        Icons.timeline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Timeline',
                            style: _titleStyle(theme).copyWith(
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Build phases and milestones',
                            style: _subtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
                  children: [
                    const SizedBox(height: _sliverTopGap),
                    _buildProjectSelector(theme, accent),
                    const SizedBox(height: 12),
                    _buildSummaryCard(theme, accent, _phases),
                    const SizedBox(height: 12),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: _contentHPad),
                      child: _buildPhaseTimelineList(
                        theme: theme,
                        accent: accent,
                      ),
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
  final double progress; // 0..1
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
