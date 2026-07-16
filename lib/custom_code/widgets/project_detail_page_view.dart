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

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle (white status bar over the dark hero)
import '/auth/firebase_auth/auth_util.dart'; // currentUserReference (owner vs shared detection)

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
    this.toDoListRouteName,

    /// ✅ NEW: Check List route (project quality checklist)
    this.checkListRouteName,

    /// ✅ NEW: Site Book route (journal site entries linked to the project)
    this.siteBookRouteName,

    /// ✅ NEW: Directory route (empty Project Team → find/add trades)
    this.directoryRouteName,

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
  final String? toDoListRouteName;
  final String? checkListRouteName;
  final String? siteBookRouteName;

  /// Directory (HomePageView) — opened from the empty Project Team state.
  final String? directoryRouteName;

  final String? listingDetailRouteName;

  final String? documentUploadRouteName;
  final String? documentDetailRouteName;

  final String? projectParamName;
  final String? listingParamName;
  final String? documentParamName;

  @override
  State<ProjectDetailPageView> createState() => _ProjectDetailPageViewState();
}

class _ProjectDetailPageViewState extends State<ProjectDetailPageView>
    with SingleTickerProviderStateMixin {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFECF0F2);
  static const Color _hairlineOnSurface = Color(0xFFCBD8DD);
  // Brand accent — TEAL.
  static const Color _spark = Color(0xFF1E282E); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFFFFFFFF);
  static const Color _teal = Color(0xFF1E282E);
  static const Color _tealBright =
      Color(0xFF4E504F); // icon on ink chips (sage)
  static const Color _tealTint =
      Color(0xFFE7EDF0); // pill / chip fill (sage tint)
  static const Color _tealText = Color(0xFF1E282E); // pill text
  static const Color _tealSurface =
      Color(0xFFE7EDF0); // tinted module card (sage)
  static const Color _tealSurfaceBorder = Color(0xFFCBD8DD);
  // Snag identity — Persimmon (snags own this inside a teal project)
  static const Color _persimmon = Color(0xFF566670);
  static const Color _persimmonSurface = Color(0xFFE7EDF0);
  static const Color _persimmonSurfaceBorder = Color(0xFFCBD8DD);
  // To-Do identity — Cobalt
  static const Color _cobalt = Color(0xFF4E504F);
  static const Color _cobaltSurface = Color(0xFFE7EDF0);
  static const Color _cobaltSurfaceBorder = Color(0xFFCBD8DD);
  // Status
  static const Color _live =
      Color(0xFF566670); // clay — live / open-now / warning
  static const Color _coral = Color(0xFF566670);
  // Info / feed accent — true teal (matches the Dashboard activity signals)
  static const Color _infoTeal =
      Color(0xFF566670); // DS: snags/needs-you = clay
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 12;
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

  // Hero scroll-away + compact sticky bar
  final ScrollController _scrollController = ScrollController();
  bool _showCompactBar = false;

  // ─── Swipe-right-to-go-back (follow the thumb, snap back or pop) ──────
  double _dragX = 0;
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<double>? _snapAnim;

  // ignore: unused_element
  void _onDragUpdate(DragUpdateDetails d) {
    if (_snapCtrl.isAnimating) _snapCtrl.stop();
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, double.infinity);
    });
  }

  // ignore: unused_element
  void _onDragEnd(DragEndDetails d) {
    final double width = MediaQuery.sizeOf(context).width;
    final double v = d.primaryVelocity ?? 0;
    final bool shouldClose = _dragX > width * 0.30 || v > 700;
    if (shouldClose) {
      _animateDragTo(width, then: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      });
    } else {
      _animateDragTo(0);
    }
  }

  // ignore: unused_element
  void _animateDragTo(double target, {VoidCallback? then}) {
    _snapAnim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() => _dragX = _snapAnim!.value);
      });
    _snapCtrl
      ..reset()
      ..forward().whenComplete(() {
        if (then != null) then();
      });
  }

  // Wraps the page in the right-to-go-back swipe gesture. deferToChild lets the
  // vertical scroll view keep vertical drags; horizontal drags pop the page.
  // Custom swipe-back REMOVED. It duplicated the platform's native edge-swipe
  // (two back gestures firing on one swipe) and its Transform.translate slid
  // the whole page sideways, exposing a blank white "extra page" behind it.
  // We now rely on the OS back-swipe only, so this is a pass-through.
  // ignore: unused_element
  Widget _swipeBack(Widget child) => child;

  // Collapsible sections (default CLOSED) — Manage stays fixed.
  bool _feedOpen = false;
  bool _docsOpen = false;
  bool _teamOpen = false;

  // Project Feed — read-only activity log (project_activity collection)
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _activityRows = [];
  bool _activityLoadedOnce = false;
  Object? _activityErr;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitySub;

  // Fallback route names (update if your FF routes differ)
  static const String _fallbackEditRoute = 'editProjectPage';
  static const String _fallbackTimelineRoute = 'timelinePage';
  static const String _fallbackCostRoute = 'projectCostPage';
  static const String _fallbackQuotesRoute = 'quotesPage';
  static const String _fallbackSnagRoute = 'snagListPage';
  static const String _fallbackToDoRoute = 'toDoListPage';
  static const String _fallbackCheckListRoute = 'CheckListPage';
  static const String _fallbackSiteBookRoute = 'siteBookPage';
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
    _scrollController.addListener(_onScroll);
    _startSubscriptions();
  }

  void _onScroll() {
    final show = _scrollController.hasClients && _scrollController.offset > 200;
    if (show != _showCompactBar && mounted) {
      setState(() => _showCompactBar = show);
    }
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
    _scrollController.dispose();
    _stopSubscriptions();
    _snapCtrl.dispose();
    super.dispose();
  }

  void _resetLocalState() {
    _projectData = <String, dynamic>{};
    _projectLoadedOnce = false;
    _docRows = [];
    _docsLoadedOnce = false;
    _listingRows = [];
    _listingsLoadedOnce = false;
    _activityRows = [];
    _activityLoadedOnce = false;
    _projectErr = null;
    _docsErr = null;
    _listingsErr = null;
    _activityErr = null;
  }

  void _stopSubscriptions() {
    _projectSub?.cancel();
    _docsSub?.cancel();
    _listingsSub?.cancel();
    _activitySub?.cancel();
    _projectSub = null;
    _docsSub = null;
    _listingsSub = null;
    _activitySub = null;
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

    // Project activity feed (read-only log). Optional fields per doc:
    //   type ('snag'|'document'|'timeline'|'todo'|'team'|'status'),
    //   title (summary), actorName (listing owner's profile name),
    //   listingTitle (the listing that made the change), createdAt (Timestamp)
    _activitySub = FirebaseFirestore.instance
        .collection('project_activity')
        .where('projectRef', isEqualTo: projectRef)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snap) {
      _activityErr = null;
      _activityRows = snap.docs;
      _activityLoadedOnce = true;
      if (!_isNavigating && mounted) setState(() {});
    }, onError: (e) {
      _activityErr = e;
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
      },
    ).whenComplete(() {
      _isNavigating = false;
    });
  }

  // ✅ NEW: navigate to the Directory (HomePageView) to find & add trades.
  // Used by the empty Project Team state.
  static const String _fallbackDirectoryRoute = 'homePage';
  void _navigateToDirectory() {
    if (_isNavigating) return;
    final target = (widget.directoryRouteName ?? '').trim().isEmpty
        ? _fallbackDirectoryRoute
        : widget.directoryRouteName!.trim();
    if (target.isEmpty) return;
    _isNavigating = true;
    FocusScope.of(context).unfocus();
    context.pushNamed(target).whenComplete(() {
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
          _inkSnack('Listing removed from project.'),
        );
    } catch (e) {
      debugPrint('🔥 Failed removing project_listings doc: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          _inkSnack('Could not remove listing.'),
        );
    }
  }

  // =========================================================
  // ✅ Delete document (Firestore doc + Storage file)
  // =========================================================
  Future<void> _removeProjectDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> docSnap,
  ) async {
    final data = docSnap.data();
    try {
      // Best-effort: delete the underlying Storage object first.
      final storagePath =
          (data['storagePath'] ?? data['storage_path'])?.toString().trim();
      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref().child(storagePath).delete();
        } catch (e) {
          debugPrint('⚠️ Storage delete skipped/failed for $storagePath: $e');
        }
      } else {
        final url = (data['fileUrl'] ??
                data['url'] ??
                data['file_url'] ??
                data['downloadUrl'] ??
                data['download_url'])
            ?.toString()
            .trim();
        if (url != null && url.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (e) {
            debugPrint('⚠️ Storage delete skipped/failed for url: $e');
          }
        }
      }

      // Delete the Firestore record (this is what removes it from the list).
      await docSnap.reference.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          _inkSnack('Document deleted.'),
        );
    } catch (e) {
      debugPrint('🔥 Failed deleting project_documents doc: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          _inkSnack('Could not delete document.'),
        );
    }
  }

  // Standard app snackbar — ink background, white text.
  SnackBar _inkSnack(String message) => SnackBar(
        backgroundColor: const Color(0xFF3D4F66),
        content: Text(
          message,
          style: const TextStyle(
            color: _paper,
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      );

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
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _paper, // ✅ shell = primaryBackground
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: _surface, // ✅ inner = secondaryBackground
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

  // Centered destructive confirm dialog — shared "delete warning" module.
  Future<void> _showDeleteDialog({
    required FlutterFlowTheme theme,
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
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
                    color: _coral.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _coral.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: _coral, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.titleMedium.override(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.override(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    lineHeight: 1.5,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await onConfirm();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _coral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        confirmLabel,
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
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
                    onTap: () => Navigator.pop(ctx),
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
                      child: Text(
                        'Cancel',
                        style: theme.bodyMedium.override(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
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

  void _showRemoveListingSheet({
    required FlutterFlowTheme theme,
    required Color accent,
    required String listingTitle,
    required DocumentReference<Map<String, dynamic>> projectListingDocRef,
  }) {
    _showDeleteDialog(
      theme: theme,
      icon: Icons.delete_rounded,
      title: 'Remove listing?',
      message:
          '“$listingTitle” will be removed from this project. This doesn’t delete the listing itself.',
      confirmLabel: 'Remove listing',
      onConfirm: () => _removeProjectListingDoc(projectListingDocRef),
    );
  }

  void _showRemoveDocumentSheet({
    required FlutterFlowTheme theme,
    required Color accent,
    required String documentTitle,
    required QueryDocumentSnapshot<Map<String, dynamic>> docSnap,
  }) {
    _showDeleteDialog(
      theme: theme,
      icon: Icons.delete_rounded,
      title: 'Delete document?',
      message:
          '“$documentTitle” and its file will be permanently removed. This can’t be undone.',
      confirmLabel: 'Delete document',
      onConfirm: () => _removeProjectDocument(docSnap),
    );
  }

  // -----------------------------
  // Theme helpers (TYPOGRAPHY LOCKED)
  // -----------------------------
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

  // C direction: the page's primary accent is ink; teal is the highlight on
  // chips/pills. Ignore the theme colour so this page reads consistently.
  Color _projectsColor(FlutterFlowTheme theme) => _ink;

  Color _tertiaryText(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).tertiaryText as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
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

  // =========================================================
  // ✅ OPTION A — INK HERO MASTHEAD
  // =========================================================
  Widget _inkHero({
    required FlutterFlowTheme theme,
    required double topInset,
    required String name,
    required String status,
    required String address,
    required String dates,
    required double progress,
    bool readOnly = false,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status-bar icons over the light header.
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF3D4F66),
        ),
        padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centered project name + eyebrow, back circle, Edit pill —
            // matches SiteBookPageView's masthead top row.
            Row(
              children: [
                _tapCard(
                  onTap: () => context.safePop(),
                  radius: BorderRadius.circular(999),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _paper.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: _paper),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium.override(
                            fontFamily: _bodyFont,
                            color: _paper,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          readOnly ? 'SHARED PROJECT' : 'PROJECT',
                          style: theme.labelSmall.override(
                            fontFamily: _bodyFont,
                            color: _paper.withOpacity(0.5),
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                readOnly
                    ? const SizedBox(width: 38, height: 38)
                    : _tapCard(
                        onTap: () => _safeNavigate(
                          widget.editProjectRouteName,
                          fallbackRoute: _fallbackEditRoute,
                        ),
                        radius: BorderRadius.circular(999),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _paper.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit_rounded, size: 14, color: _paper),
                              SizedBox(width: 5),
                              Text('Edit',
                                  style: TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _paper)),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            // Completion stat block + location / target date, mirroring
            // SiteBookPageView's large TODAY stat masthead.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COMPLETION',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: _paper.withOpacity(0.55))),
                    const SizedBox(height: 4),
                    Text('${(progress * 100).round()}%',
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (address.trim().isNotEmpty)
                          Text(address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _paper.withOpacity(0.6))),
                        if (dates.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(dates,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _paper.withOpacity(0.45))),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ✅ OPTION A — STAT STRIP (days left · budget · open snags)
  // =========================================================
  Widget _statStrip({
    required FlutterFlowTheme theme,
    required String days,
    required String budget,
    required String snags,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            theme: theme,
            value: days,
            label: 'Days left',
            valueColor: _paper,
            bg: const Color(0xFF4E504F),
            border: const Color(0xFF4E504F),
            labelColor: _paper,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            theme: theme,
            value: budget,
            label: 'Budget',
            valueColor: _paper,
            bg: const Color(0xFF4E504F),
            border: const Color(0xFF4E504F),
            labelColor: _paper,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            theme: theme,
            value: snags,
            label: 'Open snags',
            valueColor: _infoTeal,
            bg: _surface,
            border: _hairline,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required FlutterFlowTheme theme,
    required String value,
    required String label,
    required Color valueColor,
    required Color bg,
    required Color border,
    Color? labelColor,
    bool shadow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: border.withOpacity(0.9)),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0xFF4E504F).withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleLarge.override(
              fontFamily: _displayFont,
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              fontFamily: _bodyFont,
              color: labelColor ?? _inkMute,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0,
            ),
          ),
        ],
      ),
    );
  }

  // Compact Rand formatter for the budget stat (R1.2M / R850k / R900).
  String _shortRand(num v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return 'R${m.toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
    }
    if (v >= 1000) {
      return 'R${(v / 1000).toStringAsFixed(0)}k';
    }
    return 'R${v.toStringAsFixed(0)}';
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
        color: colorOverride ?? _paper,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: (borderColorOverride ?? _hairline).withOpacity(0.9),
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
                  fontFamily: _bodyFont,
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

  // Full-width tinted module row (C3 · tinted).
  // =========================================================
  // ✅ Privacy / visibility wiring
  //   • Modules  → projects.moduleVisibility { key: 'shared'|'private' }
  //   • Documents→ project_documents.visibility 'shared'|'private'
  //                project_documents.category   'drawing'|'document'
  // =========================================================
  static const Map<String, String> _defaultModuleVis = {
    'timeline': 'shared',
    'checkList': 'shared',
    'siteBook': 'private',
    'snagList': 'shared',
    'toDo': 'shared',
    'projectCost': 'private',
    'getQuotes': 'private',
  };

  Map<String, String> _moduleVisMap() {
    final out = Map<String, String>.from(_defaultModuleVis);
    final raw = _projectData['moduleVisibility'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final val = v.toString();
        if (val == 'shared' || val == 'private') out[k.toString()] = val;
      });
    }
    return out;
  }

  String _moduleVisFor(String key) {
    // Get Quotes is never shareable — always private, no toggle.
    if (key == 'getQuotes') return 'private';
    return _moduleVisMap()[key] ?? 'private';
  }

  // Human label for a module key (used by the visibility snackbar).
  String _moduleLabel(String key) {
    switch (key) {
      case 'timeline':
        return 'Timeline';
      case 'siteBook':
        return 'Site Book';
      case 'toDo':
        return 'To-Do List';
      case 'checkList':
        return 'Check List';
      case 'snagList':
        return 'Snag List';
      case 'projectCost':
        return 'Project Cost';
      case 'getQuotes':
        return 'Get Quotes';
      default:
        return 'Module';
    }
  }

  Future<void> _toggleModuleVis(String key) async {
    final ref = widget.projectRef;
    if (ref == null) return;
    final next = _moduleVisFor(key) == 'shared' ? 'private' : 'shared';

    // Optimistic local update so the icon flips immediately.
    final mv = _moduleVisMap()..[key] = next;
    _projectData = Map<String, dynamic>.from(_projectData)
      ..['moduleVisibility'] = mv;
    if (mounted) setState(() {});

    // Confirm the change with a snackbar.
    if (mounted) {
      final label = _moduleLabel(key);
      final msg = next == 'shared'
          ? '$label is now shared with your team.'
          : '$label is now private.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(_inkSnack(msg));
    }

    try {
      await ref.set(
        <String, dynamic>{
          'moduleVisibility': <String, dynamic>{key: next},
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('🔥 Failed to update module visibility: $e');
    }
  }

  String _docCategory(Map<String, dynamic> d) {
    final c = (d['category'] ?? d['cat'] ?? '').toString().toLowerCase();
    if (c.contains('draw') || c.contains('plan')) return 'drawing';
    return 'document';
  }

  String _docVisibility(Map<String, dynamic> d) {
    final v = (d['visibility'] ?? 'private').toString().toLowerCase();
    return v == 'shared' ? 'shared' : 'private';
  }

  Future<void> _toggleDocVis(
    DocumentReference<Map<String, dynamic>> ref,
    String current, [
    String title = 'Document',
  ]) async {
    final next = current == 'shared' ? 'private' : 'shared';
    try {
      await ref.update(<String, dynamic>{
        'visibility': next,
        'updatedAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(_inkSnack(
              '“$title” is now ${next == 'shared' ? 'shared.' : 'private.'}'));
      }
    } catch (e) {
      debugPrint('🔥 Failed to update document visibility: $e');
    }
  }

  IconData _docCategoryIcon(String category) => category == 'drawing'
      ? Icons.architecture_rounded
      : Icons.description_rounded;

  // Small eye/lock toggle used on module + document rows.
  Widget _visToggle({
    required String visibility,
    required VoidCallback onTap,
    Color? bgColor,
    Color? iconColor,
  }) {
    final shared = visibility == 'shared';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor ?? _surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            shared ? Icons.visibility_outlined : Icons.lock_outline_rounded,
            size: 16,
            color: iconColor ?? _inkMute,
          ),
        ),
      ),
    );
  }

  Widget _docGroupLabel(FlutterFlowTheme theme, String text) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 10),
        child: Text(
          text,
          style: theme.labelSmall.override(
            fontFamily: _bodyFont,
            color: _inkMute,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

  // Shared / Private legend shown under the Manage + Documents headers.
  Widget _visLegend(FlutterFlowTheme theme) {
    Widget item(IconData icon, Color iconColor, Color bg, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: _bodyFont,
              color: _inkMute,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Shared icon now uses the SAME neutral colours as Private.
          item(Icons.visibility_outlined, _inkMute, _surface, 'Shared'),
          const SizedBox(width: 18),
          item(Icons.lock_outline_rounded, _inkMute, _surface, 'Private'),
        ],
      ),
    );
  }

  List<Widget> _docRowWidgets(
    FlutterFlowTheme theme,
    Color accent,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rows, {
    bool readOnly = false,
  }) {
    return List.generate(rows.length, (i) {
      final docSnap = rows[i];
      final d = docSnap.data();
      final title = (d['title'] ?? d['name'] ?? 'Document').toString().trim();
      final type = (d['type'] ?? d['fileType'] ?? 'File').toString().trim();
      final updatedAt = d['updatedAt'] ?? d['createdAt'];
      final when = (updatedAt is Timestamp)
          ? dateTimeFormat('d MMM y · HH:mm', updatedAt.toDate())
          : 'recently';
      final vis = _docVisibility(d);
      final cat = _docCategory(d);
      return Padding(
        padding: EdgeInsets.zero,
        child: _documentRow(
          theme: theme,
          accent: accent,
          title: title.isEmpty ? 'Document' : title,
          subtitle: when,
          icon: _docCategoryIcon(cat),
          visibility: readOnly ? null : vis,
          onToggleVisibility:
              readOnly ? null : () => _toggleDocVis(docSnap.reference, vis),
          onTap: () => _openDocumentRow(docSnap),
          onDelete: readOnly
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  _showRemoveDocumentSheet(
                    theme: theme,
                    accent: accent,
                    documentTitle: title.isEmpty ? 'Document' : title,
                    docSnap: docSnap,
                  );
                },
          onDownload: readOnly ? () => _openDocumentRow(docSnap) : null,
        ),
      );
    });
  }

  // Documents grouped into Drawings / Documents (+ Images).
  Widget _docsByCategory(FlutterFlowTheme theme, Color accent,
      {bool readOnly = false}) {
    final all = readOnly
        ? _docRows.where((s) => _docVisibility(s.data()) == 'shared').toList()
        : _docRows;
    final drawings =
        all.where((s) => _docCategory(s.data()) == 'drawing').toList();
    final documents =
        all.where((s) => _docCategory(s.data()) == 'document').toList();
    if (drawings.isEmpty && documents.isEmpty) {
      return _cardShell(
        theme: theme,
        colorOverride: _surface,
        child: Text(
          'No documents shared with you yet.',
          style: theme.bodyMedium.override(
            fontFamily: _bodyFont,
            color: _inkMute,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drawings.isNotEmpty) ...[
          _docGroupLabel(theme, 'DRAWINGS'),
          ..._docRowWidgets(theme, accent, drawings, readOnly: readOnly),
          if (documents.isNotEmpty) const SizedBox(height: 16),
        ],
        if (documents.isNotEmpty) ...[
          _docGroupLabel(theme, 'DOCUMENTS / IMAGES'),
          ..._docRowWidgets(theme, accent, documents, readOnly: readOnly),
        ],
      ],
    );
  }

  Widget _moduleRow({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? visibility,
    VoidCallback? onToggleVisibility,
    Color? accentChip,
    Color? accentSurface,
    Color? accentBorder,
    Color? accentText,
  }) {
    final chip = accentChip ?? _teal;
    final surface = accentSurface ?? _tealSurface;
    final border = accentBorder ?? _tealSurfaceBorder;
    final titleColor = accentText ?? _ink;
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: chip,
                borderRadius: BorderRadius.circular(_radius),
              ),
              child: Icon(icon, size: 22, color: _paper),
            ),
            const SizedBox(width: 13),
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
                      color: titleColor,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelSmall.override(
                      fontFamily: _bodyFont,
                      color: _inkMute,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (visibility != null && onToggleVisibility != null) ...[
              _visToggle(
                  visibility: visibility,
                  onTap: onToggleVisibility,
                  bgColor: Colors.transparent),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, size: 22, color: _ink),
          ],
        ),
      ),
    );
  }

  // 2-up Sage module tile (Manage grid) — ink icon chip, title + subtitle.
  // featured:true renders the lead tile as a solid sage-green hero card.
  Widget _moduleGridCell({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? visibility,
    VoidCallback? onToggleVisibility,
    bool featured = false,
  }) {
    final Color cardBg = featured ? const Color(0xFF4E504F) : _tealSurface;
    final Color cardBorder =
        featured ? const Color(0xFF4E504F) : _tealSurfaceBorder;
    final Color chipBg = featured ? Colors.white.withOpacity(0.16) : _ink;
    final Color titleColor = featured ? _paper : _ink;
    final Color subColor = featured ? Colors.white.withOpacity(0.8) : _inkMute;
    return _tapCard(
      onTap: onTap,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: cardBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 21, color: _paper),
                ),
                const Spacer(),
                if (visibility != null && onToggleVisibility != null)
                  _visToggle(
                    visibility: visibility,
                    onTap: onToggleVisibility,
                    bgColor: Colors.transparent,
                    iconColor: featured ? Colors.white.withOpacity(0.9) : null,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.titleMedium.override(
                fontFamily: _displayFont,
                color: titleColor,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall.override(
                fontFamily: _bodyFont,
                color: subColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-width Sage module tile — used for the odd last module (Get Quotes).
  Widget _wideModuleCell({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? visibility,
    VoidCallback? onToggleVisibility,
  }) {
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _tealSurface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _tealSurfaceBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 21, color: _paper),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.titleMedium.override(
                      fontFamily: _displayFont,
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.labelSmall.override(
                      fontFamily: _bodyFont,
                      color: _inkMute,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            if (visibility != null && onToggleVisibility != null) ...[
              _visToggle(
                visibility: visibility,
                onTap: onToggleVisibility,
                bgColor: Colors.transparent,
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: Color(0xFF4E504F)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline.withOpacity(0.9)),
        ),
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
                      color: _ink,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: Icon(icon, size: 22, color: _tealBright),
                  ),
                  const Spacer(),
                  if ((count ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _hairline.withOpacity(0.9)),
                      ),
                      child: Text(
                        '$count',
                        style: theme.labelSmall.override(
                          fontFamily: _bodyFont,
                          color: _ink,
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
                  fontFamily: _displayFont,
                  color: _ink,
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
                  fontFamily: _bodyFont,
                  color: _inkMute,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.chevron_right_rounded, color: _inkMute),
              ),
            ],
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
                fontFamily: _bodyFont,
                color: _inkMute,
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
                    fontFamily: _bodyFont,
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.bodySmall.override(
                    fontFamily: _bodyFont,
                    color: _inkMute,
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
    String? visibility,
    VoidCallback? onToggleVisibility,
    VoidCallback? onTap,
    VoidCallback? onDelete,
    VoidCallback? onDownload,
  }) {
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEAEEF0))),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 4, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: _tealBright),
              ),
              const SizedBox(width: 13),
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
                        color: _ink,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'UPDATED',
                      style: theme.labelSmall.override(
                        fontFamily: _bodyFont,
                        color: const Color(0xFF93A3AC),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelSmall.override(
                        fontFamily: _bodyFont,
                        color: _inkMute,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (visibility != null && onToggleVisibility != null) ...[
                const SizedBox(width: 6),
                _visToggle(visibility: visibility, onTap: onToggleVisibility),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 18),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: _inkMute,
                    ),
                  ),
                ),
              ],
              if (onDownload != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDownload,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.download_rounded, size: 20, color: _ink),
                  ),
                ),
              ],
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
    VoidCallback? onDelete,
    bool readOnly = false,
  }) {
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline.withOpacity(0.9)),
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
                    size: 22, color: _paper),
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
                        fontFamily: _bodyFont,
                        color: _ink,
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
                        fontFamily: _bodyFont,
                        color: _inkMute,
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
                              fontFamily: _bodyFont,
                              color: _inkMute,
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
              if (!readOnly && onDelete != null)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: _inkMute,
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
            const Icon(Icons.upload_file_rounded, size: 18, color: _paper),
            const SizedBox(width: 8),
            Text(
              'Upload',
              style: theme.bodySmall.override(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SHARED / READ-ONLY (provider) VIEW HELPERS
  // =========================================================
  Widget _sharedByCard(FlutterFlowTheme theme, DocumentReference ownerRef) {
    return StreamBuilder<DocumentSnapshot>(
      stream: ownerRef.snapshots(),
      builder: (context, snap) {
        final d = (snap.data?.data() as Map<String, dynamic>?) ??
            const <String, dynamic>{};
        final name = (d['display_name'] ?? '').toString().trim();
        final photo = (d['photo_url'] ?? '').toString().trim();
        final phone = (d['phone_number'] ?? '').toString().trim();
        final display = name.isEmpty ? 'Project manager' : name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'SHARED WITH YOU BY',
                style: theme.labelSmall.override(
                  fontFamily: _bodyFont,
                  color: _inkMute,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _tealSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _tealSurfaceBorder),
              ),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: _ink,
                      shape: BoxShape.circle,
                    ),
                    child: photo.isNotEmpty
                        ? Image.network(
                            photo,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _avatarInitials(display),
                          )
                        : _avatarInitials(display),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium.override(
                            fontFamily: _displayFont,
                            color: _ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Project Manager',
                          style: theme.bodySmall.override(
                            fontFamily: _bodyFont,
                            color: _inkMute,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    _roundAction(Icons.call_rounded, _ink,
                        () => launchURL('tel:$phone')),
                    const SizedBox(width: 8),
                    _roundAction(Icons.chat_bubble_rounded, _tealBright,
                        () => launchURL('sms:$phone')),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _avatarInitials(String name) => Text(
        _initialsOf(name),
        style: const TextStyle(
          fontFamily: _displayFont,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _paper,
        ),
      );

  Widget _roundAction(IconData icon, Color bg, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: _paper),
        ),
      );

  String _initialsOf(String name) {
    final n = name.trim();
    if (n.isEmpty) return '–';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _statStripShared({
    required FlutterFlowTheme theme,
    required String days,
    required String snags,
    required String files,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            theme: theme,
            value: days,
            label: 'Days left',
            valueColor: _paper,
            bg: const Color(0xFF4E504F),
            border: const Color(0xFF4E504F),
            labelColor: _paper,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            theme: theme,
            value: snags,
            label: 'Open snags',
            valueColor: _paper,
            bg: const Color(0xFF4E504F),
            border: const Color(0xFF4E504F),
            labelColor: _paper,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            theme: theme,
            value: files,
            label: 'Shared files',
            valueColor: _infoTeal,
            bg: _surface,
            border: _hairline,
          ),
        ),
      ],
    );
  }

  Widget _sharedManage(FlutterFlowTheme theme) {
    final mods = <Map<String, dynamic>>[
      {
        'key': 'timeline',
        'icon': Icons.timeline_rounded,
        'title': 'Timeline',
        'sub': 'Programme & phases',
        'route': widget.timelineRouteName,
        'fb': _fallbackTimelineRoute,
      },
      {
        'key': 'toDo',
        'icon': Icons.checklist_rounded,
        'title': 'To-Do List',
        'sub': 'Tasks & reminders',
        'route': widget.toDoListRouteName,
        'fb': _fallbackToDoRoute,
      },
      {
        'key': 'snagList',
        'icon': Icons.fact_check_outlined,
        'title': 'Snag List',
        'sub': 'Defects & fixes',
        'route': widget.snagListRouteName,
        'fb': _fallbackSnagRoute,
      },
      {
        'key': 'projectCost',
        'icon': Icons.calculate_outlined,
        'title': 'Project Cost',
        'sub': 'Budget & estimates',
        'route': widget.projectCostRouteName,
        'fb': _fallbackCostRoute,
      },
      {
        'key': 'getQuotes',
        'icon': Icons.request_quote_outlined,
        'title': 'Get Quotes',
        'sub': 'Compare trades',
        'route': widget.getQuotesRouteName,
        'fb': _fallbackQuotesRoute,
      },
    ];
    final shared = mods
        .where((m) => _moduleVisFor(m['key'] as String) == 'shared')
        .toList();
    final hidden = mods
        .where((m) => _moduleVisFor(m['key'] as String) != 'shared')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Shared with you'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            "The project manager chose what to share. Private modules aren't shown.",
            style: theme.bodySmall.override(
              fontFamily: _bodyFont,
              color: _inkMute,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final m in shared) ...[
          _moduleRow(
            theme: theme,
            icon: m['icon'] as IconData,
            title: m['title'] as String,
            subtitle: m['sub'] as String,
            onTap: () => _safeNavigate(m['route'] as String?,
                fallbackRoute: m['fb'] as String),
          ),
          const SizedBox(height: 12),
        ],
        if (hidden.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5F6),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _hairlineOnSurface),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 18, color: Color(0xFF93A3AC)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${hidden.map((m) => m['title']).join(' & ')} ${hidden.length == 1 ? 'is' : 'are'} private to the project manager.',
                    style: theme.labelSmall.override(
                      fontFamily: _bodyFont,
                      color: const Color(0xFF93A3AC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =========================================================
  // PROJECT FEED — read-only activity log (helpers + section)
  // =========================================================
  String _feedDayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    final date = dateTimeFormat('d MMM', d).toUpperCase();
    if (diff == 0) return 'TODAY · $date';
    if (diff == 1) return 'YESTERDAY · $date';
    return '${dateTimeFormat('EEE', d).toUpperCase()} · $date';
  }

  String _feedTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return dateTimeFormat('HH:mm', d);
  }

  // type -> (icon, accent, tint, border)
  _FeedVisual _activityVisual(String type) {
    switch (type.toLowerCase()) {
      case 'snag':
      case 'snagadded':
      case 'snagresolved':
        return const _FeedVisual(
            Icons.fact_check_outlined, _ink, _tealSurface, _tealSurfaceBorder);
      case 'document':
      case 'documentuploaded':
        return const _FeedVisual(
            Icons.description_rounded, _ink, _tealSurface, _tealSurfaceBorder);
      case 'timeline':
        return const _FeedVisual(
            Icons.timeline_rounded, _ink, _tealSurface, _tealSurfaceBorder);
      case 'todo':
      case 'task':
        return const _FeedVisual(
            Icons.task_alt_rounded, _ink, _tealSurface, _tealSurfaceBorder);
      case 'team':
      case 'memberadded':
        return const _FeedVisual(
            Icons.group_add_rounded, _ink, _tealSurface, _tealSurfaceBorder);
      case 'status':
        return const _FeedVisual(
            Icons.flag_rounded, _ink, _tealSurface, _tealSurfaceBorder);
      default:
        return const _FeedVisual(
            Icons.bolt, _ink, _tealSurface, _tealSurfaceBorder);
    }
  }

  // Clickable section header with a rotating chevron (collapse affordance).
  Widget _collapsibleHeader(
    FlutterFlowTheme theme,
    String title,
    bool open,
    VoidCallback onToggle, {
    int? count,
    String countUnit = '',
    bool alwaysShowCount = false,
  }) {
    final bool showCount =
        !open && count != null && (count > 0 || alwaysShowCount);
    return _tapCard(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle(theme, title),
          const SizedBox(width: 8),
          AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            turns: open ? 0 : -0.25,
            child: const Icon(Icons.expand_more_rounded,
                size: 24, color: Color(0xFF93A3AC)),
          ),
          if (showCount) ...[
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count $countUnit'.trim(),
                style: theme.labelSmall.override(
                  fontFamily: _bodyFont,
                  color: _ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionDescription(FlutterFlowTheme theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          text,
          style: theme.bodySmall.override(
            fontFamily: _bodyFont,
            color: _inkMute,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // Compact sticky bar shown once the ink hero scrolls away.
  Widget _compactBar({
    required FlutterFlowTheme theme,
    required double topInset,
    required String name,
    required bool readOnly,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: const BoxDecoration(
          color: _paper,
          border: Border(bottom: BorderSide(color: _hairline)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A19232D),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, topInset + 8, 20, 12),
        child: Row(
          children: [
            _tapCard(
              onTap: () => context.safePop(),
              radius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: _ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium.override(
                        fontFamily: _displayFont,
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _tealBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            readOnly
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 15, color: _ink),
                        const SizedBox(width: 6),
                        Text('View only',
                            style: theme.bodySmall.override(
                              fontFamily: _bodyFont,
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  )
                : _tapCard(
                    onTap: () => _safeNavigate(widget.editProjectRouteName,
                        fallbackRoute: _fallbackEditRoute),
                    radius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E504F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 15, color: _paper),
                          const SizedBox(width: 6),
                          Text('Edit',
                              style: theme.bodySmall.override(
                                fontFamily: _bodyFont,
                                color: _paper,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Count of activity entries logged TODAY (drives the feed count chip).
  int _todayActivityCount() {
    final now = DateTime.now();
    return _activityRows.where((doc) {
      final ts = doc.data()['createdAt'];
      if (ts is! Timestamp) return false;
      final d = ts.toDate();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  // The collapsible Project Feed section (timeline rail, newest first).
  Widget _buildProjectFeed(FlutterFlowTheme theme) {
    final todayCount = _todayActivityCount();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _collapsibleHeader(
                theme,
                'Project Feed',
                _feedOpen,
                () => setState(() => _feedOpen = !_feedOpen),
              ),
            ),
            // Daily activity count (replaces the old "Read-only" pill).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4E504F).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 14, color: Color(0xFF4E504F)),
                  const SizedBox(width: 5),
                  Text('$todayCount today',
                      style: theme.labelSmall.override(
                        fontFamily: _bodyFont,
                        color: const Color(0xFF4E504F),
                        fontWeight: FontWeight.w900,
                      )),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _sectionDescription(theme, 'Auto-logged updates — newest first.'),
        if (_feedOpen) _projectFeedBody(theme),
      ],
    );
  }

  Widget _projectFeedBody(FlutterFlowTheme theme) {
    if (_activityErr != null) {
      return _errorCard(theme, _ink, 'Couldn’t load activity',
          'This is usually a missing Firestore index or rules issue.');
    }
    if (!_activityLoadedOnce) {
      return _loadingCard(theme, _ink, 'Loading activity…');
    }
    if (_activityRows.isEmpty) {
      return _cardShell(
        theme: theme,
        colorOverride: _surface,
        child: Text(
          'No activity yet. Updates from your team will appear here.',
          style: theme.bodyMedium.override(
            fontFamily: _bodyFont,
            color: _inkMute,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final rows = <Widget>[];
    String? currentLabel;
    for (final doc in _activityRows) {
      final d = doc.data();
      final ts = d['createdAt'];
      final when = (ts is Timestamp) ? ts.toDate() : DateTime.now();
      final label = _feedDayLabel(when);
      if (label != currentLabel) {
        currentLabel = label;
        rows.add(_feedDayChip(theme, label));
      }
      final type = (d['type'] ?? '').toString();
      final title = (d['title'] ?? d['summary'] ?? 'Update').toString();
      final actor = (d['actorName'] ?? d['actor'] ?? '').toString();
      final listing = (d['listingTitle'] ?? '').toString();
      final who =
          [actor, listing].where((x) => x.trim().isNotEmpty).join(' · ');
      final meta = who.isEmpty ? _feedTime(when) : '$who · ${_feedTime(when)}';
      rows.add(_feedRow(theme, _activityVisual(type), title, meta));
    }

    return Stack(
      children: [
        Positioned(
          left: 14,
          top: 8,
          bottom: 8,
          child: Container(width: 2, color: const Color(0xFFDCE3E6)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
      ],
    );
  }

  Widget _feedDayChip(FlutterFlowTheme theme, String label) => Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: theme.labelSmall.override(
              fontFamily: _bodyFont,
              color: _paper,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
      );

  Widget _feedRow(
    FlutterFlowTheme theme,
    _FeedVisual v,
    String title,
    String meta,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: v.tint,
              shape: BoxShape.circle,
              border: Border.all(color: v.border, width: 1.5),
            ),
            child: Icon(v.icon, size: 16, color: v.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodyMedium.override(
                      fontFamily: _bodyFont,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      lineHeight: 1.32,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: theme.labelSmall.override(
                      fontFamily: _bodyFont,
                      color: _inkMute,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final projectsAccent = _projectsColor(theme);

    if (widget.projectRef == null) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
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
                      color: _coral,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: const Icon(Icons.error_outline,
                        color: _paper, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No project selected. Please open this page from My Projects.',
                      style: theme.bodyMedium.override(
                        fontFamily: _bodyFont,
                        color: _ink,
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
        color: _paper,
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
        color: _paper,
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

    // Owner sees the full editable page; anyone else (a provider whose listing
    // was added to this project) gets the read-only shared view.
    final bool isOwner = (projData['ownerRef'] is DocumentReference) &&
        currentUserReference != null &&
        (projData['ownerRef'] as DocumentReference).path ==
            currentUserReference!.path;
    final bool readOnly = !isOwner;
    final DocumentReference? ownerProfileRef =
        projData['ownerRef'] is DocumentReference
            ? projData['ownerRef'] as DocumentReference
            : null;

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

    // ─── OPTION A · stat strip values ──────────────────────────────────
    // Days left → derived from endDate.
    String daysLeftLabel = '—';
    if (endTs is Timestamp) {
      final diff = endTs.toDate().difference(DateTime.now()).inDays;
      daysLeftLabel = diff > 0 ? '$diff' : '0';
    }
    // Budget → optional 'budget' field (num or pre-formatted string).
    final budgetRaw = projData['budget'];
    String budgetLabel = '—';
    if (budgetRaw is num) {
      budgetLabel = _shortRand(budgetRaw);
    } else if (budgetRaw is String && budgetRaw.trim().isNotEmpty) {
      budgetLabel = budgetRaw.trim();
    }
    // Open snags → optional 'openSnags' / 'snagCount' field.
    final snagsRaw = projData['openSnags'] ?? projData['snagCount'];
    final snagLabel = (snagsRaw is num) ? '${snagsRaw.toInt()}' : '—';

    // Overall completion (0..1 or 0..100) — drives the hero progress bar.
    final progressRaw = projData['progress'];
    double progressVal = 0;
    if (progressRaw is num) {
      progressVal = progressRaw.toDouble();
      if (progressVal > 1) progressVal = progressVal / 100.0;
    }
    progressVal = progressVal.clamp(0.0, 1.0);

    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return _swipeBack(
      Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        // Ink hero masthead is PINNED (fixed) — only the content below scrolls.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inkHero(
              theme: theme,
              topInset: topInset,
              name: projectName,
              status: projectStatus,
              address: projectAddress,
              dates: projectDates,
              progress: progressVal,
              readOnly: readOnly,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      _hPad, 18, _hPad, _vPad + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Redesigned body (matches DetailTask / DetailSnag) --
                      _rPills(theme),
                      const SizedBox(height: 18),
                      _rCompletion(theme),
                      if (readOnly) ...[
                        const SizedBox(height: 18),
                        _rOwnerCard(theme, ownerProfileRef),
                      ],
                      const SizedBox(height: 20),
                      _rSectionLabel('PROJECT MANAGEMENT'),
                      const SizedBox(height: 10),
                      _rModules(readOnly),
                      const SizedBox(height: 24),
                      _rDocuments(readOnly),
                      const SizedBox(height: 24),
                      _rTeam(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // REDESIGN HELPERS — layout ported 1:1 from the approved mock.
  // ===================================================================
  static const Color _rFaint = Color(0xFF93A3AC);
  static const Color _rDivider = Color(0xFFEAEEF0);
  static const Color _rThumb = Color(0xFFF2F5F6);
  static const Color _rChevron = Color(0xFFCBD8DD);
  static const Color _rThumbBorder = Color(0xFFDCE3E6);

  String _rInitials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _rSectionLabel(String s) => Text(s,
      style: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _inkMute));

  Widget _rPill(String text,
      {required Color fg, required Color bg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
        ],
        Text(text,
            style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg)),
      ]),
    );
  }

  Widget _rPills(FlutterFlowTheme theme) {
    final status = (_projectData['status'] ?? 'Active').toString().trim();
    final category = (_projectData['category'] ?? _projectData['type'] ?? '')
        .toString()
        .trim();
    return Row(children: [
      _rPill(status.isEmpty ? 'Active' : status,
          fg: _paper, bg: const Color(0xFFAC0C0C), icon: Icons.bolt_rounded),
      if (category.isNotEmpty) ...[
        const SizedBox(width: 8),
        _rPill(category, fg: _ink, bg: _surface),
      ],
    ]);
  }

  double _rProgress() {
    final pr = _projectData['progress'];
    double p = 0;
    if (pr is num) {
      p = pr.toDouble();
      if (p > 1) p = p / 100.0;
    }
    return p.clamp(0.0, 1.0);
  }

  Widget _rCompletion(FlutterFlowTheme theme) {
    final p = _rProgress();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('COMPLETION',
            style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _inkMute)),
        Text('${(p * 100).round()}%',
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _ink)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: p,
          minHeight: 6,
          backgroundColor: _surface,
          valueColor: const AlwaysStoppedAnimation<Color>(_ink),
        ),
      ),
    ]);
  }

  Widget _rRound(IconData icon, Color bg, Color fg, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: fg),
          ),
        ),
      );

  Widget _rOwnerCard(FlutterFlowTheme theme, DocumentReference? ownerRef) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(14)),
      child: FutureBuilder<DocumentSnapshot<Object?>>(
        future: ownerRef?.get(),
        builder: (context, snap) {
          final od = (snap.data?.data() as Map<String, dynamic>?) ?? {};
          final nm = (od['display_name'] ?? 'Project owner').toString().trim();
          final phone = (od['phone_number'] ?? '').toString().trim();
          return Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _paper, borderRadius: BorderRadius.circular(12)),
              child: Text(_rInitials(nm),
                  style: const TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PROJECT OWNER',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: _rFaint)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Flexible(
                      child: Text(nm.isEmpty ? 'Project owner' : nm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded, size: 14, color: _ink),
                  ]),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.call_rounded, size: 13, color: _rFaint),
                      const SizedBox(width: 5),
                      Text(phone,
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _inkMute)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _rRound(Icons.call_rounded, _paper, _ink, () {
              if (phone.isNotEmpty) launchURL('tel:$phone');
            }),
            const SizedBox(width: 8),
            _rRound(Icons.chat_bubble_rounded, _ink, _paper, () {
              if (phone.isNotEmpty) launchURL('sms:$phone');
            }),
          ]);
        },
      ),
    );
  }

  Widget _rModIcon(IconData icon) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: _paper, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 21, color: _ink),
      );

  Widget _rVisChip(String vis, Color bg) {
    final shared = vis == 'shared';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(shared ? Icons.group_rounded : Icons.lock_rounded,
            size: 11, color: shared ? _ink : _rFaint),
        const SizedBox(width: 4),
        Text(shared ? 'Shared' : 'Private',
            style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: shared ? _ink : _rFaint)),
      ]),
    );
  }

  Widget _rModTile(IconData icon, String title, String sub, String visKey,
      bool readOnly, VoidCallback onTap,
      {bool featured = false}) {
    // Featured (Timeline) keeps the bold yellow hero with a programme bar.
    if (featured) return _rTimelineTile(icon, visKey, readOnly, onTap);

    // Live status + badge, computed from the module's real collection:
    //   Site Book → site_book_entries · To-Do → tasks · Snag → snags ·
    //   Quotes → projectRef/quotes. Project Cost stays static (cost excluded).
    final ref = widget.projectRef;
    Stream<QuerySnapshot<Map<String, dynamic>>>? stream;
    if (ref != null) {
      final fs = FirebaseFirestore.instance;
      switch (visKey) {
        case 'siteBook':
          stream = fs
              .collection('site_book_entries')
              .where('projectRef', isEqualTo: ref)
              .snapshots();
          break;
        case 'toDo':
          stream = fs
              .collection('tasks')
              .where('projectRef', isEqualTo: ref)
              .snapshots();
          break;
        case 'snagList':
          stream = fs
              .collection('snags')
              .where('projectRef', isEqualTo: ref)
              .snapshots();
          break;
        case 'getQuotes':
          stream = ref.collection('quotes').snapshots();
          break;
      }
    }

    if (stream == null) {
      return _modRow(icon, title, sub, null, false, visKey, readOnly, onTap);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        String status = sub;
        String? badge;
        bool attention = false;
        switch (visKey) {
          case 'siteBook':
            final n = docs.length;
            status = n > 0 ? '$n ${n == 1 ? 'entry' : 'entries'}' : sub;
            break;
          case 'toDo':
            final open = docs
                .where(
                    (d) => (d.data()['status'] ?? 'todo').toString() != 'done')
                .length;
            status = docs.isNotEmpty ? '$open open' : sub;
            break;
          case 'snagList':
            final open = docs
                .where((d) =>
                    (d.data()['status'] ?? 'open').toString() != 'closed')
                .length;
            final fixed = docs.length - open;
            attention = open > 0;
            status = open > 0
                ? '$open open · $fixed fixed'
                : (docs.isNotEmpty ? '$fixed fixed' : sub);
            if (open > 0) badge = '$open';
            break;
          case 'getQuotes':
            final received = docs
                .where(
                    (d) => (d.data()['status'] ?? '').toString() == 'submitted')
                .length;
            status = received > 0 ? '$received received' : sub;
            if (received > 0) badge = '$received';
            break;
        }
        return _modRow(
            icon, title, status, badge, attention, visKey, readOnly, onTap);
      },
    );
  }

  // Renders one grey status tile: icon chip · title (+ trailing badge or
  // visibility chip) · live status line. Snags tint the chip red when open.
  Widget _modRow(IconData icon, String title, String status, String? badge,
      bool attention, String visKey, bool readOnly, VoidCallback onTap) {
    final Color badgeColor = visKey == 'snagList'
        ? const Color(0xFFAC0C0C)
        : const Color(0xFF4E504F);
    final String vis = _moduleVisFor(visKey);

    Widget trailing;
    if (readOnly) {
      trailing =
          const Icon(Icons.chevron_right_rounded, size: 20, color: _rChevron);
    } else if (badge != null) {
      trailing = Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 20,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
            color: badgeColor, borderRadius: BorderRadius.circular(999)),
        child: Text(badge,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      );
    } else if (visKey == 'getQuotes') {
      // Quotes visibility stays locked (no toggle).
      trailing = _rVisChip('private', _surface);
    } else {
      trailing = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggleModuleVis(visKey),
        child: _rVisChip(vis, _paper),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF1F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: attention ? const Color(0xFFF7E4E4) : _paper,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 24, color: attention ? const Color(0xFFAC0C0C) : _ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _displayFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: _ink)),
                    ),
                    const SizedBox(width: 8),
                    trailing,
                  ]),
                  const SizedBox(height: 5),
                  Text(status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF93A3AC))),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Featured Timeline tile — yellow hero with a mini programme progress bar.
  Widget _rTimelineTile(
      IconData icon, String visKey, bool readOnly, VoidCallback onTap) {
    final double p = _rProgress();
    final int? phase = _optInt(const ['phase', 'currentPhase']);
    final int total = _optInt(const ['phaseTotal', 'phaseCount']) ?? 6;
    final String next =
        (_projectData['nextMilestone'] ?? _projectData['nextPhase'] ?? '')
            .toString()
            .trim();
    final parts = <String>[
      if (phase != null) 'Phase $phase/$total',
      if (next.isNotEmpty) 'Next: $next',
    ];
    final String status =
        parts.isEmpty ? 'Programme & phases' : parts.join(' · ');
    final String vis = _moduleVisFor(visKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: const Color(0xFFE7E247),
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0x1A1E282E),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 24, color: _ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                      child: Text('Timeline',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: _displayFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: _ink)),
                    ),
                    if (!readOnly)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toggleModuleVis(visKey),
                        child: _rVisChip(vis, _paper),
                      ),
                  ]),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: p,
                      minHeight: 5,
                      backgroundColor: Colors.white.withOpacity(0.6),
                      valueColor: const AlwaysStoppedAnimation<Color>(_ink),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _inkMute)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Optional int project-doc field lookup (first key that carries a number).
  int? _optInt(List<String> keys) {
    for (final k in keys) {
      final v = _projectData[k];
      if (v is num) return v.toInt();
    }
    return null;
  }

  Widget _rModWide(IconData icon, String title, String sub, String visKey,
      bool readOnly, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _surface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _rModIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: _ink)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _rFaint)),
                ],
              ),
            ),
            if (!readOnly) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleModuleVis(visKey),
                child: _rVisChip(_moduleVisFor(visKey), _paper),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: _rChevron),
          ]),
        ),
      ),
    );
  }

  Widget _rModules(bool readOnly) {
    // Full-width single-column module rows. Shared (read-only) view shows ONLY
    // the modules the owner shared, with no visibility chips.
    final all = <List<dynamic>>[
      [
        Icons.timeline_rounded,
        'Timeline',
        'Programme & phases',
        'timeline',
        widget.timelineRouteName,
        _fallbackTimelineRoute,
        true, // featured
      ],
      [
        Icons.checklist_rounded,
        'To-Do List',
        'Tasks & reminders',
        'toDo',
        widget.toDoListRouteName,
        _fallbackToDoRoute,
        false,
      ],
      [
        Icons.rule_rounded,
        'Check List',
        'Quality checks',
        'checkList',
        widget.checkListRouteName,
        _fallbackCheckListRoute,
        false,
      ],
      [
        Icons.fact_check_outlined,
        'Snag List',
        'Defects & fixes',
        'snagList',
        widget.snagListRouteName,
        _fallbackSnagRoute,
        false,
      ],
      [
        Icons.menu_book_rounded,
        'Site Book',
        'Journal site entries',
        'siteBook',
        widget.siteBookRouteName,
        _fallbackSiteBookRoute,
        false,
      ],
      [
        Icons.calculate_outlined,
        'Project Cost',
        'Budget & estimates',
        'projectCost',
        widget.projectCostRouteName,
        _fallbackCostRoute,
        false,
      ],
      [
        Icons.request_quote_outlined,
        'Quotes',
        'Compare trades',
        'getQuotes',
        widget.getQuotesRouteName,
        _fallbackQuotesRoute,
        false,
      ],
    ];

    final mods = readOnly
        ? all.where((m) => _moduleVisFor(m[3] as String) == 'shared').toList()
        : all;

    if (readOnly && mods.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('No modules shared with you yet.',
            style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _rFaint)),
      );
    }

    final costKeys = {'projectCost', 'getQuotes'};
    final mgmt = mods.where((m) => !costKeys.contains(m[3])).toList();
    final cost = mods.where((m) => costKeys.contains(m[3])).toList();

    Widget tile(List<dynamic> m) => _rModTile(
          m[0] as IconData,
          m[1] as String,
          m[2] as String,
          m[3] as String,
          readOnly,
          () => _safeNavigate(m[4] as String?, fallbackRoute: m[5] as String),
          featured: m[6] as bool,
        );

    final children = <Widget>[];
    for (var i = 0; i < mgmt.length; i++) {
      children.add(tile(mgmt[i]));
      if (i != mgmt.length - 1) children.add(const SizedBox(height: 10));
    }
    if (cost.isNotEmpty) {
      if (mgmt.isNotEmpty) children.add(const SizedBox(height: 20));
      children.add(_rSectionLabel('PROJECT COST CONTROL'));
      children.add(const SizedBox(height: 10));
      for (var i = 0; i < cost.length; i++) {
        children.add(tile(cost[i]));
        if (i != cost.length - 1) children.add(const SizedBox(height: 10));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _rDocGroup(String label, int count) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: _rFaint)),
          const SizedBox(width: 6),
          Text('$count',
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _rChevron)),
        ]),
      );

  // Card that wraps a group of document rows — same visual container as the
  // drawings/documents lists in QuoteRequestView (paper, r12, hairline).
  Widget _rDocCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _rDivider)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      );

  Widget _rDocRow(
      QueryDocumentSnapshot<Map<String, dynamic>> snap, bool readOnly,
      {bool first = false}) {
    final d = snap.data();
    final title = (d['title'] ?? d['name'] ?? 'Document').toString().trim();
    final cat = _docCategory(d);
    final vis = _docVisibility(d);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDocumentRow(snap),
        child: Container(
          decoration: BoxDecoration(
              border: first
                  ? null
                  : const Border(top: BorderSide(color: Color(0xFFF2F5F6)))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(children: [
            Icon(
                cat == 'drawing'
                    ? Icons.architecture_rounded
                    : Icons.description_rounded,
                size: 22,
                color: const Color(0xFF4E504F)),
            const SizedBox(width: 11),
            Expanded(
                child: Text(title.isEmpty ? 'Document' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink))),
            if (!readOnly) ...[
              GestureDetector(
                onTap: () => _toggleDocVis(snap.reference, vis, title),
                child: _rVisChip(vis, vis == 'shared' ? _tealTint : _surface),
              ),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.open_in_new_rounded, size: 19, color: _ink),
          ]),
        ),
      ),
    );
  }

  Widget _rDocuments(bool readOnly) {
    final visible = readOnly
        ? _docRows.where((s) => _docVisibility(s.data()) == 'shared').toList()
        : _docRows;
    final drawings =
        visible.where((s) => _docCategory(s.data()) == 'drawing').toList();
    final documents =
        visible.where((s) => _docCategory(s.data()) == 'document').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _rSectionLabel('DOCUMENTS'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: _surface, // standard grey count pill
                borderRadius: BorderRadius.circular(999)),
            child: Text('${visible.length} files',
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _inkMute)),
          ),
        ]),
        if (!readOnly)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToUploadDocument,
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFAC0C0C),
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.add_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
      ]),
      if (!_docsLoadedOnce)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('Loading documents…',
              style: TextStyle(
                  fontFamily: _bodyFont, fontSize: 12, color: _rFaint)),
        )
      else if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('No documents yet.',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _rFaint)),
        )
      else ...[
        if (drawings.isNotEmpty) ...[
          _rDocGroup('Drawings', drawings.length),
          const SizedBox(height: 8),
          _rDocCard([
            for (var i = 0; i < drawings.length; i++)
              _rDocRow(drawings[i], readOnly, first: i == 0),
          ]),
        ],
        if (documents.isNotEmpty) ...[
          const SizedBox(height: 16),
          _rDocGroup('Documents', documents.length),
          const SizedBox(height: 8),
          _rDocCard([
            for (var i = 0; i < documents.length; i++)
              _rDocRow(documents[i], readOnly, first: i == 0),
          ]),
        ],
      ],
    ]);
  }

  Widget _rTeam() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _rSectionLabel('PROJECT TEAM'),
        const SizedBox(width: 8),
        Text('${_listingRows.length} members',
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _rFaint)),
      ]),
      const SizedBox(height: 6),
      if (!_listingsLoadedOnce)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Loading team…',
              style: TextStyle(
                  fontFamily: _bodyFont, fontSize: 12, color: _rFaint)),
        )
      else if (_listingRows.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('No trades or suppliers added yet.',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _rFaint)),
        )
      else
        ..._listingRows.map((s) {
          final d = s.data();
          final title = (d['title'] ?? 'Listing').toString();
          final trade = (d['subtitle'] ?? d['subTitle'] ?? d['trade'] ?? '')
              .toString()
              .trim();
          final city = (d['city'] ?? '').toString().trim();
          final province = (d['province'] ?? '').toString().trim();
          final locBits = <String>[
            if (city.isNotEmpty) city,
            if (province.isNotEmpty) province,
          ];
          final metaBits = <String>[
            if (trade.isNotEmpty) trade,
            if (locBits.isNotEmpty) locBits.join(', '),
          ];
          final meta = metaBits.join(' · ');
          final ref = _extractListingRef(d);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _rDivider, width: 1))),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (ref != null) _navigateToListing(ref);
                },
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _tealTint,
                        borderRadius: BorderRadius.circular(9)),
                    child: Text(_rInitials(title),
                        style: const TextStyle(
                            fontFamily: _displayFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _ink)),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _rFaint)),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
    ]);
  }
}

// Visual mapping for a Project Feed activity row.
class _FeedVisual {
  final IconData icon;
  final Color accent;
  final Color tint;
  final Color border;
  const _FeedVisual(this.icon, this.accent, this.tint, this.border);
}
