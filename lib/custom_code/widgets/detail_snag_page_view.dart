// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'dart:typed_data';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle (white status-bar icons over the ink hero)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/actions/index.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

// ─────────────────────────────────────────────────────────────────────
// UPDATE (this revision):
//   • EDITING REMOVED — there is no Edit button anymore (snags aren't edited
//     after logging). The `editSnagRouteName` param and `_openEdit` are gone.
//     Only the owner-gated Delete remains in the header.
//   • CLOSE-OUT NOW TAKES MULTIPLE FIX MEDIA — the proof-of-fix is no longer a
//     single photo. The user can attach one OR MANY photos *and* videos. Stored
//     as `fixedMedia` (a List of {url, type, storagePath}); `fixedPhotoUrl` is
//     still written (first image) for back-compat with the Snag List thumbnail.
//     Close-out is gated on at least one fix item.
//   • THE FIX MEDIA SHOW IN THE MAIN GALLERY — the detail's main photo gallery
//     now contains the defect photos AND the fix media (tagged with a green
//     "FIX" badge + green-bordered thumbnail), so the user can swipe/tap to
//     view every fix photo/video in the main viewer. The old before/after
//     strip is removed in favour of this unified gallery.
// ─────────────────────────────────────────────────────────────────────

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
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _teal = Color(0xFF1E282E);
  static const Color _tealTint =
      Color(0xFFECF0F2); // DS: lime tint → neutral surface
  static const Color _live =
      Color(0xFF566670); // DS: lime → clay (high / attention)
  static const Color _green =
      Color(0xFF0CAC47); // success green — mirrors _warn
  static const Color _greenSurface = Color(0xFFE7EDF0);
  static const Color _greenBorder = Color(0xFFCBD8DD);
  static const Color _coral = Color(0xFF566670);
  static const Color _warn =
      Color(0xFFAC0C0C); // delete-dialog red (matches DetailTaskPageView)
  static const Color _navy = Color(0xFF1E282E);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 10;

  static const String _kActiveSnagPath = 'subby_active_snag_path';

  final PageController _galleryCtrl = PageController();
  int _galleryIndex = 0;

  DocumentReference? _snagRef;
  bool _resolved = false;
  bool _refLoading = true;

  bool _stampDone = false; // read-receipt conclusively handled — stop retrying
  bool _stampInFlight = false; // a stamp attempt is currently awaiting
  bool _working = false;

  // ── CLOSE-OUT GATE ──
  // One or more proof-of-fix photos/videos are MANDATORY before a snag can
  // move to "closed". Each entry: { url, type ('image'|'video'), storagePath }.
  final List<Map<String, dynamic>> _fixedMedia = [];
  bool _uploadingFixed = false;
  bool _seededFromDoc = false; // prefill _fixedMedia from a closed snag once

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
  }

  // =========================================================
  // READ RECEIPT — stamp when the ASSIGNED listing's owner views this snag.
  //
  // Driven by the live StreamBuilder snapshot rather than a one-shot
  // first-frame callback: the doc data is already in hand (no extra read), and
  // the attempt is retried on each snapshot until it conclusively succeeds or
  // proves the viewer isn't the owner. A transient auth-not-ready state
  // (currentUserReference still null on a cold open / deep-link) or a network
  // blip no longer permanently suppresses the receipt — it simply retries on
  // the next snapshot.
  // =========================================================
  Future<void> _maybeStampReadReceipt(
      DocumentReference ref, Map<String, dynamic> data) async {
    if (_stampDone || _stampInFlight) return;
    _stampInFlight = true;
    try {
      if (data['readByListingAt'] != null) {
        _stampDone = true; // already stamped by someone — stop trying
        return;
      }
      final me = currentUserReference;
      if (me == null) return; // auth not ready yet — retry on next snapshot

      // Prefer the owner ref stored on the snag at assign time (reliable, and
      // what the security rules gate on).
      DocumentReference? ownerRef =
          data['assignedListingOwnerRef'] as DocumentReference?;

      // Back-compat: snags created before assignedListingOwnerRef existed —
      // resolve the owner live from the assigned listing.
      if (ownerRef == null) {
        final listingRef = data['assignedListingRef'] as DocumentReference?;
        if (listingRef != null) {
          ownerRef = await _resolveListingOwner(listingRef);
        }
      }

      // Only the ASSIGNED listing's owner stamps the receipt.
      if (ownerRef == null || ownerRef.path != me.path) {
        _stampDone = true; // not the owner (auth present) — never stamp
        return;
      }

      await ref.update(<String, dynamic>{
        'readByListingAt': FieldValue.serverTimestamp(),
        'readByListingUserRef': me,
      });
      _stampDone = true;
    } catch (e) {
      debugPrint('⚠️ Read-receipt stamp skipped: $e');
      // _stampDone stays false → a later snapshot retries.
    } finally {
      _stampInFlight = false;
    }
  }

  // Resolves the listing OWNER's user ref from an assigned-listing ref, whether
  // that ref points at a subby_listings doc (has ownerRef) or a project_listings
  // doc (only has listingRef → follow it to the subby_listings doc).
  Future<DocumentReference?> _resolveListingOwner(
      DocumentReference listingRef) async {
    try {
      final snap = await listingRef.get();
      final d = (snap.data() as Map<String, dynamic>? ?? {});
      final owner = (d['ownerRef'] ?? d['providerRef']) as DocumentReference?;
      if (owner != null) return owner;

      // assignedListingRef was a project_listings doc → follow listingRef.
      final inner = d['listingRef'] as DocumentReference?;
      if (inner != null) {
        final innerSnap = await inner.get();
        final id = (innerSnap.data() as Map<String, dynamic>? ?? {});
        return (id['ownerRef'] ?? id['providerRef']) as DocumentReference?;
      }
    } catch (e) {
      debugPrint('⚠️ resolve listing owner failed: $e');
    }
    return null;
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.safePop();
    }
  }

  // ✅ Delete is gated to the PROJECT OWNER (team members can add, not delete).
  //    Resolved once from the snag's projectRef → project.ownerRef.
  DocumentReference? _projectOwnerRef;
  bool _projectOwnerResolved = false;

  Future<void> _ensureProjectOwner(Map<String, dynamic> d) async {
    if (_projectOwnerResolved) return;
    final projRef = d['projectRef'] as DocumentReference?;
    if (projRef == null) {
      _projectOwnerResolved = true;
      return;
    }
    try {
      final snap = await projRef.get();
      final pd = (snap.data() as Map<String, dynamic>? ?? <String, dynamic>{});
      final owner = pd['ownerRef'];
      _projectOwnerResolved = true;
      if (owner is DocumentReference) {
        _projectOwnerRef = owner;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('⚠️ resolve project owner failed: $e');
    }
  }

  // ✅ Only the project owner may delete this snag. (Gates Delete.)
  bool _isOwner(Map<String, dynamic> d) {
    final me = currentUserReference;
    if (me == null || _projectOwnerRef == null) return false;
    return _projectOwnerRef!.path == me.path;
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

  Color _statusColor(String s) {
    switch (s) {
      case 'in_progress':
        return _paper; // white on solid green
      case 'closed':
        return _faint; // done — neutral
      case 'open':
      default:
        return _ink;
    }
  }

  Color _statusTint(String s) {
    switch (s) {
      case 'in_progress':
        return _ink; // solid ink fill (matches In Progress text)
      case 'closed':
        return _surface;
      case 'open':
      default:
        return _tealTint; // neutral surface
    }
  }

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

  // Critical = clay; major = ink; minor = faint.
  Color _severityColor(String s) => s == 'critical'
      ? const Color(0xFFAC0C0C)
      : (s == 'minor' ? _faint : _ink);
  Color _severityTint(String s) =>
      s == 'critical' ? const Color(0x1AAC0C0C) : _surface;

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
      if (mounted) _toast('Snag updated.');
    } catch (e) {
      debugPrint('🔥 Snag status update failed: $e');
      _toast('Could not update. Please try again.', success: false);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  // ── Pick + upload one OR MANY proof-of-fix photos/videos. Does NOT close on
  //    its own — it arms the gate so "Mark as Fixed" can run.
  Future<void> _pickFixedMedia() async {
    final ref = _snagRef;
    if (ref == null || _uploadingFixed || _working) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media, // images + videos
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploadingFixed = true);

      for (final f in result.files) {
        final Uint8List? bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;

        final fileName = p.basename(f.name.isNotEmpty ? f.name : 'fixed');
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
        final ts = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'snags/${ref.id}/fixed/${ts}_$safeName';
        final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
            'application/octet-stream';
        final kind = contentType.startsWith('video') ? 'video' : 'image';

        final sref = FirebaseStorage.instance.ref().child(storagePath);
        await sref.putData(bytes, SettableMetadata(contentType: contentType));
        final url = await sref.getDownloadURL();

        _fixedMedia.add({'url': url, 'type': kind, 'storagePath': storagePath});
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('🔥 Fixed-media upload failed: $e');
      _toast('Could not upload. Please try again.', success: false);
    } finally {
      if (mounted) setState(() => _uploadingFixed = false);
    }
  }

  // Remove an attached fix item (best-effort Storage delete too).
  void _removeFixedMedia(int index) {
    if (index < 0 || index >= _fixedMedia.length) return;
    final item = _fixedMedia[index];
    final storagePath = (item['storagePath'] ?? '').toString();
    if (storagePath.isNotEmpty) {
      FirebaseStorage.instance.ref().child(storagePath).delete().catchError(
            (e) => debugPrint('⚠️ fixed-media delete skipped: $e'),
          );
    }
    setState(() => _fixedMedia.removeAt(index));
  }

  // ── Close-out is GATED on at least one fixed photo/video. ──
  // ── Close-out is GATED on at least one fixed photo/video. ──
  //    Confirmed first via the shared warning dialog in GREEN (mirrors the
  //    red Delete dialog) — the success/close “message” is green, not red.
  Future<void> _confirmCloseOut() async {
    if (_fixedMedia.isEmpty) {
      _toast('Add a fixed photo or video to close this snag out.',
          success: false);
      return;
    }
    FocusScope.of(context).unfocus();
    await _showConfirmDialog(
      icon: Icons.task_alt_rounded,
      accent: _green,
      title: 'Mark as fixed?',
      message:
          'This snag closes out with the attached fix photos. You can reopen it if more work is needed.',
      confirmLabel: 'Mark as fixed',
      onConfirm: () => _closeWithFixedMedia(),
    );
  }

  Future<void> _closeWithFixedMedia() async {
    final ref = _snagRef;
    if (ref == null || _working) return;
    if (_fixedMedia.isEmpty) {
      _toast('Add a fixed photo or video to close this snag out.',
          success: false);
      return;
    }
    setState(() => _working = true);
    try {
      // Keep fixedPhotoUrl (first image) for the Snag List thumbnail + any
      // older readers; the full set lives in fixedMedia.
      final firstImage = _fixedMedia.firstWhere(
        (m) => (m['type'] ?? 'image') == 'image',
        orElse: () => const {},
      );
      final firstImageUrl = (firstImage['url'] ?? '').toString();

      await ref.update(<String, dynamic>{
        'status': 'closed',
        'fixedMedia': _fixedMedia,
        'fixedPhotoUrl': firstImageUrl,
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': currentUserReference,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _toast('Snag closed out.');
    } catch (e) {
      debugPrint('🔥 Proof upload / close failed: $e');
      _toast('Could not close out. Please try again.', success: false);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _toast(String msg, {bool success = true}) {
    if (!mounted) return;
    showAppToast(context, msg, success);
  }

  // Parse a Firestore media list into a clean List<Map>.
  List<Map<String, dynamic>> _parseMedia(dynamic raw) {
    final out = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) out.add(Map<String, dynamic>.from(m));
      }
    }
    return out;
  }

  // =========================================================
  // Build
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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

          // Seed local fix media from an already-closed snag (once) so the
          // gallery + (if reopened) the dock show what's on record.
          if (!_seededFromDoc) {
            final docFixed = _parseMedia(d['fixedMedia']);
            if (docFixed.isEmpty) {
              final fp = (d['fixedPhotoUrl'] ?? '').toString().trim();
              if (fp.isNotEmpty) {
                docFixed.add({'url': fp, 'type': 'image'});
              }
            }
            if (docFixed.isNotEmpty) {
              _fixedMedia
                ..clear()
                ..addAll(docFixed);
            }
            _seededFromDoc = true;
          }

          // Retry the read-receipt stamp off the live snapshot (auth + Firestore
          // are warm once data has arrived) until it conclusively resolves.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeStampReadReceipt(ref, d);
            _ensureProjectOwner(d);
          });
          return _content(ref, d);
        },
      ),
    );
  }

  Widget _shell({required Widget child}) => Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: SafeArea(top: false, bottom: true, child: child),
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

  // =========================================================
  // Hero — dark ink header (matches ProjectTimelinePageView)
  // =========================================================
  Widget _heroCircle(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );

  // Centered project name in the hero (streamed from the snag's projectRef) —
  // matches AddSnagPageView / SnagListPageView.
  Widget _heroProjectName(DocumentReference? projectRef) {
    const style = TextStyle(
        fontFamily: _bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _paper);
    if (projectRef == null) {
      return const Text('Project',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style);
    }
    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: projectRef.snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final name = ((data['name'] ??
                data['projectName'] ??
                data['title'] ??
                'Project'))
            .toString()
            .trim();
        return Text(name.isEmpty ? 'Project' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: style);
      },
    );
  }

  Widget _detailHero(
    DocumentReference ref,
    String title,
    String status,
    String area,
    DateTime? due,
    bool isOwner, {
    DocumentReference? projectRef,
  }) {
    final dueHint = _dueHint(due, status);
    final parts = <String>[];
    if (area.trim().isNotEmpty) parts.add(area.trim());
    if (dueHint.isNotEmpty) parts.add(dueHint);
    // Eyebrow above the title — uppercased, matching the other snag headers.
    final meta = parts.join('  ·  ').toUpperCase();
    return Container(
      width: double.infinity,
      color: const Color(0xFF2F3A4C),
      // Match the Snag List header height.
      constraints:
          BoxConstraints(minHeight: MediaQuery.of(context).padding.top + 138),
      padding: EdgeInsets.fromLTRB(
          20, 14 + MediaQuery.of(context).padding.top, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered project name + eyebrow, back on the left, delete on right.
          Row(
            children: [
              _heroCircle(Icons.arrow_back_ios_new_rounded, _handleBack),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _heroProjectName(projectRef),
                      const SizedBox(height: 2),
                      Text('SNAG DETAIL',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
              if (isOwner)
                _heroCircle(Icons.delete_outline_rounded,
                    () => _confirmDelete(ref, title))
              else
                const SizedBox(width: 38, height: 38),
            ],
          ),
          const SizedBox(height: 16),
          if (meta.isNotEmpty) ...[
            Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: _paper.withOpacity(0.55))),
            const SizedBox(height: 4),
          ],
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.1,
                  color: _paper)),
        ],
      ),
    );
  }

  Widget _content(DocumentReference ref, Map<String, dynamic> d) {
    final title = (d['title'] ?? 'Snag').toString();
    final description = (d['description'] ?? '').toString();
    final area = (d['area'] ?? d['room'] ?? 'Area not set').toString();
    final status = (d['status'] ?? 'open').toString();
    final severity = (d['severity'] ?? 'minor').toString();
    final listingName =
        (d['assignedListingName'] ?? d['assignedToName'] ?? '').toString();
    final createdByName = (d['createdByName'] ?? '').toString();
    final isOwner = _isOwner(d); // ✅ gate Delete

    // Original defect media.
    final media = _parseMedia(d['media']);
    if (media.isEmpty) {
      final single = (d['photoUrl'] ?? '').toString();
      if (single.isNotEmpty) media.add({'url': single, 'type': 'image'});
    }

    // Fix media — prefer what's attached locally (in progress), else the doc.
    final docFixed = _parseMedia(d['fixedMedia']);
    if (docFixed.isEmpty) {
      final fp = (d['fixedPhotoUrl'] ?? '').toString().trim();
      if (fp.isNotEmpty) docFixed.add({'url': fp, 'type': 'image'});
    }
    final fixList = _fixedMedia.isNotEmpty ? _fixedMedia : docFixed;

    // ✅ Unified gallery: defect photos first, then the fix media (badged), so
    //    the user can view every fix photo/video in the main viewer.
    final galleryMedia = <Map<String, dynamic>>[
      ...media.map((m) => {...m, 'origin': 'snag'}),
      ...fixList.map((m) => {...m, 'origin': 'fix'}),
    ];

    final due = _asDate(d['dueDate']);
    final createdAt = _asDate(d['createdAt']);
    final readAt = _asDate(d['readByListingAt']);

    return Column(
      children: [
        _detailHero(ref, title, status, area, due, isOwner,
            projectRef: d['projectRef'] as DocumentReference?),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _gallery(galleryMedia),
                    const SizedBox(height: 16),
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
                      leading: const Icon(Icons.place_outlined,
                          size: 19, color: _faint),
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
                      leading: const Icon(Icons.person_outline,
                          size: 19, color: _faint),
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
          ),
        ),
      ],
    );
  }

  // ---- Gallery (defect photos + fix media, with FIX badges) ----
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

    // Keep the index in range when the list size changes.
    if (_galleryIndex >= media.length) _galleryIndex = media.length - 1;

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
                // FIX badge on fix media.
                if ((media[_galleryIndex]['origin'] ?? 'snag') == 'fix')
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 5),
                          Text('FIX',
                              style: TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  )
                else
                  // BEFORE badge (red) on the original defect media.
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _warn,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.error_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 5),
                          Text('BEFORE',
                              style: TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
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
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _thumb(media[i], i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumb(Map<String, dynamic> m, int i) {
    final url = (m['url'] ?? '').toString();
    final isVideo = (m['type'] ?? 'image') == 'video';
    final isFix = (m['origin'] ?? 'snag') == 'fix';
    final selected = i == _galleryIndex;
    final selColor = isFix ? _green : _teal;
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? selColor
                  : (isFix ? _greenBorder : _hairlineOnSurface),
              width: selected ? 2 : 1),
          image: (url.isNotEmpty)
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
        ),
        child: Stack(
          children: [
            if (isVideo)
              const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 18, color: Colors.white)),
            if (isFix)
              Positioned(
                bottom: 3,
                right: 3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _paper, width: 1),
                  ),
                ),
              ),
          ],
        ),
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
                borderRadius: BorderRadius.circular(10)),
            child: has
                ? Text(_initials(name),
                    style: const TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _ink))
                : const Icon(Icons.person_outline_rounded,
                    size: 17, color: _faint),
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
                Text(has ? 'Team member' : 'Assign from the form',
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
                          size: 14, color: _green),
                      const SizedBox(width: 5),
                      Text(
                        'Read ${dateTimeFormat('d MMM · HH:mm', readAt)}',
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _green),
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
              size: 19, color: Color(0xFFCBD8DD)),
        ],
      ),
    );
  }

  // ---- Close-out dock ----
  Widget _closeOutDock(String status) {
    final inProgress = status == 'in_progress';
    final gated = inProgress && _fixedMedia.isEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: Color(0xFFEAEEF0), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepper(status),
            if (inProgress) ...[
              const SizedBox(height: 14),
              _fixedMediaRequirement(),
            ],
            const SizedBox(height: 12),
            _primaryAction(status),
            if (gated) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline_rounded, size: 13, color: _faint),
                  SizedBox(width: 5),
                  Text(
                      'At least one fixed photo or video is required to close out',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _faint)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Mandatory proof-of-fix capture — one or more photos/videos. ──
  Widget _fixedMediaRequirement() {
    final has = _fixedMedia.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: has ? _surface : const Color(0x0F566670),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: has ? _hairlineOnSurface : const Color(0x59566670)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              has
                  ? 'FIXED MEDIA · ${_fixedMedia.length} ADDED'
                  : 'FIXED MEDIA · REQUIRED',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                  color: has ? _green : _live)),
          const SizedBox(height: 3),
          Text(
              has
                  ? 'Add more photos or video, or mark this snag as fixed.'
                  : 'Add one or more photos or video of the completed fix to close this snag out.',
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  color: _inkMute)),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add tile
                GestureDetector(
                  onTap: _uploadingFixed ? null : _pickFixedMedia,
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: has ? _hairlineOnSurface : _live,
                          width: has ? 1 : 1.5),
                    ),
                    child: _uploadingFixed
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_live)))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 18, color: has ? _ink : _live),
                              const SizedBox(height: 2),
                              Text('Add',
                                  style: TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: _inkMute)),
                            ],
                          ),
                  ),
                ),
                for (int i = 0; i < _fixedMedia.length; i++) ...[
                  const SizedBox(width: 8),
                  _fixedThumb(i),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fixedThumb(int i) {
    final m = _fixedMedia[i];
    final url = (m['url'] ?? '').toString();
    final isVideo = (m['type'] ?? 'image') == 'video';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _greenSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _greenBorder),
            image: (!isVideo && url.isNotEmpty)
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: isVideo
              ? const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 24, color: Colors.white))
              : (url.isEmpty
                  ? const Center(
                      child:
                          Icon(Icons.image_outlined, size: 20, color: _green))
                  : null),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeFixedMedia(i),
            child: Container(
              width: 22,
              height: 22,
              decoration:
                  const BoxDecoration(color: _ink, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 14, color: _paper),
            ),
          ),
        ),
      ],
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
      return Text(label,
          style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: done ? _teal : const Color(0xFFCBD8DD)));
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
                color: idx >= 0 ? _teal : const Color(0xFFCBD8DD),
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
    // OPEN → start work.
    if (status == 'open') {
      return _actionButton(
        label: 'Move to In Progress',
        icon: Icons.play_arrow_rounded,
        bg: const Color(0xFFE7E247), // lime
        fg: _ink,
        onTap: () => _setStatus('in_progress'),
      );
    }

    // IN PROGRESS → close-out, GATED on at least one fix photo/video.
    if (status == 'in_progress') {
      final ready = _fixedMedia.isNotEmpty;
      return _actionButton(
        label: 'Mark as Fixed',
        icon: ready ? Icons.task_alt_rounded : Icons.lock_outline_rounded,
        bg: ready ? const Color(0xFFE7E247) : _surface, // lime when ready
        fg: ready ? _ink : _faint,
        border: ready ? null : _hairlineOnSurface,
        onTap: ready ? _confirmCloseOut : _pickFixedMedia,
      );
    }

    // CLOSED → reopen (clears the proof gate).
    return _actionButton(
      label: 'Reopen Snag',
      icon: Icons.replay_rounded,
      bg: _surface,
      fg: _ink,
      border: _hairlineOnSurface,
      onTap: () {
        setState(() {
          _fixedMedia.clear();
          _galleryIndex = 0;
        });
        _setStatus('open', extra: {'fixedMedia': [], 'fixedPhotoUrl': null});
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    Color? border,
  }) {
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
              border: border != null ? Border.all(color: border) : null,
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
                        valueColor: AlwaysStoppedAnimation<Color>(fg)),
                  )
                else
                  Icon(icon, size: 20, color: fg),
                const SizedBox(width: 9),
                Text(label,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: fg)),
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

  // =========================================================
  // Delete — shared "delete warning" dialog (centred card, clay badge,
  // 22-radius, filled clay confirm + outlined cancel, 55%-black scrim).
  // =========================================================
  Future<void> _confirmDelete(DocumentReference ref, String title) async {
    FocusScope.of(context).unfocus();
    await _showConfirmDialog(
      icon: Icons.delete_rounded,
      accent: _warn,
      title: 'Delete this snag?',
      message: '“$title” will be permanently removed. This can’t be undone.',
      confirmLabel: 'Delete snag',
      onConfirm: () => _deleteSnag(ref),
    );
  }

  Future<void> _deleteSnag(DocumentReference ref) async {
    try {
      await ref.delete();
      if (!mounted) return;
      _toast('Snag deleted.');
      _handleBack();
    } catch (e) {
      debugPrint('🔥 Delete snag failed: $e');
      if (mounted)
        _toast('Could not delete. Please try again.', success: false);
    }
  }

  // Shared centred confirm dialog. `accent` colours the badge + confirm button
  // — _warn (red) for Delete, _green for the close-out “Mark as fixed” message.
  Future<void> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
    Color accent = _warn,
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
              borderRadius: BorderRadius.circular(10),
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
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: accent.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontSize: 18,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    fontSize: 14,
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFCBD8DD), width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
