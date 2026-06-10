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
import '/auth/firebase_auth/auth_util.dart';

class SnagListHomePageView extends StatefulWidget {
  const SnagListHomePageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Route name for returning to Dashboard page
    /// If left null, we fallback to "dashboardPage"
    this.dashboardRouteName,

    /// ✅ OPTIONAL: pass the active project reference directly
    this.projectRef,

    /// ✅ OPTIONAL: route name for Snag List page (destination)
    /// If left null, we fallback to "snagListPage"
    this.snagListRouteName,
  });

  final double? width;
  final double? height;

  final String? dashboardRouteName;

  /// ✅ Active project (optional)
  final DocumentReference? projectRef;

  final String? snagListRouteName;

  @override
  State<SnagListHomePageView> createState() => _SnagListHomePageViewState();
}

class _SnagListHomePageViewState extends State<SnagListHomePageView> {
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

  // ✅ Route fallbacks
  static const String _fallbackDashboardRoute = 'dashboardPage';
  static const String _fallbackSnagListRoute = 'snagListPage';

  // ✅ SharedPrefs key for the active project (shared across sections)
  static const String _kActiveProjectPath = 'subby_active_project_path';

  DocumentReference? _activeProjectRef;
  bool _resolvingProject = true;

  @override
  void initState() {
    super.initState();
    _initActiveProject();
  }

  Future<void> _initActiveProject() async {
    try {
      // 1) If passed in directly, use it.
      if (widget.projectRef != null) {
        _activeProjectRef = widget.projectRef;
        return;
      }

      // 2) Try SharedPreferences path saved by Projects section.
      final prefs = await SharedPreferences.getInstance();
      final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
      if (path.isNotEmpty) {
        _activeProjectRef = FirebaseFirestore.instance.doc(path);
        return;
      }

      // 3) Fallback: latest project for this user.
      final ownerRef = currentUserReference;
      if (ownerRef == null) return;

      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await FirebaseFirestore.instance
            .collection('projects')
            .where('ownerRef', isEqualTo: ownerRef)
            .orderBy('updatedAt', descending: true)
            .limit(1)
            .get();
      } catch (_) {
        snap = await FirebaseFirestore.instance
            .collection('projects')
            .where('ownerRef', isEqualTo: ownerRef)
            .limit(1)
            .get();
      }

      if (snap.docs.isNotEmpty) {
        _activeProjectRef = snap.docs.first.reference;
      }
    } finally {
      if (mounted) setState(() => _resolvingProject = false);
    }
  }

  // -----------------------------
  // Back navigation (uncover)
  // -----------------------------
  void _backToDashboard() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }

    final target = (widget.dashboardRouteName ?? '').trim().isNotEmpty
        ? widget.dashboardRouteName!.trim()
        : _fallbackDashboardRoute;

    context.pushReplacementNamed(
      target,
      extra: {
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.leftToRight,
          duration: Duration(milliseconds: 260),
        ),
      },
    );
  }

  // -----------------------------
  // Theme helpers
  // -----------------------------
  Color _snagColour(FlutterFlowTheme theme) {
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
  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.override(
      fontFamily: _displayFont,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: _displayFont,
      );

  TextStyle _metaStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _cardTitleStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
      );

  TextStyle _pillTextStyle(FlutterFlowTheme t) => t.labelSmall.override(
        fontFamily: _bodyFont,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );

  // -----------------------------
  // Subby card shell (for helper/info blocks)
  // -----------------------------
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
            blurRadius: 14,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  // -----------------------------
  // ✅ Status pill (outlined + dot) — matches MyProjects
  // -----------------------------
  Widget _statusPillOutlined({
    required FlutterFlowTheme theme,
    required Color accent,
    required String text,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent.withOpacity(0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pillTextStyle(theme).copyWith(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Count pill (unchanged)
  // -----------------------------
  Widget _countPill({
    required FlutterFlowTheme theme,
    required Color bg,
    required Color fg,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: _pillTextStyle(theme).copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // ✅ Navigate to Snag List page
  // -----------------------------
  Future<void> _openSnagList() async {
    final ref = _activeProjectRef;
    if (ref == null) return;

    // save for SnagListPageView
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveProjectPath, ref.path);

    final target = (widget.snagListRouteName ?? '').trim().isNotEmpty
        ? widget.snagListRouteName!.trim()
        : _fallbackSnagListRoute;

    context.pushNamed(
      target,
      extra: {
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    );
  }

  // -----------------------------
  // Snag counts stream (project scoped)
  // -----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>>? _snagCountStream(
      String statusKey) {
    final ref = _activeProjectRef;
    if (ref == null) return null;

    return FirebaseFirestore.instance
        .collection('snags')
        .where('projectRef', isEqualTo: ref)
        .where('status', isEqualTo: statusKey)
        .snapshots();
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'closed':
        return Icons.check_circle_rounded;
      case 'in_progress':
        return Icons.play_arrow_rounded;
      case 'review':
        return Icons.search_rounded;
      case 'open':
      default:
        return Icons.circle_rounded;
    }
  }

  // -----------------------------
  // ✅ Project tile (MATCHES MyProjects/Timeline) + snag counts row
  // -----------------------------
  Widget _projectTileWithCounts({
    required FlutterFlowTheme theme,
    required Color accent,
    required String name,
    required String location,
    required String status,
    required String lastUpdated,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openSnagList();
          });
        },
        borderRadius: BorderRadius.circular(_radius),

        // ✅ kill splash/highlight/overlay (flicker)
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.08),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Container(
              color: _paper,
              child: Row(
                children: [
                  Container(width: 4, color: accent),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: const Icon(Icons.checklist_rounded,
                        color: _paper, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status.trim().isNotEmpty)
                            _statusPillOutlined(
                              theme: theme,
                              accent: accent,
                              text: status,
                            ),
                          if (status.trim().isNotEmpty)
                            const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _cardTitleStyle(theme).copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: _inkMute),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _metaStyle(theme).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Last updated $lastUpdated',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _metaStyle(theme).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ✅ Counts row (Open / In Progress / Closed)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _snagCountPill(theme, accent, 'open'),
                              _snagCountPill(theme, accent, 'in_progress'),
                              _snagCountPill(theme, accent, 'closed'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _inkMute),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _snagCountPill(
      FlutterFlowTheme theme, Color accent, String statusKey) {
    final stream = _snagCountStream(statusKey);

    // If no project, show muted pills
    if (stream == null) {
      final c = _inkMute;
      return _countPill(
        theme: theme,
        bg: _hairline.withOpacity(0.35),
        fg: c,
        icon: _statusIcon(statusKey),
        label: '${_statusLabel(statusKey)} 0',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final n = snap.data?.docs.length ?? 0;
        final c = _statusColor(theme, accent, statusKey);

        return _countPill(
          theme: theme,
          bg: c.withOpacity(0.14),
          fg: c,
          icon: _statusIcon(statusKey),
          label: '${_statusLabel(statusKey)} $n',
        );
      },
    );
  }

  // -----------------------------
  // ✅ Active Project tile
  // -----------------------------
  Widget _activeProjectTile(FlutterFlowTheme theme, Color accent) {
    if (_resolvingProject) {
      return _subbyCardShell(
        theme: theme,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading your project…',
                style: _metaStyle(theme).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    if (_activeProjectRef == null) {
      return _subbyCardShell(
        theme: theme,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: Icon(Icons.folder_open_rounded, color: _inkMute, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No project selected',
                    style: _cardTitleStyle(theme).copyWith(
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a project in My Projects to view snags.',
                    style:
                        _metaStyle(theme).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: _activeProjectRef!.snapshots(),
      builder: (context, snap) {
        final raw = snap.data?.data();
        final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

        final name =
            (data['name'] ?? data['projectName'] ?? data['title'] ?? 'Project')
                .toString();

        final status = (data['status'] ?? 'Active').toString().trim();

        final province = (data['province'] ?? '').toString().trim();
        final city = (data['city'] ?? '').toString().trim();
        final address = (data['address'] ?? '').toString().trim();

        String locationLine = address;
        if (locationLine.isEmpty) {
          final parts = <String>[];
          if (city.isNotEmpty) parts.add(city);
          if (province.isNotEmpty) parts.add(province);
          locationLine = parts.join(', ');
        }
        if (locationLine.trim().isNotEmpty == false)
          locationLine = 'South Africa';

        final updatedAt = data['updatedAt'];
        final updatedLabel = (updatedAt is Timestamp)
            ? dateTimeFormat('relative', updatedAt.toDate())
            : 'recently';

        return _projectTileWithCounts(
          theme: theme,
          accent: accent,
          name: name,
          location: locationLine,
          status: status,
          lastUpdated: updatedLabel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final snagColour = _snagColour(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _backToDashboard,
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
                        color: snagColour,
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
                            style: _appTitleStyle(theme).copyWith(
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a project to view your snag list.',
                            style: _appSubtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Heading like other modules
                Text(
                  'Projects added',
                  style: _sectionTitleStyle(theme).copyWith(
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ Active Project Tile (only)
                _activeProjectTile(theme, snagColour),

                // ✅ removed: Tip tile
              ],
            ),
          ),
        ),
      ),
    );
  }
}
