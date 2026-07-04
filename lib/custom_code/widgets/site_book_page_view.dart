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
// A project-linked site journal. Team members log dated site entries — a note,
// the weather, tags and (optionally) photos — that read newest-first, grouped
// by calendar day. Mirrors the Subby "less-is-more" system (ink hero, sage
// accent, Inter Tight / Inter) used by DashboardPageView & ProjectDetailPageView.
//
// LAYOUT
//   • Pinned ink hero masthead (back · SITE BOOK · add) + project name + count.
//   • Search field (filters note / author / tags client-side).
//   • Day-grouped entry cards (TODAY / YESTERDAY / 'WED 2 JUL').
//   • Pinned bottom composer ("Add today's site note…").
//   • Tapping the composer / add button slides the New-Entry editor in from the
//     RIGHT (matches ProjectTimelinePageView's edit page), which writes a new
//     doc to `site_book_entries` on Save.
//
// FIRESTORE — collection `site_book_entries` (all fields optional on read):
//   projectRef : DocumentReference   (scopes the query)
//   authorRef  : DocumentReference
//   authorName : String
//   note       : String
//   weather    : String  ('sunny' | 'cloudy' | 'rain')
//   temp       : num?     (°C)
//   tags       : List<String>
//   photoUrls  : List<String>
//   visibility : String  ('shared' | 'private')
//   createdAt  : Timestamp (serverTimestamp)

class SiteBookPageView extends StatefulWidget {
  const SiteBookPageView({
    super.key,
    this.width,
    this.height,

    /// Project this journal belongs to.
    this.projectRef,

    /// Optional: open a single entry (tap a card). If empty, cards are inert.
    this.entryDetailRouteName,

    /// Param name used when passing the entry ref to the detail page.
    this.entryParamName,
  });

  final double? width;
  final double? height;
  final DocumentReference? projectRef;
  final String? entryDetailRouteName;
  final String? entryParamName;

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
  static const Color _sage = Color(0xFF5D737E);
  static const Color _tint = Color(0xFFE7EDF0);
  static const Color _tintBorder = Color(0xFFCBD8DD);
  static const Color _fieldBorder = Color(0xFFE1E7EA);
  static const Color _editorBg = Color(0xFFF4F6F7);

  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 20;

  static const List<String> _weekdays = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT',
    'SUN' // ignore: require_trailing_commas
  ];
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  static const List<String> _suggestedTags = [
    'Foundations',
    'Milestone',
    'Inspection',
    'Electrical',
    'Plumbing',
    'Structural',
  ];

  // Search
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

  // Composer / editor slide-in
  bool _compose = false;
  final TextEditingController _noteCtl = TextEditingController();
  String _weather = 'sunny';
  final Set<String> _tags = <String>{};
  bool _saving = false;

  // Editor scroll
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
  // Save a new entry
  // -----------------------------
  Future<void> _saveEntry() async {
    if (_saving) return;
    final note = _noteCtl.text.trim();
    if (note.isEmpty || widget.projectRef == null) {
      _closeComposer();
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('site_book_entries').add({
        'projectRef': widget.projectRef,
        'authorRef': currentUserReference,
        'authorName': currentUserDisplayName,
        'note': note,
        'weather': _weather,
        'tags': _tags.toList(),
        'photoUrls': <String>[],
        'visibility': 'shared',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 Failed to save site book entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor: _ink,
            content: const Text('Could not save entry.',
                style: TextStyle(
                    color: _paper,
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w700)),
          ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
      _closeComposer();
    }
  }

  void _openComposer() => setState(() => _compose = true);

  void _closeComposer() {
    if (!mounted) return;
    setState(() {
      _compose = false;
      _noteCtl.clear();
      _tags.clear();
      _weather = 'sunny';
    });
  }

  void _openEntry(DocumentReference ref) {
    final route = (widget.entryDetailRouteName ?? '').trim();
    if (route.isEmpty) return;
    final param = (widget.entryParamName ?? 'entryRef').trim().isEmpty
        ? 'entryRef'
        : widget.entryParamName!.trim();
    context.pushNamed(
      route,
      queryParameters: <String, dynamic>{
        param: serializeParam(ref, ParamType.DocumentReference),
      }.withoutNulls,
      extra: <String, dynamic>{param: ref},
    );
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
            // bottom layer — the journal
            Positioned.fill(child: _viewScreen()),
            // editor — slides over from the right
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
        // pinned ink hero
        _hero(topInset),
        // scrollable journal
        Expanded(
          child: q == null
              ? _noProject()
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: q.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return _loading();
                    }
                    final docs = (snap.data?.docs ?? const [])
                        .where((d) => _matches(d.data()))
                        .toList();
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(_hPad, 18, _hPad, 24),
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
        // pinned bottom composer
        _bottomComposer(bottomInset),
      ],
    );
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
      final ts = d.data()['createdAt'];
      if (ts is! Timestamp) continue; // pending serverTimestamp
      final key = _dayKey(ts.toDate());
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
    final temp = d['temp'];
    final tags = (d['tags'] as List?)?.whereType<String>().toList() ?? const [];
    final photos =
        (d['photoUrls'] as List?)?.whereType<String>().toList() ?? const [];
    final ts = d['createdAt'];
    final time = ts is Timestamp ? _timeLabel(ts.toDate()) : '';

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
          onTap: () => _openEntry(doc.reference),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_weatherIcon(weather),
                              size: 12, color: _inkMute),
                          if (temp is num) ...[
                            const SizedBox(width: 4),
                            Text('${temp.round()}°',
                                style: const TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _ink)),
                          ],
                        ],
                      ),
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
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photos[i],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Container(width: 72, height: 72, color: _surface),
                      ),
                    ),
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

  Widget _bottomComposer(double bottomInset) => Container(
        decoration: const BoxDecoration(
          color: _paper,
          border: Border(top: BorderSide(color: _hairline)),
        ),
        padding: EdgeInsets.fromLTRB(_hPad, 12, _hPad, 12 + bottomInset + 8),
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

    return Container(
      color: _editorBg,
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
                  child: Column(
                    children: [
                      Text('New site entry',
                          style: TextStyle(
                              fontFamily: _displayFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                    ],
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
              padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 24),
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
                  _label('TAGS'),
                  const SizedBox(height: 8),
                  _tagSelector(),
                ],
              ),
            ),
          ),
          // save bar
          Container(
            decoration: const BoxDecoration(
              color: _paper,
              border: Border(top: BorderSide(color: _fieldBorder)),
            ),
            padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saveEntry,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: _ink, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: _paper),
                      SizedBox(width: 8),
                      Text('Save entry',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _paper)),
                    ],
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

  Widget _tagSelector() => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in _suggestedTags)
            GestureDetector(
              onTap: () => setState(() {
                if (_tags.contains(t)) {
                  _tags.remove(t);
                } else {
                  _tags.add(t);
                }
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _tags.contains(t) ? _ink : _paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: _tags.contains(t) ? _ink : _fieldBorder),
                ),
                child: Text(t,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: _tags.contains(t)
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: _tags.contains(t) ? _paper : _inkMute)),
              ),
            ),
        ],
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
