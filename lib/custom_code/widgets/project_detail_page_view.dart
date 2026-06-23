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

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle (white status bar over the dark hero)

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
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — TEAL.
  static const Color _spark = Color(0xFF017374); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFFFFFFFF);
  static const Color _teal = Color(0xFF017374);
  static const Color _tealBright = Color(0xFFFEB518); // icon on ink chips
  static const Color _tealTint = Color(0xFFE3F4F2); // pill / chip fill
  static const Color _tealText = Color(0xFF017374); // pill text
  static const Color _tealSurface = Color(0xFFF0FAF8); // tinted module card
  static const Color _tealSurfaceBorder = Color(0xFFD3ECE8);
  // Status
  static const Color _live =
      Color(0xFFE5771E); // orange — live / open-now / warning
  static const Color _coral = Color(0xFFE5771E);
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

  // Fallback route names (update if your FF routes differ)
  static const String _fallbackEditRoute = 'editProjectPage';
  static const String _fallbackTimelineRoute = 'timelinePage';
  static const String _fallbackCostRoute = 'projectCostPage';
  static const String _fallbackQuotesRoute = 'quotesPage';
  static const String _fallbackSnagRoute = 'snagListPage';
  static const String _fallbackToDoRoute = 'toDoListPage';
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
          const SnackBar(content: Text('Document deleted.')),
        );
    } catch (e) {
      debugPrint('🔥 Failed deleting project_documents doc: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not delete document.')),
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
                color: _paper,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listingTitle,
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
                    _actionModuleRow(
                      theme: theme,
                      icon: Icons.delete_outline_rounded,
                      iconColor: _coral,
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

  void _showRemoveDocumentSheet({
    required FlutterFlowTheme theme,
    required Color accent,
    required String documentTitle,
    required QueryDocumentSnapshot<Map<String, dynamic>> docSnap,
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
                color: _paper,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            documentTitle,
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
                    _actionModuleRow(
                      theme: theme,
                      icon: Icons.delete_outline_rounded,
                      iconColor: _coral,
                      title: 'Delete document',
                      subtitle:
                          'Permanently removes this document and its file.',
                      destructive: true,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _removeProjectDocument(docSnap);
                      },
                    ),
                    const SizedBox(height: 10),
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
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White status-bar icons (time, signal, battery) over the dark ink hero.
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: _ink),
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 8, _hPad, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tapCard(
                  onTap: () => context.safePop(),
                  radius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: _paper),
                  ),
                ),
                const Spacer(),
                _tapCard(
                  onTap: () => _safeNavigate(
                    widget.editProjectRouteName,
                    fallbackRoute: _fallbackEditRoute,
                  ),
                  radius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFE5771E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 18, color: _paper),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: theme.bodySmall.override(
                            fontFamily: _bodyFont,
                            color: _paper,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'PROJECT',
              style: theme.labelSmall.override(
                fontFamily: _bodyFont,
                color: _tealBright,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.titleLarge.override(
                fontFamily: _displayFont,
                color: _paper,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                lineHeight: 1.08,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _tealBright.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _tealBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: theme.labelSmall.override(
                      fontFamily: _bodyFont,
                      color: _tealBright,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.white.withOpacity(0.55)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall.override(
                      fontFamily: _bodyFont,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              dates,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall.override(
                fontFamily: _bodyFont,
                color: Colors.white.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
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
            valueColor: _tealText,
            bg: _tealSurface,
            border: _tealSurfaceBorder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            theme: theme,
            value: budget,
            label: 'Budget',
            valueColor: _ink,
            bg: _surface,
            border: _hairline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            theme: theme,
            value: snags,
            label: 'Open snags',
            valueColor: _coral,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: border.withOpacity(0.9)),
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
              color: _inkMute,
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

  String _moduleVisFor(String key) => _moduleVisMap()[key] ?? 'private';

  Future<void> _toggleModuleVis(String key) async {
    final ref = widget.projectRef;
    if (ref == null) return;
    final next = _moduleVisFor(key) == 'shared' ? 'private' : 'shared';

    // Optimistic local update so the icon flips immediately.
    final mv = _moduleVisMap()..[key] = next;
    _projectData = Map<String, dynamic>.from(_projectData)
      ..['moduleVisibility'] = mv;
    if (mounted) setState(() {});

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
    String current,
  ) async {
    final next = current == 'shared' ? 'private' : 'shared';
    try {
      await ref.update(<String, dynamic>{
        'visibility': next,
        'updatedAt': Timestamp.now(),
      });
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
            color: shared ? _tealTint : _surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            shared ? Icons.visibility_outlined : Icons.lock_outline_rounded,
            size: 16,
            color: shared ? _teal : _inkMute,
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

  List<Widget> _docRowWidgets(
    FlutterFlowTheme theme,
    Color accent,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rows,
  ) {
    return List.generate(rows.length, (i) {
      final docSnap = rows[i];
      final d = docSnap.data();
      final title = (d['title'] ?? d['name'] ?? 'Document').toString().trim();
      final type = (d['type'] ?? d['fileType'] ?? 'File').toString().trim();
      final updatedAt = d['updatedAt'] ?? d['createdAt'];
      final when = (updatedAt is Timestamp)
          ? dateTimeFormat('relative', updatedAt.toDate())
          : 'recently';
      final vis = _docVisibility(d);
      final cat = _docCategory(d);
      return Padding(
        padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : _gap),
        child: _documentRow(
          theme: theme,
          accent: accent,
          title: title.isEmpty ? 'Document' : title,
          subtitle: '$type • Updated $when',
          icon: _docCategoryIcon(cat),
          visibility: vis,
          onToggleVisibility: () => _toggleDocVis(docSnap.reference, vis),
          onTap: () => _openDocumentRow(docSnap),
          onDelete: () {
            FocusScope.of(context).unfocus();
            _showRemoveDocumentSheet(
              theme: theme,
              accent: accent,
              documentTitle: title.isEmpty ? 'Document' : title,
              docSnap: docSnap,
            );
          },
        ),
      );
    });
  }

  // Documents grouped into Drawings / Documents (+ Images).
  Widget _docsByCategory(FlutterFlowTheme theme, Color accent) {
    final drawings =
        _docRows.where((s) => _docCategory(s.data()) == 'drawing').toList();
    final documents =
        _docRows.where((s) => _docCategory(s.data()) == 'document').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drawings.isNotEmpty) ...[
          _docGroupLabel(theme, 'DRAWINGS'),
          ..._docRowWidgets(theme, accent, drawings),
          if (documents.isNotEmpty) const SizedBox(height: 16),
        ],
        if (documents.isNotEmpty) ...[
          _docGroupLabel(theme, 'DOCUMENTS / IMAGES'),
          ..._docRowWidgets(theme, accent, documents),
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
  }) {
    return _tapCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _tealSurface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _tealSurfaceBorder),
        ),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _teal,
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
                      color: _ink,
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
              _visToggle(visibility: visibility, onTap: onToggleVisibility),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: Color(0xFFCDD6E2)),
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
                child: Icon(icon, size: 22, color: _tealBright),
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
                  ],
                ),
              ),
              if (visibility != null && onToggleVisibility != null) ...[
                const SizedBox(width: 6),
                _visToggle(visibility: visibility, onTap: onToggleVisibility),
              ],
              const SizedBox(width: 6),
              Icon(Icons.open_in_new_rounded, size: 18, color: _inkMute),
              if (onDelete != null) ...[
                const SizedBox(width: 2),
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
                    size: 22, color: _tealBright),
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

    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== INK HERO MASTHEAD (fixed) =====
          _inkHero(
            theme: theme,
            topInset: topInset,
            name: projectName,
            status: projectStatus,
            address: projectAddress,
            dates: projectDates,
          ),
          // ===== SCROLLING CONTENT =====
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  EdgeInsets.fromLTRB(_hPad, 18, _hPad, _vPad + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================================
                  // 1) STAT STRIP
                  // ============================================================
                  _statStrip(
                    theme: theme,
                    days: daysLeftLabel,
                    budget: budgetLabel,
                    snags: snagLabel,
                  ),

                  const SizedBox(height: 22),

                  // ============================================================
                  // 2) PROJECT MODULE LINKS
                  // ============================================================
                  _sectionTitle(theme, 'Manage'),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _moduleRow(
                        theme: theme,
                        icon: Icons.timeline_rounded,
                        title: 'Timeline',
                        subtitle: 'Programme & phases',
                        visibility: _moduleVisFor('timeline'),
                        onToggleVisibility: () => _toggleModuleVis('timeline'),
                        onTap: () => _safeNavigate(
                          widget.timelineRouteName,
                          fallbackRoute: _fallbackTimelineRoute,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _moduleRow(
                        theme: theme,
                        icon: Icons.calculate_outlined,
                        title: 'Project Cost',
                        subtitle: 'Budget & estimates',
                        visibility: _moduleVisFor('projectCost'),
                        onToggleVisibility: () =>
                            _toggleModuleVis('projectCost'),
                        onTap: () => _safeNavigate(
                          widget.projectCostRouteName,
                          fallbackRoute: _fallbackCostRoute,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _moduleRow(
                        theme: theme,
                        icon: Icons.request_quote_outlined,
                        title: 'Get Quotes',
                        subtitle: 'Compare trades',
                        visibility: _moduleVisFor('getQuotes'),
                        onToggleVisibility: () => _toggleModuleVis('getQuotes'),
                        onTap: () => _safeNavigate(
                          widget.getQuotesRouteName,
                          fallbackRoute: _fallbackQuotesRoute,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _moduleRow(
                        theme: theme,
                        icon: Icons.fact_check_outlined,
                        title: 'Snag List',
                        subtitle: 'Defects & fixes',
                        visibility: _moduleVisFor('snagList'),
                        onToggleVisibility: () => _toggleModuleVis('snagList'),
                        onTap: () => _safeNavigate(
                          widget.snagListRouteName,
                          fallbackRoute: _fallbackSnagRoute,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _moduleRow(
                        theme: theme,
                        icon: Icons.checklist_rounded,
                        title: 'To-Do List',
                        subtitle: 'Tasks & reminders',
                        visibility: _moduleVisFor('toDo'),
                        onToggleVisibility: () => _toggleModuleVis('toDo'),
                        onTap: () => _safeNavigate(
                          widget.toDoListRouteName,
                          fallbackRoute: _fallbackToDoRoute,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ============================================================
                  // 3) DOCUMENTS
                  // ============================================================
                  Row(
                    children: [
                      Expanded(child: _sectionTitle(theme, 'Documents')),
                      _uploadDocButton(theme, projectsAccent),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                      colorOverride: _surface,
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
                                    fontFamily: _bodyFont,
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Upload PDFs, images, and files linked to this project.',
                                  style: theme.bodySmall.override(
                                    fontFamily: _bodyFont,
                                    color: _inkMute,
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
                                  color: _paper, size: 18),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _docsByCategory(theme, projectsAccent),

                  const SizedBox(height: 22),

                  // ============================================================
                  // 4) LISTINGS
                  // ============================================================
                  _sectionTitle(theme, 'Listings Added to Project'),
                  const SizedBox(height: 12),

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
                      colorOverride: _surface,
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
                                fontFamily: _bodyFont,
                                color: _ink,
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
                            subtitle:
                                subtitle.trim().isNotEmpty ? subtitle : '—',
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
                                          fontFamily: _bodyFont,
                                          color: _paper,
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
        ],
      ),
    );
  }
}
