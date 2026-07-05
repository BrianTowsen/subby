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

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// QuoteRequestView — the trade opens an invitation: view shared drawings &
/// documents, pick scope sections, then prepare a quote. Marks status 'viewed'.
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
  static const Color _ink = Color(0xFF29343A);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _green = Color(0xFF5D737E);
  static const Color _cobalt = Color(0xFF5D737E);
  static const String _body = 'Inter';
  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kActiveQuotePath = 'subby_active_quote_path';

  static const List<String> _scopeOptions = [
    'Professional Fees',
    'Site Preparation',
    'Concrete Works',
    'Brickwork & Blockwork',
    'Roofing & Trusses',
    'Windows & Door Frames',
    'Plumbing & Drainage',
    'Electrical Works',
    'Electrical Fittings',
    'Plastering & Screeds',
    'Tiling',
    'Painting & Decorating',
    'External Site Works',
    'Special Items',
  ];

  DocumentReference<Map<String, dynamic>>? _projectRef;
  DocumentReference<Map<String, dynamic>>? _quoteRef;
  String _projectName = 'Project';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;
  final Set<String> _scope = {};
  bool _saving = false;

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
      if (mounted) setState(() => _projectName = name);
    });
    // Mark as viewed ONLY if the quote exists and is still 'invited' —
    // never downgrade a submitted/decided quote, never create orphan docs.
    final qref = quoteRef;
    if (qref != null) {
      try {
        final snap = await qref.get();
        final status = (snap.data()?['status'] ?? '').toString();
        if (snap.exists && (status == 'invited' || status.isEmpty)) {
          await qref.set({
            'status': 'viewed',
            'viewedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
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
        'scope': _scope.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    final r = widget.submitQuoteRouteName;
    if (r != null && r.isNotEmpty) {
      context.pushNamed(r);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            backgroundColor: _ink,
            content: Text('Scope saved — continue to Submit Quote.',
                style: TextStyle(
                    fontFamily: _body,
                    fontWeight: FontWeight.w700,
                    color: _paper))));
    }
  }

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
            color: _ink,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 18),
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
                    child: const Text('Viewed',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFCBD8DD)))),
              ]),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                    color: _paper.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Invited by the project manager',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                        Text('Review the drawings, then quote',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _paper.withOpacity(0.55))),
                      ])),
                ]),
              ),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      _docsSection(ref, 'DRAWINGS', 'drawing',
                          Icons.architecture_rounded),
                      const SizedBox(height: 14),
                      _docsSection(ref, 'DOCUMENTS', 'document',
                          Icons.description_rounded),
                      const SizedBox(height: 16),
                      const Text('YOUR SCOPE · pick sections',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: _faint)),
                      const SizedBox(height: 10),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [for (final s in _scopeOptions) _chip(s)]),
                    ],
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
                color: _paper,
                border: Border(top: BorderSide(color: _surface))),
            padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
            child: InkWell(
              onTap: _saving ? null : _prepare,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _scope.isEmpty ? const Color(0xFFB7C2C7) : _green,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.edit_document, size: 19, color: _paper),
                  SizedBox(width: 8),
                  Text('Prepare your quote',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _paper)),
                ]),
              ),
            ),
          ),
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          backgroundColor: _ink,
          content: Text('No file attached to this document.',
              style: TextStyle(
                  fontFamily: _body,
                  fontWeight: FontWeight.w700,
                  color: _paper))));
  }

  Widget _docsSection(DocumentReference<Map<String, dynamic>> ref, String title,
      String category, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontFamily: _body,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: _faint)),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border)),
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
                borderRadius: BorderRadius.circular(12),
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

  Widget _chip(String s) {
    final on = _scope.contains(s);
    return GestureDetector(
      onTap: () => setState(() => on ? _scope.remove(s) : _scope.add(s)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: on ? _ink : _surface,
          borderRadius: BorderRadius.circular(999),
          border: on ? null : Border.all(color: const Color(0xFFDCE3E6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (on) ...[
            const Icon(Icons.check_rounded, size: 15, color: _paper),
            const SizedBox(width: 6)
          ],
          Text(s,
              style: TextStyle(
                  fontFamily: _body,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: on ? _paper : _inkMute)),
        ]),
      ),
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
