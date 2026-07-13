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

import 'index.dart'; // Imports other custom widgets

import 'package:flutter/services.dart'; // SystemUiOverlayStyle
import 'package:cloud_firestore/cloud_firestore.dart';

// ======================= DetailSiteBookPageView =============================
//
// The site-book ENTRY DETAIL, extracted from SiteBookPageView into its own
// routed page (DetailSiteBookPage) so it gets native push/pop + edge-swipe
// back for free — no in-widget overlay, no PopScope juggling.
//
// It resolves the entry to show from `entryRef` (passed by the widget param if
// FlutterFlow wires it, otherwise read straight off the route query string, the
// same way ToDoListPageView reads its projectRef), then streams that document.
//
// Navigate to it from the list with:
//   context.pushNamed(
//     'DetailSiteBookPage',
//     queryParameters: {
//       'entryRef': serializeParam(doc.reference, ParamType.DocumentReference),
//     }.withoutNulls,
//   );

class DetailSiteBookPageView extends StatefulWidget {
  const DetailSiteBookPageView({
    super.key,
    this.width,
    this.height,
    this.entryRef,
  });

  final double? width;
  final double? height;
  final DocumentReference? entryRef;

  @override
  State<DetailSiteBookPageView> createState() => _DetailSiteBookPageViewState();
}

class _DetailSiteBookPageViewState extends State<DetailSiteBookPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);

  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';

  static const double _hPad = 20;

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

  DocumentReference? _ref;
  bool _resolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return; // resolve the entry ref once (needs context)
    _resolved = true;
    _ref =
        widget.entryRef ?? _readRefFromRoute('entryRef', 'site_book_entries');
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

  void _back() => context.safePop();

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

  // =====================================================================
  // BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: _ref == null
            ? _notFound()
            : StreamBuilder<DocumentSnapshot<Object?>>(
                stream: _ref!.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return _loading();
                  }
                  final data =
                      (snap.data?.data() as Map<String, dynamic>?) ?? const {};
                  if (data.isEmpty) return _notFound();
                  return _detail(data);
                },
              ),
      ),
    );
  }

  Widget _detail(Map<String, dynamic> d) {
    final topInset = MediaQuery.of(context).viewPadding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

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

    return Column(
      children: [
        // ink masthead
        Container(
          width: double.infinity,
          color: const Color(0xFF808789),
          padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _circleBtn(Icons.arrow_back_ios_new_rounded, _back, size: 16),
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
                    border:
                        Border(top: BorderSide(color: _paper.withOpacity(0.1))),
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
  Widget _loading() => Column(
        children: [
          _bareMasthead(),
          const Expanded(
            child: Center(
              child: Text('Loading entry…',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _faint)),
            ),
          ),
        ],
      );

  Widget _notFound() => Column(
        children: [
          _bareMasthead(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.article_outlined, size: 30, color: _faint),
                  SizedBox(height: 10),
                  Text('Entry not available',
                      style: TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _inkMute)),
                ],
              ),
            ),
          ),
        ],
      );

  // A minimal ink header (back only) for the loading / not-found states.
  Widget _bareMasthead() {
    final topInset = MediaQuery.of(context).viewPadding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF808789),
      padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 18),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_ios_new_rounded, _back, size: 16),
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
          const SizedBox(width: 38, height: 38),
        ],
      ),
    );
  }
}
