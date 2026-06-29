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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────
// NOTE: The Snag List itself is unchanged — it has no inline status toggle,
// so the To-Do "snackbar on quick action" change has no equivalent here.
// All behavioural changes (working Edit, ownership-gated Edit/Delete, the
// shared delete-warning dialog, update/close/delete snackbars, the
// before/after proof view) live on DetailSnagPageView + AddSnagPageView.
// Pass the Detail page's new `editSnagRouteName` to your Add/Edit Snag route.
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
  static const Color _ink = Color(0xFF323F4D);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  static const Color _teal = Color(0xFF323F4D);
  static const Color _tealTint =
      Color(0xFFEEF1F4); // DS: lime tint → neutral surface
  static const Color _live =
      Color(0xFFCC4B3C); // DS: lime → clay (high / attention)
  static const Color _green = Color(0xFF1F8A5B); // DS: in-progress / info
  static const Color _coral = Color(0xFFCC4B3C); // destructive / error (clay)
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;
  static const double _gap = 0;

  static const double _sliverTopGap = 4;
  static const double _stickyTabsHeight = 58;
  static const double _contentHPad = _hPad;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  late TabController _tabController;

  DocumentReference? _projectRef;
  bool _resolved = false; // resolve projectRef once

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  // Soft-tint pill.
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
        return _green; // solid green fill
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
  Color _severityColor(String sev) =>
      sev == 'critical' ? _live : (sev == 'minor' ? _faint : _ink);
  Color _severityTint(String sev) =>
      sev == 'critical' ? const Color(0x29CC4B3C) : _surface;

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
  // Underline tabs
  // ---------------------------------------
  Widget _buildTabs(FlutterFlowTheme theme, Color accent) {
    return Container(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      alignment: Alignment.bottomLeft,
      child: TabBar(
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
        labelStyle: theme.bodyMedium.override(
          fontFamily: _bodyFont,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        unselectedLabelStyle: theme.bodyMedium.override(
          fontFamily: _bodyFont,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Open'),
          Tab(text: 'In Progress'),
          Tab(text: 'Closed'),
        ],
      ),
    );
  }

  // ---------------------------------------
  // Snag counts row (soft pills)
  // ---------------------------------------
  Widget _buildCountsRow(FlutterFlowTheme theme, Color accent) {
    if (_projectRef == null) return const SizedBox.shrink();

    Widget countPill(String label, String statusKey, IconData icon) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('snags')
            .where('projectRef', isEqualTo: _projectRef)
            .where('status', isEqualTo: statusKey)
            .snapshots(),
        builder: (context, snap) {
          final n = snap.data?.docs.length ?? 0;
          final c = _statusColor(theme, accent, statusKey);
          return _softPill('$label $n',
              fg: c, bg: _statusTint(statusKey), icon: icon);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          countPill('Open', 'open', Icons.circle),
          countPill('In Progress', 'in_progress', Icons.play_arrow_rounded),
          countPill('Closed', 'closed', Icons.check_circle),
        ],
      ),
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
                  borderRadius: BorderRadius.circular(12),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _ink,
          content: Text(
            'Add Snag page not linked yet.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: _bodyFont,
                  color: _paper,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
      return;
    }

    context.pushNamed(
      route,
      queryParameters: {
        'projectRef': serializeParam(_projectRef, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _snagColor(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: _vPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — minimal back + big title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _hPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _minBack(),
                        const SizedBox(height: 18),
                        Text('Snag List', style: _pageTitle(theme)),
                        const SizedBox(height: 8),
                        Text('Capture defects and close them out',
                            style: _pageSubtitle(theme)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Body
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (context, inner) {
                        return [
                          const SliverToBoxAdapter(
                            child: SizedBox(height: _sliverTopGap),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildProjectCard(theme, accent),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCountsRow(theme, accent),
                            ),
                          ),
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

                          return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: stream,
                            builder: (context, snap) {
                              // Surface query errors instead of silently
                              // showing an empty list (e.g. a missing index).
                              if (snap.hasError) {
                                debugPrint('🔥 Snag list query error: '
                                    '${snap.error}');
                                return ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 12, 0, 110),
                                  children: [
                                    _buildEmptyState(
                                        theme, 'Could not load snags'),
                                  ],
                                );
                              }

                              final docs = _sortedByCreatedDesc(
                                  snap.data?.docs ?? const []);

                              if (snap.connectionState ==
                                      ConnectionState.waiting &&
                                  docs.isEmpty) {
                                return ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 12, 0, 110),
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
                                                    AlwaysStoppedAnimation<
                                                        Color>(_teal),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 12, 0, 110),
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
            ),

            // Floating Add button — flat slate
            Positioned(
              left: _hPad,
              right: _hPad,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleAddSnag,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: _paper, size: 20),
                          const SizedBox(width: 9),
                          Text(
                            'Add Snag',
                            style: theme.bodyMedium.override(
                              fontFamily: _bodyFont,
                              color: _paper,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
}

// ============================================================================
// Sticky header delegate (pinned tabs)
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
