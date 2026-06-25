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

class _DocumentUploadPageViewState extends State<DocumentUploadPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF323F4D);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF323F4D);
  // Status
  static const Color _live =
      Color(0xFFC7E87A); // orange — live / paid / done / warning
  static const Color _coral = Color(0xFFC7E87A);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;
  static const double _gap = 12;

  // Local state
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docRows = [];
  bool _docsLoadedOnce = false;
  Object? _docsErr;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _docsSub;

  bool _isUploading = false;

  // ✅ New-upload selectors — written onto each uploaded document.
  String _newCat = 'drawing'; // 'drawing' | 'document'
  String _newVis = 'private'; // 'shared'  | 'private'

  String get _projectParamName =>
      (widget.projectParamName ?? 'projectRef').trim().isEmpty
          ? 'projectRef'
          : widget.projectParamName!.trim();

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
  // Typography (Option C — minimal underline)
  // -----------------------------
  TextStyle _appSubtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
      );

  TextStyle _helperStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
      );

  // Uppercase micro-label above each section.
  TextStyle _uLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  Color _projectsColor(FlutterFlowTheme theme) => _teal;

  // -----------------------------
  // Underline UI helpers
  // -----------------------------
  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _hairline, width: 1)),
  );

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

  // Full-width ink upload button (with Uploading spinner state).
  Widget _uploadButton(FlutterFlowTheme theme) {
    return _tapCard(
      onTap: _isUploading ? null : _pickAndUpload,
      radius: BorderRadius.circular(999),
      child: Opacity(
        opacity: _isUploading ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(_paper),
                    ),
                  ),
                )
              else
                const Icon(Icons.upload_file_rounded, size: 18, color: _paper),
              const SizedBox(width: 8),
              Text(
                _isUploading ? 'Uploading…' : 'Upload document',
                style: theme.bodyMedium.override(
                  fontFamily: _bodyFont,
                  color: _paper,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hairline-divided document row.
  // Category of a document row (drawing vs document/image).
  String _docCategory(Map<String, dynamic> d) {
    final c = (d['category'] ?? d['cat'] ?? '').toString().toLowerCase();
    if (c.contains('draw') || c.contains('plan')) return 'drawing';
    return 'document';
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

  // ✅ Delete document (Firestore record + Storage file)
  Future<void> _deleteDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    final data = snap.data();
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
        final url = (data['fileUrl'] ?? data['url'])?.toString().trim();
        if (url != null && url.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (e) {
            debugPrint('⚠️ Storage delete skipped/failed for url: $e');
          }
        }
      }

      // Delete the Firestore record (this is what removes it from the list).
      await snap.reference.delete();

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

  // Segmented pill used by the new-upload selectors.
  Widget _segPill(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? _paper : _inkMute),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.labelSmall.override(
                fontFamily: _bodyFont,
                color: selected ? _paper : _inkMute,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorRow(
      FlutterFlowTheme theme, String label, List<Widget> pills) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.bodySmall.override(
                fontFamily: _bodyFont,
                color: _inkMute,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(mainAxisSize: MainAxisSize.min, children: pills),
          ),
        ],
      ),
    );
  }

  // The document list, grouped Drawings / Documents (+ Images).
  Widget _uDocsByCategory(FlutterFlowTheme theme, Color accent) {
    final drawings =
        _docRows.where((s) => _docCategory(s.data()) == 'drawing').toList();
    final documents =
        _docRows.where((s) => _docCategory(s.data()) == 'document').toList();

    Widget rowFor(QueryDocumentSnapshot<Map<String, dynamic>> snap) {
      final d = snap.data();
      final title = (d['title'] ?? 'Document').toString();
      final type = (d['type'] ?? 'File').toString();
      final updatedAt = d['updatedAt'];
      final when = (updatedAt is Timestamp)
          ? dateTimeFormat('d MMM y · HH:mm', updatedAt.toDate())
          : 'recently';
      final url = (d['fileUrl'] ?? '').toString();
      final vis =
          (d['visibility'] ?? 'private').toString().toLowerCase() == 'shared'
              ? 'shared'
              : 'private';
      return _uDocRow(
        theme: theme,
        accent: accent,
        title: title,
        subtitle: when,
        icon: _iconForType(type),
        visibility: vis,
        onToggleVisibility: () => _toggleDocVis(snap.reference, vis),
        onTap: () async {
          if (url.trim().isEmpty) return;
          await launchURL(url);
        },
        onDelete: () => _deleteDoc(snap),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (drawings.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text('DRAWINGS', style: _uLabelStyle(theme)),
          ),
          ...drawings.map(rowFor),
        ],
        if (documents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 2),
            child: Text('DOCUMENTS / IMAGES', style: _uLabelStyle(theme)),
          ),
          ...documents.map(rowFor),
        ],
      ],
    );
  }

  Widget _uDocRow({
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
      radius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _uRule,
        child: Row(
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(width: 14),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'UPDATED',
                    style: theme.labelSmall.override(
                      fontFamily: _bodyFont,
                      color: const Color(0xFF93A0B0),
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
              InkWell(
                onTap: onToggleVisibility,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: visibility == 'shared'
                        ? const Color(0xFFEEF7D6)
                        : _surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        visibility == 'shared'
                            ? Icons.visibility_outlined
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: visibility == 'shared' ? _teal : _inkMute,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        visibility == 'shared' ? 'Shared' : 'Private',
                        style: theme.labelSmall.override(
                          fontFamily: _bodyFont,
                          color: visibility == 'shared' ? _teal : _inkMute,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ] else
              const SizedBox(width: 14),
            if (onDelete != null)
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
    );
  }

  Widget _stateRow(
    FlutterFlowTheme theme,
    Color accent,
    IconData icon,
    String title,
    String? subtitle, {
    bool spinner = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _uRule,
      child: Row(
        children: [
          if (spinner)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            )
          else
            Icon(icon, size: 22, color: accent),
          const SizedBox(width: 14),
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
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: _helperStyle(theme)),
                ],
              ],
            ),
          ),
        ],
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
        // ✅ categorisation + visibility chosen in the selectors above.
        'category': _newCat,
        'visibility': _newVis,
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
            child: _stateRow(
              theme,
              _coral,
              Icons.error_outline,
              'No project selected',
              'Open this page from a Project so we know where to upload.',
            ),
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // ✅ OPTION C — MINIMAL UNDERLINE
    // ---------------------------------------------------------
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TOP ROW: back =====
              Row(
                children: [
                  _tapCard(
                    onTap: _goBack,
                    radius: BorderRadius.circular(999),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: _hairline.withOpacity(0.9)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: _inkMute),
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 20),

              // ===== TITLE =====
              Text(
                'Documents',
                style: theme.titleLarge.override(
                  fontFamily: _displayFont,
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  lineHeight: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload and manage project files.',
                style: _appSubtitleStyle(theme).copyWith(fontSize: 13),
              ),

              const SizedBox(height: 24),

              // ===== NEW-UPLOAD SELECTORS =====
              _selectorRow(theme, 'New file type', [
                _segPill(
                  theme,
                  icon: Icons.architecture_rounded,
                  label: 'Drawings',
                  selected: _newCat == 'drawing',
                  onTap: () => setState(() => _newCat = 'drawing'),
                ),
                _segPill(
                  theme,
                  icon: Icons.description_rounded,
                  label: 'Docs / Images',
                  selected: _newCat == 'document',
                  onTap: () => setState(() => _newCat = 'document'),
                ),
              ]),
              _selectorRow(theme, 'New upload visibility', [
                _segPill(
                  theme,
                  icon: Icons.visibility_outlined,
                  label: 'Shared',
                  selected: _newVis == 'shared',
                  onTap: () => setState(() => _newVis = 'shared'),
                ),
                _segPill(
                  theme,
                  icon: Icons.lock_outline_rounded,
                  label: 'Private',
                  selected: _newVis == 'private',
                  onTap: () => setState(() => _newVis = 'private'),
                ),
              ]),

              // ===== UPLOAD =====
              _uploadButton(theme),
              const SizedBox(height: 10),
              Text(
                _newVis == 'shared'
                    ? 'New files will be visible to listings on this project.'
                    : 'New files stay private until you choose to share them.',
                style: _helperStyle(theme),
              ),

              const SizedBox(height: 28),

              // ===== DOCUMENT LIST =====
              Text('PROJECT DOCUMENTS', style: _uLabelStyle(theme)),
              const SizedBox(height: 4),

              if (_docsErr != null)
                _stateRow(
                  theme,
                  _coral,
                  Icons.error_outline,
                  'Couldn’t load documents',
                  'This is usually a missing Firestore index or rules issue.',
                )
              else if (!_docsLoadedOnce)
                _stateRow(theme, accent, Icons.hourglass_empty_rounded,
                    'Loading documents…', null,
                    spinner: true)
              else if (_docRows.isEmpty)
                _stateRow(
                  theme,
                  accent,
                  Icons.folder_open_rounded,
                  'No documents yet.',
                  'Upload PDFs, images, and files linked to this project.',
                )
              else
                _uDocsByCategory(theme, accent),
            ],
          ),
        ),
      ),
    );
  }
}
