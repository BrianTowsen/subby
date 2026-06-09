// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

class ToDoListHomePageView extends StatefulWidget {
  const ToDoListHomePageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Route name for returning to Dashboard page
    /// If left null, we fallback to "dashboardPage"
    this.dashboardRouteName,

    /// ✅ OPTIONAL: pass the active project reference directly
    this.projectRef,
  });

  final double? width;
  final double? height;

  final String? dashboardRouteName;

  /// ✅ Active project (optional)
  final DocumentReference? projectRef;

  @override
  State<ToDoListHomePageView> createState() => _ToDoListHomePageViewState();
}

class _ToDoListHomePageViewState extends State<ToDoListHomePageView> {
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
  static const double _gap = 12;

  // ✅ Route fallbacks
  static const String _fallbackDashboardRoute = 'dashboardPage';

  // ✅ Destination route (To Do page)
  // Update if your FF route name differs.
  static const String _fallbackToDoRoute = 'toDoListPage';

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
  Color _todoColour(FlutterFlowTheme theme) {
    // Try FF custom color "TodoColour" -> todoColour
    try {
      final c = (theme as dynamic).todoColour as Color?;
      return c ?? theme.primary;
    } catch (_) {
      return theme.primary;
    }
  }

  // -----------------------------
  // Typography
  // -----------------------------
  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
      );

  TextStyle _metaStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _cardTitleStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  // -----------------------------
  // Subby card shell
  // -----------------------------
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

  // ✅ outlined status chip (matches MyProjects/Timeline)
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
                style: theme.labelSmall.override(
                  fontFamily: theme.labelSmallFamily,
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

  // -----------------------------
  // ✅ Navigate to To Do page
  // -----------------------------
  Future<void> _openToDo() async {
    final ref = _activeProjectRef;
    if (ref == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveProjectPath, ref.path);

    context.pushNamed(
      _fallbackToDoRoute,
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
  // ✅ Active Project Card (MATCHES MyProjects/Timeline tile)
  // -----------------------------
  Widget _activeProjectCard(FlutterFlowTheme theme, Color accent) {
    // Loading state
    if (_resolvingProject) {
      return _subbyCardShell(
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
                'Loading your project…',
                style: _metaStyle(theme).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_activeProjectRef == null) {
      return _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: Icon(Icons.folder_open_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No project selected',
                    style: _cardTitleStyle(theme).copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a project in Projects to see it here.',
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

    // Live project tile
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
        final location =
            [city, province].where((x) => x.trim().isNotEmpty).join(', ');

        final updatedAt = data['updatedAt'];
        final updatedLabel = (updatedAt is Timestamp)
            ? dateTimeFormat('relative', updatedAt.toDate())
            : 'recently';

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_radius),
          child: InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _openToDo();
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
                  color: theme.primaryBackground,
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
                        child: const Icon(Icons.task_alt,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (status.isNotEmpty)
                                _statusPillOutlined(
                                  theme: theme,
                                  accent: accent,
                                  text: status,
                                ),
                              if (status.isNotEmpty) const SizedBox(height: 6),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _cardTitleStyle(theme).copyWith(
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 16, color: theme.secondaryText),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      location.isEmpty
                                          ? 'South Africa'
                                          : location,
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
                                'Last updated $updatedLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _metaStyle(theme).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: theme.secondaryText),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final todoColour = _todoColour(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: theme.primaryBackground,
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
                        color: todoColour,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: const Icon(
                        Icons.task_alt,
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
                            'To Do List',
                            style: _appTitleStyle(theme).copyWith(
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tasks and assignments for your build.',
                            style: _appSubtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Only projects on this page
                Text(
                  'Projects added',
                  style: _sectionTitleStyle(theme).copyWith(
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 10),

                _activeProjectCard(theme, todoColour),

                // ✅ removed: bottom message tile
              ],
            ),
          ),
        ),
      ),
    );
  }
}
