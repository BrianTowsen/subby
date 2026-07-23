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

import '/custom_code/actions/index.dart';

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// QuotesReceivedView — owner reviews & compares quotes on the active
/// project.
///
/// Streams projects/{id}/quotes. Accept / Decline updates status.
class QuotesReceivedView extends StatefulWidget {
  const QuotesReceivedView(
      {super.key,
      this.width,
      this.height,
      this.inviteRouteName,
      this.quoteDetailRouteName});
  final double? width;
  final double? height;

  /// Optional FlutterFlow route name for the "Invite trades" button.
  final String? inviteRouteName;

  /// FlutterFlow route name of the Quote Detail page (QuoteDetailView).
  final String? quoteDetailRouteName;
  @override
  State<QuotesReceivedView> createState() => _QuotesReceivedViewState();
}

class _QuotesReceivedViewState extends State<QuotesReceivedView> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _green = Color(0xFF4E504F);
  static const Color _success = Color(0xFF0CAC47); // success / awarded green
  static const Color _lime = Color(0xFFE7E247); // primary CTA / positive accent
  static const Color _sageBorder = Color(0xFFCBD8DD);
  static const Color _coral = Color(0xFF566670);
  static const Color _cobalt = Color(0xFF4E504F);
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kActiveQuotePath = 'subby_active_quote_path';

  DocumentReference<Map<String, dynamic>>? _projectRef;
  String _projectName = 'Project';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _projSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;
    final ref = FirebaseFirestore.instance.doc(path);
    setState(() => _projectRef = ref);
    _projSub = ref.snapshots().listen((snap) {
      final d = snap.data() ?? const {};
      final name =
          (d['name'] ?? d['projectName'] ?? d['title'] ?? 'Project').toString();
      if (mounted) setState(() => _projectName = name);
    });
  }

  Future<void> _setStatus(DocumentReference ref, String status) async {
    try {
      if (status == 'accepted') {
        // Award this quote and close the tender: decline the other
        // still-submitted quotes in the same batch.
        final batch = FirebaseFirestore.instance.batch();
        batch.update(ref,
            {'status': 'accepted', 'decidedAt': FieldValue.serverTimestamp()});
        final others =
            await ref.parent.where('status', isEqualTo: 'submitted').get();
        for (final o in others.docs) {
          if (o.reference.path == ref.path) continue;
          batch.update(o.reference, {
            'status': 'declined',
            'decidedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } else {
        await ref.update(
            {'status': status, 'decidedAt': FieldValue.serverTimestamp()});
      }
    } catch (_) {}
  }

  Future<void> _openDetail(DocumentReference ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveQuotePath, ref.path);
    if (!mounted) return;
    final r = widget.quoteDetailRouteName;
    if (r != null && r.isNotEmpty) {
      context.pushNamed(r);
    } else {
      showAppToast(
          context,
          'Set quoteDetailRouteName on QuotesReceivedView to open quotes.',
          false);
    }
  }

  String _awardDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    }
    return '';
  }

  String _fmt(num v) {
    final n = v.round();
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(
                0xFF2F3A4C), // steel — matches DashboardPageView hero
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _circleBtn(),
                  Expanded(
                    child: Column(children: [
                      Text(_projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                      const SizedBox(height: 2),
                      Text('QUOTES RECEIVED',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5))),
                    ]),
                  ),
                  _inviteBtn(),
                ]),
              ],
            ),
          ),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  // Scrolls away with the page — dark colour continues below the pinned bar.
  Widget _heroLower() => Container(
        width: double.infinity,
        color: const Color(0xFF2F3A4C),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COMPARE & ACCEPT QUOPTES',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: _paper.withOpacity(0.55))),
            const SizedBox(height: 4),
            const Text('Quotes Received',
                style: TextStyle(
                    fontFamily: _display,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: _paper)),
          ],
        ),
      );

  Widget _list() {
    final ref = _projectRef;
    if (ref == null) {
      return const Center(
          child: Text('No project selected.',
              style: TextStyle(
                  fontFamily: _body,
                  color: _faint,
                  fontWeight: FontWeight.w600)));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ref.collection('quotes').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        // sort: submitted/accepted first, then by total asc
        docs.sort((a, b) {
          int rank(String s) => s == 'accepted'
              ? 0
              : (s == 'submitted'
                  ? 1
                  : (s == 'quoting'
                      ? 2
                      : (s == 'viewed' ? 3 : (s == 'declined' ? 5 : 4))));
          final ra = rank((a.data()['status'] ?? 'invited').toString());
          final rb = rank((b.data()['status'] ?? 'invited').toString());
          if (ra != rb) return ra.compareTo(rb);
          final ta = (a.data()['total'] ?? 1e12) as num;
          final tb = (b.data()['total'] ?? 1e12) as num;
          return ta.compareTo(tb);
        });
        final submitted = docs
            .where((d) => (d.data()['status'] ?? '').toString() == 'submitted')
            .length;
        final awarded = docs
            .where((d) => (d.data()['status'] ?? '').toString() == 'accepted')
            .length;
        final viewed = docs
            .where((d) => (d.data()['status'] ?? '').toString() == 'viewed')
            .length;
        final summaryParts = <String>[
          '${docs.length} quote${docs.length == 1 ? '' : 's'}',
        ];
        if (awarded > 0) summaryParts.add('$awarded awarded');
        if (submitted > 0) summaryParts.add('$submitted submitted');
        if (viewed > 0) summaryParts.add('$viewed viewed');
        final summary = summaryParts.join(' · ');
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Hero lower block scrolls away; only the top bar pins.
            _heroLower(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary,
                      style: const TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _inkMute)),
                  const SizedBox(height: 14),
                  if (docs.isEmpty)
                    _emptyCard()
                  else
                    for (var i = 0; i < docs.length; i++) _quoteCard(docs[i]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emptyCard() => Container(
        decoration: BoxDecoration(
            color: const Color(0xFFF2F5F6),
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(18),
        child: const Text(
            'No team members invited yet. Invite team members from the project team to request quotes.',
            style: TextStyle(
                fontFamily: _body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _inkMute)),
      );

  Widget _quoteCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final status = (d['status'] ?? 'invited').toString();
    final name = (d['listingName'] ?? 'Trade').toString();
    final total = (d['total'] ?? 0) as num;
    final lead = (d['leadWeeks'] ?? 0);
    final dep = (d['depositPct'] ?? 0);
    final hasFile = (d['fileName'] ?? '').toString().isNotEmpty;
    final fileName = (d['fileName'] ?? '').toString();
    final vatIncl = d['vatIncluded'] != false;
    final submitted = status == 'submitted' || status == 'accepted';
    final accepted = status == 'accepted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          // Tapping anywhere on the quote block opens the full Quote Detail.
          onTap: () => _openDetail(doc.reference),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: submitted ? _paper : const Color(0xFFF2F5F6),
              borderRadius: BorderRadius.circular(10),
              border: submitted
                  ? Border.all(
                      color: accepted ? _sageBorder : _border,
                      width: accepted ? 1.5 : 1)
                  : null,
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: submitted ? _ink : _surface,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.storefront_rounded,
                        size: 20, color: submitted ? _paper : _faint),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _ink)),
                          const SizedBox(height: 2),
                          Text(
                              submitted
                                  ? 'Lead $lead wks · $dep% deposit'
                                  : 'Awaiting response',
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _inkMute)),
                        ]),
                  ),
                  _statusPill(status),
                ]),
                if (submitted) ...[
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openDetail(doc.reference),
                        child: Row(children: [
                          Text('R ${_fmt(total)}',
                              style: const TextStyle(
                                  fontFamily: 'Roboto Mono',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _ink)),
                          const SizedBox(width: 4),
                          Text(vatIncl ? 'incl. VAT' : 'no VAT',
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 11,
                                  color: _faint)),
                        ]),
                      ),
                    ),
                  ]),
                  if (hasFile)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(children: [
                        const Icon(Icons.picture_as_pdf_rounded,
                            size: 16, color: _green),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _ink)),
                        ),
                      ]),
                    ),
                  if (!accepted) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _setStatus(doc.reference, 'accepted'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: _lime,
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified_rounded,
                                      size: 16, color: _ink),
                                  SizedBox(width: 6),
                                  Text('Accept',
                                      style: TextStyle(
                                          fontFamily: _body,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _ink)),
                                ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      InkWell(
                        onTap: () => _setStatus(doc.reference, 'declined'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _paper,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFCBD8DD), width: 1.4)),
                          child: const Icon(Icons.close_rounded,
                              size: 19, color: _coral),
                        ),
                      ),
                    ]),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(children: [
                        const Icon(Icons.verified_rounded,
                            size: 16, color: _success),
                        const SizedBox(width: 6),
                        const Text('Awarded',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _success)),
                        if (_awardDate(d['decidedAt']).isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('· ${_awardDate(d['decidedAt'])}',
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _faint)),
                        ],
                      ]),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color fg = _faint, bg = _surface;
    IconData ic = Icons.schedule_rounded;
    String label = 'Invited';
    switch (status) {
      case 'viewed':
        fg = _cobalt;
        bg = const Color(0xFFE7EDF0);
        ic = Icons.visibility_outlined;
        label = 'Viewed';
        break;
      case 'submitted':
        fg = _green;
        bg = const Color(0xFFE7EDF0);
        ic = Icons.check_circle_rounded;
        label = 'Submitted';
        break;
      case 'quoting':
        fg = _ink;
        bg = const Color(0xFFE7EDF0);
        ic = Icons.edit_note_rounded;
        label = 'Quoting';
        break;
      case 'accepted':
        fg = _ink;
        bg = _lime;
        ic = Icons.verified_rounded;
        label = 'Accepted';
        break;
      case 'declined':
        fg = _coral;
        bg = const Color(0xFFE7EDF0);
        ic = Icons.close_rounded;
        label = 'Declined';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontFamily: _body,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: fg)),
      ]),
    );
  }

  Widget _inviteBtn() => GestureDetector(
        onTap: () {
          final r = widget.inviteRouteName;
          if (r != null && r.isNotEmpty) context.pushNamed(r);
        },
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _paper.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.person_add_alt_1_rounded, size: 15, color: _paper),
            SizedBox(width: 5),
            Text('Invite',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _paper)),
          ]),
        ),
      );

  Widget _circleBtn() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) nav.pop();
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _paper),
          ),
        ),
      );
}
