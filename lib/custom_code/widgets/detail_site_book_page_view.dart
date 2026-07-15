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

import 'package:flutter/services.dart'; // SystemUiOverlayStyle
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart'; // currentUserReference (owner gate)

// ======================= DetailSiteBookPageView =============================
//
// The site-book ENTRY DETAIL, extracted from SiteBookPageView into its own
// routed page (DetailSiteBookPage) so it gets native push/pop + edge-swipe
// back for free — no in-widget overlay, no PopScope juggling.
//
// HEADER (this revision): the masthead is now a 1:1 match of
// SiteBookPageView's hero — same 3F5C69 ink block, same paddings/spacers, a
// centered project-name + SITE ENTRY eyebrow top row (back circle left, an
// owner-only delete circle + weather pill right), and a large stat block
// (avatar + LOGGED BY / author name at 34px, with a right-aligned date + media
// meta column). Because the vertical metrics are identical to the list hero,
// the header ends at exactly the same height.
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
  static const Color _warn =
      Color(0xFFAC0C0C); // delete-dialog red (matches DetailTaskPageView)

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

  // Short forms for the masthead's right-aligned date column.
  static const List<String> _weekdaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' //
  ];
  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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

  // =====================================================================
  // DELETE — gated to the PROJECT OWNER (matches DetailTaskPageView).
  //
  // The owner is resolved once from the entry's projectRef → project.ownerRef
  // and compared against the signed-in user. Only then does the masthead show
  // the delete affordance, and only the owner's tap can remove the doc.
  // =====================================================================
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

  // Only the project owner may delete this entry.
  bool _isOwner() {
    final me = currentUserReference;
    if (me == null || _projectOwnerRef == null) return false;
    return _projectOwnerRef!.path == me.path;
  }

  Future<void> _confirmDelete() async {
    FocusScope.of(context).unfocus();
    await _showDeleteDialog(
      icon: Icons.delete_rounded,
      title: 'Delete this entry?',
      message:
          'This site entry and its photos will be permanently removed. This can’t be undone.',
      confirmLabel: 'Delete entry',
      onConfirm: _deleteEntry,
    );
  }

  Future<void> _deleteEntry() async {
    final ref = _ref;
    if (ref == null) return;
    try {
      await ref.delete();
      if (!mounted) return;
      _toast('Entry deleted.');
      _back();
    } catch (e) {
      debugPrint('🔥 Delete site entry failed: $e');
      if (mounted) _toast('Could not delete. Please try again.');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF3F5C69), // slate
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w700)),
      ));
  }

  // Centred destructive confirm dialog — shared "delete warning" module
  // (clay badge, 22-radius card, filled clay confirm + outlined cancel over a
  // 55%-black scrim), identical to DetailTaskPageView._showDeleteDialog.
  Future<void> _showDeleteDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
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
              borderRadius: BorderRadius.circular(22),
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
                    color: _warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _warn.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: _warn, size: 30),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _warn,
                        borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
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

  // Compact date for the masthead meta column (e.g. "Wed 15 Jul · 08:12").
  String _shortDate(DateTime dt) {
    final l = dt.toLocal();
    return '${_weekdaysShort[l.weekday - 1]} ${l.day} ${_monthsShort[l.month - 1]} · ${_timeLabel(l)}';
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

  // Centered project name in the masthead top row (streamed off the entry's
  // projectRef) — 1:1 with SiteBookPageView._heroName.
  Widget _heroName(Map<String, dynamic> d) {
    const style = TextStyle(
        fontFamily: _bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _paper);
    final ref = d['projectRef'] as DocumentReference?;
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
                  // Resolve the project owner off the live snapshot so the
                  // delete affordance appears only for the owner.
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _ensureProjectOwner(data));
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
    final dateShort = _shortDate(_dateOf(d['createdAt']));

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
    final metaLabel = metaParts.join(' · ');

    return Column(
      children: [
        // ink masthead — matches SiteBookPageView._hero (same paddings,
        // 14-spacer, 38-row, 16-gap, 34px stat), so it ends the same height.
        Container(
          width: double.infinity,
          color: const Color(0xFF3F5C69),
          padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row: back · centered project name + SITE ENTRY eyebrow ·
              // owner-only delete + weather pill
              Row(
                children: [
                  _circleBtn(Icons.arrow_back_ios_new_rounded, _back, size: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          _heroName(d),
                          const SizedBox(height: 2),
                          Text('SITE ENTRY',
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
                  if (_isOwner()) ...[
                    _circleBtn(Icons.delete_outline_rounded, _confirmDelete,
                        size: 18),
                    const SizedBox(width: 8),
                  ],
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
              const SizedBox(height: 16),
              // stat block pinned to the same height as SiteBookPageView's
              // hero stat (~51) so the masthead ends at an identical height.
              SizedBox(
                height: 51,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: _paper.withOpacity(0.14),
                                shape: BoxShape.circle),
                            child: Text(_initials(author),
                                style: const TextStyle(
                                    fontFamily: _displayFont,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _paper)),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LOGGED BY',
                                    style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                        color: _paper.withOpacity(0.55))),
                                const SizedBox(height: 4),
                                Text(author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: _displayFont,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.6,
                                        height: 1.05,
                                        color: _paper)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(dateShort,
                              style: TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _paper.withOpacity(0.6))),
                          if (metaLabel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(metaLabel,
                                style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _paper.withOpacity(0.45))),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  // A minimal ink header (back only) for the loading / not-found states —
  // kept the same height as the full masthead's top row + spacer.
  Widget _bareMasthead() {
    final topInset = MediaQuery.of(context).viewPadding.top;
    return Container(
      width: double.infinity,
      color: const Color(0xFF3F5C69),
      padding: EdgeInsets.fromLTRB(_hPad, topInset + 14, _hPad, 18),
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
