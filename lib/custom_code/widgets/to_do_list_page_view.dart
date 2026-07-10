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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────
// UPDATE (this revision):
//   • The status filter is now a single SEGMENTED PILL control (replaces the
//     separate soft-pill counts row + underline TabBar). The active segment is
//     a GREEN pill that SLIDES between To Do / In Progress / Done
//     (AnimatedAlign, 260ms easeOutCubic). Each segment folds in its live count.
//   • The page now uses a NestedScrollView so the project card scrolls away and
//     the pill row stays PINNED to the top while the task list scrolls up
//     (pinned SliverPersistentHeader). The old fixed header Column + standalone
//     counts row have been removed.
//   • Quick-toggling a task done/undone from the list still shows the standard
//     ink snackbar ("Task updated.") — see _quickToggle + _snack().
// ─────────────────────────────────────────────────────────────────────

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
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _teal = Color(0xFF1E282E);
  static const Color _tealTint =
      Color(0xFFECF0F2); // DS: lime tint → neutral surface
  static const Color _live =
      Color(0xFF566670); // DS: lime → clay (high/attention)
  static const Color _navy = Color(0xFF1E282E);
  static const Color _green =
      Color(0xFF5D737E); // DS: to-do / in-progress / info
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;
  static const double _stickyTabsHeight = 62;
  static const String _kActiveProjectPath = 'subby_active_project_path';

  late TabController _tabController;
  DocumentReference? _projectRef;
  bool _resolved = false; // resolve projectRef once

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Rebuild so the sliding pill + segment weights track the selected tab.
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    // NOTE: route reading must happen in didChangeDependencies (needs context).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;

    // 1) projectRef from the route (ProjectDetailPageView passes this), else prefs.
    final fromRoute = _readRefFromRoute('projectRef', 'projects');
    if (fromRoute != null) {
      _projectRef = fromRoute;
      // Persist so Add Task / Detail Task inherit it (and survive cold start).
      SharedPreferences.getInstance()
          .then((p) => p.setString(_kActiveProjectPath, fromRoute.path));
      if (mounted) setState(() {});
    } else {
      _loadActiveProject();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Reads a serialized DocumentReference query param (same logic as
  // AddTaskPageView / DetailTaskPageView) and turns it into a DocumentReference.
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

  // Standard app snackbar — ink background, white text.
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: _green, // slate
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w700)),
      ));
  }

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
      s == 'high' ? const Color(0xFFAC0C0C) : (s == 'low' ? _faint : _teal);
  Color _priorityTint(String s) => s == 'high'
      ? const Color(0x1AAC0C0C)
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
    // Closing a task (marking it done) from the list asks for confirmation.
    // Reopening (done → todo) does not.
    if (next == 'done') {
      final ok = await _confirmClose();
      if (ok != true) return;
    }
    try {
      await ref.update(<String, dynamic>{
        'status': next,
        if (next == 'done') 'doneAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _snack('Task updated.'); // ✅ update snackbar
    } catch (e) {
      debugPrint('🔥 Quick toggle failed: $e');
      if (mounted) _snack('Could not update. Please try again.');
    }
  }

  // Red, full-width confirm before closing a task from the list
  // (shared "warning" module — matches DocumentUploadPageView).
  Future<bool?> _confirmClose() {
    const Color warn = Color(0xFFAC0C0C);
    return showDialog<bool>(
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
                    color: warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: warn.withOpacity(0.22), width: 1),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: warn, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Close this task?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontSize: 18,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This task will be marked as done. You can reopen it later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    fontSize: 14,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: warn,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Close task',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                    onTap: () => Navigator.pop(ctx, false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFCBD8DD), width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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

  // =========================================================
  // Project card
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

  // =========================================================
  // Segmented PILL tabs (sliding green indicator + folded counts)
  // =========================================================
  Widget _tabsBar() {
    return Container(
      color: _paper,
      padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 10),
      child: _pillTabs(
        current: _tabController.index,
        labels: const ['To Do', 'In Progress', 'Done'],
        statusKeys: const ['todo', 'in_progress', 'done'],
        collection: 'tasks',
        onTap: (i) => _tabController.animateTo(i),
      ),
    );
  }

  // Reusable segmented pill: a surface track with a GREEN pill that slides to
  // the active segment; each segment shows its label + a live count.
  Widget _pillTabs({
    required int current,
    required List<String> labels,
    required List<String> statusKeys,
    required String collection,
    required ValueChanged<int> onTap,
  }) {
    final n = labels.length;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / n;
          return Stack(
            children: [
              // Sliding green pill.
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: n == 1
                    ? Alignment.center
                    : Alignment(-1 + (2 * current / (n - 1)), 0),
                child: Container(
                  width: segW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E247),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 3,
                          offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
              // Tappable labels.
              Row(
                children: List.generate(n, (i) {
                  final active = i == current;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              labels[i],
                              style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 12.5,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                                color: active ? _ink : _faint,
                              ),
                            ),
                            const SizedBox(width: 5),
                            _tabCount(collection, statusKeys[i], active),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  // Live per-status count shown inside a pill segment.
  Widget _tabCount(String collection, String statusKey, bool active) {
    if (_projectRef == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('projectRef', isEqualTo: _projectRef)
          .where('status', isEqualTo: statusKey)
          .snapshots(),
      builder: (context, snap) {
        final n = snap.data?.docs.length ?? 0;
        return Text(
          '$n',
          style: TextStyle(
            fontFamily: _bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: (active ? _ink : _faint).withOpacity(0.75),
          ),
        );
      },
    );
  }

  // =========================================================
  // Task list (grouped by due date)
  // =========================================================
  Widget _taskList(int tabIndex) {
    if (_projectRef == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 110),
        children: [
          _emptyCard('No project selected',
              'Open this page from a project to see tasks.'),
        ],
      );
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

        section('Overdue', _live, const Color(0x33566670), overdue);
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
                              color: const Color(0xFFCBD8DD), width: 2),
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
  // Hero — dark ink header (matches ProjectTimelinePageView)
  // =========================================================
  Widget _hero() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF3A5966),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _heroCircle(Icons.arrow_back_ios_new_rounded, _handleBack),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _heroName(),
                      const SizedBox(height: 2),
                      Text('TO DO LIST',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
              _heroCountPill(),
            ],
          ),
          const SizedBox(height: 16),
          _heroStat(),
        ],
      ),
    );
  }

  Widget _heroCircle(IconData icon, VoidCallback onTap) => Material(
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

  Widget _heroName() {
    const style = TextStyle(
        fontFamily: _bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _paper);
    if (_projectRef == null) {
      return const Text('Project',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style);
    }
    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: _projectRef!.snapshots(),
      builder: (context, snap) {
        final raw = snap.data?.data();
        final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
        final name =
            (data['name'] ?? data['projectName'] ?? data['title'] ?? 'Project')
                .toString();
        return Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: style);
      },
    );
  }

  // One project-tasks query → total / open / completed / overdue counts.
  Widget _taskCounts(
      Widget Function(int total, int open, int done, int overdue) build) {
    if (_projectRef == null) return build(0, 0, 0, 0);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('projectRef', isEqualTo: _projectRef)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        int total = docs.length, open = 0, done = 0, overdue = 0;
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        for (final d in docs) {
          final st = (d.data()['status'] ?? 'todo').toString();
          if (st == 'done') {
            done++;
          } else {
            open++;
            final due = _asDate(d.data()['dueDate']);
            if (due != null &&
                DateTime(due.year, due.month, due.day).isBefore(todayStart)) {
              overdue++;
            }
          }
        }
        return build(total, open, done, overdue);
      },
    );
  }

  Widget _heroCountPill() =>
      _taskCounts((total, open, done, overdue) => Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.checklist_rounded, size: 14, color: _paper),
                const SizedBox(width: 5),
                Text('$total ${total == 1 ? 'task' : 'tasks'}',
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _paper)),
              ],
            ),
          ));

  Widget _heroStat() => _taskCounts((total, open, done, overdue) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OPEN TASKS',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _paper.withOpacity(0.55))),
              const SizedBox(height: 4),
              Text('$open ${open == 1 ? 'task' : 'tasks'}',
                  style: const TextStyle(
                      fontFamily: _displayFont,
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
                Text('$done completed',
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _paper.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text('$overdue overdue',
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _paper.withOpacity(0.45))),
              ],
            ),
          ),
        ],
      ));

  // Bright-white elevated footer (matches the Timeline inspector shell).
  Widget _footerBar() => Container(
        decoration: const BoxDecoration(
          color: _paper,
          border: Border(top: BorderSide(color: Color(0xFFEAEEF0), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14),
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
                    color: const Color(0xFFE7E247),
                    borderRadius: BorderRadius.circular(_radius)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_rounded, color: _ink, size: 20),
                    SizedBox(width: 9),
                    Text('Add Task',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  // =========================================================
  // Build
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(),
              // Body — pill tabs pin under the hero.
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, inner) {
                    return [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          minHeight: _stickyTabsHeight,
                          maxHeight: _stickyTabsHeight,
                          child: _tabsBar(),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _taskList(0),
                      _taskList(1),
                      _taskList(2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _footerBar()),
        ],
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

// ============================================================================
// Sticky header delegate (pinned pill tabs)
// ============================================================================
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
