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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// InboxView — a trade's quote requests across all projects.
/// collectionGroup('quotes') where listingRef == current user. Tapping a row
/// sets the active project so the Quote Request page can open it.
class InboxView extends StatefulWidget {
  const InboxView(
      {super.key, this.width, this.height, this.quoteRequestRouteName});
  final double? width;
  final double? height;

  /// FlutterFlow route name of the Quote Request page (QuoteRequestView).
  final String? quoteRequestRouteName;
  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _green = Color(0xFF5D737E);
  static const Color _lime = Color(0xFFE7E247); // positive / awarded accent
  static const Color _coral = Color(0xFF566670);
  static const Color _cobalt = Color(0xFF5D737E);
  static const String _body = 'Inter';
  static const String _kActiveQuotePath = 'subby_active_quote_path';

  Future<void> _open(DocumentReference<Map<String, dynamic>> quoteRef) async {
    // Store the full quote path — QuoteRequestView / SubmitQuoteView derive
    // the project from it. Deliberately does NOT touch the owner-side
    // active-project pref, so checking the inbox never switches projects.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveQuotePath, quoteRef.path);
    if (!mounted) return;
    final r = widget.quoteRequestRouteName;
    if (r != null && r.isNotEmpty) {
      context.pushNamed(r);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            backgroundColor: _ink,
            content: Text(
                'Set quoteRequestRouteName on InboxView to open requests.',
                style: TextStyle(
                    fontFamily: _body,
                    fontWeight: FontWeight.w700,
                    color: _paper))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final me = currentUserReference;
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: _ink,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 20),
            child: Row(children: [
              _circleBtn(),
              Expanded(
                  child: Column(children: const [
                Text('Quote requests',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _paper)),
                SizedBox(height: 2),
                Text('YOUR INBOX',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0x80FFFFFF))),
              ])),
              const SizedBox(width: 38),
            ]),
          ),
          Expanded(
            child: me == null
                ? const Center(
                    child: Text('Sign in to see quote requests.',
                        style: TextStyle(
                            fontFamily: _body,
                            color: _faint,
                            fontWeight: FontWeight.w600)))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collectionGroup('quotes')
                        .where('providerRef', isEqualTo: me)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'Couldn\'t load requests.\nCheck the collection-group rule and\nproviderRef index on "quotes".',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: _body,
                                        color: _faint,
                                        fontWeight: FontWeight.w600))));
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'No quote requests yet.\nProjects that invite you will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: _body,
                                        color: _faint,
                                        fontWeight: FontWeight.w600))));
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [for (final d in docs) _row(d)],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final status = (d['status'] ?? 'invited').toString();
    final projectRef = doc.reference.parent.parent;

    return GestureDetector(
      onTap: () => _open(doc.reference),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border)),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _surface, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.request_quote_outlined,
                  size: 22, color: _ink)),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: projectRef?.get(),
              builder: (context, ps) {
                final pd = ps.data?.data() ?? const {};
                final pname = (pd['name'] ??
                        pd['projectName'] ??
                        pd['title'] ??
                        'Project')
                    .toString();
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                      const SizedBox(height: 3),
                      Text(_statusText(status),
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _inkMute)),
                    ]);
              },
            ),
          ),
          _statusPill(status),
        ]),
      ),
    );
  }

  String _statusText(String s) {
    switch (s) {
      case 'submitted':
        return 'Quote submitted';
      case 'accepted':
        return 'You were awarded 🎉';
      case 'declined':
        return 'Not selected';
      case 'viewed':
        return 'Viewed · continue your quote';
      default:
        return 'New request · tap to view';
    }
  }

  Widget _statusPill(String status) {
    Color fg = _faint, bg = _surface;
    String label = 'Invited';
    switch (status) {
      case 'viewed':
        fg = _cobalt;
        bg = const Color(0xFFE7EDF0);
        label = 'Viewed';
        break;
      case 'submitted':
        fg = _green;
        bg = const Color(0xFFE7EDF0);
        label = 'Submitted';
        break;
      case 'accepted':
        fg = _ink;
        bg = _lime;
        label = 'Awarded';
        break;
      case 'declined':
        fg = _coral;
        bg = const Color(0xFFE7EDF0);
        label = 'Declined';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontFamily: _body,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg)),
    );
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
