// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class DocumentUploadPageView extends StatefulWidget {
  const DocumentUploadPageView({
    super.key,
    this.width,
    this.height,

    /// ✅ REQUIRED: which project to attach documents to
    this.projectRef,

    /// ✅ Optional route name to return (otherwise uses safePop)
    this.backRouteName,

    /// ✅ Optional param name if you pushNamed elsewhere (default "projectRef")
    this.projectParamName,
  });

  final double? width;
  final double? height;

  final DocumentReference? projectRef;

  final String? backRouteName;
  final String? projectParamName;

  @override
  State<DocumentUploadPageView> createState() => _DocumentUploadPageViewState();
}

class _DocumentUploadPageViewState extends State<DocumentUploadPageView>
    with SingleTickerProviderStateMixin {
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
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF0D9488);
  // Status
  static const Color _live =
      Color(0xFFFF6A2B); // orange — live / paid / done / warning
  static const Color _coral = Color(0xFFE0531C);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 12;
  static const double _gap = 12;

  // Local state
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docRows = [];
  bool _docsLoadedOnce = false;
  Object? _docsErr;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _docsSub;

  bool _isUploading = false;

  String get _projectParamName =>
      (widget.projectParamName ?? 'projectRef').trim().isEmpty
          ? 'projectRef'
          : widget.projectParamName!.trim();

  // ─── Swipe-to-dismiss (follow the thumb, snap back or close) ────────
  double _dragX = 0;
  late final AnimationController _snapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<double>? _snapAnim;

  void _onDragUpdate(DragUpdateDetails d) {
    if (_snapCtrl.isAnimating) _snapCtrl.stop();
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final double w = MediaQuery.sizeOf(context).width;
    final double v = d.primaryVelocity ?? 0;
    final bool shouldClose = _dragX > w * 0.30 || v > 700;
    if (shouldClose) {
      _animateDragTo(w, then: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      });
    } else {
      _animateDragTo(0);
    }
  }

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

  @override
  void initState() {
    super.initState();
    _startDocsSub();
  }

  @override
  void didUpdateWidget(covariant DocumentUploadPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRef?.path != widget.projectRef?.path) {
      _stopDocsSub();
      _docRows = [];
      _docsLoadedOnce = false;
      _docsErr = null;
      _startDocsSub();
    }
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    _stopDocsSub();
    super.dispose();
  }

  void _stopDocsSub() {
    _docsSub?.cancel();
    _docsSub = null;
  }

  void _startDocsSub() {
    final projectRef = widget.projectRef;
    if (projectRef == null) return;

    _docsSub = FirebaseFirestore.instance
        .collection('project_documents')
        .where('projectRef', isEqualTo: projectRef)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _docsErr = null;
      _docRows = snap.docs;
      _docsLoadedOnce = true;
      if (mounted) setState(() {});
    }, onError: (e) {
      _docsErr = e;
      if (mounted) setState(() {});
    });
  }

  // -----------------------------
  // Theme helpers (match ProjectDetailPageView)
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

  // Teal accent for the page (icon chips, progress, highlights).
  Color _projectsColor(FlutterFlowTheme theme) => _teal;

  // -----------------------------
  // UI helpers (match ProjectDetailPageView)
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
    FlutterFlowTheme theme,
    Color accent,
    String title,
    String subtitle,
  ) {
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
    VoidCallback? onTap,
    VoidCallback? onMore,
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
                child: Icon(icon, size: 22, color: _paper),
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
              if (onMore != null)
                InkWell(
                  onTap: onMore,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_horiz_rounded,
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

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (t.contains('image') || t.contains('jpg') || t.contains('png')) {
      return Icons.image_outlined;
    }
    if (t.contains('doc') || t.contains('word')) return Icons.description;
    if (t.contains('xls') || t.contains('sheet')) return Icons.grid_on_outlined;
    return Icons.attach_file_rounded;
  }

  String _fileExt(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0) return '';
    return name.substring(i + 1).toLowerCase();
  }

  String _guessTypeFromName(String name) {
    final ext = _fileExt(name);
    if (ext.isEmpty) return 'File';
    return ext.toUpperCase();
  }

  // ============================================================
  // ✅ FilePicker + FirebaseStorage (NO FlutterFlow helper calls)
  // ============================================================
  Future<void> _pickAndUpload() async {
    final theme = FlutterFlowTheme.of(context);
    final accent = _projectsColor(theme);
    final projectRef = widget.projectRef;

    if (projectRef == null) return;
    if (_isUploading) return;

    FocusScope.of(context).unfocus();

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true, // ✅ ensures bytes available (web + mobile)
      );

      if (result == null || result.files.isEmpty) return;

      final f = result.files.first;
      final Uint8List? bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
                content: Text('Could not read that file. Try again.')),
          );
        return;
      }

      final rawName = (f.name.isNotEmpty ? f.name : 'document');
      final fileName = p.basename(rawName);
      final typeLabel = _guessTypeFromName(fileName);

      setState(() => _isUploading = true);

      // Storage path
      final projectId = projectRef.id;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
      final storagePath = 'projects/$projectId/documents/${ts}_$safeName';

      final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
          'application/octet-stream';

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final url = await storageRef.getDownloadURL();

      final now = Timestamp.now();
      final docRef =
          FirebaseFirestore.instance.collection('project_documents').doc();

      await docRef.set(<String, dynamic>{
        'projectRef': projectRef,
        'title': fileName,
        'type': typeLabel,
        'fileUrl': url,
        'storagePath': storagePath,
        'sizeBytes': bytes.length,
        // ✅ uploader (safe if not signed in)
        'uploadedBy': currentUserReference,
        'createdAt': now,
        'updatedAt': now,
      }.withoutNulls);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Document uploaded.')),
        );
    } catch (e) {
      debugPrint('🔥 Document upload failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _goBack() {
    final route = (widget.backRouteName ?? '').trim();
    if (route.isEmpty) {
      context.safePop();
      return;
    }

    // If they gave a specific route, go there (and pass projectRef)
    final projectRef = widget.projectRef;
    context.pushNamed(
      route,
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
          transitionType: PageTransitionType.leftToRight,
          duration: Duration(milliseconds: 220),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _projectsColor(theme);

    if (widget.projectRef == null) {
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
              accent,
              'No project selected',
              'Open this page from a Project so we know where to upload.',
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
          color: _paper,
          child: SafeArea(
            top: true,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== FIXED HEADER =====
                Container(
                  decoration: BoxDecoration(
                    color: _paper,
                    border: Border(
                      bottom: BorderSide(
                          color: _hairline.withOpacity(0.9), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 14),
                  child: Row(
                    children: [
                      _tapCard(
                        onTap: _goBack,
                        radius: BorderRadius.circular(999),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: _hairline.withOpacity(0.9)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: _inkMute,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Documents',
                              style: _appTitleStyle(theme).copyWith(
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload and manage project files.',
                              style: _appSubtitleStyle(theme),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ===== SCROLLING CONTENT =====
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, _vPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // UPLOAD CARD
                        _cardShell(
                          theme: theme,
                          colorOverride: _surface,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(_radius),
                                ),
                                child: Icon(Icons.upload_rounded,
                                    color: accent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upload a document',
                                      style: theme.bodyMedium.override(
                                        fontFamily: _bodyFont,
                                        color: _ink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'PDF, images, or other files supported by your app.',
                                      style: theme.bodySmall.override(
                                        fontFamily: _bodyFont,
                                        color: _inkMute,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _tapCard(
                                onTap: _isUploading ? null : _pickAndUpload,
                                radius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isUploading
                                        ? _hairline.withOpacity(0.4)
                                        : _ink,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isUploading) ...[
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation(_paper),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Uploading',
                                          style: theme.bodySmall.override(
                                            fontFamily: _bodyFont,
                                            color: _paper,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(Icons.add_rounded,
                                            size: 18, color: _paper),
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
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // DOCUMENT LIST
                        _sectionTitle(theme, 'Project Documents'),
                        const SizedBox(height: 10),

                        if (_docsErr != null)
                          _errorCard(
                            theme,
                            accent,
                            'Couldn’t load documents',
                            'This is usually a missing Firestore index or rules issue.',
                          )
                        else if (!_docsLoadedOnce)
                          _loadingCard(theme, accent, 'Loading documents…')
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
                                    color: accent.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(_radius),
                                  ),
                                  child: Icon(Icons.folder_open_rounded,
                                      color: accent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No documents yet.',
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
                            children: List.generate(_docRows.length, (i) {
                              final d = _docRows[i].data();

                              final title =
                                  (d['title'] ?? 'Document').toString();
                              final type = (d['type'] ?? 'File').toString();
                              final updatedAt = d['updatedAt'];
                              final when = (updatedAt is Timestamp)
                                  ? dateTimeFormat(
                                      'relative', updatedAt.toDate())
                                  : 'recently';

                              final url = (d['fileUrl'] ?? '').toString();

                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom:
                                        i == _docRows.length - 1 ? 0 : _gap),
                                child: _documentRow(
                                  theme: theme,
                                  accent: accent,
                                  title: title,
                                  subtitle: '$type • Updated $when',
                                  icon: _iconForType(type),
                                  onTap: () async {
                                    if (url.trim().isEmpty) return;
                                    await launchURL(url);
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
          ),
        ),
      ),
    );
  }
}
