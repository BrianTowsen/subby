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

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// InviteView — owner invites selected project-team trades to quote.
/// Streams project_listings for the active project; on send, seeds a quote doc
/// (status 'invited') under projects/{id}/quotes/{listingId}.
class InviteView extends StatefulWidget {
  const InviteView({super.key, this.width, this.height});
  final double? width;
  final double? height;
  @override
  State<InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends State<InviteView> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _green = Color(0xFF4E504F);
  static const Color _lime = Color(0xFFE7E247); // primary CTA / positive accent
  static const Color _sageBorder = Color(0xFFCBD8DD);
  static const Color _cobalt = Color(0xFF4E504F);
  static const String _body = 'Inter';
  static const String _kActiveProjectPath = 'subby_active_project_path';

  DocumentReference<Map<String, dynamic>>? _projectRef;
  String _projectName = 'Project';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _projSub;
  final Set<String> _selected = {};
  bool _sending = false;
  final TextEditingController _msgCtl = TextEditingController();
  final GlobalKey _msgKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _projSub?.cancel();
    _msgCtl.dispose();
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

  DocumentReference? _listingRefOf(Map<String, dynamic> d) {
    final raw = d['listingRef'] ?? d['listing_ref'] ?? d['listing'];
    if (raw is DocumentReference) return raw;
    return null;
  }

  /// Resolve the trade's user ref for a project_listings row: prefer the
  /// denormalized field on the row, else follow listingRef and read its owner.
  Future<DocumentReference?> _providerRefOf(
      Map<String, dynamic> d, DocumentReference? lref) async {
    final direct =
        d['assignedListingOwnerRef'] ?? d['ownerRef'] ?? d['providerRef'];
    if (direct is DocumentReference) return direct;
    if (lref == null) return null;
    try {
      final snap = await lref.get();
      final raw = snap.data();
      if (raw is Map<String, dynamic>) {
        final o = raw['ownerRef'] ?? raw['providerRef'] ?? raw['claimedByRef'];
        if (o is DocumentReference) return o;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _send(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> rows) async {
    final ref = _projectRef;
    if (ref == null || _sending || _selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final skipped = <String>[];
      var sent = 0;
      for (final row in rows) {
        final d = row.data();
        final lref = _listingRefOf(d);
        final id = lref?.id ?? row.id;
        if (!_selected.contains(id)) continue;
        // Denormalize the provider (trade's user ref) onto the quote so
        // InboxView / DashboardPageView can find it via
        // collectionGroup('quotes').where('providerRef', ...). If we can't
        // resolve the trade's user ref, the invite would be INVISIBLE to them
        // (both the collection-group query and its security rule match on
        // providerRef), so skip it and report rather than writing an orphan
        // invite that shows for nobody.
        final providerRef = await _providerRefOf(d, lref);
        if (providerRef == null) {
          skipped.add((d['title'] ?? 'Trade').toString());
          continue;
        }
        sent++;
        batch.set(
            ref.collection('quotes').doc(id),
            {
              'listingRef': lref,
              'listingName': (d['title'] ?? 'Trade').toString(),
              'providerRef': providerRef,
              'message': _msgCtl.text.trim(),
              'status': 'invited',
              'invitedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }
      if (sent == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                backgroundColor: _ink,
                content: Text(
                    'Couldn\'t invite ${skipped.length == 1 ? 'this trade' : 'these trades'} — no linked Subby account found. Ask them to claim their listing, then try again.',
                    style: const TextStyle(
                        fontFamily: _body,
                        fontWeight: FontWeight.w700,
                        color: _paper))));
        }
        return;
      }
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            backgroundColor: _ink,
            content: Text(
                skipped.isEmpty
                    ? 'Quote request sent to $sent trade${sent == 1 ? '' : 's'}.'
                    : 'Sent to $sent; skipped ${skipped.length} trade${skipped.length == 1 ? '' : 's'} with no linked account.',
                style: const TextStyle(
                    fontFamily: _body,
                    fontWeight: FontWeight.w700,
                    color: _paper))));
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              backgroundColor: _ink,
              content: Text('Couldn\'t send invites — check your connection.',
                  style: TextStyle(
                      fontFamily: _body,
                      fontWeight: FontWeight.w700,
                      color: _paper))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
            color: const Color(0xFF3D4F66), // steel — matches app hero headers
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 20),
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
                  Text('GET QUOTES',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: _paper.withOpacity(0.5))),
                ])),
                const SizedBox(width: 38),
              ]),
              const SizedBox(height: 16),
              const Text('Invite trades to quote',
                  style: TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: _paper)),
              const SizedBox(height: 6),
              Text('Selected trades will see the shared drawings & documents.',
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _paper.withOpacity(0.6))),
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
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('project_listings')
                        .where('projectRef', isEqualTo: ref)
                        .snapshots(),
                    builder: (context, snap) {
                      final rows = snap.data?.docs ?? [];
                      return Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 18, 16, 16),
                              children: [
                                Text('PROJECT TEAM · ${rows.length}',
                                    style: const TextStyle(
                                        fontFamily: _body,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: _inkMute)),
                                const SizedBox(height: 12),
                                if (rows.isEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF2F5F6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _border)),
                                    padding: const EdgeInsets.all(18),
                                    child: const Text(
                                        'No trades on the project team yet. Add trades to the project, then invite them to quote.',
                                        style: TextStyle(
                                            fontFamily: _body,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _inkMute)),
                                  )
                                else
                                  for (final row in rows) _teamRow(row),
                                const SizedBox(height: 8),
                                Column(
                                    key: _msgKey,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('MESSAGE TO TRADES · optional',
                                          style: TextStyle(
                                              fontFamily: _body,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.6,
                                              color: _inkMute)),
                                      const SizedBox(height: 9),
                                      Container(
                                        decoration: BoxDecoration(
                                            color: _paper,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(color: _border)),
                                        padding: const EdgeInsets.all(12),
                                        child: TextField(
                                          controller: _msgCtl,
                                          minLines: 4,
                                          maxLines: 6,
                                          cursorColor: _ink,
                                          style: const TextStyle(
                                              fontFamily: _body,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              height: 1.5,
                                              color: _ink),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            hintText:
                                                'Add a note — e.g. what to quote for, key dates, site access…',
                                            hintStyle: TextStyle(
                                                fontFamily: _body,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: _faint),
                                          ),
                                        ),
                                      ),
                                    ]),
                                const SizedBox(height: 14),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE7EDF0),
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Icon(Icons.visibility_outlined,
                                            size: 18, color: _cobalt),
                                        SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                'Invited trades can view the drawings & documents you marked shared.',
                                                style: TextStyle(
                                                    fontFamily: _body,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF566670),
                                                    height: 1.4))),
                                      ]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                                color: _paper,
                                border:
                                    Border(top: BorderSide(color: _surface))),
                            padding:
                                EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
                            child: InkWell(
                              onTap: _selected.isNotEmpty && !_sending
                                  ? () => _send(rows)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: _selected.isNotEmpty
                                        ? _lime
                                        : const Color(0xFFB7C2C7),
                                    borderRadius: BorderRadius.circular(10)),
                                child: _sending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    _ink)))
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            const Icon(Icons.send_rounded,
                                                size: 19, color: _ink),
                                            const SizedBox(width: 8),
                                            Text(
                                                'Send quote request (${_selected.length})',
                                                style: const TextStyle(
                                                    fontFamily: _body,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: _ink)),
                                          ]),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _teamRow(QueryDocumentSnapshot<Map<String, dynamic>> row) {
    final d = row.data();
    final lref = _listingRefOf(d);
    final id = lref?.id ?? row.id;
    final title = (d['title'] ?? 'Trade').toString();
    final sub = (d['subtitle'] ?? d['subTitle'] ?? '').toString();
    final on = _selected.contains(id);
    return GestureDetector(
      onTap: () {
        setState(() => on ? _selected.remove(id) : _selected.add(id));
        if (!on) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _msgKey.currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(ctx,
                  alignment: 0.05,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut);
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: on ? _sageBorder : _border, width: on ? 1.5 : 1),
        ),
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: on ? _ink : _surface,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.storefront_rounded,
                  size: 22, color: on ? _paper : _faint)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _inkMute)),
                ],
              ])),
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: on ? _lime : _paper,
                shape: BoxShape.circle,
                border: on
                    ? null
                    : Border.all(color: const Color(0xFFCBD8DD), width: 1.6)),
            child: on
                ? const Icon(Icons.check_rounded, size: 17, color: _ink)
                : null,
          ),
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
