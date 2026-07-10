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

import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPageView extends StatefulWidget {
  const SavedPageView({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  State<SavedPageView> createState() => _SavedPageViewState();
}

class _SavedPageViewState extends State<SavedPageView> {
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF3A5966);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF5D737E);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

  static const String _kSavedField = 'savedListingRefs';

  String _str(dynamic v) => (v == null) ? '' : v.toString().trim();

  double _dbl(dynamic v, {double fallback = 0.0}) {
    if (v is num) return v.toDouble();
    return double.tryParse(_str(v)) ?? fallback;
  }

  bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = _str(v).toLowerCase();
    return s == 'true' || s == 'yes' || s == '1';
  }

  List<DocumentReference> _extractSavedRefs(Map<String, dynamic> data) {
    final v = data[_kSavedField];
    if (v is List) return v.whereType<DocumentReference>().toList();
    return <DocumentReference>[];
  }

  Future<List<DocumentSnapshot>> _fetchListingDocs(
      List<DocumentReference> refs) async {
    final futures = refs.map((r) async {
      try {
        return await r.get();
      } catch (_) {
        return null;
      }
    }).toList();
    final results = await Future.wait(futures);
    return results
        .whereType<DocumentSnapshot>()
        .where((d) => d.exists)
        .toList();
  }

  Future<void> _removeBookmark(DocumentReference listingRef) async {
    final userRef = currentUserReference;
    if (userRef == null) return;
    try {
      await userRef.set(
        {
          _kSavedField: FieldValue.arrayRemove([listingRef])
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('⚠️ remove bookmark failed: $e');
    }
  }

  void _openListing(DocumentReference listingRef) {
    final qp = <String, dynamic>{
      'listingRef': serializeParam(listingRef, ParamType.DocumentReference),
    }..removeWhere((k, v) => v == null || v == 'null');
    try {
      context.pushNamed(
        'listingDetailPage',
        queryParameters: qp,
        extra: <String, dynamic>{'listingRef': listingRef},
      );
    } catch (e) {
      debugPrint('⚠️ navigation to listingDetailPage failed: $e');
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Professionals':
        return Icons.assignment_ind_outlined;
      case 'Trades':
        return Icons.handyman_outlined;
      case 'Suppliers':
        return Icons.storefront_outlined;
      case 'Associations':
        return Icons.apartment_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _loading() => const Center(
        child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_ink),
                strokeWidth: 2)),
      );

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _steel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _masthead(topInset),
            Expanded(
              child: Container(
                color: _paper,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      _hPad, 22, _hPad, MediaQuery.of(context).padding.bottom),
                  child: currentUserReference == null
                      ? _centered(_loginState())
                      : StreamBuilder<DocumentSnapshot>(
                          stream: currentUserReference!.snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) return _loading();
                            final data =
                                (snap.data!.data() as Map<String, dynamic>?) ??
                                    {};
                            final savedRefs = _extractSavedRefs(data);
                            if (savedRefs.isEmpty) {
                              return _centered(_emptyState());
                            }
                            return FutureBuilder<List<DocumentSnapshot>>(
                              future: _fetchListingDocs(savedRefs),
                              builder: (context, listSnap) {
                                if (!listSnap.hasData) return _loading();
                                final docs =
                                    listSnap.data ?? <DocumentSnapshot>[];
                                if (docs.isEmpty) {
                                  return _centered(_emptyState());
                                }
                                final byPath = <String, DocumentSnapshot>{
                                  for (final d in docs) d.reference.path: d,
                                };
                                final ordered = <DocumentSnapshot>[];
                                for (final r in savedRefs) {
                                  final d = byPath[r.path];
                                  if (d != null) ordered.add(d);
                                }
                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: ordered.length,
                                  itemBuilder: (context, i) {
                                    final doc = ordered[i];
                                    final listing =
                                        (doc.data() as Map<String, dynamic>?) ??
                                            {};
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _listingCard(
                                        listingRef: doc.reference,
                                        listing: listing,
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centered(Widget child) => Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: child,
        ),
      );

  Widget _listingCard({
    required DocumentReference listingRef,
    required Map<String, dynamic> listing,
  }) {
    final String name = _str(listing['name']);
    final String category = _str(listing['category']);
    final String speciality = _str(listing['speciality']);
    final String city = _str(listing['city']);
    final String province = _str(listing['province']);
    final bool isVerified = _bool(listing['isVerified']);
    final double rating = _dbl(listing['rating']);
    final String location =
        [city, province].where((s) => s.trim().isNotEmpty).join(' • ');

    return InkWell(
      onTap: () => _openListing(listingRef),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hairline),
        ),
        child: Row(children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(12)),
            child: Icon(_iconForCategory(category), size: 26, color: _slate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: Row(children: [
                      Flexible(
                        child: Text(name.isNotEmpty ? name : 'Listing',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: _displayFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: _ink)),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 15, color: _slate),
                      ],
                    ]),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, size: 16, color: _slate),
                  const SizedBox(width: 4),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _removeBookmark(listingRef),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _lime, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.bookmark_rounded,
                          size: 16, color: _ink),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (category.isNotEmpty) _pill(category),
                  if (speciality.isNotEmpty) _pill(speciality),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: _faint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _faint)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _inkMute)),
      );

  Widget _emptyState() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _hairlineOnSurface)),
              child:
                  const Icon(Icons.bookmark_border, size: 34, color: _inkMute),
            ),
            const SizedBox(height: 14),
            const Text('No saved listings yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
            const SizedBox(height: 8),
            const Text('When you bookmark a listing, it will show here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _inkMute)),
            const SizedBox(height: 16),
            _primaryPill('Explore listings', () {
              try {
                context.pushNamed('explorePage');
              } catch (_) {}
            }),
          ],
        ),
      );

  Widget _loginState() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _hairlineOnSurface)),
              child: const Icon(Icons.lock_outline, size: 34, color: _inkMute),
            ),
            const SizedBox(height: 14),
            const Text('Sign in to see your saved listings',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
            const SizedBox(height: 8),
            const Text('Bookmarks are tied to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _inkMute)),
            const SizedBox(height: 16),
            _primaryPill('Go to login', () {
              try {
                context.pushNamed('login');
              } catch (_) {}
            }),
          ],
        ),
      );

  Widget _primaryPill(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
              color: _lime, borderRadius: BorderRadius.circular(14)),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink)),
        ),
      );

  Widget _masthead(double topInset) => Container(
        width: double.infinity,
        color: _steel,
        padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Material(
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
                        color: _paper.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: _paper),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('SAVED',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: _paper.withOpacity(0.5),
                      )),
                ),
              ),
              const SizedBox(width: 38),
            ]),
            const SizedBox(height: 14),
            const Text('Saved',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.08,
                  color: _paper,
                )),
            const SizedBox(height: 8),
            Text('Your bookmarked listings.',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _paper.withOpacity(0.55),
                )),
          ],
        ),
      );
}
