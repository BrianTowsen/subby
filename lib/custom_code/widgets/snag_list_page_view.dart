// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnagListPageView extends StatefulWidget {
  const SnagListPageView({
    super.key,
    this.width,
    this.height,

    /// Optional: route name to open "Add Snag" page (no params by default)
    this.addSnagRouteName,

    /// Optional: route name to open "Snag Detail" page (expects snagRef param)
    this.snagDetailRouteName,

    /// Optional: where to go back to (fallback = pop)
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
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF14243F);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFFFE74C); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF14243F);
  // Status
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / done / warning
  static const Color _coral = Color(0xFFC8102E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
  static const double _gap = 12;

  // ✅ subtle sliver breathing room (no clipping)
  static const double _sliverSidePad = 2;
  static const double _sliverTopGap = 8;

  // ✅ sticky header must be tall enough for a shadowed card
  static const double _stickyTabsHeight = 92;

  // ✅ content padding moved INSIDE containers so scrollbar can sit on the edge
  static const double _contentHPad = _hPad + _sliverSidePad;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  late TabController _tabController;

  DocumentReference? _projectRef;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActiveProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -----------------------------
  // Active project from SharedPrefs
  // -----------------------------
  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;

    if (mounted) {
      setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
    }
  }

  // -----------------------------
  // Back navigation (safe)
  // -----------------------------
  void _handleBack() {
    if ((widget.backRouteName ?? '').trim().isNotEmpty) {
      context.pushNamed(widget.backRouteName!.trim());
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  // -----------------------------
  // ✅ Accent colour (SnagListColour theme token)
  // -----------------------------
  Color _snagColor(FlutterFlowTheme theme) {
    // FlutterFlow custom color name: SnagListColour -> getter typically snagListColour
    try {
      final c = (theme as dynamic).snagListColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY (CONSISTENT: token + explicit family)
  // =========================================================
  TextStyle _titleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.override(
      fontFamily: _displayFont,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _subtitleStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: _bodyFont,
      color: _inkMute,
    );
  }

  TextStyle _sectionTitleStyle(FlutterFlowTheme theme) {
    return theme.titleSmall.override(
      fontFamily: _displayFont,
      fontWeight: FontWeight.w800,
      color: _ink,
    );
  }

  TextStyle _rowTitleStyle(FlutterFlowTheme theme) {
    return theme.bodyMedium.override(
      fontFamily: _bodyFont,
      fontWeight: FontWeight.w900,
      color: _ink,
    );
  }

  TextStyle _rowMetaStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: _bodyFont,
      color: _inkMute,
    );
  }

  TextStyle _pillTextStyle(FlutterFlowTheme theme) {
    return theme.labelSmall.override(
      fontFamily: _bodyFont,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
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
        color: _paper,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: _hairline.withOpacity(0.9),
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

  Widget _divider(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      height: 1.5,
      color: _hairline.withOpacity(0.75),
    );
  }

  // ---------------------------------------
  // Pills
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

  Color _statusColor(FlutterFlowTheme theme, Color accent, String status) {
    switch (status) {
      case 'closed':
        return _live;
      case 'in_progress':
        return accent;
      case 'review':
        return _inkMute;
      case 'open':
      default:
        return _coral;
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

  Color _severityColor(FlutterFlowTheme theme, String sev) {
    switch (sev) {
      case 'critical':
        return _coral;
      case 'major':
        return _inkMute;
      case 'minor':
      default:
        return _inkMute;
    }
  }

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
  // Project card (wired)
  // ---------------------------------------
  Widget _buildProjectCard(FlutterFlowTheme theme, Color accent) {
    if (_projectRef == null) {
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
                  color: _hairline.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(Icons.folder_off_rounded, color: _inkMute, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No project selected', style: _rowTitleStyle(theme)),
                    const SizedBox(height: 4),
                    Text(
                      'Select a project first to view snags.',
                      style: _rowMetaStyle(theme),
                    ),
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

          return _subbyCardShell(
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
                  child:
                      Icon(Icons.fact_check_rounded, color: accent, size: 22),
                ),
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
  // Sticky tabs
  // ---------------------------------------
  Widget _buildTabs(FlutterFlowTheme theme, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(6),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
          labelColor: _paper,
          unselectedLabelColor: _inkMute,
          labelStyle: theme.bodyMedium.override(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle: theme.bodyMedium.override(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w800,
          ),
          tabs: const [
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------
  // Snag counts row
  // ---------------------------------------
  Widget _buildCountsRow(FlutterFlowTheme theme, Color accent) {
    if (_projectRef == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
        child: _subbyCardShell(
          theme: theme,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Select a project to load counts.',
                  style: _rowMetaStyle(theme),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
          return _pill(
            theme,
            text: '$label $n',
            bg: c.withOpacity(0.14),
            fg: c,
            icon: icon,
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            countPill('Open', 'open', Icons.circle_rounded),
            countPill('In Progress', 'in_progress', Icons.play_arrow_rounded),
            countPill('Closed', 'closed', Icons.check_circle_rounded),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------
  // Snag list stream for a tab
  // ---------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>>? _snagStreamForTab(int tabIndex) {
    if (_projectRef == null) return null;
    final statusKey = _tabStatusKey(tabIndex);

    return FirebaseFirestore.instance
        .collection('snags')
        .where('projectRef', isEqualTo: _projectRef)
        .where('status', isEqualTo: statusKey)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ---------------------------------------
  // Snag card
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

    final sc = _statusColor(theme, accent, status);
    final sevC = _severityColor(theme, severity);

    return InkWell(
      borderRadius: BorderRadius.circular(_radius),
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
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _hairline.withOpacity(0.9)),
                image: photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: photoUrl.isEmpty
                  ? Icon(Icons.photo_camera_rounded, color: _inkMute, size: 22)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _rowTitleStyle(theme), maxLines: 2),
                  const SizedBox(height: 4),
                  Text(area, style: _rowMetaStyle(theme)),
                  if (assignedName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Assigned: $assignedName',
                        style: _rowMetaStyle(theme)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _pill(
                        theme,
                        text: _statusLabel(status),
                        bg: sc.withOpacity(0.14),
                        fg: sc,
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        theme,
                        text: _severityLabel(severity),
                        bg: sevC.withOpacity(0.12),
                        fg: sevC,
                      ),
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

  // ---------------------------------------
  // Empty state
  // ---------------------------------------
  Widget _buildEmptyState(FlutterFlowTheme theme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _sectionTitleStyle(theme)),
            const SizedBox(height: 6),
            Text(
              'No items here yet.',
              style: _rowMetaStyle(theme),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------
  // Add snag
  // ---------------------------------------
  void _handleAddSnag() {
    final route = (widget.addSnagRouteName ?? '').trim();
    if (route.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add Snag page not linked yet.',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                  color: _paper,
                  fontWeight: FontWeight.w800,
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

  // -----------------------------
  // Build page
  // -----------------------------
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
                              color: _paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _hairline.withOpacity(0.9),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 22,
                              color: _ink,
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
                            Icons.checklist_rounded,
                            color: _paper,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Snag List',
                                style: _titleStyle(theme).copyWith(
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capture defects and close them out',
                                style: _subtitleStyle(theme),
                              ),
                            ],
                          ),
                        ),
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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildProjectCard(theme, accent),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCountsRow(theme, accent),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              minHeight: _stickyTabsHeight,
                              maxHeight: _stickyTabsHeight,
                              child: Container(
                                color: _paper,
                                padding: const EdgeInsets.only(bottom: 12),
                                alignment: Alignment.bottomCenter,
                                child: _buildTabs(theme, accent),
                              ),
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
                              final docs = snap.data?.docs ?? const [];

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
                                      child: _subbyCardShell(
                                        theme: theme,
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(accent),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Loading snags…',
                                              style: _rowMetaStyle(theme),
                                            ),
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
                                  children: [
                                    _buildEmptyState(theme, label),
                                  ],
                                );
                              }

                              return ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 12, 0, 110),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: _gap),
                                itemBuilder: (context, i) {
                                  final doc = docs[i];
                                  final d = doc.data();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: _contentHPad),
                                    child: _buildSnagCard(
                                      theme,
                                      accent,
                                      snagRef: doc.reference,
                                      d: d,
                                    ),
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

            // Floating Add button (Subby style)
            Positioned(
              left: _hPad,
              right: _hPad,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: InkWell(
                  onTap: _handleAddSnag,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _spark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withOpacity(0.18),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: _sparkInk, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Add Snag',
                          style: theme.bodyMedium.override(
                            fontFamily: _bodyFont,
                            color: _sparkInk,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
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
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
