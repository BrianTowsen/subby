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

import '/custom_code/actions/index.dart';

import 'index.dart'; // Imports other custom widgets

import 'index.dart'; // Imports other custom widgets

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// QuoteRequestView — the trade opens an invitation: view shared drawings &
/// documents, then prepare a quote. Marks status 'viewed'.
class QuoteRequestView extends StatefulWidget {
  const QuoteRequestView(
      {super.key, this.width, this.height, this.submitQuoteRouteName});
  final double? width;
  final double? height;

  /// FlutterFlow route name of the Submit Quote page (SubmitQuoteView).
  final String? submitQuoteRouteName;
  @override
  State<QuoteRequestView> createState() => _QuoteRequestViewState();
}

class _QuoteRequestViewState extends State<QuoteRequestView> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _green = Color(0xFF4E504F);
  static const Color _lime = Color(0xFFE7E247); // primary CTA / positive accent
  static const Color _cobalt = Color(0xFF4E504F);
  static const String _body = 'Inter';
  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kActiveQuotePath = 'subby_active_quote_path';

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _quoteRef;
  String _projectName = 'Project';
  DocumentReference? _ownerRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;
  bool _saving = false;
  String _status = 'invited';
  String _pmMessage = '';

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
    final quotePath = (prefs.getString(_kActiveQuotePath) ?? '').trim();
    DocumentReference<Map<String, dynamic>>? quoteRef;
    DocumentReference<Map<String, dynamic>>? projectRef;
    if (quotePath.isNotEmpty) {
      quoteRef = FirebaseFirestore.instance.doc(quotePath);
      projectRef = quoteRef.parent.parent;
    } else {
      // Legacy fallback: active project + this trade's uid.
      final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
      if (path.isNotEmpty) {
        projectRef = FirebaseFirestore.instance.doc(path);
        final uid = currentUserReference?.id;
        if (uid != null) quoteRef = projectRef.collection('quotes').doc(uid);
      }
    }
    if (projectRef == null) return;
    setState(() {
      _projectRef = projectRef;
      _quoteRef = quoteRef;
    });
    _projSub = projectRef.snapshots().listen((snap) {
      final d = snap.data() ?? const {};
      final name =
          (d['name'] ?? d['projectName'] ?? d['title'] ?? 'Project').toString();
      final ownerRef = d['ownerRef'];
      if (mounted) {
        setState(() {
          _projectName = name;
          if (ownerRef is DocumentReference) _ownerRef = ownerRef;
        });
      }
    });
    // Mark as viewed ONLY if the quote exists and is still 'invited' —
    // never downgrade a submitted/decided quote, never create orphan docs.
    final qref = quoteRef;
    if (qref != null) {
      try {
        final snap = await qref.get();
        final status = (snap.data()?['status'] ?? '').toString();
        final msg = (snap.data()?['message'] ?? '').toString();
        if (mounted && msg.isNotEmpty) setState(() => _pmMessage = msg);
        if (snap.exists && (status == 'invited' || status.isEmpty)) {
          await qref.set({
            'status': 'viewed',
            'viewedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          if (mounted) setState(() => _status = 'viewed');
        } else if (snap.exists) {
          if (mounted) setState(() => _status = status);
        }
      } catch (_) {}
    }
  }

  Future<void> _prepare() async {
    final qref = _quoteRef;
    if (qref == null || _saving) return;
    setState(() => _saving = true);
    try {
      await qref.set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    final r = widget.submitQuoteRouteName;
    if (r != null && r.isNotEmpty) {
      context.pushNamed(r);
    } else {
      showAppToast(context, 'Continue to Submit Quote.', true);
    }
  }

  // Trade accepts the invitation to tender. Distinct from the OWNER's
  // 'accepted' (award) status: the trade-side accept uses 'quoting' so the
  // owner's QuotesReceivedView award/decline logic is untouched.
  Future<void> _accept() async {
    final qref = _quoteRef;
    if (qref == null || _saving) return;
    setState(() => _saving = true);
    try {
      await qref.set({
        'status': 'quoting',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) setState(() => _status = 'quoting');
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
        context,
        'Invitation accepted — review the drawings, then prepare your quote.',
        true);
  }

  // Trade declines the invitation. Sets 'declined' so the invite drops off
  // their dashboard and the owner sees they've passed.
  Future<void> _decline() async {
    final qref = _quoteRef;
    if (qref == null || _saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _paper,
        title: const Text('Decline this invite?',
            style: TextStyle(
                fontFamily: _body, fontWeight: FontWeight.w800, color: _ink)),
        content: const Text(
            'The project manager will see that you\'ve passed on this quote.',
            style: TextStyle(
                fontFamily: _body, fontWeight: FontWeight.w600, color: _ink)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(
                      fontFamily: _body,
                      fontWeight: FontWeight.w700,
                      color: _ink))),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Decline',
                  style: TextStyle(
                      fontFamily: _body,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC0392B)))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await qref.set({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(context, 'Invite declined.', true);
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Widget _bottomBar(double bottom) {
    // Once accepted ('quoting') or already submitted, show the quote CTA.
    // Before that, the two choices are Accept and Decline.
    final accepted = _status == 'quoting' || _status == 'submitted';
    return Container(
      decoration: const BoxDecoration(
          color: _paper, border: Border(top: BorderSide(color: _surface))),
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
      child: Row(children: [
        if (_status != 'submitted') ...[
          _outlineBtn('Decline', _saving ? null : _decline),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: accepted
              ? _primaryBtn(
                  icon: Icons.edit_document,
                  label: 'Prepare your quote',
                  color: _lime,
                  onTap: _saving ? null : _prepare)
              : _primaryBtn(
                  icon: Icons.check_rounded,
                  label: 'Accept invitation',
                  color: _lime,
                  onTap: _saving ? null : _accept),
        ),
      ]),
    );
  }

  Widget _outlineBtn(String label, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD8DD), width: 1.4)),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: _body,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink)),
        ),
      );

  Widget _primaryBtn(
          {required IconData icon,
          required String label,
          required Color color,
          required VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 19, color: _ink),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final ref = _projectRef;
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  Text('QUOTE REQUEST',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: _paper.withOpacity(0.5))),
                ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: _cobalt.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.visibility_outlined,
                          size: 12, color: Color(0xFFCBD8DD)),
                      SizedBox(width: 4),
                      Text('Viewed',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFCBD8DD))),
                    ])),
              ]),
            ]),
          ),
          Expanded(
            child: ref == null
                ? const Center(
                    child: Text('No project selected.',
                        style: TextStyle(
                            fontFamily: _body,
                            color: _faint,
                            fontWeight: FontWeight.w600)))
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Hero lower block scrolls away; only the bar pins.
                      Container(
                        width: double.infinity,
                        color: _paper,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                        child: Container(
                          decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.all(11),
                          child: Row(children: [
                            Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: _green, shape: BoxShape.circle),
                                child: const Text('JM',
                                    style: TextStyle(
                                        fontFamily: 'Inter Tight',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _paper))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('Invited by the project manager',
                                      style: TextStyle(
                                          fontFamily: _body,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _ink)),
                                  Text('Review the drawings, then quote',
                                      style: TextStyle(
                                          fontFamily: _body,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _inkMute)),
                                ])),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _pmCard(),
                            const SizedBox(height: 18),
                            if (_pmMessage.isNotEmpty) ...[
                              _messageCard(),
                              const SizedBox(height: 16),
                            ],
                            _docsSection(ref, 'DRAWINGS', 'drawing',
                                Icons.architecture_rounded),
                            const SizedBox(height: 14),
                            _docsSection(ref, 'DOCUMENTS', 'document',
                                Icons.description_rounded),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          _bottomBar(bottom),
        ],
      ),
    );
  }

  void _openDoc(Map<String, dynamic> d) {
    final url = (d['url'] ??
            d['fileUrl'] ??
            d['file_url'] ??
            d['downloadUrl'] ??
            d['download_url'])
        ?.toString()
        .trim();
    if (url != null && url.isNotEmpty) {
      launchURL(url);
      return;
    }
    showAppToast(context, 'No file attached to this document.', false);
  }

  Widget _docsSection(DocumentReference<Map<String, dynamic>> ref, String title,
      String category, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontFamily: _body,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _inkMute)),
      const SizedBox(height: 9),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('project_documents')
            .where('projectRef', isEqualTo: ref)
            .where('visibility', isEqualTo: 'shared')
            .snapshots(),
        builder: (context, snap) {
          final all = snap.data?.docs ?? [];
          final rows = all.where((d) {
            final c = (d.data()['category'] ?? d.data()['cat'] ?? '')
                .toString()
                .toLowerCase();
            final isDrawing = c.contains('draw') || c.contains('plan');
            return category == 'drawing' ? isDrawing : !isDrawing;
          }).toList();
          if (rows.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF2F5F6),
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(13),
              child: Text('No shared ${category}s.',
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _inkMute)),
            );
          }
          return Container(
            decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++)
                InkWell(
                  onTap: () => _openDoc(rows[i].data()),
                  child: Container(
                    decoration: BoxDecoration(
                        border: i == 0
                            ? null
                            : const Border(top: BorderSide(color: _line))),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    child: Row(children: [
                      Icon(icon, size: 22, color: _green),
                      const SizedBox(width: 11),
                      Expanded(
                          child: Text(
                              (rows[i].data()['title'] ??
                                      rows[i].data()['name'] ??
                                      'File')
                                  .toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink))),
                      const Icon(Icons.open_in_new_rounded,
                          size: 19, color: _ink),
                    ]),
                  ),
                ),
            ]),
          );
        },
      ),
    ]);
  }

  Widget _messageCard() => Container(
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MESSAGE FROM PROJECT MANAGER',
              style: TextStyle(
                  fontFamily: _body,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _inkMute)),
          const SizedBox(height: 8),
          Text(_pmMessage,
              style: const TextStyle(
                  fontFamily: _body,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: _ink)),
        ]),
      );

  // Phone helpers — mirror ListingDetailPageView so the manager calling card
  // dials and opens WhatsApp consistently across the app.
  String _telNumber(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  // wa.me needs an international number with no '+'/spaces. Local SA numbers
  // beginning with 0 are converted to the 27 country code.
  String _waNumber(String s) {
    var n = s.replaceAll(RegExp(r'[^0-9+]'), '').replaceAll('+', '');
    if (n.isEmpty) return '';
    if (n.startsWith('0')) n = '27${n.substring(1)}';
    return n;
  }

  void _noContactSnack(String what) {
    showAppToast(context, 'No $what for this project manager.', false);
  }

  // Project Manager calling card — mirrors the shared ProjectDetailPageView
  // owner card: reads the project's ownerRef profile (name + phone) and
  // exposes call / WhatsApp actions.
  Widget _pmCard() {
    final ref = _ownerRef;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(10)),
      child: FutureBuilder<DocumentSnapshot<Object?>>(
        future: ref?.get(),
        builder: (context, snap) {
          final od = (snap.data?.data() as Map<String, dynamic>?) ??
              const <String, dynamic>{};
          final nm =
              (od['display_name'] ?? 'Project manager').toString().trim();
          final phone =
              (od['phone_number'] ?? od['phoneNumber'] ?? od['phone'] ?? '')
                  .toString()
                  .trim();
          final display = nm.isEmpty ? 'Project manager' : nm;
          return Row(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _paper, borderRadius: BorderRadius.circular(10)),
              child: Text(_initials(display),
                  style: const TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PROJECT MANAGER',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: _faint)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Flexible(
                          child: Text(display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: _body,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _ink))),
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded, size: 14, color: _ink),
                    ]),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.call_rounded, size: 13, color: _faint),
                        const SizedBox(width: 5),
                        Text(phone,
                            style: const TextStyle(
                                fontFamily: _body,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _inkMute)),
                      ]),
                    ],
                  ]),
            ),
            const SizedBox(width: 8),
            _pmRound(Icons.call_rounded, _paper, _ink, () {
              final n = _telNumber(phone);
              if (n.isNotEmpty) {
                launchURL('tel:$n');
              } else {
                _noContactSnack('phone number');
              }
            }),
            const SizedBox(width: 8),
            _pmRound(Icons.chat_rounded, const Color(0xFF25D366), _paper, () {
              final n = _waNumber(phone);
              if (n.isNotEmpty) {
                launchURL('https://wa.me/$n');
              } else {
                _noContactSnack('WhatsApp number');
              }
            }),
          ]);
        },
      ),
    );
  }

  Widget _pmRound(IconData icon, Color bg, Color fg, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: fg),
          ),
        ),
      );

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '\u2013';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

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
