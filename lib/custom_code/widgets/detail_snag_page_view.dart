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

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class DetailSnagPageView extends StatefulWidget {
  const DetailSnagPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<DetailSnagPageView> createState() => _DetailSnagPageViewState();
}

class _DetailSnagPageViewState extends State<DetailSnagPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF017374);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  static const Color _teal = Color(0xFF017374);
  static const Color _tealTint = Color(0xFFE3F4F2);
  static const Color _live = Color(0xFFE5771E);
  static const Color _coral = Color(0xFFE5771E);
  static const Color _navy = Color(0xFF1D2834);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;

  static const String _kActiveSnagPath = 'subby_active_snag_path';

  final PageController _galleryCtrl = PageController();
  int _galleryIndex = 0;

  DocumentReference? _snagRef;
  bool _resolved = false;
  bool _refLoading = true;

  bool _stampChecked = false; // read-receipt stamped at most once per open
  bool _working = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    // 1) snagRef from the route query (Snag List passes this), else prefs.
    _snagRef = _readRefFromRoute('snagRef', 'snags');
    if (_snagRef == null) {
      _loadActiveSnag();
    } else {
      _refLoading = false;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeStampReadReceipt());
    }
  }

  @override
  void dispose() {
    _galleryCtrl.dispose();
    super.dispose();
  }

  DocumentReference? _readRefFromRoute(String key, String fallbackCollection) {
    try {
      final qp = GoRouterState.of(context).uri.queryParameters;
      var s = (qp[key] ?? '').trim();
      if (s.isEmpty) return null;
      s = s.replaceAll('"', '');
      if (s.startsWith('{')) {
        final m = RegExp(r'([A-Za-z0-9_]+/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)')
            .firstMatch(s);
        if (m != null) s = m.group(1)!;
      }
      if (s.contains('/')) return FirebaseFirestore.instance.doc(s);
      return FirebaseFirestore.instance.collection(fallbackCollection).doc(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadActiveSnag() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveSnagPath) ?? '').trim();
    if (!mounted) return;
    setState(() {
      _snagRef = path.isEmpty ? null : FirebaseFirestore.instance.doc(path);
      _refLoading = false;
    });
    if (_snagRef != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeStampReadReceipt());
    }
  }

  // =========================================================
  // READ RECEIPT — stamp when the ASSIGNED LISTING's owner opens this snag.
  // =========================================================
  Future<void> _maybeStampReadReceipt() async {
    if (_stampChecked) return;
    _stampChecked = true;

    final ref = _snagRef;
    final me = currentUserReference;
    if (ref == null || me == null) return;

    try {
      final snap = await ref.get();
      final data = (snap.data() as Map<String, dynamic>? ?? {});
      if (data['readByListingAt'] != null) return;

      final listingRef = data['assignedListingRef'] as DocumentReference?;
      if (listingRef == null) return;

      final listingSnap = await listingRef.get();
      final ld = (listingSnap.data() as Map<String, dynamic>? ?? {});
      final ownerRef =
          (ld['ownerRef'] ?? ld['providerRef']) as DocumentReference?;

      if (ownerRef == null || ownerRef.path != me.path) return;

      await ref.update(<String, dynamic>{
        'readByListingAt': FieldValue.serverTimestamp(),
        'readByListingUserRef': me,
      });
    } catch (e) {
      debugPrint('⚠️ Read-receipt stamp skipped: $e');
    }
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.safePop();
    }
  }

  // =========================================================
  // Status helpers
  // =========================================================
  String _statusLabel(String s) {
    switch (s) {
      case 'in_progress':
        return 'In Progress';
      case 'closed':
        return 'Closed';
      case 'open':
      default:
        return 'Open';
    }
  }

  Color _statusColor(String s) => s == 'in_progress' ? _teal : _live;
  Color _statusTint(String s) =>
      s == 'in_progress' ? _tealTint : const Color(0x1FE5771E);

  String _severityLabel(String s) {
    switch (s) {
      case 'critical':
        return 'Critical';
      case 'major':
        return 'Major';
      case 'minor':
      default:
        return 'Minor';
    }
  }

  Color _severityColor(String s) => s == 'minor' ? _faint : _live;
  Color _severityTint(String s) =>
      s == 'minor' ? _surface : const Color(0x1FE5771E);

  Widget _softPill(String text, {required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // =========================================================
  // Status transitions
  // =========================================================
  Future<void> _setStatus(String next, {Map<String, dynamic>? extra}) async {
    final ref = _snagRef;
    if (ref == null || _working) return;
    setState(() => _working = true);
    try {
      await ref.update(<String, dynamic>{
        'status': next,
        if (next == 'in_progress') 'startedAt': FieldValue.serverTimestamp(),
        if (next == 'closed') 'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?extra,
      });
    } catch (e) {
      debugPrint('🔥 Snag status update failed: $e');
      _toast('Could not update. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pickProofAndClose() async {
    final ref = _snagRef;
    if (ref == null || _working) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _toast('Add a "fixed" photo to close this snag.');
        return;
      }
      final f = result.files.first;
      final Uint8List? bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        _toast('Could not read that photo.');
        return;
      }

      setState(() => _working = true);

      final fileName = p.basename(f.name.isNotEmpty ? f.name : 'fixed.jpg');
      final safeName = fileName.replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'snags/${ref.id}/fixed/${ts}_$safeName';
      final contentType =
          lookupMimeType(fileName, headerBytes: bytes) ?? 'image/jpeg';

      final sref = FirebaseStorage.instance.ref().child(storagePath);
      await sref.putData(bytes, SettableMetadata(contentType: contentType));
      final url = await sref.getDownloadURL();

      await ref.update(<String, dynamic>{
        'status': 'closed',
        'fixedPhotoUrl': url,
        'fixedPhotoStoragePath': storagePath,
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': currentUserReference,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) _toast('Snag closed out.');
    } catch (e) {
      debugPrint('🔥 Proof upload / close failed: $e');
      _toast('Could not close out. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: _ink,
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w700)),
      ));
  }

  // =========================================================
  // Build
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (_refLoading) {
      return _shell(
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_teal)),
          ),
        ),
      );
    }

    final ref = _snagRef;
    if (ref == null) {
      return _shell(
        child: Padding(
          padding: const EdgeInsets.all(_hPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _minBack(),
              const SizedBox(height: 18),
              const Text('No snag selected',
                  style: TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _ink)),
              const SizedBox(height: 6),
              const Text('Open this page from a snag in the list.',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _faint)),
            ],
          ),
        ),
      );
    }

    return _shell(
      child: StreamBuilder<DocumentSnapshot<Object?>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_teal)),
              ),
            );
          }
          final raw = snap.data?.data();
          final d = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          return _content(ref, d);
        },
      ),
    );
  }

  Widget _shell({required Widget child}) => Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: SafeArea(top: true, bottom: true, child: child),
      );

  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _hairline)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _inkMute),
          ),
        ),
      );

  Widget _content(DocumentReference ref, Map<String, dynamic> d) {
    final title = (d['title'] ?? 'Snag').toString();
    final description = (d['description'] ?? '').toString();
    final area = (d['area'] ?? d['room'] ?? 'Area not set').toString();
    final status = (d['status'] ?? 'open').toString();
    final severity = (d['severity'] ?? 'minor').toString();
    final listingName =
        (d['assignedListingName'] ?? d['assignedToName'] ?? '').toString();
    final createdByName = (d['createdByName'] ?? '').toString();

    final media = <Map<String, dynamic>>[];
    final rawMedia = d['media'];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map) media.add(Map<String, dynamic>.from(m));
      }
    }
    if (media.isEmpty) {
      final single = (d['photoUrl'] ?? '').toString();
      if (single.isNotEmpty) media.add({'url': single, 'type': 'image'});
    }

    final due = _asDate(d['dueDate']);
    final createdAt = _asDate(d['createdAt']);
    final readAt = _asDate(d['readByListingAt']);

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_hPad, 6, _hPad, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _minBack(),
                  Row(
                    children: [
                      _iconBtn(Icons.ios_share_rounded, _inkMute, () {}),
                      const SizedBox(width: 4),
                      _iconBtn(Icons.delete_outline_rounded, _coral,
                          () => _confirmDelete(ref)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _gallery(media),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.1,
                      color: _navy)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _softPill(_statusLabel(status),
                      fg: _statusColor(status), bg: _statusTint(status)),
                  const SizedBox(width: 8),
                  _softPill(_severityLabel(severity),
                      fg: _severityColor(severity),
                      bg: _severityTint(severity)),
                ],
              ),
              const SizedBox(height: 14),
              _metaRow(
                leading:
                    const Icon(Icons.place_outlined, size: 19, color: _faint),
                title: area,
                trailingLabel: 'Area',
              ),
              _assignedRow(listingName, readAt),
              _metaRow(
                leading: const Icon(Icons.calendar_month_outlined,
                    size: 19, color: _faint),
                title: due == null
                    ? 'No due date'
                    : dateTimeFormat('d MMM y', due),
                trailingLabel: _dueHint(due, status),
                trailingColor: _dueColor(due, status),
              ),
              _metaRow(
                leading:
                    const Icon(Icons.person_outline, size: 19, color: _faint),
                title: createdByName.isEmpty ? 'Logged' : createdByName,
                trailingLabel: createdAt == null
                    ? 'Logged'
                    : dateTimeFormat('d MMM', createdAt),
                divider: false,
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(description,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: _inkMute)),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _closeOutDock(status),
        ),
      ],
    );
  }

  // ---- Gallery ----
  Widget _gallery(List<Map<String, dynamic>> media) {
    if (media.isEmpty) {
      return Container(
        height: 188,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairlineOnSurface),
        ),
        child: const Center(
          child: Icon(Icons.photo_camera_outlined, size: 28, color: _faint),
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            height: 188,
            decoration: BoxDecoration(
              border: Border.all(color: _hairlineOnSurface),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _galleryCtrl,
                  itemCount: media.length,
                  onPageChanged: (i) => setState(() => _galleryIndex = i),
                  itemBuilder: (context, i) {
                    final m = media[i];
                    final url = (m['url'] ?? '').toString();
                    final isVideo = (m['type'] ?? 'image') == 'video';
                    return Container(
                      color: _surface,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (url.isNotEmpty)
                            Image.network(url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        color: _faint, size: 26))),
                          if (isVideo)
                            const Center(
                              child: Icon(Icons.play_circle_fill_rounded,
                                  size: 44, color: Colors.white),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (media.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x8C0D141C),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${_galleryIndex + 1} / ${media.length}',
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _paper)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (media.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < media.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _thumb(media[i], i),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _thumb(Map<String, dynamic> m, int i) {
    final url = (m['url'] ?? '').toString();
    final isVideo = (m['type'] ?? 'image') == 'video';
    final selected = i == _galleryIndex;
    return GestureDetector(
      onTap: () {
        _galleryCtrl.animateToPage(i,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
              color: selected ? _teal : _hairlineOnSurface,
              width: selected ? 2 : 1),
          image: (url.isNotEmpty)
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
        ),
        child: isVideo
            ? const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 18, color: Colors.white))
            : null,
      ),
    );
  }

  // ---- Meta rows ----
  Widget _metaRow({
    required Widget leading,
    required String title,
    String? trailingLabel,
    Color? trailingColor,
    bool divider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _hairline, width: 1)))
          : null,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
          ),
          if (trailingLabel != null && trailingLabel.isNotEmpty)
            Text(trailingLabel,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trailingColor ?? _faint)),
        ],
      ),
    );
  }

  Widget _assignedRow(String name, DateTime? readAt) {
    final has = name.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline, width: 1))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: has ? _tealTint : _surface,
                borderRadius: BorderRadius.circular(9)),
            child: has
                ? Text(_initials(name),
                    style: const TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _ink))
                : const Icon(Icons.handyman_outlined, size: 17, color: _faint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(has ? name : 'Unassigned',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _navy)),
                const SizedBox(height: 2),
                Text(has ? 'Assigned listing' : 'Assign from the form',
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: _faint)),
                // ── READ RECEIPT ──
                if (readAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.done_all_rounded,
                          size: 14, color: _teal),
                      const SizedBox(width: 5),
                      Text(
                        'Read ${dateTimeFormat('d MMM · HH:mm', readAt)}',
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _teal),
                      ),
                    ],
                  ),
                ] else if (has) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.remove_done_rounded,
                          size: 14, color: _faint),
                      const SizedBox(width: 5),
                      const Text('Not read yet',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _faint)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 19, color: Color(0xFFC7D0DA)),
        ],
      ),
    );
  }

  // ---- Close-out dock ----
  Widget _closeOutDock(String status) {
    return Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: _hairline, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepper(status),
            const SizedBox(height: 12),
            _primaryAction(status),
            if (status == 'in_progress') ...[
              const SizedBox(height: 8),
              const Text('Add a “fixed” photo to close this snag out',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _faint)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepper(String status) {
    final idx = status == 'closed'
        ? 2
        : status == 'in_progress'
            ? 1
            : 0;
    Widget node(String label, int i) {
      final done = i <= idx;
      final color = i == 0 ? _live : _teal;
      return Text(label,
          style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? color : const Color(0xFFC7D0DA)));
    }

    Widget bar(bool active) => Expanded(
          child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: active ? _teal : _hairline),
        );

    return Row(
      children: [
        Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: idx >= 0 ? _live : const Color(0xFFC7D0DA),
                shape: BoxShape.circle)),
        node('Open', 0),
        bar(idx >= 1),
        node('In Progress', 1),
        bar(idx >= 2),
        node('Closed', 2),
      ],
    );
  }

  Widget _primaryAction(String status) {
    String label;
    IconData icon;
    VoidCallback onTap;
    Color bg = _teal;

    switch (status) {
      case 'open':
        label = 'Move to In Progress';
        icon = Icons.play_arrow_rounded;
        onTap = () => _setStatus('in_progress');
        break;
      case 'in_progress':
        label = 'Mark as Fixed';
        icon = Icons.task_alt_rounded;
        onTap = _pickProofAndClose;
        break;
      case 'closed':
      default:
        label = 'Reopen Snag';
        icon = Icons.replay_rounded;
        bg = _surface;
        onTap = () => _setStatus('open', extra: {'fixedPhotoUrl': null});
        break;
    }

    final isGhost = status == 'closed';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _working ? null : onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Opacity(
          opacity: _working ? 0.7 : 1,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_radius),
              border: isGhost ? Border.all(color: _hairlineOnSurface) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_working)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isGhost ? _ink : _paper)),
                  )
                else
                  Icon(icon, size: 20, color: isGhost ? _ink : _paper),
                const SizedBox(width: 9),
                Text(label,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isGhost ? _ink : _paper)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 21, color: color),
          ),
        ),
      );

  Future<void> _confirmDelete(DocumentReference ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _hairline, width: 1),
        ),
        title: const Text('Delete snag?',
            style: TextStyle(
                fontFamily: _displayFont,
                color: _ink,
                fontWeight: FontWeight.w900)),
        content: const Text('This permanently removes the snag.',
            style: TextStyle(
                fontFamily: _bodyFont, color: _inkMute, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    color: _inkMute,
                    fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.delete();
                if (mounted) _handleBack();
              } catch (e) {
                _toast('Could not delete.');
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    color: _coral,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // ---- helpers ----
  DateTime? _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _dueHint(DateTime? due, String status) {
    if (due == null) return '';
    if (status == 'closed') return 'Closed';
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days < 0) return 'Overdue ${-days}d';
    if (days == 0) return 'Due today';
    return 'Due in ${days}d';
  }

  Color _dueColor(DateTime? due, String status) {
    if (due == null || status == 'closed') return _faint;
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return days <= 3 ? _live : _faint;
  }
}
