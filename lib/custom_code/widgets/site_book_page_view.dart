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

import 'package:flutter/services.dart'; // SystemUiOverlayStyle
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

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
    this.addSiteBookRouteName,
  });

  final double? width;
  final double? height;
  final DocumentReference? projectRef;

  // Route name of the standalone composer page — parity with the To-Do /
  // Snag lists' addTaskRouteName / addSnagRouteName. Falls back to
  // 'AddSiteBookPage' when not wired in FlutterFlow, so the push just works.
  final String? addSiteBookRouteName;

  @override
  State<SiteBookPageView> createState() => _SiteBookPageViewState();
}

class _SiteBookPageViewState extends State<SiteBookPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
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

  // Search
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

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

  // Push the standalone composer route (AddSiteBookPage), handing it the
  // project so the new entry lands in the right place — same shape as the
  // To-Do / Snag lists' _handleAddTask / _handleAddSnag.
  void _handleAddSiteBook() {
    if (widget.projectRef == null) {
      _snack('No project selected.');
      return;
    }
    final route = (widget.addSiteBookRouteName ?? '').trim().isEmpty
        ? 'AddSiteBookPage'
        : widget.addSiteBookRouteName!.trim();
    context.pushNamed(
      route,
      queryParameters: {
        'projectRef':
            serializeParam(widget.projectRef, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

  void _openEntry(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    // The entry detail is its own route now (DetailSiteBookPage) — push it with
    // the tapped entry's reference so it gets native push/pop + swipe-back.
    context.pushNamed(
      'DetailSiteBookPage',
      queryParameters: {
        'entryRef': serializeParam(doc.reference, ParamType.DocumentReference),
      }.withoutNulls,
    );
  }

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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: _viewScreen(),
    );
  }

  // =====================================================================
  // VIEW SCREEN
  // =====================================================================
  Widget _viewScreen() {
    final topInset = MediaQuery.of(context).viewPadding.top;
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

  // Hero — dark ink header (matches ToDoListPageView / ProjectTimelinePageView):
  // back circle · centered project name + SITE BOOK eyebrow · count pill, then
  // a large stat block (today's entries) with with-photos / contributors.
  Widget _hero(double topInset) => Container(
        width: double.infinity,
        color: const Color(0xFF3A5966),
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _circleBtn(
                    Icons.arrow_back_ios_new_rounded, () => context.safePop(),
                    size: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        _heroName(),
                        const SizedBox(height: 2),
                        Text('SITE BOOK',
                            style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5),
                            )),
                      ],
                    ),
                  ),
                ),
                _heroCountPill(),
              ],
            ),
            const SizedBox(height: 16),
            _heroStat(),
          ],
        ),
      );

  // Centered project name (streamed from the project doc).
  Widget _heroName() {
    const style = TextStyle(
        fontFamily: _bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _paper);
    final ref = widget.projectRef;
    if (ref == null) {
      return const Text('Site Book',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style);
    }
    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final name = (data['name'] as String?)?.trim() ?? 'Site Book';
        return Text(name.isEmpty ? 'Site Book' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: style);
      },
    );
  }

  // One entries query → total / today / with-photos / contributor counts.
  Widget _entryCounts(
      Widget Function(int total, int today, int withPhotos, int contributors)
          build) {
    final q = _entriesQuery();
    if (q == null) return build(0, 0, 0, 0);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final todayKey = _dayKey(DateTime.now());
        var today = 0, withPhotos = 0;
        final authors = <String>{};
        for (final d in docs) {
          final data = d.data();
          if (_dayKey(_dateOf(data['createdAt'])) == todayKey) today++;
          if (_mediaOf(data).isNotEmpty) withPhotos++;
          final a = (data['authorName'] as String?)?.trim() ?? '';
          if (a.isNotEmpty) authors.add(a.toLowerCase());
        }
        return build(docs.length, today, withPhotos, authors.length);
      },
    );
  }

  // Translucent count pill on the right of the top row.
  Widget _heroCountPill() =>
      _entryCounts((total, today, withPhotos, contributors) => Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, size: 14, color: _paper),
                const SizedBox(width: 5),
                Text('$total ${total == 1 ? 'entry' : 'entries'}',
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _paper)),
              ],
            ),
          ));

  // Large stat block: today's entries + with-photos / contributors.
  Widget _heroStat() =>
      _entryCounts((total, today, withPhotos, contributors) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TODAY',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: _paper.withOpacity(0.55))),
                  const SizedBox(height: 4),
                  Text('$today ${today == 1 ? 'entry' : 'entries'}',
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
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$withPhotos with photos',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.6))),
                    const SizedBox(height: 2),
                    Text(
                        '$contributors ${contributors == 1 ? 'contributor' : 'contributors'}',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.45))),
                  ],
                ),
              ),
            ],
          ));

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
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: _faint),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtl,
                textInputAction: TextInputAction.done,
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
          border: Border(top: BorderSide(color: Color(0xFFEAEEF0))),
        ),
        padding: EdgeInsets.fromLTRB(_hPad, 14, _hPad, 14 + bottomInset + 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleAddSiteBook,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
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
