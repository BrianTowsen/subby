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

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// QuoteDetailView — owner views one quote in full (Accept / Decline).
///
/// Reads the active project + active quote id from prefs.
///
/// After ACCEPTING (awarding) a quote the owner is returned to Quotes
/// Received (quotesReceivedRouteName — defaults to 'QuotesReceived') so they
/// land back on the tender list with the award reflected.
class QuoteDetailView extends StatefulWidget {
  const QuoteDetailView(
      {super.key, this.width, this.height, this.quotesReceivedRouteName});
  final double? width;
  final double? height;

  /// FlutterFlow route name of the Quotes Received page (QuotesReceivedView).
  final String? quotesReceivedRouteName;
  @override
  State<QuoteDetailView> createState() => _QuoteDetailViewState();
}

class _QuoteDetailViewState extends State<QuoteDetailView> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _green = Color(0xFF4E504F);
  static const Color _lime = Color(0xFFE7E247); // primary CTA / positive accent
  static const Color _coral = Color(0xFF566670);
  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kActiveQuoteId = 'subby_active_quote_id';
  static const String _kActiveQuotePath = 'subby_active_quote_path';
  static const String _fallbackQuotesReceivedRoute = 'QuotesReceived';

  DocumentReference<Map<String, dynamic>>? _quoteRef;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final quotePath = (prefs.getString(_kActiveQuotePath) ?? '').trim();
    if (quotePath.isNotEmpty) {
      _quoteRef = FirebaseFirestore.instance.doc(quotePath);
    } else {
      // Legacy fallback: active project path + quote id.
      final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
      final qid = (prefs.getString(_kActiveQuoteId) ?? '').trim();
      if (path.isNotEmpty && qid.isNotEmpty) {
        _quoteRef =
            FirebaseFirestore.instance.doc(path).collection('quotes').doc(qid);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setStatus(String status) async {
    final ref = _quoteRef;
    if (ref == null) return;
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
    if (!mounted) return;

    // After AWARDING, return the owner to Quotes Received so they land back on
    // the tender list showing the award. A decline just pops.
    if (status == 'accepted') {
      final route = (widget.quotesReceivedRouteName ?? '').trim().isEmpty
          ? _fallbackQuotesReceivedRoute
          : widget.quotesReceivedRouteName!.trim();
      context.goNamed(route);
      return;
    }
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _downloadFile(String url) async {
    if (url.isEmpty) {
      showAppToast(context, 'No file attached to this quote.', false);
      return;
    }
    final uri = Uri.tryParse(url);
    bool ok = false;
    if (uri != null) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok && mounted) {
      showAppToast(context, 'Could not open the file.', false);
    }
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
    final bottom = MediaQuery.of(context).padding.bottom;
    if (_loading) {
      return Container(
          width: widget.width,
          height: widget.height,
          color: _paper,
          child: const Center(child: CircularProgressIndicator(color: _green)));
    }
    if (_quoteRef == null) {
      return Container(
          width: widget.width,
          height: widget.height,
          color: _paper,
          child: const Center(
              child: Text('No quote selected.',
                  style: TextStyle(
                      fontFamily: _body,
                      color: _faint,
                      fontWeight: FontWeight.w600))));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _quoteRef!.snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() ?? const {};
        if (snap.hasData && !(snap.data!.exists)) {
          return Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? double.infinity,
              color: _paper,
              child: const Center(
                  child: Text('Quote not found.',
                      style: TextStyle(
                          fontFamily: _body,
                          color: _faint,
                          fontWeight: FontWeight.w600))));
        }
        final status = (d['status'] ?? 'submitted').toString();
        final name = (d['listingName'] ?? 'Trade').toString();
        final excl = (d['amountExcl'] ?? 0) as num;
        final total = (d['total'] ?? 0) as num;
        final vat = (total - excl);
        final lead = (d['leadWeeks'] ?? 0);
        final dep = (d['depositPct'] ?? 0);
        final notes = (d['notes'] ?? '').toString();
        final hasFile = (d['fileName'] ?? '').toString().isNotEmpty;
        final fileUrl = (d['fileUrl'] ?? '').toString();
        final vatIncl = d['vatIncluded'] != false;
        final decided = status == 'accepted' || status == 'declined';

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
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _paper)),
                          const SizedBox(height: 2),
                          Text('QUOTE DETAIL',
                              style: TextStyle(
                                  fontFamily: _body,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                  color: _paper.withOpacity(0.5))),
                        ])),
                        const SizedBox(width: 38),
                      ]),
                    ]),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Hero lower block scrolls away; only the bar pins.
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF2F3A4C),
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vatIncl ? 'TOTAL INCL. VAT' : 'TOTAL (NO VAT)',
                                style: TextStyle(
                                    fontFamily: _body,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: _paper.withOpacity(0.55))),
                            const SizedBox(height: 4),
                            Text('R ${_fmt(total)}',
                                style: const TextStyle(
                                    fontFamily: _display,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: _paper,
                                    height: 1.0)),
                          ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _card([
                            _row('Amount (excl. VAT)', 'R ${_fmt(excl)}'),
                            _line1(),
                            _row('VAT', 'R ${_fmt(vat)}'),
                            _line1(),
                            _row('Total', 'R ${_fmt(total)}', bold: true),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child:
                                    _stat('LEAD TIME', 'Start in $lead wks')),
                            const SizedBox(width: 10),
                            Expanded(child: _stat('DEPOSIT', '$dep% upfront')),
                          ]),
                          const SizedBox(height: 12),
                          if (notes.isNotEmpty)
                            _card([
                              const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('INCLUSIONS / EXCLUSIONS',
                                      style: TextStyle(
                                          fontFamily: _body,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                          color: _faint))),
                              const SizedBox(height: 6),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(notes,
                                      style: const TextStyle(
                                          fontFamily: _body,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _ink,
                                          height: 1.45))),
                            ]),
                          if (hasFile) ...[
                            const SizedBox(height: 12),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _downloadFile(fileUrl),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: _paper,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _border)),
                                  padding: const EdgeInsets.all(13),
                                  child: Row(children: [
                                    Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: _ink,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Icon(
                                            Icons.picture_as_pdf_rounded,
                                            size: 21,
                                            color: _paper)),
                                    const SizedBox(width: 11),
                                    Expanded(
                                        child: Text(
                                            (d['fileName'] ?? 'Quote.pdf')
                                                .toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _body,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: _ink))),
                                    const Icon(Icons.download_rounded,
                                        size: 20, color: _ink),
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!decided)
                Container(
                  decoration: const BoxDecoration(
                      color: _paper,
                      border: Border(top: BorderSide(color: _surface))),
                  padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
                  child: Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _setStatus('accepted'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _lime,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded,
                                    size: 19, color: _ink),
                                SizedBox(width: 8),
                                Text('Accept & award',
                                    style: TextStyle(
                                        fontFamily: _body,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: _ink)),
                              ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _setStatus('declined'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _paper,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFCBD8DD), width: 1.4)),
                          child: const Icon(Icons.close_rounded,
                              size: 22, color: _coral)),
                    ),
                  ]),
                )
              else
                Container(
                  width: double.infinity,
                  color: status == 'accepted'
                      ? const Color(0xFFE7EDF0)
                      : const Color(0xFFE7EDF0),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            status == 'accepted'
                                ? Icons.verified_rounded
                                : Icons.cancel_rounded,
                            size: 18,
                            color: status == 'accepted' ? _green : _coral),
                        const SizedBox(width: 8),
                        Text(
                            status == 'accepted'
                                ? 'Awarded to this team member'
                                : 'Declined',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: status == 'accepted' ? _green : _coral)),
                      ]),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: children),
      );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Expanded(
              child: Text(l,
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: bold ? 14 : 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: _ink))),
          Text(v,
              style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: _ink)),
        ]),
      );

  Widget _line1() => Container(height: 1, color: _line);

  Widget _stat(String l, String v) => Container(
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border)),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l,
              style: const TextStyle(
                  fontFamily: _body,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: _faint)),
          const SizedBox(height: 3),
          Text(v,
              style: const TextStyle(
                  fontFamily: _display,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink)),
        ]),
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
                  size: 16, color: _paper)),
        ),
      );
}
