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

import '/auth/firebase_auth/auth_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPageView extends StatefulWidget {
  const SavedPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<SavedPageView> createState() => _SavedPageViewState();
}

class _SavedPageViewState extends State<SavedPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF1D2529);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFECF0F2);
  static const Color _hairlineOnSurface = Color(0xFFCBD8DD);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFF5D737E); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF1D2529);
  // Status
  static const Color _live =
      Color(0xFF566670); // orange — live / open-now / warning
  static const Color _coral = Color(0xFF566670);
  // Geometry
  static const double _rSmall = 6;
  static const double _rMed = 8;
  static const double _rLarge = 12;
  static const double _rPill = 999;
  static const double _pageHPad = 20;
  static const double _sectionGap = 32;
  static const double _navReserve = 96;
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = _pageHPad;
  static const double _vPad = 18;

  /// users/<uid>.savedListingRefs : List<DocRef(subby_listings)>
  static const String _kSavedField = 'savedListingRefs';

  // =========================================================
  // ✅ TYPOGRAPHY (locked palette — explicit family + colour)
  // =========================================================
  TextStyle get _appTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _topTitle => _appTitleStyle;

  TextStyle get _topSubtitle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _headingStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle get _nameStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle get _bodyMuted => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _pillText => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _ink,
      );

  TextStyle get _ratingText => const TextStyle(
        fontFamily: _monoFont,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _ink,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  TextStyle get _locationText => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  TextStyle get _buttonTextOnPrimary => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _sparkInk, // ink-on-yellow
      );
  // =========================================================

  String _str(dynamic v) => (v == null) ? '' : v.toString().trim();

  double _dbl(dynamic v, {double fallback = 0.0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = _str(v);
    return double.tryParse(s) ?? fallback;
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
    List<DocumentReference> refs,
  ) async {
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
    // serializeParam returns String? -> keep queryParameters as Map<String, dynamic>
    final qp = <String, dynamic>{
      'listingRef': serializeParam(listingRef, ParamType.DocumentReference),
    }..removeWhere((k, v) => v == null || v == 'null');

    final extra = <String, dynamic>{'listingRef': listingRef};

    try {
      context.pushNamed(
        'listingDetailPage',
        queryParameters: qp,
        extra: extra,
      );
    } catch (e) {
      debugPrint('⚠️ navigation to listingDetailPage failed: $e');
    }
  }

  Widget _loading(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_ink),
          strokeWidth: 2,
        ),
      ),
    );
  }

  // =========================
  // Subby-style buttons (primary action — yellow, ink-on-yellow)
  // =========================
  Widget _primaryPillButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_rPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: _spark,
          borderRadius: BorderRadius.circular(_rPill),
        ),
        child: Text(
          label,
          style: _buttonTextOnPrimary,
        ),
      ),
    );
  }

  // =========================
  // States (polished + centered)
  // =========================
  Widget _emptyState(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(_rLarge),
              border: Border.all(color: _hairlineOnSurface, width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.bookmark_border,
              size: 34,
              color: _inkMute,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No saved listings yet',
            style: _headingStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When you bookmark a listing, it will show here.',
            style: _bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _primaryPillButton(
            context,
            label: 'Explore listings',
            onTap: () {
              try {
                context.pushNamed('explorePage');
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Widget _loginState(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(_rLarge),
              border: Border.all(color: _hairlineOnSurface, width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lock_outline, size: 34, color: _inkMute),
          ),
          const SizedBox(height: 14),
          Text(
            'Sign in to see your saved listings',
            style: _headingStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bookmarks are tied to your account.',
            style: _bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _primaryPillButton(
            context,
            label: 'Go to login',
            onTap: () {
              try {
                context.pushNamed('login');
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Widget _centeredContent(Widget child) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: child,
        ),
      ),
    );
  }

  // ==========================================================
  // ✅ Explore-style listing card (locked palette)
  // ==========================================================
  Widget _pill(
    BuildContext context, {
    required String text,
  }) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_rPill),
        border: Border.all(color: _hairlineOnSurface, width: 1),
      ),
      child: Text(
        text,
        style: _pillText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _listingCardExploreStyle(
    BuildContext context, {
    required DocumentReference listingRef,
    required Map<String, dynamic> listing,
  }) {
    final String name = _str(listing['name']);
    final String category = _str(listing['category']);
    final String speciality = _str(listing['speciality']);
    final String city = _str(listing['city']);
    final String province = _str(listing['province']);

    final bool isVerified = _bool(listing['isVerified']);
    final double rating = _dbl(listing['rating'], fallback: 0.0);

    final String location =
        [city, province].where((s) => s.trim().isNotEmpty).join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_rLarge),
        border: Border.all(color: _hairline, width: 1),
      ),
      child: Row(
        children: [
          // Left image placeholder (same feel as Explore)
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(_rLarge),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              size: 24,
              color: _inkMute,
            ),
          ),
          const SizedBox(width: 12),

          // Right content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rating + bookmark icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name.isNotEmpty ? name : 'Listing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _nameStyle,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: _ink,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: _ink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: _ratingText,
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _removeBookmark(listingRef),
                      borderRadius: BorderRadius.circular(_rMed),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(_rMed),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.bookmark_rounded,
                          size: 16,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Pills row (Category + Speciality)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (category.isNotEmpty) _pill(context, text: category),
                    if (speciality.isNotEmpty) _pill(context, text: speciality),
                  ],
                ),

                const SizedBox(height: 8),

                // Location only
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: _inkMute),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _locationText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Build
  // =========================
  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ✅ Remove SafeArea white bands: pad manually but keep background color full-screen
    final insets = MediaQuery.of(context).padding;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _hPad,
            insets.top + _vPad,
            _hPad,
            insets.bottom + _vPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved', style: _topTitle),
              const SizedBox(height: 6),
              Text('Your bookmarked listings', style: _topSubtitle),
              const SizedBox(height: 16),
              Expanded(
                child: currentUserReference == null
                    ? _centeredContent(_loginState(context))
                    : StreamBuilder<DocumentSnapshot>(
                        stream: currentUserReference!.snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) return _loading(context);

                          final data =
                              (snap.data!.data() as Map<String, dynamic>?) ??
                                  {};
                          final savedRefs = _extractSavedRefs(data);

                          if (savedRefs.isEmpty) {
                            return _centeredContent(_emptyState(context));
                          }

                          return FutureBuilder<List<DocumentSnapshot>>(
                            future: _fetchListingDocs(savedRefs),
                            builder: (context, listSnap) {
                              if (!listSnap.hasData) return _loading(context);

                              final docs =
                                  listSnap.data ?? <DocumentSnapshot>[];
                              if (docs.isEmpty) {
                                return _centeredContent(_emptyState(context));
                              }

                              // preserve saved order
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

                                  return InkWell(
                                    onTap: () => _openListing(doc.reference),
                                    child: _listingCardExploreStyle(
                                      context,
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
            ],
          ),
        ),
      ),
    );
  }
}
