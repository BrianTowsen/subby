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
import '/auth/firebase_auth/auth_util.dart';

// ======================= MyProjectsHomePageView (FULL FILE) =======================

class MyProjectsHomePageView extends StatefulWidget {
  const MyProjectsHomePageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Route name for the Project Detail page
    /// Default: "ProjectDetailPage"
    this.projectDetailRouteName,

    /// ✅ Route name for returning to Dashboard page
    /// Default: "DashboardPage"
    this.dashboardRouteName,

    /// ✅ Route name for the Add Project page
    /// Default: "addProjectsPage"
    this.addProjectsRouteName,

    /// ✅ Param name used when passing projectRef to other pages
    /// Default: "projectRef"
    this.projectParamName,
  });

  final double? width;
  final double? height;

  final String? projectDetailRouteName;

  /// ✅ Back-to-dashboard route
  final String? dashboardRouteName;

  /// ✅ Add Project route
  final String? addProjectsRouteName;

  /// ✅ param name used in queryParameters
  final String? projectParamName;

  @override
  State<MyProjectsHomePageView> createState() => _MyProjectsHomePageViewState();
}

class _MyProjectsHomePageViewState extends State<MyProjectsHomePageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFAEE03F); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF16202E);
  // Status
  static const Color _live =
      Color(0xFFFF6A2B); // orange — live / open-now / warning
  static const Color _coral = Color(0xFFE0531C);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 12; // ✅ match Dashboard tiles
  static const double _gap = 12;

  // ✅ Route fallback
  static const String _fallbackProjectDetailRoute = 'ProjectDetailPage';

  // ✅ Dashboard fallback (adjust if your FF page name differs)
  static const String _fallbackDashboardRoute = 'DashboardPage';

  // ✅ Add Projects fallback (matches your FF page name)
  static const String _fallbackAddProjectsRoute = 'addProjectsPage';

  // =========================================================
  // ✅ LIVE MODE (wired)
  // =========================================================
  static const bool useLiveProjects = true;

  // =========================================================
  // ✅ Prevent “collapse flicker” when tapping a project
  // =========================================================
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedProjectDocs = [];
  bool _hasLoadedProjectsOnce = false;

  // ✅ Separate cache for archived list
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedArchivedDocs = [];
  bool _hasLoadedArchivedOnce = false;

  // =========================================================
  // ✅ UI Video link (How to upload project design)
  // Reads from Firestore: collection 'ui' -> field 'createNewProjectUrl'
  // =========================================================
  String? _cachedHowToUrl;
  bool _howToLoadedOnce = false;

  // ✅ NEW: preload the Future once so the header doesn’t “jump”
  late final Future<String?> _howToFuture;

  // ✅ NEW: reserve a fixed slot so the row width never changes
  static const double _howToSlotW = 108; // adjust if you want wider
  static const double _howToSlotH = 28;

  String get _projectParamName =>
      (widget.projectParamName ?? 'projectRef').trim().isEmpty
          ? 'projectRef'
          : widget.projectParamName!.trim();

  @override
  void initState() {
    super.initState();
    // Preload once (prevents rebuild-triggered “pop in” behaviour)
    _howToFuture = _fetchCreateProjectVideoUrl();
  }

  // =========================================================
  // ✅ TYPOGRAPHY (LOCKED — SAME CONTRACT AS DASHBOARD)
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
        fontWeight: FontWeight.w900,
        color: _ink,
      );

  TextStyle _metaStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _cardTitleStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
      );

  // -----------------------------
  // Navigation (slide in from right)
  // -----------------------------
  void _safeNavigate(String? route, {String? fallbackRoute}) {
    final target = (route ?? '').trim().isEmpty
        ? (fallbackRoute ?? '').trim()
        : route!.trim();

    if (target.isEmpty) return;

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

  void _goToAddProject() {
    _safeNavigate(
      widget.addProjectsRouteName,
      fallbackRoute: _fallbackAddProjectsRoute,
    );
  }

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

  void _goToProjectDetail(DocumentReference projectRef) {
    final target = (widget.projectDetailRouteName ?? '').trim().isNotEmpty
        ? widget.projectDetailRouteName!.trim()
        : _fallbackProjectDetailRoute;

    debugPrint(
        '➡️ Navigate to $target with $_projectParamName=${projectRef.path}');

    context.pushNamed(
      target,
      queryParameters: <String, dynamic>{
        _projectParamName: serializeParam(
          projectRef,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
      extra: <String, dynamic>{
        _projectParamName: projectRef,
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    );
  }

  Color _projectsColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).projectsColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  Color _tertiaryText(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).tertiaryText as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // ✅ Subby card shell (same feel as Dashboard tiles) — no shadows
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  // =========================================================
  // ✅ Add Project section (RESTORED)
  // =========================================================
  Widget _buildAddProjectSection({
    required FlutterFlowTheme theme,
    required Color accent,
  }) {
    return _subbyCardShell(
      theme: theme,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: accent.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Project',
                  style: _cardTitleStyle(theme).copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new workspace for your build.',
                  style:
                      _metaStyle(theme).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              _goToAddProject();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _spark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Create',
                style: theme.bodyMedium.override(
                  fontFamily: _bodyFont,
                  color: _sparkInk,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ✅ How-to video URL (from Firestore)
  // =========================================================
  Future<String?> _fetchCreateProjectVideoUrl() async {
    if (_howToLoadedOnce) return _cachedHowToUrl;

    try {
      final snap =
          await FirebaseFirestore.instance.collection('ui').limit(1).get();
      if (snap.docs.isEmpty) {
        _howToLoadedOnce = true;
        return _cachedHowToUrl;
      }

      final d = snap.docs.first.data();
      final v = d['createNewProjectUrl'];

      String? url;
      if (v is String) url = v.trim();

      if (url != null && url.isNotEmpty) {
        _cachedHowToUrl = url;
      }

      _howToLoadedOnce = true;
      return _cachedHowToUrl;
    } catch (e) {
      debugPrint('🔥 fetchCreateProjectVideoUrl failed: $e');
      _howToLoadedOnce = true;
      return _cachedHowToUrl;
    }
  }

  // ✅ Small inline help action (next to heading)
  // ✅ FIXED: reserves constant space so there is no “jump” on load.
  Widget _buildInlineHowToLink({
    required FlutterFlowTheme theme,
    required Color projectsColour,
    String label = 'How to upload project design',
  }) {
    return SizedBox(
      width: _howToSlotW,
      height: _howToSlotH,
      child: FutureBuilder<String?>(
        future: _howToFuture,
        builder: (context, snap) {
          final url = (snap.data ?? _cachedHowToUrl ?? '').trim();
          final hasUrl = url.isNotEmpty;

          return Align(
            alignment: Alignment.centerRight,
            child: IgnorePointer(
              ignoring: !hasUrl,
              child: AnimatedOpacity(
                opacity: hasUrl ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: InkWell(
                  onTap: hasUrl
                      ? () {
                          FocusScope.of(context).unfocus();
                          launchURL(url);
                        }
                      : null,
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 16,
                          color: projectsColour,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 78),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.override(
                              fontFamily: _bodyFont,
                              color: projectsColour,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // ✅ Archive / Restore / Delete actions
  // =========================================================

  Future<void> _archiveProject(DocumentReference projectRef) async {
    try {
      await projectRef.update({
        'archived': true,
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 Archive failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not archive project. Please try again.')),
      );
    }
  }

  Future<void> _restoreProject(DocumentReference projectRef) async {
    try {
      await projectRef.update({
        'archived': false,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
        'restoredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 Restore failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not restore project. Please try again.')),
      );
    }
  }

  /// ✅ HARD delete (removes from Archived list immediately)
  Future<void> _hardDeleteProject(DocumentReference projectRef) async {
    try {
      await projectRef.delete();
    } catch (e) {
      debugPrint('🔥 Hard delete failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not delete project. Please try again.')),
      );
    }
  }

  Future<void> _confirmAndHardDeleteProject(
      DocumentReference projectRef) async {
    final theme = FlutterFlowTheme.of(context);

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: _paper, // ✅ shell = primaryBackground
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _hairline.withOpacity(0.75)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12), // shell padding
              child: Container(
                decoration: BoxDecoration(
                  color: theme
                      .secondaryBackground, // ✅ inner = secondaryBackground
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _hairline.withOpacity(0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Delete project?',
                        style: theme.titleMedium.override(
                          fontFamily: _displayFont,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Body
                      Text(
                        'This will permanently remove the project and its data. This can’t be undone.',
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          color: _inkMute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Actions row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(ctx, false),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _paper,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _hairline.withOpacity(0.75),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: theme.bodyMedium.override(
                                    fontFamily: _bodyFont,
                                    color: _ink,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(ctx, true),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _coral.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _coral.withOpacity(0.35),
                                  ),
                                ),
                                child: Text(
                                  'Delete',
                                  style: theme.bodyMedium.override(
                                    fontFamily: _bodyFont,
                                    color: _coral,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (ok == true) {
      await _hardDeleteProject(projectRef);
    }
  }

  // =========================================================
  // ✅ PREMIUM module row
  // ✅ REQUESTED:
  // - Module "shell" background = primaryBackground
  // - Inner "tile" background = secondaryBackground
  // =========================================================
  Widget _actionModuleRow({
    required FlutterFlowTheme theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final borderColor =
        destructive ? _coral.withOpacity(0.25) : _hairline.withOpacity(0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          // ✅ OUTER module shell
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _paper, // ✅ requested
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Container(
            // ✅ INNER tile
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: _surface, // ✅ requested
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: destructive
                    ? _coral.withOpacity(0.18)
                    : _hairline.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon chip
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.22),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          color: destructive ? _coral : _ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          fontFamily: _bodyFont,
                          color: _inkMute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Icon(
                  Icons.chevron_right_rounded,
                  color: _inkMute,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ✅ PREMIUM bottom sheet (grabber + consistent spacing)
  // Active tile: Archive ONLY
  // Archived tile: Restore + Delete
  // =========================================================
  void _showProjectActions({
    required FlutterFlowTheme theme,
    required Color accent,
    required DocumentReference projectRef,
    required String projectName,
    required bool isArchived,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              decoration: BoxDecoration(
                color: _paper, // ✅ shell = primaryBackground
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hairline.withOpacity(0.75)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grabber
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: _hairline.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            projectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleMedium.override(
                              fontFamily: _displayFont,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              color: _inkMute,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (!isArchived)
                      _actionModuleRow(
                        theme: theme,
                        icon: Icons.archive_outlined,
                        iconColor: accent,
                        title: 'Archive project',
                        subtitle: 'Moves it out of Active Projects.',
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _archiveProject(projectRef);
                        },
                      ),

                    if (isArchived) ...[
                      _actionModuleRow(
                        theme: theme,
                        icon: Icons.unarchive_outlined,
                        iconColor: accent,
                        title: 'Restore project',
                        subtitle: 'Moves it back to Active Projects.',
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _restoreProject(projectRef);
                        },
                      ),
                      const SizedBox(height: 10),
                      _actionModuleRow(
                        theme: theme,
                        icon: Icons.delete_outline,
                        iconColor: _coral,
                        title: 'Delete project',
                        subtitle: 'Permanently removes the project.',
                        destructive: true,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _confirmAndHardDeleteProject(projectRef);
                        },
                      ),
                    ],

                    const SizedBox(height: 12),

                    _actionModuleRow(
                      theme: theme,
                      icon: Icons.close_rounded,
                      iconColor: _inkMute,
                      title: 'Cancel',
                      subtitle: 'Close this menu.',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ✅ Project Card
  // =========================================================
  Widget _projectCard({
    required FlutterFlowTheme theme,
    required Color accent,
    required DocumentReference projectRef,
    required bool isArchived,
    required String name,
    required String location,
    required String status,
    required String lastUpdated,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final tText = _tertiaryText(theme);
    final cardColor = isArchived ? accent.withOpacity(0.65) : accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                FocusScope.of(context).unfocus();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) onTap();
                });
              },
        borderRadius: BorderRadius.circular(_radius),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: _hairline.withOpacity(0.55),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusPill(theme: theme, accent: tText, text: status),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showProjectActions(
                        theme: theme,
                        accent: accent,
                        projectRef: projectRef,
                        projectName: name,
                        isArchived: isArchived,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: tText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tText.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(_radius),
                        border: Border.all(
                          color: tText.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, size: 22, color: tText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _cardTitleStyle(theme).copyWith(
                              color: tText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: tText),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _metaStyle(theme).copyWith(
                                    color: tText.withOpacity(0.90),
                                    fontWeight: FontWeight.w700,
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
                              color: tText.withOpacity(0.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: tText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill({
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
            color: accent.withOpacity(0.22),
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
                color: accent.withOpacity(0.90),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.override(
                  fontFamily: _bodyFont,
                  color: accent,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ✅ PROJECTS QUERIES (LIVE)
  // =========================================================
  Query<Map<String, dynamic>> _activeProjectsQuery() {
    final userRef = currentUserReference;
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: userRef)
        .where('archived', isEqualTo: false)
        .orderBy('updatedAt', descending: true);
  }

  Query<Map<String, dynamic>> _archivedProjectsQuery() {
    final userRef = currentUserReference;
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: userRef)
        .where('archived', isEqualTo: true)
        .orderBy('updatedAt', descending: true);
  }

  // =========================================================
  // ✅ UI: Active Projects list
  // =========================================================
  Widget _buildActiveProjectsList({
    required FlutterFlowTheme theme,
    required Color accent,
  }) {
    final demoProjects = <Map<String, dynamic>>[
      {
        'name': 'Winston Ridge Renovation',
        'location': 'Durbanville, Cape Town',
        'status': 'Active',
        'updated': 'today',
        'icon': Icons.home_work_outlined,
      },
      {
        'name': 'La Lucia Pool & Patio',
        'location': 'La Lucia, Durban',
        'status': 'Planning',
        'updated': '2 days ago',
        'icon': Icons.pool_outlined,
      },
      {
        'name': 'Fourways New Build',
        'location': 'Fourways, Johannesburg',
        'status': 'On Hold',
        'updated': '1 week ago',
        'icon': Icons.construction_outlined,
      },
    ];

    if (!useLiveProjects) {
      return Column(
        children: List.generate(demoProjects.length, (i) {
          final p = demoProjects[i];
          final dummyRef =
              FirebaseFirestore.instance.collection('projects').doc('demo_$i');
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == demoProjects.length - 1 ? 0 : _gap,
            ),
            child: _projectCard(
              theme: theme,
              accent: accent,
              projectRef: dummyRef,
              isArchived: false,
              name: p['name'] as String,
              location: p['location'] as String,
              status: p['status'] as String,
              lastUpdated: p['updated'] as String,
              icon: p['icon'] as IconData,
              onTap: () {},
            ),
          );
        }),
      );
    }

    if (currentUserReference == null) {
      return _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.lock_outline, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login required',
                    style: _cardTitleStyle(theme).copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please sign in to view your projects.',
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

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _activeProjectsQuery().snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('🔥 Projects stream error: ${snap.error}');
          return _subbyCardShell(
            theme: theme,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.error_outline, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Couldn’t load projects',
                        style: _cardTitleStyle(theme).copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is usually a Firestore index or rules issue. You can still create a project.',
                        style: _metaStyle(theme).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _goToAddProject,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child:
                        const Icon(Icons.add_rounded, color: _paper, size: 24),
                  ),
                ),
              ],
            ),
          );
        }

        final freshDocs = snap.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final isWaiting = snap.connectionState == ConnectionState.waiting;
        if (freshDocs.isNotEmpty || (!isWaiting && _hasLoadedProjectsOnce)) {
          _cachedProjectDocs = freshDocs;
          _hasLoadedProjectsOnce = true;
        }

        final docs = (freshDocs.isNotEmpty || !isWaiting)
            ? freshDocs
            : _cachedProjectDocs;

        if (!_hasLoadedProjectsOnce &&
            isWaiting &&
            (snap.data == null || freshDocs.isEmpty) &&
            docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _subbyCardShell(
              theme: theme,
              padding: const EdgeInsets.all(16),
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
                      'Loading your projects…',
                      style: _metaStyle(theme)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (docs.isEmpty) {
          return _subbyCardShell(
            theme: theme,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.folder_open_rounded, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No active projects yet',
                        style: _cardTitleStyle(theme).copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap “Create a project” to start your first build workspace.',
                        style: _metaStyle(theme)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _goToAddProject,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child:
                        const Icon(Icons.add_rounded, color: _paper, size: 24),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: List.generate(docs.length, (i) {
            final doc = docs[i];
            final d = doc.data();

            final name = (d['name'] ?? 'Untitled Project').toString();
            final status = (d['status'] ?? 'Active').toString();
            final province = (d['province'] ?? '').toString();
            final city = (d['city'] ?? '').toString();
            final location =
                [city, province].where((x) => x.trim().isNotEmpty).join(', ');

            final updatedAt = d['updatedAt'];
            final updatedLabel = (updatedAt is Timestamp)
                ? dateTimeFormat('relative', updatedAt.toDate())
                : 'recently';

            return Padding(
              padding: EdgeInsets.only(bottom: i == docs.length - 1 ? 0 : _gap),
              child: _projectCard(
                theme: theme,
                accent: accent,
                projectRef: doc.reference,
                isArchived: false,
                name: name,
                location: location.isEmpty ? 'South Africa' : location,
                status: status,
                lastUpdated: updatedLabel,
                icon: Icons.folder_open_rounded,
                onTap: () => _goToProjectDetail(doc.reference),
              ),
            );
          }),
        );
      },
    );
  }

  // =========================================================
  // ✅ UI: Archived Projects list
  // =========================================================
  Widget _buildArchivedProjectsList({
    required FlutterFlowTheme theme,
    required Color accent,
  }) {
    if (currentUserReference == null) {
      return _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hairline.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.lock_outline, color: _inkMute, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please sign in to view archived projects.',
                style: _metaStyle(theme).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _archivedProjectsQuery().snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('🔥 Archived projects stream error: ${snap.error}');
          return _subbyCardShell(
            theme: theme,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _hairline.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.error_outline, color: _inkMute, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Couldn’t load archived projects.',
                    style:
                        _metaStyle(theme).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }

        final freshDocs = snap.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final isWaiting = snap.connectionState == ConnectionState.waiting;
        if (freshDocs.isNotEmpty || (!isWaiting && _hasLoadedArchivedOnce)) {
          _cachedArchivedDocs = freshDocs;
          _hasLoadedArchivedOnce = true;
        }

        final docs = (freshDocs.isNotEmpty || !isWaiting)
            ? freshDocs
            : _cachedArchivedDocs;

        if (!_hasLoadedArchivedOnce && isWaiting && docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _subbyCardShell(
              theme: theme,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(_inkMute),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Loading archived projects…',
                      style: _metaStyle(theme)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: _hairline.withOpacity(0.9),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hairline.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.archive_outlined,
                    color: _inkMute,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No archived projects yet. Archive finished builds to keep your workspace clean.',
                    style:
                        _metaStyle(theme).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: List.generate(docs.length, (i) {
            final doc = docs[i];
            final d = doc.data();

            final name = (d['name'] ?? 'Untitled Project').toString();
            final status = (d['status'] ?? 'Archived').toString();
            final province = (d['province'] ?? '').toString();
            final city = (d['city'] ?? '').toString();
            final location =
                [city, province].where((x) => x.trim().isNotEmpty).join(', ');

            final updatedAt = d['updatedAt'];
            final updatedLabel = (updatedAt is Timestamp)
                ? dateTimeFormat('relative', updatedAt.toDate())
                : 'recently';

            return Padding(
              padding: EdgeInsets.only(bottom: i == docs.length - 1 ? 0 : _gap),
              child: _projectCard(
                theme: theme,
                accent: accent,
                projectRef: doc.reference,
                isArchived: true,
                name: name,
                location: location.isEmpty ? 'South Africa' : location,
                status: status,
                lastUpdated: updatedLabel,
                icon: Icons.archive_outlined,
                onTap: () => _goToProjectDetail(doc.reference),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final projectsColour = _projectsColor(theme);

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
                // ======================================================
                // Header
                // ======================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _backToDashboard,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _paper,
                          borderRadius: BorderRadius.circular(12),
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
                        color: projectsColour,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: const Icon(
                        Icons.folder_open_rounded,
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
                            'My Projects',
                            style: _appTitleStyle(theme).copyWith(
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Building plans, docs and progress.',
                            style: _appSubtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ======================================================
                // Active Projects
                // ======================================================
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Active Projects',
                        style: _sectionTitleStyle(theme),
                      ),
                    ),
                    _buildInlineHowToLink(
                      theme: theme,
                      projectsColour: projectsColour,
                      label: 'Tutorial',
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildActiveProjectsList(
                  theme: theme,
                  accent: projectsColour,
                ),

                // ======================================================
                // ✅ Add Project Section
                // ======================================================
                const SizedBox(height: 16),

                _buildAddProjectSection(
                  theme: theme,
                  accent: projectsColour,
                ),

                const SizedBox(height: 20),

                // ======================================================
                // Archived Projects
                // ======================================================
                Text(
                  'Archived Projects',
                  style: _sectionTitleStyle(theme),
                ),
                const SizedBox(height: 10),

                _buildArchivedProjectsList(
                  theme: theme,
                  accent: projectsColour,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
