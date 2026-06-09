// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectDetailPageView extends StatefulWidget {
  const ProjectDetailPageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Project reference (used to load project + filter project-specific data)
    this.projectRef,

    /// ✅ Routes (project-specific modules)
    this.editProjectRouteName,
    this.timelineRouteName,
    this.projectCostRouteName,
    this.getQuotesRouteName,
    this.snagListRouteName,

    /// ✅ NEW: Listing detail route (tap on added listing)
    this.listingDetailRouteName,

    /// ✅ NEW: Document upload route (tap Upload Document)
    this.documentUploadRouteName,

    /// ✅ Optional: Document detail route (tap document row if no URL)
    this.documentDetailRouteName,

    /// ✅ Optional param name for passing the project ref to the other pages
    /// Default: "projectRef"
    this.projectParamName,

    /// ✅ NEW: Optional param name for passing the listing ref to Listing Detail
    /// Default: "listingRef"
    this.listingParamName,

    /// ✅ NEW: Optional param name for passing the document ref to Document Detail
    /// Default: "documentRef"
    this.documentParamName,
  });

  final double? width;
  final double? height;

  final DocumentReference? projectRef;

  final String? editProjectRouteName;
  final String? timelineRouteName;
  final String? projectCostRouteName;
  final String? getQuotesRouteName;
  final String? snagListRouteName;

  final String? listingDetailRouteName;

  final String? documentUploadRouteName;
  final String? documentDetailRouteName;

  final String? projectParamName;
  final String? listingParamName;
  final String? documentParamName;

  @override
  State<ProjectDetailPageView> createState() => _ProjectDetailPageViewState();
}

class _ProjectDetailPageViewState extends State<ProjectDetailPageView> {
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
  static const double _gap = 12;
  static const double _pmGridTileH = 165; // ✅ SAME as DashboardPageView

  // Local state (stable)
  Map<String, dynamic> _projectData = <String, dynamic>{};
  bool _projectLoadedOnce = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docRows = [];
  bool _docsLoadedOnce = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _listingRows = [];
  bool _listingsLoadedOnce = false;

  // Errors (optional display)
  Object? _projectErr;
  Object? _docsErr;
  Object? _listingsErr;

  // Subscriptions
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projectSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _docsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _listingsSub;

  // ✅ navigation lock (NO setState)
  bool _isNavigating = false;

  // Fallback route names (update if your FF routes differ)
  static const String _fallbackEditRoute = 'editProjectPage';
  static const String _fallbackTimelineRoute = 'timelinePage';
  static const String _fallbackCostRoute = 'projectCostPage';
  static const String _fallbackQuotesRoute = 'quotesPage';
  static const String _fallbackSnagRoute = 'snagListPage';
  static const String _fallbackListingDetailRoute = 'listingDetailPage';

  // ✅ NEW fallbacks for documents
  static const String _fallbackDocUploadRoute = 'projectDocumentUploadPage';
  static const String _fallbackDocDetailRoute = 'projectDocumentDetailPage';

  String get _projectParamName =>
      (widget.projectParamName ?? 'projectRef').trim().isEmpty
          ? 'projectRef'
          : widget.projectParamName!.trim();

  String get _listingParamName =>
      (widget.listingParamName ?? 'listingRef').trim().isEmpty
          ? 'listingRef'
          : widget.listingParamName!.trim();

  String get _documentParamName =>
      (widget.documentParamName ?? 'documentRef').trim().isEmpty
          ? 'documentRef'
          : widget.documentParamName!.trim();

  @override
  void initState() {
    super.initState();
    _startSubscriptions();
  }

  @override
  void didUpdateWidget(covariant ProjectDetailPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRef?.path != widget.projectRef?.path) {
      _stopSubscriptions();
      _resetLocalState();
      _startSubscriptions();
    }
  }

  @override
  void dispose() {
    _stopSubscriptions();
    super.dispose();
  }

  void _resetLocalState() {
    _projectData = <String, dynamic>{};
    _projectLoadedOnce = false;
    _docRows = [];
    _docsLoadedOnce = false;
    _listingRows = [];
    _listingsLoadedOnce = false;
    _projectErr = null;
    _docsErr = null;
    _listingsErr = null;
  }

  void _stopSubscriptions() {
    _projectSub?.cancel();
    _docsSub?.cancel();
    _listingsSub?.cancel();
    _projectSub = null;
    _docsSub = null;
    _listingsSub = null;
  }

  void _startSubscriptions() {
    final projectRef = widget.projectRef;
    if (projectRef == null) return;

    // Project doc
    _projectSub = projectRef
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
          toFirestore: (m, _) => m,
        )
        .snapshots()
        .listen((snap) {
      _projectErr = null;
      final data = snap.data();
      if (data != null && data.isNotEmpty) {
        _projectData = data;
        _projectLoadedOnce = true;
      }
      if (!_isNavigating && mounted) setState(() {});
    }, onError: (e) {
      _projectErr = e;
      if (!_isNavigating && mounted) setState(() {});
    });

    // Documents query
    _docsSub = FirebaseFirestore.instance
        .collection('project_documents')
        .where('projectRef', isEqualTo: projectRef)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _docsErr = null;
      _docRows = snap.docs;
      _docsLoadedOnce = true;
      if (!_isNavigating && mounted) setState(() {});
    }, onError: (e) {
      _docsErr = e;
      if (!_isNavigating && mounted) setState(() {});
    });

    // Listings query
    _listingsSub = FirebaseFirestore.instance
        .collection('project_listings')
        .where('projectRef', isEqualTo: projectRef)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _listingsErr = null;
      _listingRows = snap.docs;
      _listingsLoadedOnce = true;
      if (!_isNavigating && mounted) setState(() {});
    }, onError: (e) {
      _listingsErr = e;
      if (!_isNavigating && mounted) setState(() {});
    });
  }

  // -----------------------------
  // Navigation (immediate push)
  // -----------------------------
  void _safeNavigate(String? route, {String? fallbackRoute}) {
    if (_isNavigating) return;

    final target = (route ?? '').trim().isEmpty
        ? (fallbackRoute ?? '').trim()
        : route!.trim();
    if (target.isEmpty) return;

    final projectRef = widget.projectRef;

    _isNavigating = true;
    FocusScope.of(context).unfocus();

    context.pushNamed(
      target,
      queryParameters: (projectRef == null)
          ? <String, dynamic>{}
          : <String, dynamic>{
              _projectParamName: serializeParam(
                projectRef,
                ParamType.DocumentReference,
              ),
            }.withoutNulls,
      extra: <String, dynamic>{
        if (projectRef != null) _projectParamName: projectRef,
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    ).whenComplete(() {
      _isNavigating = false;
    });
  }

  void _navigateToListing(DocumentReference listingRef) {
    if (_isNavigating) return;

    final target = (widget.listingDetailRouteName ?? '').trim().isEmpty
        ? _fallbackListingDetailRoute
        : widget.listingDetailRouteName!.trim();

    _isNavigating = true;
    FocusScope.of(context).unfocus();

    context.pushNamed(
      target,
      queryParameters: <String, dynamic>{
        _listingParamName: serializeParam(
          listingRef,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
      extra: <String, dynamic>{
        _listingParamName: listingRef,
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    ).whenComplete(() {
      _isNavigating = false;
    });
  }

  // ✅ NEW: navigate to upload document page
  void _navigateToUploadDocument() {
    if (_isNavigating) return;

    final target = (widget.documentUploadRouteName ?? '').trim().isEmpty
        ? _fallbackDocUploadRoute
        : widget.documentUploadRouteName!.trim();

    final projectRef = widget.projectRef;
    if (projectRef == null) return;

    _isNavigating = true;
    FocusScope.of(context).unfocus();

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
    ).whenComplete(() {
      _isNavigating = false;
    });
  }

  // ✅ NEW: open document if URL exists, otherwise optional detail page
  void _openDocumentRow(
    QueryDocumentSnapshot<Map<String, dynamic>> docSnap,
  ) {
    final d = docSnap.data();

    final url = (d['url'] ??
            d['fileUrl'] ??
            d['file_url'] ??
            d['downloadUrl'] ??
            d['download_url'])
        ?.toString()
        .trim();

    if (url != null && url.isNotEmpty) {
      launchURL(url);
      return;
    }

    final target = (widget.documentDetailRouteName ?? '').trim().isEmpty
        ? _fallbackDocDetailRoute
        : widget.documentDetailRouteName!.trim();

    // If you don't have a detail page, just do nothing.
    if (target.trim().isEmpty) return;

    if (_isNavigating) return;
    _isNavigating = true;
    FocusScope.of(context).unfocus();

    final ref = docSnap.reference;

    context.pushNamed(
      target,
      queryParameters: <String, dynamic>{
        _documentParamName: serializeParam(
          ref,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
      extra: <String, dynamic>{
        _documentParamName: ref,
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
          duration: Duration(milliseconds: 260),
        ),
      },
    ).whenComplete(() {
      _isNavigating = false;
    });
  }

  // ✅ read listingRef from project_listings row
  DocumentReference? _extractListingRef(Map<String, dynamic> d) {
    final raw = d['listingRef'] ?? d['listing_ref'] ?? d['listing'];
    if (raw is DocumentReference) return raw;

    if (raw is String && raw.trim().isNotEmpty) {
      final path = raw.trim();
      try {
        return FirebaseFirestore.instance.doc(path);
      } catch (_) {
        return null;
      }
    }

    final id = d['listingId'] ?? d['listing_id'];
    if (id is String && id.trim().isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('subby_listings')
          .doc(id.trim());
    }

    return null;
  }

  // =========================================================
  // ✅ Remove listing (module-style sheet like MyProjectsHomePageView)
  // =========================================================
  Future<void> _removeProjectListingDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Listing removed from project.')),
        );
    } catch (e) {
      debugPrint('🔥 Failed removing project_listings doc: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not remove listing.')),
        );
    }
  }

  Widget _actionModuleRow({
    required FlutterFlowTheme theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final borderColor = destructive
        ? theme.error.withOpacity(0.25)
        : theme.alternate.withOpacity(0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryBackground, // ✅ shell = primaryBackground
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: theme.secondaryBackground, // ✅ inner = secondaryBackground
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: destructive
                    ? theme.error.withOpacity(0.18)
                    : theme.alternate.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: iconColor.withOpacity(0.22),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          fontFamily: theme.bodyMediumFamily,
                          color: destructive ? theme.error : theme.primaryText,
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
                          fontFamily: theme.bodySmallFamily,
                          color: theme.secondaryText,
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
                  color: theme.secondaryText,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveListingSheet({
    required FlutterFlowTheme theme,
    required Color accent,
    required String listingTitle,
    required DocumentReference<Map<String, dynamic>> projectListingDocRef,
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
                color: theme.primaryBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.alternate.withOpacity(0.75)),
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
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: theme.alternate.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listingTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleMedium.override(
                              fontFamily: theme.titleMediumFamily,
                              fontWeight: FontWeight.w900,
                              color: theme.primaryText,
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
                              color: theme.secondaryText,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _actionModuleRow(
                      theme: theme,
                      icon: Icons.delete_outline_rounded,
                      iconColor: theme.error,
                      title: 'Remove listing',
                      subtitle:
                          'Removes it from this project (does not delete it).',
                      destructive: true,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _removeProjectListingDoc(projectListingDocRef);
                      },
                    ),
                    const SizedBox(height: 10),
                    _actionModuleRow(
                      theme: theme,
                      icon: Icons.close_rounded,
                      iconColor: theme.secondaryText,
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

  // -----------------------------
  // Theme helpers (TYPOGRAPHY LOCKED)
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
        fontWeight: FontWeight.w900,
        color: t.primaryText,
      );

  Color _projectsColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).projectsColour as Color?;
      return c ?? theme.primary;
    } catch (_) {
      return theme.primary;
    }
  }

  Color _tertiaryText(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).tertiaryText as Color?;
      return c ?? theme.primaryText;
    } catch (_) {
      return theme.primaryText;
    }
  }

  Color _themeColorOr(FlutterFlowTheme theme, String field, Color fallback) {
    try {
      final dyn = theme as dynamic;
      switch (field) {
        // ✅ REMOVED: todoColour usage (tile removed)
        // case 'todoColour':
        //   return (dyn.todoColour as Color?) ?? fallback;
        case 'timelineColour':
          return (dyn.timelineColour as Color?) ?? fallback;
        case 'projectCostColour':
          return (dyn.projectCostColour as Color?) ?? fallback;
        case 'getQuotesColour':
          return (dyn.getQuotesColour as Color?) ?? fallback;
        case 'snagListColour':
          return (dyn.snagListColour as Color?) ?? fallback;
        default:
          return fallback;
      }
    } catch (_) {
      return fallback;
    }
  }

  // -----------------------------
  // UI helpers
  // -----------------------------
  Widget _cardShell({
    required FlutterFlowTheme theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    Color? colorOverride,
    Color? borderColorOverride,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorOverride ?? theme.primaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: (borderColorOverride ?? theme.alternate).withOpacity(0.9),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _sectionTitle(FlutterFlowTheme theme, String text) {
    return Text(text, style: _sectionTitleStyle(theme));
  }

  Widget _tapCard({
    required Widget child,
    required VoidCallback? onTap,
    BorderRadius? radius,
  }) {
    final r = radius ?? BorderRadius.circular(_radius);
    return Material(
      color: Colors.transparent,
      borderRadius: r,
      child: InkWell(
        onTap: onTap,
        borderRadius: r,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: child,
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
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleGridTile({
    required FlutterFlowTheme theme,
    required Color bg,
    required Color content,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? count,
  }) {
    final fg = theme.tertiaryText;
    final overlay = Colors.white.withOpacity(0.18);
    final overlayBorder = Colors.white.withOpacity(0.22);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: overlay,
                        borderRadius: BorderRadius.circular(_radius),
                        border: Border.all(color: overlayBorder),
                      ),
                      child: Icon(icon, size: 22, color: fg),
                    ),
                    const Spacer(),
                    if ((count ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: overlay,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: overlayBorder),
                        ),
                        child: Text(
                          '$count',
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: fg,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleLarge.override(
                    fontFamily: theme.titleLargeFamily,
                    color: fg,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: fg.withOpacity(0.90),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.chevron_right_rounded, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingCard(FlutterFlowTheme theme, Color accent, String label) {
    return _cardShell(
      theme: theme,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(
      FlutterFlowTheme theme, Color accent, String title, String subtitle) {
    return _cardShell(
      theme: theme,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Icon(Icons.error_outline, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentRow({
    required FlutterFlowTheme theme,
    required Color accent,
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: theme.alternate.withOpacity(0.9)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.primaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelSmall.override(
                        fontFamily: theme.labelSmallFamily,
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded,
                  size: 18, color: theme.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ UPDATED: chevron removed, bin takes its place (right edge)
  Widget _listingRow({
    required FlutterFlowTheme theme,
    required Color accent,
    required String title,
    required String subtitle,
    required String ratingText,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: theme.alternate.withOpacity(0.9)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: const Icon(Icons.storefront_outlined,
                    size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.primaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelSmall.override(
                        fontFamily: theme.labelSmallFamily,
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ratingText.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            ratingText,
                            style: theme.labelSmall.override(
                              fontFamily: theme.labelSmallFamily,
                              color: theme.secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: theme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadDocButton(FlutterFlowTheme theme, Color accent) {
    return _tapCard(
      onTap: _navigateToUploadDocument,
      radius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file_rounded,
                size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Upload',
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final projectsAccent = _projectsColor(theme);
    final tertiaryText = _tertiaryText(theme);

    // ✅ REMOVED: todoAccent (tile removed)
    // final todoAccent = _themeColorOr(theme, 'todoColour', theme.primary);
    final timelineAccent =
        _themeColorOr(theme, 'timelineColour', theme.primary);
    final costAccent = _themeColorOr(theme, 'projectCostColour', theme.primary);
    final quotesAccent = _themeColorOr(theme, 'getQuotesColour', theme.primary);
    final snagAccent = _themeColorOr(theme, 'snagListColour', theme.primary);

    if (widget.projectRef == null) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: theme.primaryBackground,
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
            child: _cardShell(
              theme: theme,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.error,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: const Icon(Icons.error_outline,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No project selected. Please open this page from My Projects.',
                      style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_projectErr != null) {
      debugPrint('🔥 Project stream error: $_projectErr');
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: theme.primaryBackground,
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
            child: _errorCard(
              theme,
              projectsAccent,
              'Couldn’t load project',
              'This is usually Firestore rules or a missing index.',
            ),
          ),
        ),
      );
    }

    if (!_projectLoadedOnce && _projectData.isEmpty) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: theme.primaryBackground,
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
            child: _loadingCard(theme, projectsAccent, 'Loading project…'),
          ),
        ),
      );
    }

    final projData = _projectData;

    final projectName = (projData['name'] ?? 'Project').toString();
    final projectStatus = (projData['status'] ?? 'Active').toString();

    final city = (projData['city'] ?? '').toString();
    final province = (projData['province'] ?? '').toString();
    final address = (projData['address'] ?? '').toString();

    final locationBits = <String>[
      if (address.trim().isNotEmpty) address.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (province.trim().isNotEmpty) province.trim(),
    ];
    final projectAddress =
        locationBits.isEmpty ? 'South Africa' : locationBits.join(', ');

    final startTs = projData['startDate'];
    final endTs = projData['endDate'];

    final startLabel = (startTs is Timestamp)
        ? dateTimeFormat('d MMM y', startTs.toDate())
        : '—';
    final endLabel =
        (endTs is Timestamp) ? dateTimeFormat('d MMM y', endTs.toDate()) : '—';

    final projectDates = 'Start: $startLabel • Target: $endLabel';
    final projectNotes = (projData['notes'] ?? '').toString().trim().isEmpty
        ? 'No notes yet.'
        : (projData['notes'] ?? '').toString();

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
                // ============================================================
                // 1) TOP BAR
                // ============================================================
                Row(
                  children: [
                    _tapCard(
                      onTap: () => context.safePop(),
                      radius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: theme.alternate.withOpacity(0.9)),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 22, color: theme.primaryText),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project',
                            style: _appTitleStyle(theme).copyWith(
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Workspace overview and modules.',
                            style: _appSubtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                    _tapCard(
                      onTap: () => _safeNavigate(
                        widget.editProjectRouteName,
                        fallbackRoute: _fallbackEditRoute,
                      ),
                      radius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: projectsAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: theme.bodySmall.override(
                                fontFamily: theme.bodySmallFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ============================================================
                // 2) PROJECT DETAIL CARD
                // ============================================================
                _cardShell(
                  theme: theme,
                  padding: const EdgeInsets.all(16),
                  colorOverride: projectsAccent,
                  borderColorOverride: theme.alternate.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tertiaryText.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(_radius),
                              border: Border.all(
                                color: tertiaryText.withOpacity(0.18),
                                width: 1,
                              ),
                            ),
                            child: Icon(Icons.folder_open_rounded,
                                size: 22, color: tertiaryText),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statusPill(
                                  theme: theme,
                                  accent: tertiaryText,
                                  text: projectStatus,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  projectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.titleLarge.override(
                                    fontFamily: theme.titleLargeFamily,
                                    color: tertiaryText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: tertiaryText),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              projectAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.override(
                                fontFamily: theme.bodySmallFamily,
                                color: tertiaryText.withOpacity(0.92),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        projectDates,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall.override(
                          fontFamily: theme.labelSmallFamily,
                          color: tertiaryText.withOpacity(0.92),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        projectNotes,
                        style: theme.bodySmall.override(
                          fontFamily: theme.bodySmallFamily,
                          color: tertiaryText.withOpacity(0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ============================================================
                // 3) PROJECT MODULE LINKS (grid)  ✅ TODO REMOVED
                // ============================================================
                _sectionTitle(theme, 'Project Modules'),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final cols = w >= 680 ? 3 : 2;
                    const spacing = 12.0;
                    final tileW = (w - (spacing * (cols - 1))) / cols;
                    final tileH = _pmGridTileH;

                    final tiles = <Widget>[
                      // ✅ REMOVED: Todo List tile
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: _moduleGridTile(
                          theme: theme,
                          bg: timelineAccent,
                          content: tertiaryText,
                          icon: Icons.timeline_rounded,
                          title: 'Timeline',
                          subtitle: 'Project schedule',
                          onTap: () => _safeNavigate(
                            widget.timelineRouteName,
                            fallbackRoute: _fallbackTimelineRoute,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: _moduleGridTile(
                          theme: theme,
                          bg: costAccent,
                          content: tertiaryText,
                          icon: Icons.calculate_outlined,
                          title: 'Project Cost',
                          subtitle: 'Budget & tracking',
                          onTap: () => _safeNavigate(
                            widget.projectCostRouteName,
                            fallbackRoute: _fallbackCostRoute,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: _moduleGridTile(
                          theme: theme,
                          bg: quotesAccent,
                          content: tertiaryText,
                          icon: Icons.request_quote_outlined,
                          title: 'Get Quotes',
                          subtitle: 'Request pricing',
                          onTap: () => _safeNavigate(
                            widget.getQuotesRouteName,
                            fallbackRoute: _fallbackQuotesRoute,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: tileW,
                        height: tileH,
                        child: _moduleGridTile(
                          theme: theme,
                          bg: snagAccent,
                          content: tertiaryText,
                          icon: Icons.fact_check_outlined,
                          title: 'Snag List',
                          subtitle: 'Punch & defects',
                          onTap: () => _safeNavigate(
                            widget.snagListRouteName,
                            fallbackRoute: _fallbackSnagRoute,
                          ),
                        ),
                      ),
                    ];

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: tiles,
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ============================================================
                // 4) DOCUMENTS  ✅ UPDATED (Upload button + tap opens URL)
                // ============================================================
                Row(
                  children: [
                    Expanded(child: _sectionTitle(theme, 'Documents')),
                    _uploadDocButton(theme, projectsAccent),
                  ],
                ),
                const SizedBox(height: 10),

                if (_docsErr != null)
                  _errorCard(
                    theme,
                    projectsAccent,
                    'Couldn’t load documents',
                    'This is usually a missing Firestore index or rules issue.',
                  )
                else if (!_docsLoadedOnce)
                  _loadingCard(theme, projectsAccent, 'Loading documents…')
                else if (_docRows.isEmpty)
                  _cardShell(
                    theme: theme,
                    colorOverride: theme.secondaryBackground,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: projectsAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                          child: Icon(Icons.folder_open_rounded,
                              color: projectsAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No documents yet.',
                                style: theme.bodyMedium.override(
                                  fontFamily: theme.bodyMediumFamily,
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Upload PDFs, images, and files linked to this project.',
                                style: theme.bodySmall.override(
                                  fontFamily: theme.bodySmallFamily,
                                  color: theme.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _tapCard(
                          onTap: _navigateToUploadDocument,
                          radius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: projectsAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: List.generate(_docRows.length, (i) {
                      final docSnap = _docRows[i];
                      final d = docSnap.data();
                      final title = (d['title'] ?? d['name'] ?? 'Document')
                          .toString()
                          .trim();
                      final type = (d['type'] ?? d['fileType'] ?? 'File')
                          .toString()
                          .trim();

                      final updatedAt = d['updatedAt'] ?? d['createdAt'];
                      final when = (updatedAt is Timestamp)
                          ? dateTimeFormat('relative', updatedAt.toDate())
                          : 'recently';

                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: i == _docRows.length - 1 ? 0 : _gap),
                        child: _documentRow(
                          theme: theme,
                          accent: projectsAccent,
                          title: title.isEmpty ? 'Document' : title,
                          subtitle: '$type • Updated $when',
                          icon: Icons.picture_as_pdf_rounded,
                          onTap: () => _openDocumentRow(docSnap),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 18),

                // ============================================================
                // 5) LISTINGS
                // ============================================================
                _sectionTitle(theme, 'Listings Added to Project'),
                const SizedBox(height: 10),

                if (_listingsErr != null)
                  _errorCard(
                    theme,
                    projectsAccent,
                    'Couldn’t load listings',
                    'This is usually a missing Firestore index or rules issue.',
                  )
                else if (!_listingsLoadedOnce)
                  _loadingCard(theme, projectsAccent, 'Loading listings…')
                else if (_listingRows.isEmpty)
                  _cardShell(
                    theme: theme,
                    colorOverride: theme.secondaryBackground,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: projectsAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                          child: Icon(Icons.storefront_outlined,
                              color: projectsAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No listings added yet.',
                            style: theme.bodyMedium.override(
                              fontFamily: theme.bodyMediumFamily,
                              color: theme.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: List.generate(_listingRows.length, (i) {
                      final rowDoc = _listingRows[i];
                      final d = rowDoc.data();
                      final title = (d['title'] ?? 'Listing').toString();

                      // ✅ FIX: support BOTH keys (subtitle + legacy subTitle)
                      final subtitle =
                          (d['subtitle'] ?? d['subTitle'] ?? '').toString();

                      final rating = (d['ratingText'] ?? '').toString();

                      final listingRef = _extractListingRef(d);

                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: i == _listingRows.length - 1 ? 0 : _gap),
                        child: _listingRow(
                          theme: theme,
                          accent: projectsAccent,
                          title: title,
                          subtitle: subtitle.trim().isNotEmpty ? subtitle : '—',
                          ratingText: rating,
                          onTap: () {
                            if (listingRef == null) {
                              debugPrint(
                                  '⚠️ Missing listingRef. project_listings doc: ${rowDoc.id} data=$d');
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'This listing link is missing. Please re-add the listing.',
                                      style: theme.bodySmall.override(
                                        fontFamily: theme.bodySmallFamily,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              return;
                            }
                            _navigateToListing(listingRef);
                          },
                          onDelete: () {
                            FocusScope.of(context).unfocus();
                            _showRemoveListingSheet(
                              theme: theme,
                              accent: projectsAccent,
                              listingTitle: title,
                              projectListingDocRef: rowDoc.reference,
                            );
                          },
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
