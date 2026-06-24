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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToDoListPageView extends StatefulWidget {
  const ToDoListPageView({
    super.key,
    this.width,
    this.height,
    this.addTaskRouteName,
    this.taskDetailRouteName,
    this.backRouteName,
  });

  final double? width;
  final double? height;

  final String? addTaskRouteName;
  final String? taskDetailRouteName;
  final String? backRouteName;

  @override
  State<ToDoListPageView> createState() => _ToDoListPageViewState();
}

class _ToDoListPageViewState extends State<ToDoListPageView>
    with SingleTickerProviderStateMixin {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF017374);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  static const Color _teal = Color(0xFF017374);
  static const Color _tealTint = Color(0xFFE3F4F2);
  static const Color _live = Color(0xFFE5771E);
  static const Color _navy = Color(0xFF1D2834);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;
  static const String _kActiveProjectPath = 'subby_active_project_path';

  late TabController _tabController;
  DocumentReference? _projectRef;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadActiveProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty || !mounted) return;
    setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
  }

  void _handleBack() {
    if ((widget.backRouteName ?? '').trim().isNotEmpty) {
      context.pushNamed(widget.backRouteName!.trim());
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  String _tabKey(int i) => i == 0 ? 'todo' : (i == 1 ? 'in_progress' : 'done');

  // =========================================================
  // Type
  // =========================================================
  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _hairline)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _inkMute),
          ),
        ),
      );

  String _priorityLabel(String s) =>
      s == 'high' ? 'High' : (s == 'low' ? 'Low' : 'Medium');
  Color _priorityColor(String s) =>
      s == 'high' ? _live : (s == 'low' ? _faint : _teal);
  Color _priorityTint(String s) => s == 'high'
      ? const Color(0x1FE5771E)
      : (s == 'low' ? _surface : _tealTint);

  Widget _softPill(String text,
      {required Color fg, required Color bg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ],
      ),
    );
  }

  // =========================================================
  // Add / navigation
  // =========================================================
  void _handleAdd() {
    final route = (widget.addTaskRouteName ?? '').trim();
    if (route.isEmpty) return;
    context.pushNamed(
      route,
      queryParameters: {
        'projectRef': serializeParam(_projectRef, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  void _openTask(DocumentReference ref) {
    final route = (widget.taskDetailRouteName ?? '').trim();
    if (route.isEmpty) return;
    context.pushNamed(
      route,
      queryParameters: {
        'taskRef': serializeParam(ref, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  Future<void> _quickToggle(DocumentReference ref, String status) async {
    final next = status == 'done' ? 'todo' : 'done';
    try {
      await ref.update(<String, dynamic>{
        'status': next,
        if (next == 'done') 'doneAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 Quick toggle failed: $e');
    }
  }

  // =========================================================
  // Project card + counts
  // =========================================================
  Widget _projectCard() {
    if (_projectRef == null) {
      return _flatCard(Row(
        children: const [
          Icon(Icons.folder_off_rounded, color: _faint, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text('No project selected',
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink)),
          ),
        ],
      ));
    }
    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: _projectRef!.snapshots(),
      builder: (context, snap) {
        final raw = snap.data?.data();
        final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final name =
            (data['name'] ?? data['projectName'] ?? data['title'] ?? 'Project')
                .toString();
        return _flatCard(Row(
          children: [
            const Icon(Icons.checklist_rounded, color: _teal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 3),
                  const Text('Plan work, assign and track it',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _faint)),
                ],
              ),
            ),
          ],
        ));
      },
    );
  }

  Widget _flatCard(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        child: child,
      );

  Widget _countsRow() {
    if (_projectRef == null) return const SizedBox.shrink();
    Widget pill(String label, String key, IconData icon, Color fg, Color bg) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('projectRef', isEqualTo: _projectRef)
            .where('status', isEqualTo: key)
            .snapshots(),
        builder: (context, snap) {
          final n = snap.data?.docs.length ?? 0;
          return _softPill('$label $n', fg: fg, bg: bg, icon: icon);
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill('To Do', 'todo', Icons.radio_button_unchecked, _live,
            const Color(0x1FE5771E)),
        pill('In Progress', 'in_progress', Icons.play_arrow_rounded, _teal,
            _tealTint),
        pill('Done', 'done', Icons.check_circle, _faint, _surface),
      ],
    );
  }

  // =========================================================
  // Tabs
  // =========================================================
  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.only(right: 24),
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: _teal,
      indicatorWeight: 2,
      dividerColor: _hairlineOnSurface,
      labelColor: _teal,
      unselectedLabelColor: _faint,
      labelStyle: const TextStyle(
          fontFamily: _bodyFont, fontWeight: FontWeight.w800, fontSize: 14),
      unselectedLabelStyle: const TextStyle(
          fontFamily: _bodyFont, fontWeight: FontWeight.w600, fontSize: 14),
      tabs: const [
        Tab(text: 'To Do'),
        Tab(text: 'In Progress'),
        Tab(text: 'Done'),
      ],
    );
  }

  // =========================================================
  // Task list (grouped by due date)
  // =========================================================
  Widget _taskList(int tabIndex) {
    if (_projectRef == null) {
      return _emptyCard(
          'No project selected', 'Open this page from a project to see tasks.');
    }
    final statusKey = _tabKey(tabIndex);
    final stream = FirebaseFirestore.instance
        .collection('tasks')
        .where('projectRef', isEqualTo: _projectRef)
        .where('status', isEqualTo: statusKey)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 110),
            children: [
              _loadingCard(),
            ],
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          final label = tabIndex == 0
              ? 'No tasks to do'
              : tabIndex == 1
                  ? 'Nothing in progress'
                  : 'Nothing done yet';
          return ListView(
            padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 110),
            children: [_emptyCard(label, 'Tasks you add will show up here.')],
          );
        }

        // Done tab: flat list, most-recent first.
        if (statusKey == 'done') {
          final sorted = [...docs];
          sorted.sort((a, b) {
            final da =
                _asDate(a.data()['doneAt']) ?? _asDate(a.data()['updatedAt']);
            final db =
                _asDate(b.data()['doneAt']) ?? _asDate(b.data()['updatedAt']);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
          return ListView(
            padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 110),
            children: [for (final d in sorted) _taskRow(d, statusKey)],
          );
        }

        // To Do / In Progress: group by due date.
        final overdue = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final today = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        for (final d in docs) {
          final due = _asDate(d.data()['dueDate']);
          if (due == null) {
            upcoming.add(d);
          } else {
            final dd = DateTime(due.year, due.month, due.day);
            if (dd.isBefore(todayStart)) {
              overdue.add(d);
            } else if (dd.isAtSameMomentAs(todayStart)) {
              today.add(d);
            } else {
              upcoming.add(d);
            }
          }
        }

        int byDue(QueryDocumentSnapshot<Map<String, dynamic>> a,
            QueryDocumentSnapshot<Map<String, dynamic>> b) {
          final da = _asDate(a.data()['dueDate']);
          final db = _asDate(b.data()['dueDate']);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        }

        overdue.sort(byDue);
        today.sort(byDue);
        upcoming.sort(byDue);

        final children = <Widget>[];
        void section(String label, Color color, Color tint,
            List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
          if (list.isEmpty) return;
          children.add(Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 2),
            child: Row(
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                      color: tint, borderRadius: BorderRadius.circular(999)),
                  child: Text('${list.length}',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ],
            ),
          ));
          for (final d in list) {
            children.add(_taskRow(d, statusKey));
          }
        }

        section('Overdue', _live, const Color(0x1FE5771E), overdue);
        section('Due Today', _teal, _tealTint, today);
        section('Upcoming', _faint, _surface, upcoming);

        return ListView(
          padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 110),
          children: children,
        );
      },
    );
  }

  Widget _taskRow(
      QueryDocumentSnapshot<Map<String, dynamic>> doc, String statusKey) {
    final d = doc.data();
    final title = (d['title'] ?? 'Task').toString();
    final priority = (d['priority'] ?? 'med').toString();
    final listingName = (d['assignedListingName'] ?? '').toString().trim();
    final userName = (d['assignedUserName'] ?? '').toString().trim();
    final assignee = listingName.isNotEmpty
        ? listingName
        : (userName.isNotEmpty ? userName : 'Unassigned');
    final due = _asDate(d['dueDate']);
    final isDone = statusKey == 'done';

    final checklist = <Map<String, dynamic>>[];
    final rawCl = d['checklist'];
    if (rawCl is List) {
      for (final c in rawCl) {
        if (c is Map) checklist.add(Map<String, dynamic>.from(c));
      }
    }
    final clDone = checklist.where((c) => c['done'] == true).length;

    final dueLabel =
        isDone ? 'Done' : (due == null ? 'No date' : _dueLabel(due));

    return InkWell(
      onTap: () => _openTask(doc.reference),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: _hairlineOnSurface, width: 1))),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _quickToggle(doc.reference, statusKey),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 1, right: 13),
                child: isDone
                    ? const Icon(Icons.check_circle_rounded,
                        size: 22, color: _teal)
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFC7D0DA), width: 2),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          color: isDone ? _faint : _ink,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none)),
                  const SizedBox(height: 3),
                  Text('$dueLabel · $assignee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _faint)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _softPill(_priorityLabel(priority),
                          fg: _priorityColor(priority),
                          bg: _priorityTint(priority)),
                      if (checklist.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _softPill('$clDone/${checklist.length}',
                            fg: _faint,
                            bg: _surface,
                            icon: Icons.checklist_rounded),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String title, String body) {
    return _flatCard(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: _displayFont,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink)),
        const SizedBox(height: 6),
        Text(body,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _faint)),
      ],
    ));
  }

  Widget _loadingCard() {
    return _flatCard(Row(
      children: const [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_teal)),
        ),
        SizedBox(width: 12),
        Text('Loading tasks…',
            style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _faint)),
      ],
    ));
  }

  // =========================================================
  // Build
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _minBack(),
                      const SizedBox(height: 18),
                      const Text('To Do List',
                          style: TextStyle(
                              fontFamily: _displayFont,
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              height: 1.05,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      const Text('Plan work, assign and track it',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _faint)),
                      const SizedBox(height: 18),
                      _projectCard(),
                      const SizedBox(height: 14),
                      _countsRow(),
                      const SizedBox(height: 16),
                      _tabs(),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _taskList(0),
                      _taskList(1),
                      _taskList(2),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: _hPad,
              right: _hPad,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleAdd,
                    borderRadius: BorderRadius.circular(_radius),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                          color: _teal,
                          borderRadius: BorderRadius.circular(_radius)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_rounded, color: _paper, size: 20),
                          SizedBox(width: 9),
                          Text('Add Task',
                              style: TextStyle(
                                  fontFamily: _bodyFont,
                                  color: _paper,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- helpers ----
  DateTime? _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final dd = DateTime(due.year, due.month, due.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = dd.difference(today).inDays;
    if (days < 0) return 'Due ${dateTimeFormat('d MMM', due)}';
    if (days == 0) return 'Due today';
    return 'Due ${dateTimeFormat('d MMM', due)}';
  }
}
