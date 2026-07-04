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

import 'dart:typed_data';
import 'package:flutter/services.dart'; // SystemUiOverlayStyle
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

// ======================= SiteBookPageView (FULL FILE) =======================
//
// UPDATE (this revision) — three fixes + polish:
//   1. SAVING WORKS. A new entry now saves whenever there is a note OR at least
//      one photo/video (previously an empty-note tap silently discarded the
//      entry). A toast confirms the save; failures surface an error toast.
//   2. PHOTO / VIDEO UPLOAD. The editor picks images and videos (FilePicker,
//      FileType.media), uploads each to Firebase Storage under
//      projects/{id}/site_book/, and stores them on the entry as `media`
//      ([{url,type,storagePath}]). Cards + detail render images inline and
//      videos with a play badge. `photoUrls` is still written (image URLs only)
//      for backward compatibility with anything reading the old field.
//   3. USER-DEFINED TAGS. The hard-coded suggestion list is gone. Users type
//      any tag (Enter / comma / Add). Tags previously used on THIS project's
//      entries are offered as tap-to-add chips ("Previously used").
//
//   Visual polish to match ToDoListPageView / AddTaskPageView:
//     • Editor content background is white (_paper), like To Do content.
//     • Bottom bars use the app's bright-white elevated footer (top hairline +
//       upward shadow) — see _footerShadow.
//     • Scroll bodies clear the pinned bottom bar (extra bottom padding).
//     • Tapping a card opens an in-widget entry DETAIL screen with an ink
//       masthead header (eyebrow + weather chip + avatar + author + date +
//       contents strip).
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

class SiteBookPageView extends StatefulWidget {
  const SiteBookPageView({
    super.key,
    this.width,
    this.height,
    this.projectRef,
  });

  final double? width;
  final double? height;
  final DocumentReference? projectRef;

  @override
  State<SiteBookPageView> createState() => _SiteBookPageViewState();
}

class _SiteBookPageViewState extends State<SiteBookPageView>
    with SingleTickerProviderStateMixin {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _sage = Color(0xFF5D737E);
  static const Color _tint = Color(0xFFE7EDF0);
  static const Color _tintBorder = Color(0xFFCBD8DD);
  static const Color _fieldBorder = Color(0xFFE1E7EA);

  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';

  // App-standard bright-white elevated footer shadow (matches _footerBar in
  // ToDoListPageView / AddTaskPageView).
  static const List<BoxShadow> _footerShadow = [
    BoxShadow(color: Color(0x1F19232D), blurRadius: 30, offset: Offset(0, -10)),
  ];
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 20;
  static const double _radius = 12;

  static const List<String> _weekdays = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN' //
  ];
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  static const List<String> _weekdaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  static const List<String> _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Search
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

  // Composer / editor slide-in
  bool _compose = false;
  final TextEditingController _noteCtl = TextEditingController();
  final TextEditingController _tagCtl = TextEditingController();
  String _weather = 'sunny';
  final List<String> _tags = <String>[];
  // media: [{ 'url', 'type' ('image'|'video'), 'storagePath' }]
  final List<Map<String, dynamic>> _media = <Map<String, dynamic>>[];
  bool _uploading = false;
  bool _saving = false;

  // Detail slide-in
  QueryDocumentSnapshot<Map<String, dynamic>>? _detailDoc;

  // Tags previously used on this project (for tap-to-reuse). Kept fresh from
  // the entries stream in _viewScreen.
  final List<String> _knownTags = <String>[];

  final ScrollController _editorScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(() {
      final q = _searchCtl.text.trim().toLowerCase();
      if (q != _query && mounted) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _noteCtl.dispose();
    _tagCtl.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  // -----------------------------
  // Query
  // -----------------------------
  Query<Map<String, dynamic>>? _entriesQuery() {
    final ref = widget.projectRef;
    if (ref == null) return null;
    return FirebaseFirestore.instance
        .collection('site_book_entries')
        .where('projectRef', isEqualTo: ref)
        .orderBy('createdAt', descending: true)
        .limit(200);
  }

  // -----------------------------
  // Media upload
  // -----------------------------
  Future<void> _pickMedia() async {
    if (_uploading || _saving) return;
    final projectRef = widget.projectRef;
    if (projectRef == null) {
      _snack('No project selected.');
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
      _snack('Upload failed. Please try again.');
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
    // ✅ Save when there's a note OR media (was: note required).
    if (note.isEmpty && _media.isEmpty) {
      _snack('Add a note or a photo first.');
      return;
    }
    if (widget.projectRef == null) {
      _snack('No project selected.');
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
        'projectRef': widget.projectRef,
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
      if (mounted) _snack('Entry saved.');
      _closeComposer();
    } catch (e) {
      debugPrint('🔥 Failed to save site book entry: $e');
      if (mounted) _snack('Could not save entry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openComposer() => setState(() => _compose = true);

  void _closeComposer() {
    if (!mounted) return;
    setState(() {
      _compose = false;
      _noteCtl.clear();
      _tagCtl.clear();
      _tags.clear();
      _media.clear();
      _weather = 'sunny';
    });
  }

  void _openEntry(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      setState(() => _detailDoc = doc);
  void _closeEntry() => setState(() => _detailDoc = null);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: _ink,
        content: Text(msg,
            style: const TextStyle(
                color: _paper,
                fontFamily: _bodyFont,
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

  String _dayKey(DateTime dt) {
    final l = dt.toLocal();
    final m = l.month.toString().padLeft(2, '0');
    final d = l.day.toString().padLeft(2, '0');
    return '${l.year}-$m-$d';
  }

  String _dayLabel(String dayKey) {
    final p = dayKey.split('-');
    final dt = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(dt).inDays;
    final full =
        '${_weekdays[dt.weekday - 1]} ${dt.day} ${_months[dt.month - 1]}';
    if (diff == 0) return 'TODAY · $full';
    if (diff == 1) return 'YESTERDAY · $full';
    return full;
  }

  // A doc's createdAt as a DateTime. While a serverTimestamp() write is
  // pending, Firestore returns createdAt == null — treat that as "now" so the
  // freshly-added entry stays visible instead of flickering out.
  DateTime _dateOf(dynamic ts) =>
      ts is Timestamp ? ts.toDate() : DateTime.now();

  String _timeLabel(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fullDate(DateTime dt) {
    final l = dt.toLocal();
    return '${_weekdaysFull[l.weekday - 1]} ${l.day} ${_monthsFull[l.month - 1]} · ${_timeLabel(l)}';
  }

  String _weatherLabelOf(String w) =>
      w == 'cloudy' ? 'Cloudy' : (w == 'rain' ? 'Rain' : 'Sunny');

  IconData _weatherIcon(String w) {
    switch (w) {
      case 'cloudy':
        return Icons.cloud_outlined;
      case 'rain':
        return Icons.grain;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  // media list off a doc (falls back to legacy photoUrls as images).
  List<Map<String, dynamic>> _mediaOf(Map<String, dynamic> d) {
    final raw = d['media'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final photos = (d['photoUrls'] as List?)?.whereType<String>() ?? const [];
    return [
      for (final u in photos) {'url': u, 'type': 'image'}
    ];
  }

  bool _matches(Map<String, dynamic> d) {
    if (_query.isEmpty) return true;
    final note = (d['note'] as String?)?.toLowerCase() ?? '';
    final author = (d['authorName'] as String?)?.toLowerCase() ?? '';
    final tags = (d['tags'] as List?)?.join(' ').toLowerCase() ?? '';
    return note.contains(_query) ||
        author.contains(_query) ||
        tags.contains(_query);
  }

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    const dur = Duration(milliseconds: 300);
    const curve = Curves.easeOutCubic;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: Stack(
          children: [
            Positioned.fill(child: _viewScreen()),
            // detail — slides over from the right
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _detailDoc == null,
                child: AnimatedSlide(
                  duration: dur,
                  curve: curve,
                  offset: _detailDoc != null ? Offset.zero : const Offset(1, 0),
                  child: _detailScreen(),
                ),
              ),
            ),
            // editor — slides over from the right (top-most)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_compose,
                child: AnimatedSlide(
                  duration: dur,
                  curve: curve,
                  offset: _compose ? Offset.zero : const Offset(1, 0),
                  child: _editorScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // VIEW SCREEN
  // =====================================================================
  Widget _viewScreen() {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final q = _entriesQuery();

    return Column(
      children: [
        _hero(topInset),
        Expanded(
          child: q == null
              ? _noProject()
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: q.snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      // Server rejected the listen AFTER cache rendered —
                      // this is why entries flash and then vanish.
                      debugPrint('SiteBook stream error: ${snap.error}');
                      return _streamError(snap.error);
                    }
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return _loading();
                    }
                    final all = snap.data?.docs ?? const [];
                    // Refresh the reuse-tag pool from every entry.
                    _refreshKnownTags(all);
                    final docs = all.where((d) => _matches(d.data())).toList();
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(_hPad, 18, _hPad, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _searchField(),
                          if (docs.isEmpty)
                            _empty()
                          else
                            ..._buildGroupedEntries(docs),
                        ],
                      ),
                    );
                  },
                ),
        ),
        _bottomComposer(bottomInset),
      ],
    );
  }

  void _refreshKnownTags(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final seen = <String>{};
    final out = <String>[];
    for (final d in docs) {
      final tags = (d.data()['tags'] as List?)?.whereType<String>() ?? const [];
      for (final t in tags) {
        final k = t.toLowerCase();
        if (k.isEmpty || seen.contains(k)) continue;
        seen.add(k);
        out.add(t);
      }
    }
    _knownTags
      ..clear()
      ..addAll(out);
  }

  Widget _hero(double topInset) => Container(
        width: double.infinity,
        color: _ink,
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _circleBtn(
                    Icons.arrow_back_ios_new_rounded, () => context.safePop(),
                    size: 16),
                Expanded(
                  child: Center(
                    child: Text('SITE BOOK',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: _paper.withOpacity(0.5),
                        )),
                  ),
                ),
                _circleBtn(Icons.add_rounded, _openComposer, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            _projectTitle(),
          ],
        ),
      );

  Widget _projectTitle() {
    final ref = widget.projectRef;
    if (ref == null) {
      return const Text('Site Book',
          style: TextStyle(
              fontFamily: _displayFont,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: _paper));
    }
    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final name = (data['name'] as String?)?.trim() ?? 'Site Book';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.isEmpty ? 'Site Book' : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.1,
                    color: _paper)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _entriesQuery()?.snapshots(),
              builder: (context, s) {
                final n = s.data?.docs.length ?? 0;
                return Row(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        size: 13, color: _paper.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Text('Site journal · $n entries',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.55))),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {double size = 16}) =>
      Material(
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
            child: Icon(icon, size: size, color: _paper),
          ),
        ),
      );

  Widget _searchField() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _tintBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: _faint),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtl,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _ink),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search entries, authors or tags…',
                  hintStyle: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _faint),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () => _searchCtl.clear(),
                child: const Icon(Icons.close_rounded, size: 16, color: _faint),
              ),
          ],
        ),
      );

  List<Widget> _buildGroupedEntries(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final order = <String>[];
    final groups =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final d in docs) {
      final key = _dayKey(_dateOf(d.data()['createdAt']));
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(d);
    }
    final out = <Widget>[];
    for (final key in order) {
      out.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
        child: Text(_dayLabel(key),
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _faint)),
      ));
      for (final d in groups[key]!) {
        out.add(_entryCard(d));
      }
    }
    return out;
  }

  Widget _entryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final author = (d['authorName'] as String?)?.trim() ?? 'Team member';
    final note = (d['note'] as String?)?.trim() ?? '';
    final weather = (d['weather'] as String?) ?? '';
    final tags = (d['tags'] as List?)?.whereType<String>().toList() ?? const [];
    final media = _mediaOf(d);
    final time = _timeLabel(_dateOf(d['createdAt']));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEntry(doc),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: _tint, shape: BoxShape.circle),
                    child: Text(_initials(author),
                        style: const TextStyle(
                            fontFamily: _displayFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                  ),
                  if (weather.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _tint,
                          borderRadius: BorderRadius.circular(999)),
                      child: Icon(_weatherIcon(weather),
                          size: 12, color: _inkMute),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(time,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _faint)),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 11),
                Text(note,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: _ink)),
              ],
              if (media.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: media.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _thumb(media[i], 84),
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(t,
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _inkMute)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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

  // Bright-white elevated bottom composer (matches _footerBar shell).
  Widget _bottomComposer(double bottomInset) => Container(
        decoration: const BoxDecoration(
          color: _paper,
          border: Border(top: BorderSide(color: _surface)),
          boxShadow: _footerShadow,
        ),
        padding: EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14 + bottomInset + 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openComposer,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _tintBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: _ink, shape: BoxShape.circle),
                    child: Text(_initials(currentUserDisplayName),
                        style: const TextStyle(
                            fontFamily: _displayFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _paper)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Add today's site note…",
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7C8B93))),
                  ),
                  const Icon(Icons.photo_camera_outlined,
                      size: 20, color: _sage),
                ],
              ),
            ),
          ),
        ),
      );

  // =====================================================================
  // EDITOR SCREEN (slide-in)
  // =====================================================================
  Widget _editorScreen() {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final reuse = _reuseTags();

    return Container(
      color: _paper, // ✅ white content (matches To Do List content)
      child: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            color: _ink,
            padding: EdgeInsets.fromLTRB(14, topInset + 10, 14, 16),
            child: Row(
              children: [
                _circleBtn(Icons.arrow_back_ios_new_rounded, _closeComposer,
                    size: 16),
                const Expanded(
                  child: Center(
                    child: Text('New site entry',
                        style: TextStyle(
                            fontFamily: _displayFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _paper)),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saveEntry,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _paper.withOpacity(0.12),
                          shape: BoxShape.circle),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_paper)),
                            )
                          : const Icon(Icons.check_rounded,
                              size: 18, color: _paper),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // body
          Expanded(
            child: SingleChildScrollView(
              controller: _editorScroll,
              padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: _ink, shape: BoxShape.circle),
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
                  ),
                  const SizedBox(height: 16),
                  _label('SITE NOTE'),
                  const SizedBox(height: 8),
                  Container(
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
                  ),
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
          ),
          // save bar — bright-white elevated footer
          Container(
            decoration: const BoxDecoration(
              color: _paper,
              border: Border(top: BorderSide(color: _surface)),
              boxShadow: _footerShadow,
            ),
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 14),
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
                        color: _ink,
                        borderRadius: BorderRadius.circular(_radius)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_rounded, size: 18, color: _paper),
                        SizedBox(width: 8),
                        Text('Save entry',
                            style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                  onSubmitted: (_) => _commitTag(),
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
                      border: Border.all(color: _hairlineOnSurface),
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

  // =====================================================================
  // DETAIL SCREEN (slide-in) — ink masthead header
  // =====================================================================
  Widget _detailScreen() {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final d = _detailDoc?.data() ?? const {};
    final author = (d['authorName'] as String?)?.trim() ?? 'Team member';
    final note = (d['note'] as String?)?.trim() ?? '';
    final weather = (d['weather'] as String?) ?? '';
    final tags = (d['tags'] as List?)?.whereType<String>().toList() ?? const [];
    final media = _mediaOf(d);
    final dateLabel = _fullDate(_dateOf(d['createdAt']));

    final photos = media.where((m) => (m['type'] ?? 'image') != 'video').length;
    final videos = media.length - photos;
    final metaParts = <String>[];
    if (photos > 0)
      metaParts.add('$photos ${photos == 1 ? 'photo' : 'photos'}');
    if (videos > 0)
      metaParts.add('$videos ${videos == 1 ? 'video' : 'videos'}');
    if (tags.isNotEmpty) {
      metaParts.add('${tags.length} ${tags.length == 1 ? 'tag' : 'tags'}');
    }
    final metaLabel = metaParts.join('  ·  ');

    return Container(
      color: _paper,
      child: Column(
        children: [
          // ink masthead
          Container(
            width: double.infinity,
            color: _ink,
            padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _circleBtn(Icons.arrow_back_ios_new_rounded, _closeEntry,
                        size: 16),
                    Expanded(
                      child: Center(
                        child: Text('SITE ENTRY',
                            style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                                color: _paper.withOpacity(0.5))),
                      ),
                    ),
                    if (weather.isNotEmpty)
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: _paper.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_weatherIcon(weather),
                                size: 13, color: _paper.withOpacity(0.85)),
                            const SizedBox(width: 5),
                            Text(_weatherLabelOf(weather),
                                style: const TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: _paper)),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 38, height: 38),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _paper.withOpacity(0.14),
                          shape: BoxShape.circle),
                      child: Text(_initials(author),
                          style: const TextStyle(
                              fontFamily: _displayFont,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _displayFont,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                  color: _paper)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 12, color: _paper.withOpacity(0.55)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(dateLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _paper.withOpacity(0.55))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (metaLabel.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: _paper.withOpacity(0.1))),
                    ),
                    child: Text(metaLabel,
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: _paper.withOpacity(0.5))),
                  ),
                ],
              ],
            ),
          ),
          // body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(_hPad, 20, _hPad, bottomInset + 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.isNotEmpty)
                    Text(note,
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            color: _ink)),
                  if (media.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    for (final m in media) ...[
                      _detailMedia(m),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text(t,
                                style: const TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _inkMute)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Full-width media in the detail gallery. Videos show a large play badge
  // (wire a video player / route on tap as needed).
  Widget _detailMedia(Map<String, dynamic> m) {
    final url = (m['url'] ?? '').toString();
    final isVideo = (m['type'] ?? 'image') == 'video';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          if (!isVideo)
            Image.network(url,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(height: 200, color: _surface))
          else
            Container(height: 200, width: double.infinity, color: _ink),
          if (isVideo)
            Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                      color: Color(0xEBFFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 30, color: _ink),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------------
  // Placeholder states
  // -----------------------------
  Widget _loading() => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Text('Loading site book…',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _faint)),
        ),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _tint, borderRadius: BorderRadius.circular(16)),
              child:
                  const Icon(Icons.menu_book_rounded, size: 28, color: _sage),
            ),
            const SizedBox(height: 16),
            Text(_query.isEmpty ? 'No entries yet' : 'No matching entries',
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _ink)),
            const SizedBox(height: 6),
            Text(
                _query.isEmpty
                    ? "Log the first site note — it'll appear here for the whole team."
                    : 'Try a different search term.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: _inkMute)),
          ],
        ),
      );

  Widget _streamError(Object? error) {
    final msg = error.toString();
    final isIndex = msg.contains('failed-precondition') ||
        msg.contains('requires an index');
    final isDenied = msg.contains('permission-denied');
    final title = isIndex
        ? 'Missing Firestore index'
        : isDenied
            ? 'Permission denied'
            : 'Couldn\u2019t load entries';
    final detail = isIndex
        ? 'The site_book_entries query needs a composite index '
            '(projectRef ASC, createdAt DESC). Create it in the Firebase '
            'console, then reopen this page.'
        : isDenied
            ? 'Firestore security rules are blocking reads on '
                'site_book_entries. Add a rules block for this collection '
                'in the Firebase console.'
            : msg;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(_hPad, 40, _hPad, 40),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _tint, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.cloud_off_rounded, size: 28, color: _sage),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _ink)),
          const SizedBox(height: 6),
          Text(detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: _inkMute)),
        ],
      ),
    );
  }

  Widget _noProject() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No project selected. Open this from a project.',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink)),
        ),
      );
}
