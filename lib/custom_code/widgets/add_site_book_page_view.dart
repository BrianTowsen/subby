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

import 'dart:typed_data';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle (white status-bar icons over the ink hero)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

// ======================= AddSiteBookPageView ================================
//
// The site-book ENTRY COMPOSER, extracted from SiteBookPageView into its own
// routed page (AddSiteBookPage) so it gets native push/pop + edge-swipe back
// for free — no in-widget overlay, no PopScope / AnimatedSlide juggling. This
// is the exact parity move already done for Add Task / Add Snag.
//
// It resolves the project to write to from `projectRef` (SiteBookPageView's
// "add" bar passes it as a route query param, the same way the To-Do / Snag
// lists hand projectRef to their Add pages), falling back to the persisted
// active project. On save it writes a new `site_book_entries` doc and pops.
//
// Navigate to it from the list with:
//   context.pushNamed(
//     'AddSiteBookPage',
//     queryParameters: {
//       'projectRef': serializeParam(projectRef, ParamType.DocumentReference),
//     }.withoutNulls,
//   );
//
// FIRESTORE — collection `site_book_entries`:
//   projectRef : DocumentReference
//   authorRef  : DocumentReference
//   authorName : String
//   note       : String
//   weather    : String  ('sunny' | 'cloudy' | 'rain')
//   tags       : List<String>            (free-form, user-defined)
//   media      : List<Map>  [{url,type('image'|'video'),storagePath}]
//   photoUrls  : List<String>            (image URLs only — legacy compat)
//   visibility : String  ('shared' | 'private')
//   createdAt  : Timestamp (serverTimestamp)

class AddSiteBookPageView extends StatefulWidget {
  const AddSiteBookPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<AddSiteBookPageView> createState() => _AddSiteBookPageViewState();
}

class _AddSiteBookPageViewState extends State<AddSiteBookPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _sage = Color(0xFF5D737E);
  static const Color _tint = Color(0xFFE7EDF0);
  static const Color _tintBorder = Color(0xFFCBD8DD);
  static const Color _fieldBorder = Color(0xFFE1E7EA);

  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';

  // App-standard bright-white elevated footer shadow (matches _footerBar in
  // ToDoListPageView / AddTaskPageView).
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 20;
  static const double _radius = 12;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  final TextEditingController _noteCtl = TextEditingController();
  final TextEditingController _tagCtl = TextEditingController();
  final ScrollController _editorScroll = ScrollController();

  String _weather = 'sunny';
  final List<String> _tags = <String>[];
  // media: [{ 'url', 'type' ('image'|'video'), 'storagePath' }]
  final List<Map<String, dynamic>> _media = <Map<String, dynamic>>[];

  // Tags previously used on this project (tap-to-reuse). Loaded once.
  final List<String> _knownTags = <String>[];

  DocumentReference? _projectRef;
  bool _resolved = false;

  bool _uploading = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;

    _projectRef = _readRefFromRoute('projectRef', 'projects');
    if (_projectRef == null) {
      _loadActiveProject();
    } else {
      _loadKnownTags();
    }
  }

  @override
  void dispose() {
    _noteCtl.dispose();
    _tagCtl.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  // Reads a serialized DocumentReference query param and turns it into a
  // DocumentReference (same logic as ToDoListPageView / AddTaskPageView).
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

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty || !mounted) return;
    setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
    _loadKnownTags();
  }

  // Pull the tags used on this project's existing entries so the composer can
  // offer them as tap-to-add chips (parity with the old inline editor).
  Future<void> _loadKnownTags() async {
    final ref = _projectRef;
    if (ref == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('site_book_entries')
          .where('projectRef', isEqualTo: ref)
          .limit(200)
          .get();
      final seen = <String>{};
      final out = <String>[];
      for (final d in snap.docs) {
        final tags =
            (d.data()['tags'] as List?)?.whereType<String>() ?? const [];
        for (final t in tags) {
          final k = t.toLowerCase();
          if (k.isEmpty || seen.contains(k)) continue;
          seen.add(k);
          out.add(t);
        }
      }
      if (!mounted) return;
      setState(() {
        _knownTags
          ..clear()
          ..addAll(out);
      });
    } catch (e) {
      debugPrint('⚠️ load known tags skipped: $e');
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

  // -----------------------------
  // Media upload
  // -----------------------------
  Future<void> _pickMedia() async {
    if (_uploading || _saving) return;
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('No project selected.');
      return;
    }
    FocusScope.of(context).unfocus();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media, // images + videos
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploading = true);

      for (final f in result.files) {
        final Uint8List? bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;

        final fileName = p.basename(f.name.isNotEmpty ? f.name : 'file');
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
        final ts = DateTime.now().millisecondsSinceEpoch;
        final storagePath =
            'projects/${projectRef.id}/site_book/${ts}_$safeName';
        final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
            'application/octet-stream';
        final kind = contentType.startsWith('video') ? 'video' : 'image';

        final ref = FirebaseStorage.instance.ref().child(storagePath);
        await ref.putData(bytes, SettableMetadata(contentType: contentType));
        final url = await ref.getDownloadURL();

        _media.add({'url': url, 'type': kind, 'storagePath': storagePath});
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('🔥 Site book media upload failed: $e');
      _toast('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeMedia(int i) {
    final sp = (_media[i]['storagePath'] ?? '').toString();
    if (sp.isNotEmpty) {
      FirebaseStorage.instance
          .ref()
          .child(sp)
          .delete()
          .catchError((e) => debugPrint('⚠️ media delete skipped: $e'));
    }
    setState(() => _media.removeAt(i));
  }

  // -----------------------------
  // Tags (user-defined)
  // -----------------------------
  void _commitTag() {
    var raw = _tagCtl.text.trim();
    raw = raw.replaceAll(RegExp(r',+$'), '').trim();
    if (raw.isEmpty) return;
    final exists = _tags.any((t) => t.toLowerCase() == raw.toLowerCase());
    if (!exists) _tags.add(raw);
    setState(() => _tagCtl.clear());
  }

  void _addExistingTag(String t) {
    if (_tags.any((x) => x.toLowerCase() == t.toLowerCase())) return;
    setState(() => _tags.add(t));
  }

  void _removeTag(String t) => setState(() => _tags.remove(t));

  // Tags used on existing entries, minus ones already on the draft.
  List<String> _reuseTags() {
    final seen = _tags.map((t) => t.toLowerCase()).toSet();
    final out = <String>[];
    for (final t in _knownTags) {
      final k = t.toLowerCase();
      if (k.isEmpty || seen.contains(k)) continue;
      seen.add(k);
      out.add(t);
    }
    return out;
  }

  // -----------------------------
  // Save a new entry
  // -----------------------------
  Future<void> _saveEntry() async {
    if (_saving || _uploading) return;
    final note = _noteCtl.text.trim();
    // Save when there's a note OR media.
    if (note.isEmpty && _media.isEmpty) {
      _toast('Add a note or a photo first.');
      return;
    }
    if (_projectRef == null) {
      _toast('No project selected.');
      return;
    }

    setState(() => _saving = true);
    try {
      final photoUrls = _media
          .where((m) => (m['type'] ?? 'image') == 'image')
          .map((m) => (m['url'] ?? '').toString())
          .where((u) => u.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('site_book_entries').add({
        'projectRef': _projectRef,
        'authorRef': currentUserReference,
        'authorName': currentUserDisplayName,
        'note': note,
        'weather': _weather,
        'tags': List<String>.from(_tags),
        'media': List<Map<String, dynamic>>.from(_media),
        'photoUrls': photoUrls, // legacy compat (images only)
        'visibility': 'shared',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _toast('Entry saved.');
      _handleBack();
    } catch (e) {
      debugPrint('🔥 Failed to save site book entry: $e');
      if (mounted) _toast('Could not save entry.');
    } finally {
      if (mounted) setState(() => _saving = false);
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

  // -----------------------------
  // Helpers
  // -----------------------------
  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final reuse = _reuseTags();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            _addHero('Add Site Entry', 'Log a site note with photos & tags'),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _editorScroll,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _authorRow(),
                        const SizedBox(height: 16),
                        _label('SITE NOTE'),
                        const SizedBox(height: 8),
                        _noteField(),
                        const SizedBox(height: 18),
                        _label('WEATHER'),
                        const SizedBox(height: 8),
                        _weatherSelector(),
                        const SizedBox(height: 18),
                        _label('PHOTOS & VIDEOS'),
                        const SizedBox(height: 8),
                        _mediaSelector(),
                        const SizedBox(height: 18),
                        _label('TAGS'),
                        const SizedBox(height: 8),
                        _tagEditor(reuse),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _footerBar(bottomInset),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Hero — dark ink header (matches AddTaskPageView / AddSnagPageView)
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

  Widget _addHero(String title, String subtitle) => Container(
        width: double.infinity,
        color: const Color(0xFF3A5966),
        padding: EdgeInsets.fromLTRB(
            _hPad, 6 + MediaQuery.of(context).padding.top, _hPad, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _heroCircle(Icons.arrow_back_ios_new_rounded, _handleBack),
                Expanded(
                  child: Center(
                    child: Text('NEW ENTRY',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _paper.withOpacity(0.5))),
                  ),
                ),
                const SizedBox(width: 38, height: 38),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: _paper)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _paper.withOpacity(0.6))),
          ],
        ),
      );

  // Bright-white elevated footer (matches AddTaskPageView).
  Widget _footerBar(double bottomInset) => Container(
        decoration: const BoxDecoration(
          color: _paper,
          border: Border(top: BorderSide(color: Color(0xFFEAEEF0), width: 1)),
        ),
        // SafeArea(bottom:true) already reserves the device inset, so the bar
        // uses a plain bottom pad — matching the To-Do list composer height and
        // keeping the button flush to the bottom instead of floating up.
        padding: EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _saveEntry,
            borderRadius: BorderRadius.circular(_radius),
            child: Opacity(
              opacity: (_saving || _uploading) ? 0.7 : 1,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFE7E247),
                    borderRadius: BorderRadius.circular(_radius)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_saving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(_paper)),
                      )
                    else
                      const Icon(Icons.check_rounded, size: 18, color: _ink),
                    const SizedBox(width: 8),
                    Text(_saving ? 'Saving…' : 'Save entry',
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  // =========================================================
  // Body fields
  // =========================================================
  Widget _authorRow() => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: _ink, shape: BoxShape.circle),
            child: Text(_initials(currentUserDisplayName),
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _paper)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  currentUserDisplayName.trim().isEmpty
                      ? 'You'
                      : currentUserDisplayName.trim(),
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
              const Text('posting now',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _faint)),
            ],
          ),
        ],
      );

  Widget _noteField() => Container(
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _fieldBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: TextField(
          controller: _noteCtl,
          maxLines: 5,
          minLines: 4,
          textInputAction: TextInputAction.done,
          cursorColor: _ink,
          style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: _ink),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'What happened on site today?',
            hintStyle: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: _faint),
          ),
        ),
      );

  Widget _label(String s) => Text(s,
      style: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _inkMute));

  Widget _weatherSelector() {
    Widget seg(String key, String label, IconData icon) {
      final sel = _weather == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _weather = key),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel ? _paper : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: sel
                  ? [
                      BoxShadow(
                          color: _ink.withOpacity(0.08),
                          blurRadius: 3,
                          offset: const Offset(0, 1))
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: sel ? _ink : _faint),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: sel ? _ink : _faint)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFE7ECEF),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          seg('sunny', 'Sunny', Icons.wb_sunny_outlined),
          const SizedBox(width: 6),
          seg('cloudy', 'Cloudy', Icons.cloud_outlined),
          const SizedBox(width: 6),
          seg('rain', 'Rain', Icons.grain),
        ],
      ),
    );
  }

  Widget _mediaSelector() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // add tile
          GestureDetector(
            onTap: _pickMedia,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _tintBorder, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_sage)),
                        )
                      : const Icon(Icons.photo_camera_outlined,
                          size: 20, color: _sage),
                  const SizedBox(height: 5),
                  Text(_uploading ? '…' : 'Add',
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _sage)),
                ],
              ),
            ),
          ),
          // thumbnails
          for (int i = 0; i < _media.length; i++)
            Stack(
              clipBehavior: Clip.none,
              children: [
                _thumb(_media[i], 84),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeMedia(i),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                          color: Color(0xB814202B), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: _paper),
                    ),
                  ),
                ),
              ],
            ),
        ],
      );

  // Media thumbnail (image or video-with-play-badge).
  Widget _thumb(Map<String, dynamic> m, double size) {
    final url = (m['url'] ?? '').toString();
    final isVideo = (m['type'] ?? 'image') == 'video';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            color: _surface,
            child: isVideo
                ? const SizedBox.shrink()
                : Image.network(url,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(width: size, height: size, color: _surface)),
          ),
          if (isVideo)
            Positioned.fill(
              child: Container(
                color: const Color(0x4714202B),
                alignment: Alignment.center,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                      color: Color(0xEBFFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 18, color: _ink),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tagEditor(List<String> reuse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // entered tags
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in _tags)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                  decoration: BoxDecoration(
                      color: _ink, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t,
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _paper)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(t),
                        child: Icon(Icons.close_rounded,
                            size: 13, color: _paper.withOpacity(0.75)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        // tag input
        Container(
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _fieldBorder),
          ),
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          child: Row(
            children: [
              const Icon(Icons.sell_outlined, size: 15, color: _faint),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tagCtl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _commitTag(),
                  cursorColor: _ink,
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Add a tag, press Enter',
                    hintStyle: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _faint),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _commitTag,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: _sage, borderRadius: BorderRadius.circular(9)),
                  child: const Text('Add',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _paper)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text('Type any tag your team uses — no fixed list.',
            style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _faint)),
        // previously used (tap to reuse)
        if (reuse.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('PREVIOUSLY USED · TAP TO ADD',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _faint)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in reuse)
                GestureDetector(
                  onTap: () => _addExistingTag(t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            size: 12, color: Color(0xFF7C8B93)),
                        const SizedBox(width: 5),
                        Text(t,
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _inkMute)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
