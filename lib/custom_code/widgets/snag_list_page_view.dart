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

import '/custom_code/actions/index.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────
// UPDATE (this revision):
//   • The status filter is now a single SEGMENTED PILL control (replaces the
//     separate soft-pill counts row + underline TabBar). The active segment is
//     a GREEN pill that SLIDES between Open / In Progress / Closed
//     (AnimatedAlign, 260ms easeOutCubic). Each segment folds in its live count
//     (Open 3, In Progress 2, Closed 2) — see _pillTabs + _tabCount.
//   • The pill row stays PINNED to the top while the list scrolls up (it is the
//     pinned SliverPersistentHeader in the NestedScrollView). The old standalone
//     counts sliver has been removed.
//   • Tapping a segment drives the TabController (animateTo); a controller
//     listener rebuilds so the sliding pill tracks the selection.
// ─────────────────────────────────────────────────────────────────────

class SnagListPageView extends StatefulWidget {
  const SnagListPageView({
    super.key,
    this.width,
    this.height,
    this.addSnagRouteName,
    this.snagDetailRouteName,
    this.backRouteName,
  });

  final double? width;
  final double? height;

  final String? addSnagRouteName;
  final String? snagDetailRouteName;
  final String? backRouteName;

  @override
  State<SnagListPageView> createState() => _SnagListPageViewState();
}

class _SnagListPageViewState extends State<SnagListPageView>
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
      Color(0xFF566670); // DS: lime → clay (high / attention)
  static const Color _green = Color(0xFF4E504F); // DS: in-progress / info
  static const Color _coral = Color(0xFF566670); // destructive / error (clay)
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 10;
  static const double _gap = 0;

  static const double _sliverTopGap = 4;
  static const double _stickyTabsHeight = 62;
  static const double _contentHPad = _hPad;

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
    // Follow the swipe continuously so the pill slides with the finger.
    _tabController.animation?.addListener(() {
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
      // Persist so Add Snag / Detail Snag inherit it (and survive cold start).
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
  // AddSnagPageView / DetailSnagPageView) and turns it into a DocumentReference.
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
    if (path.isEmpty) return;

    if (mounted) {
      setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
    }
  }

  // Matches ToDoListPageView: prefer an explicit back route, else pop.
  void _handleBack() {
    if ((widget.backRouteName ?? '').trim().isNotEmpty) {
      context.pushNamed(widget.backRouteName!.trim());
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Color _snagColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).snagListColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY (flat slate system)
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

  // Soft-tint pill (still used by the snag row for status + severity).
  Widget _softPill(String text,
      {required Color fg, required Color bg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ).copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // Status helpers (string-based for Firestore)
  // ---------------------------------------
  String _tabStatusKey(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'open';
      case 1:
        return 'in_progress';
      case 2:
        return 'closed';
      default:
        return 'open';
    }
  }

  // In Progress = white on solid GREEN; Open = ink on neutral surface;
  // Closed = faint on surface.
  Color _statusColor(FlutterFlowTheme theme, Color accent, String status) {
    switch (status) {
      case 'in_progress':
        return _paper; // white on solid green
      case 'closed':
      case 'review':
        return _faint; // done — neutral
      case 'open':
      default:
        return _ink;
    }
  }

  Color _statusTint(String status) {
    switch (status) {
      case 'in_progress':
        return _ink; // solid ink fill (matches In Progress text)
      case 'closed':
      case 'review':
        return _surface;
      default:
        return _tealTint; // neutral surface
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'closed':
        return 'Closed';
      case 'in_progress':
        return 'In Progress';
      case 'review':
        return 'Review';
      case 'open':
      default:
        return 'Open';
    }
  }

  // Critical = clay; major = ink; minor = faint. Tint: critical clay@16%, else surface.
  Color _severityColor(String sev) => sev == 'critical'
      ? const Color(0xFFAC0C0C)
      : (sev == 'minor' ? _faint : _ink);
  Color _severityTint(String sev) =>
      sev == 'critical' ? const Color(0x1AAC0C0C) : _surface;

  String _severityLabel(String sev) {
    switch (sev) {
      case 'critical':
        return 'Critical';
      case 'major':
        return 'Major';
      case 'minor':
      default:
        return 'Minor';
    }
  }

  // ---------------------------------------
  // Project card (wired) — flat
  // ---------------------------------------
  Widget _buildProjectCard(FlutterFlowTheme theme, Color accent) {
    if (_projectRef == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
        child: _flatCard(
          Row(
            children: [
              const Icon(Icons.folder_off_rounded, color: _faint, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No project selected', style: _rowTitleStyle(theme)),
                    const SizedBox(height: 4),
                    Text('Select a project first to view snags.',
                        style: _rowMetaStyle(theme)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: StreamBuilder<DocumentSnapshot<Object?>>(
        stream: _projectRef!.snapshots(),
        builder: (context, snap) {
          final raw = snap.data?.data();
          final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          final name = (data['name'] ??
                  data['projectName'] ??
                  data['title'] ??
                  'Project')
              .toString();

          return _flatCard(
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, color: _teal, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: _rowTitleStyle(theme)),
                      const SizedBox(height: 4),
                      Text('Track issues, assign and close out',
                          style: _rowMetaStyle(theme)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------
  // Segmented PILL tabs (sliding green indicator + folded counts)
  // ---------------------------------------
  Widget _buildTabs(FlutterFlowTheme theme, Color accent) {
    return Container(
      color: _paper,
      padding: const EdgeInsets.fromLTRB(_contentHPad, 4, _contentHPad, 10),
      alignment: Alignment.bottomLeft,
      child: _pillTabs(
        current:
            _tabController.animation?.value ?? _tabController.index.toDouble(),
        labels: const ['Open', 'In Progress', 'Closed'],
        statusKeys: const ['open', 'in_progress', 'closed'],
        collection: 'snags',
        onTap: (i) => _tabController.animateTo(i),
      ),
    );
  }

  // Reusable segmented pill: a surface track with a GREEN pill that slides to
  // the active segment; each segment shows its label + a live count.
  Widget _pillTabs({
    required double current,
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
                  final active = current.round() == i;
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

  Stream<QuerySnapshot<Map<String, dynamic>>>? _snagStreamForTab(int tabIndex) {
    if (_projectRef == null) return null;
    final statusKey = _tabStatusKey(tabIndex);
    // NOTE: no .orderBy here — two equality filters auto-index, so this needs
    // no composite index. We sort by createdAt (desc) client-side below.
    return FirebaseFirestore.instance
        .collection('snags')
        .where('projectRef', isEqualTo: _projectRef)
        .where('status', isEqualTo: statusKey)
        .snapshots();
  }

  // Newest-first sort done in Dart so the list query needs no composite index.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedByCreatedDesc(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = [...docs];
    int millis(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final v = doc.data()['createdAt'];
      if (v is Timestamp) return v.millisecondsSinceEpoch;
      if (v is DateTime) return v.millisecondsSinceEpoch;
      return 0;
    }

    list.sort((a, b) => millis(b).compareTo(millis(a)));
    return list;
  }

  // ---------------------------------------
  // Snag row (hairline-ruled, flat)
  // ---------------------------------------
  Widget _buildSnagCard(
    FlutterFlowTheme theme,
    Color accent, {
    required DocumentReference snagRef,
    required Map<String, dynamic> d,
  }) {
    final title = (d['title'] ?? 'Snag').toString();
    final area = (d['area'] ?? d['room'] ?? 'Area not set').toString();
    final status = (d['status'] ?? 'open').toString();
    final severity = (d['severity'] ?? 'minor').toString();
    final assignedName =
        (d['assignedToName'] ?? d['assignedTo'] ?? '').toString().trim();
    final photoUrl = (d['photoUrl'] ?? d['photo_url'] ?? '').toString().trim();

    final sub = assignedName.isNotEmpty ? '$area · $assignedName' : area;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final route = (widget.snagDetailRouteName ?? '').trim();
          if (route.isEmpty) return;
          context.pushNamed(
            route,
            queryParameters: {
              'snagRef': serializeParam(snagRef, ParamType.DocumentReference),
            }.withoutNulls,
          );
        },
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: _hairlineOnSurface, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _hairlineOnSurface),
                  image: photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: photoUrl.isEmpty
                    ? const Icon(Icons.photo_camera_outlined,
                        color: _faint, size: 22)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _rowTitleStyle(theme), maxLines: 2),
                    const SizedBox(height: 3),
                    Text(sub, style: _rowMetaStyle(theme)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _softPill(_statusLabel(status),
                            fg: _statusColor(theme, accent, status),
                            bg: _statusTint(status)),
                        const SizedBox(width: 8),
                        _softPill(_severityLabel(severity),
                            fg: _severityColor(severity),
                            bg: _severityTint(severity)),
                      ],
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

  // ---------------------------------------
  // Empty state — flat
  // ---------------------------------------
  Widget _buildEmptyState(FlutterFlowTheme theme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _flatCard(
        padding: const EdgeInsets.all(18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _rowTitleStyle(theme)),
            const SizedBox(height: 6),
            Text('No items here yet.', style: _rowMetaStyle(theme)),
          ],
        ),
      ),
    );
  }

  void _handleAddSnag() {
    final route = (widget.addSnagRouteName ?? '').trim();
    if (route.isEmpty) {
      showAppToast(context, 'Add Snag page not linked yet.', false);
      return;
    }

    context.pushNamed(
      route,
      queryParameters: {
        'projectRef': serializeParam(_projectRef, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  // =========================================================
  // Hero — dark ink header (matches ProjectTimelinePageView)
  // =========================================================
  Widget _hero() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF2F3A4C),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 14),
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
                      Text('SNAG LIST',
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
        ],
      ),
    );
  }

  // Scrolls away with the page — dark colour continues below the pinned bar.
  // Stat block now sits on WHITE, in a bordered card below the pinned ink
  // masthead (matches the redesigned ProjectDetailPageView overview card).
  Widget _heroLower() => Container(
        width: double.infinity,
        color: _paper,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
        child: _heroStat(),
      );

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

  // One project-snags query → total / active / closed / critical counts.
  Widget _snagCounts(
      Widget Function(int total, int active, int closed, int critical) build) {
    if (_projectRef == null) return build(0, 0, 0, 0);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('snags')
          .where('projectRef', isEqualTo: _projectRef)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        int total = docs.length, active = 0, closed = 0, critical = 0;
        for (final d in docs) {
          final st = (d.data()['status'] ?? 'open').toString();
          if (st == 'closed') {
            closed++;
          } else {
            active++;
            if ((d.data()['severity'] ?? 'minor').toString() == 'critical') {
              critical++;
            }
          }
        }
        return build(total, active, closed, critical);
      },
    );
  }

  Widget _heroCountPill() =>
      _snagCounts((total, active, closed, critical) => Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fact_check_outlined, size: 14, color: _paper),
                const SizedBox(width: 5),
                Text('$total ${total == 1 ? 'snag' : 'snags'}',
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _paper)),
              ],
            ),
          ));

  Widget _heroStat() =>
      _snagCounts((total, active, closed, critical) => Container(
            decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAEEF0))),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OPEN SNAGS',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: _inkMute)),
                    const SizedBox(height: 6),
                    Text('$active ${active == 1 ? 'snag' : 'snags'}',
                        style: const TextStyle(
                            fontFamily: _displayFont,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                            color: _ink,
                            height: 0.95)),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$closed closed',
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _inkMute)),
                      const SizedBox(height: 2),
                      Text('$critical critical',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: critical > 0
                                  ? const Color(0xFFAC0C0C)
                                  : const Color(0xFF93A3AC))),
                    ],
                  ),
                ),
              ],
            ),
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
              onTap: _handleAddSnag,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFFE7E247),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_rounded, color: _ink, size: 20),
                    SizedBox(width: 9),
                    Text('Add Snag',
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _snagColor(theme);

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
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, inner) {
                    return [
                      // Hero stat scrolls away; the tabs pin under the bar.
                      SliverToBoxAdapter(child: _heroLower()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          minHeight: _stickyTabsHeight,
                          maxHeight: _stickyTabsHeight,
                          child: _buildTabs(theme, accent),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: List.generate(3, (tabIndex) {
                      final stream = _snagStreamForTab(tabIndex);

                      if (_projectRef == null) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
                          children: [
                            _buildEmptyState(theme, 'No project selected'),
                          ],
                        );
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: stream,
                        builder: (context, snap) {
                          if (snap.hasError) {
                            debugPrint('🔥 Snag list query error: '
                                '${snap.error}');
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
                              children: [
                                _buildEmptyState(theme, 'Could not load snags'),
                              ],
                            );
                          }

                          final docs =
                              _sortedByCreatedDesc(snap.data?.docs ?? const []);

                          if (snap.connectionState == ConnectionState.waiting &&
                              docs.isEmpty) {
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: _contentHPad),
                                  child: _flatCard(
                                    padding: const EdgeInsets.all(18),
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    _teal),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('Loading snags…',
                                            style: _rowMetaStyle(theme)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          if (docs.isEmpty) {
                            final label = tabIndex == 0
                                ? 'Open snags'
                                : tabIndex == 1
                                    ? 'In progress'
                                    : 'Closed';
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
                              children: [_buildEmptyState(theme, label)],
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                _contentHPad, 4, _contentHPad, 110),
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              return _buildSnagCard(
                                theme,
                                accent,
                                snagRef: doc.reference,
                                d: doc.data(),
                              );
                            },
                          );
                        },
                      );
                    }),
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
