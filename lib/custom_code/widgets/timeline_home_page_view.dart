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

class TimelineHomePageView extends StatefulWidget {
  const TimelineHomePageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Route name for a Timeline Detail page (optional)
    /// Default: "TimelineDetailPage"
    this.timelineDetailRouteName,

    /// ✅ Route name for returning to Dashboard page
    /// If left null, we fallback to "dashboardPage"
    this.dashboardRouteName,

    /// ✅ OPTIONAL: if you pass a projectRef, we can pre-highlight it later
    this.projectRef,
  });

  final double? width;
  final double? height;

  final String? timelineDetailRouteName;

  /// ✅ Back-to-dashboard route
  final String? dashboardRouteName;

  /// ✅ Active project (optional)
  final DocumentReference? projectRef;

  @override
  State<TimelineHomePageView> createState() => _TimelineHomePageViewState();
}

class _TimelineHomePageViewState extends State<TimelineHomePageView> {
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16; // ✅ match Dashboard tiles
  static const double _gap = 12;

  // ✅ Route fallbacks
  static const String _fallbackTimelineDetailRoute = 'TimelineDetailPage';
  static const String _fallbackDashboardRoute = 'dashboardPage';

  // ✅ Param name expected by your Timeline detail page
  static const String _kProjectRefParamName = 'projectRef';

  // =========================================================
  // ✅ TYPOGRAPHY (CONSISTENT: token + explicit family, color only)
  // =========================================================
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
  // Navigation helpers
  // -----------------------------
  void _safeNavigateToDetail(DocumentReference projectRef) {
    final target = (widget.timelineDetailRouteName ?? '').trim().isNotEmpty
        ? widget.timelineDetailRouteName!.trim()
        : _fallbackTimelineDetailRoute;

    context.pushNamed(
      target,
      queryParameters: {
        _kProjectRefParamName: serializeParam(
          projectRef,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
      extra: {
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    );
  }

  /// ✅ Back to Dashboard with "uncover" effect:
  /// - POP if possible (true reveal).
  /// - Otherwise, navigate to dashboard with leftToRight.
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
  Color _timelineColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).timelineColour as Color?;
      return c ?? theme.primary;
    } catch (_) {
      return theme.primary;
    }
  }

  // ✅ Subby card shell (same feel as Dashboard tiles)
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

  // ✅ compact status chip (outlined) — matches MyProjects
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
  // UI: Empty state (no projects)
  // -----------------------------
  Widget _buildEmptyProjects(FlutterFlowTheme theme, Color accent) {
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
            child: Icon(Icons.folder_off_rounded,
                color: theme.secondaryText, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No projects yet',
                  style: _cardTitleStyle(theme).copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a project in My Projects to view your timeline here.',
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

  // -----------------------------
  // ✅ Project tile/card (MATCHES MyProjects design)
  // -----------------------------
  Widget _projectCard({
    required FlutterFlowTheme theme,
    required Color accent,
    required DocumentReference projectRef,
    required String name,
    required String location,
    required String status,
    required String lastUpdated,
    IconData icon = Icons.folder_open_rounded,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _safeNavigateToDetail(projectRef);
          });
        },
        borderRadius: BorderRadius.circular(_radius),
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
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status.trim().isNotEmpty)
                            _statusPill(
                                theme: theme, accent: accent, text: status),
                          if (status.trim().isNotEmpty)
                            const SizedBox(height: 6),
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
                        ],
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: theme.secondaryText),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // Firestore query builders
  // -----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _projectsStreamOrdered(
      DocumentReference ownerRef) {
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: ownerRef)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _projectsStreamFallback(
      DocumentReference ownerRef) {
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: ownerRef)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final timelineColour = _timelineColor(theme);
    final ownerRef = currentUserReference;

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
                        color: timelineColour,
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
                            'Timeline',
                            style: _appTitleStyle(theme).copyWith(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a project to view your build timeline.',
                            style: _appSubtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Heading
                Text(
                  'Projects added',
                  style: _sectionTitleStyle(theme).copyWith(
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 10),

                // Projects list
                if (ownerRef == null)
                  _buildEmptyProjects(theme, timelineColour)
                else
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _projectsStreamOrdered(ownerRef),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: _projectsStreamFallback(ownerRef),
                          builder: (context, snap2) {
                            if (!snap2.hasData) {
                              return _subbyCardShell(
                                theme: theme,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: timelineColour,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Loading projects…',
                                      style: _cardTitleStyle(theme).copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final docs = snap2.data!.docs;
                            if (docs.isEmpty) {
                              return _buildEmptyProjects(theme, timelineColour);
                            }

                            return Column(
                              children: List.generate(docs.length, (i) {
                                final doc = docs[i];
                                final d = doc.data();

                                final name = (d['name'] ??
                                        d['projectName'] ??
                                        d['title'] ??
                                        'Project')
                                    .toString();

                                final status =
                                    (d['status'] ?? 'Active').toString().trim();

                                final province =
                                    (d['province'] ?? '').toString().trim();
                                final city =
                                    (d['city'] ?? '').toString().trim();
                                final location = [city, province]
                                    .where((x) => x.isNotEmpty)
                                    .join(', ');

                                final updatedAt = d['updatedAt'];
                                final updatedLabel = (updatedAt is Timestamp)
                                    ? dateTimeFormat(
                                        'relative', updatedAt.toDate())
                                    : 'recently';

                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: i == docs.length - 1 ? 0 : _gap),
                                  child: _projectCard(
                                    theme: theme,
                                    accent: timelineColour,
                                    projectRef: doc.reference,
                                    name: name,
                                    location: location.isEmpty
                                        ? 'South Africa'
                                        : location,
                                    status: status,
                                    lastUpdated: updatedLabel,
                                    icon: Icons.home_work_outlined,
                                  ),
                                );
                              }),
                            );
                          },
                        );
                      }

                      if (!snap.hasData) {
                        return _subbyCardShell(
                          theme: theme,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: timelineColour,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading projects…',
                                style: _cardTitleStyle(theme).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.primaryText,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final docs = snap.data!.docs;
                      if (docs.isEmpty) {
                        return _buildEmptyProjects(theme, timelineColour);
                      }

                      return Column(
                        children: List.generate(docs.length, (i) {
                          final doc = docs[i];
                          final d = doc.data();

                          final name = (d['name'] ??
                                  d['projectName'] ??
                                  d['title'] ??
                                  'Project')
                              .toString();

                          final status =
                              (d['status'] ?? 'Active').toString().trim();

                          final province =
                              (d['province'] ?? '').toString().trim();
                          final city = (d['city'] ?? '').toString().trim();
                          final location = [city, province]
                              .where((x) => x.isNotEmpty)
                              .join(', ');

                          final updatedAt = d['updatedAt'];
                          final updatedLabel = (updatedAt is Timestamp)
                              ? dateTimeFormat('relative', updatedAt.toDate())
                              : 'recently';

                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: i == docs.length - 1 ? 0 : _gap),
                            child: _projectCard(
                              theme: theme,
                              accent: timelineColour,
                              projectRef: doc.reference,
                              name: name,
                              location:
                                  location.isEmpty ? 'South Africa' : location,
                              status: status,
                              lastUpdated: updatedLabel,
                              icon: Icons.home_work_outlined,
                            ),
                          );
                        }),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
