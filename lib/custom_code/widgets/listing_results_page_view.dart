// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/flutter_flow/custom_functions.dart' as functions;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingResultsPageView extends StatefulWidget {
  const ListingResultsPageView({
    super.key,
    this.width,
    this.height,
    this.province,
    this.city, // region label from HomePageView
    this.speciality,
    this.category,
    this.searchText,

    // ✅ NEW: index-safe params
    this.provinceSlug,
    this.categorySlug,
    this.specialitySlug,
  });

  final double? width;
  final double? height;

  final String? province;
  final String? city;
  final String? speciality;
  final String? category;
  final String? searchText;

  final String? provinceSlug;
  final String? categorySlug;
  final String? specialitySlug;

  @override
  State<ListingResultsPageView> createState() => _ListingResultsPageViewState();
}

class _ListingResultsPageViewState extends State<ListingResultsPageView> {
  static const double _hPad = 24;
  static const double _vPad = 24;

  String _sortBy = 'A–Z';

  bool _verifiedOnly = false;
  double _minRating = 0.0;

  bool get _hasActiveFilters => _verifiedOnly || _minRating > 0.0;

  final GlobalKey _sortKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();

  // ✅ users/<uid> field where bookmarks live
  static const String _kSavedField = 'savedListingRefs';

  // ------------------------------------------------------------
  // Region keyword map (client-side matching only)
  // ------------------------------------------------------------
  static const Map<String, List<String>> _regionKeywordMap = {
    'johannesburg': [
      'johannesburg',
      'sandton',
      'midrand',
      'randburg',
      'roodepoort',
      'fourways',
      'rosebank',
      'hyde park',
      'parkhurst',
      'soweto',
      'northcliff',
      'krugersdorp',
    ],
    'pretoria': [
      'pretoria',
      'centurion',
      'hatfield',
      'menlyn',
      'brooklyn',
      'arcadia',
      'lynnwood',
    ],
    'centurion': ['centurion'],
    'midrand': ['midrand'],
    'sandton': ['sandton'],
    'soweto': ['soweto'],
    'east rand': [
      'boksburg',
      'benoni',
      'kempton',
      'kempton park',
      'edenvale',
      'germiston',
      'springs',
      'brakpan',
      'alberton',
    ],
    'west rand': [
      'roodepoort',
      'krugersdorp',
      'randfontein',
      'carletonville',
    ],
    'vaal': [
      'vanderbijlpark',
      'vereeniging',
      'sasolsburg',
      'meyerton',
    ],
    'gqeberha (port elizabeth)': ['gqeberha', 'port elizabeth'],
    'nelspruit (mbombela)': ['nelspruit', 'mbombela'],
    'witbank (emalahleni)': ['witbank', 'emalahleni'],
    'cape town': ['cape town', 'durbanville', 'bellville', 'milnerton'],
    'durban': ['durban', 'umhlanga', 'pinetown'],
  };

  // =========================================================
  // ✅ TYPOGRAPHY (Theme labels + correct families, no unknown theme getters)
  // =========================================================
  TextStyle _titleStyle(FlutterFlowTheme t) => t.titleLarge.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      );

  TextStyle _subtitleStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _chipLabelStyle(FlutterFlowTheme t) => t.labelMedium.override(
        fontFamily: t.labelMediumFamily,
      );

  TextStyle _cardNameStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
        fontWeight: FontWeight.w700,
      );

  TextStyle _cardMetaStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _cardSmallStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.primaryText,
      );
  // =========================================================

  // ----------------------------
  // Helpers
  // ----------------------------
  String _norm(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  // Safe read from record snapshotData (so you’re not dependent on generated fields)
  String _readString(SubbyListingsRecord listing, String key) {
    try {
      final dynamic snapData = (listing as dynamic).snapshotData;
      if (snapData is Map && snapData[key] is String) {
        return (snapData[key] as String).trim();
      }
    } catch (_) {}
    return '';
  }

  bool _matchesSearch(SubbyListingsRecord listing, String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;

    final haystack = <String>[
      listing.name,
      listing.speciality,
      listing.province ?? '',
      listing.city ?? '',
      listing.suburb ?? '',
      listing.category ?? '',
      _readString(listing, 'categorySlug'),
      _readString(listing, 'provinceSlug'),
      _readString(listing, 'specialitySlug'),
      (listing.services ?? const <String>[]).join(' '),
      (listing.tags ?? const <String>[]).join(' '),
      (listing.searchKeywords ?? const <String>[]).join(' '),
    ].join(' ').toLowerCase();

    return haystack.contains(q);
  }

  bool _matchesRegionClient(SubbyListingsRecord l, String? regionParam) {
    var raw = _norm(regionParam ?? '');
    if (raw.isEmpty) return true;

    final city = _norm(l.city ?? '');
    final suburb = _norm(l.suburb ?? '');

    if (city.isEmpty && suburb.isEmpty) return false;

    final blob = ('$city $suburb').trim();

    if (blob.contains(raw)) return true;

    final keywords = _regionKeywordMap[raw];
    if (keywords != null && keywords.isNotEmpty) {
      for (final k in keywords) {
        final kk = _norm(k);
        if (kk.isEmpty) continue;
        if (blob.contains(kk)) return true;
      }
    }

    if (raw.contains('(') && raw.contains(')')) {
      final before = _norm(raw.split('(').first);
      final inside = _norm(raw.split('(').last.replaceAll(')', ''));
      if (before.isNotEmpty && blob.contains(before)) return true;
      if (inside.isNotEmpty && blob.contains(inside)) return true;
    }

    return false;
  }

  List<SubbyListingsRecord> _applyClientFilters(
    List<SubbyListingsRecord> input,
    String searchText,
    String? speciality,
    String? regionParam,
  ) {
    var out = input;

    // Region
    out = out.where((l) => _matchesRegionClient(l, regionParam)).toList();

    // Search
    if (_norm(searchText).isNotEmpty) {
      out = out.where((l) => _matchesSearch(l, searchText)).toList();
    }

    // Speciality
    final String sSlug = functions.slugify(speciality ?? '');
    if (sSlug.isNotEmpty) {
      out = out.where((l) {
        final ls = _readString(l, 'specialitySlug');
        if (ls.isNotEmpty) return functions.slugify(ls) == sSlug;
        return (l.speciality)
            .toString()
            .toLowerCase()
            .contains(_norm(speciality ?? ''));
      }).toList();
    }

    // Verified
    if (_verifiedOnly) {
      out = out.where((l) => l.isVerified == true).toList();
    }

    // Rating
    if (_minRating > 0) {
      out = out.where((l) => (l.rating ?? 0.0) >= _minRating).toList();
    }

    return out;
  }

  List<SubbyListingsRecord> _applySort(List<SubbyListingsRecord> input) {
    final out = [...input];

    int cmpString(String a, String b) =>
        a.toLowerCase().compareTo(b.toLowerCase());

    switch (_sortBy) {
      case 'Highest rated':
        out.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        break;
      case 'Most jobs':
        out.sort(
            (a, b) => (b.jobsCompleted ?? 0).compareTo(a.jobsCompleted ?? 0));
        break;
      case 'A–Z':
        out.sort((a, b) => cmpString(a.name, b.name));
        break;
      case 'Z–A':
        out.sort((a, b) => cmpString(b.name, a.name));
        break;
      default:
        out.sort((a, b) => cmpString(a.name, b.name));
        break;
    }

    return out;
  }

  RelativeRect _menuPositionFor(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    if (box == null) {
      return const RelativeRect.fromLTRB(24, 120, 24, 0);
    }

    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;

    return RelativeRect.fromRect(
      Rect.fromLTWH(pos.dx, pos.dy + size.height, size.width, 0),
      Offset.zero & overlay.size,
    );
  }

  Future<void> _openSortMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: _menuPositionFor(_sortKey),
      items: const [
        PopupMenuItem(value: 'A–Z', child: Text('A–Z')),
        PopupMenuItem(value: 'Z–A', child: Text('Z–A')),
        PopupMenuItem(value: 'Highest rated', child: Text('Highest rated')),
        PopupMenuItem(value: 'Most jobs', child: Text('Most jobs')),
      ],
    );

    if (!mounted) return;
    if (selected != null) setState(() => _sortBy = selected);
  }

  // ===========================
  // BOOKMARK (Saved listings)
  // ===========================
  DocumentReference? _currentUserRefOrNull() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Set<String> _savedPathsFromUserDoc(Map<String, dynamic> userData) {
    final v = userData[_kSavedField];
    if (v is List) {
      final refs = v.whereType<DocumentReference>().toList();
      return refs.map((r) => r.path).toSet();
    }
    return <String>{};
  }

  // ✅ Subby-style snackbar (typography labels only + correct families)
  void _showBookmarkSnack({required bool wasSaved}) {
    if (!mounted) return;
    final theme = FlutterFlowTheme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevation: 0,
          backgroundColor: theme.secondaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.alternate, width: 1),
          ),
          duration: const Duration(milliseconds: 1400),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  wasSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 16,
                  color: theme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wasSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
                  style: _snackTextStyle(theme),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _toggleSaved({
    required DocumentReference listingRef,
    required bool isSaved,
  }) async {
    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }

    try {
      await userRef.set(
        {
          _kSavedField: isSaved
              ? FieldValue.arrayRemove([listingRef])
              : FieldValue.arrayUnion([listingRef]),
        },
        SetOptions(merge: true),
      );

      _showBookmarkSnack(wasSaved: !isSaved);
    } catch (e) {
      debugPrint('⚠️ toggleSaved failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not update bookmark.')),
        );
    }
  }

  Future<void> _openFiltersSheet() async {
    final theme = FlutterFlowTheme.of(context);

    bool tempVerified = _verifiedOnly;
    double tempMinRating = _minRating;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Filters',
                          style: theme.titleMedium
                              .override(fontFamily: theme.titleMediumFamily),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: theme.secondaryText),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.alternate, width: 1),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: tempVerified,
                            onChanged: (v) =>
                                modalSetState(() => tempVerified = v),
                            title: Text(
                              'Verified only',
                              style: theme.bodyMedium
                                  .override(fontFamily: theme.bodyMediumFamily),
                            ),
                          ),
                          Divider(
                              height: 1, thickness: 1, color: theme.alternate),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Minimum rating',
                                  style: theme.bodyMedium.override(
                                      fontFamily: theme.bodyMediumFamily),
                                ),
                                const Spacer(),
                                Text(
                                  tempMinRating.toStringAsFixed(1),
                                  style: theme.bodySmall.override(
                                    fontFamily: theme.bodySmallFamily,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                            child: Slider(
                              value: tempMinRating,
                              min: 0,
                              max: 5,
                              divisions: 10,
                              onChanged: (v) =>
                                  modalSetState(() => tempMinRating = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              modalSetState(() {
                                tempVerified = false;
                                tempMinRating = 0.0;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side:
                                  BorderSide(color: theme.alternate, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Reset',
                              style: theme.labelLarge
                                  .override(fontFamily: theme.labelLargeFamily),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply',
                              style: theme.labelLarge.override(
                                fontFamily: theme.labelLargeFamily,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _verifiedOnly = tempVerified;
      _minRating = tempMinRating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    final String? provinceLabel = widget.province;
    final String? regionLabel = widget.city;
    final String? specialityLabel = widget.speciality;
    final String? categoryLabel = widget.category;

    final String provinceSlug = (widget.provinceSlug ?? '').trim().isNotEmpty
        ? widget.provinceSlug!.trim()
        : functions.slugify(provinceLabel ?? '');

    final String categorySlug = (widget.categorySlug ?? '').trim().isNotEmpty
        ? widget.categorySlug!.trim()
        : functions.slugify(categoryLabel ?? '');

    final String specialitySlug =
        (widget.specialitySlug ?? '').trim().isNotEmpty
            ? widget.specialitySlug!.trim()
            : functions.slugify(specialityLabel ?? '');

    final String searchText = (widget.searchText ?? '').trim();

    String subtitle;
    if ((provinceLabel != null && provinceLabel.isNotEmpty) &&
        (regionLabel != null && regionLabel.isNotEmpty)) {
      subtitle = '$provinceLabel • $regionLabel';
    } else if (provinceLabel != null && provinceLabel.isNotEmpty) {
      subtitle = provinceLabel;
    } else if (specialityLabel != null && specialityLabel.isNotEmpty) {
      subtitle = specialityLabel;
    } else {
      subtitle = 'Subbies near you';
    }

    String title;
    if (specialityLabel != null && specialityLabel.isNotEmpty) {
      title = specialityLabel;
    } else if (categoryLabel != null && categoryLabel.isNotEmpty) {
      title = categoryLabel;
    } else {
      title = 'Subbies near you';
    }

    debugPrint(
        'ListingResults query slugs: provinceSlug=$provinceSlug categorySlug=$categorySlug orderBy=name');

    final userRef = _currentUserRefOrNull();

    return SizedBox(
      width: width,
      height: height,
      child: SafeArea(
        child: Container(
          color: theme.primaryBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP BAR ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.secondaryBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.alternate, width: 1),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: _titleStyle(theme)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: _subtitleStyle(theme)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ---------- SORT + FILTER ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: _sortKey,
                        borderRadius: BorderRadius.circular(999),
                        onTap: _openSortMenu,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.primaryBackground,
                            borderRadius: BorderRadius.circular(999),
                            border:
                                Border.all(color: theme.alternate, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sort_rounded,
                                  size: 18, color: theme.secondaryText),
                              const SizedBox(width: 8),
                              Text(_sortBy, style: _chipLabelStyle(theme)),
                              const Spacer(),
                              Icon(Icons.expand_more_rounded,
                                  size: 18, color: theme.secondaryText),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      key: _filterKey,
                      borderRadius: BorderRadius.circular(999),
                      onTap: _openFiltersSheet,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: theme.alternate, width: 1),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(Icons.tune_rounded,
                                    size: 18, color: theme.secondaryText),
                                if (_hasActiveFilters)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Text('Filters', style: _chipLabelStyle(theme)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ---------- LIST ----------
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: userRef?.snapshots(),
                  builder: (context, userSnap) {
                    final userData =
                        (userSnap.data?.data() as Map<String, dynamic>?) ??
                            <String, dynamic>{};
                    final savedPaths = _savedPathsFromUserDoc(userData);

                    return StreamBuilder<List<SubbyListingsRecord>>(
                      stream: querySubbyListingsRecord(
                        queryBuilder: (q) {
                          var query = q;

                          if (provinceSlug.isNotEmpty) {
                            query = query.where('provinceSlug',
                                isEqualTo: provinceSlug);
                          }

                          if (categorySlug.isNotEmpty) {
                            query = query.where('categorySlug',
                                isEqualTo: categorySlug);
                          }

                          query = query.orderBy('name');
                          return query;
                        },
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState(
                            title: 'Couldn’t load listings',
                            subtitle:
                                'This can happen while indexes are building or if permissions block reads.\nTry again in a moment.',
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildSubbyLoader();
                        }

                        final allListings =
                            snapshot.data ?? const <SubbyListingsRecord>[];

                        // ✅ Speciality filter: pass the label (slug comparisons happen inside)
                        final filtered = _applyClientFilters(
                          allListings,
                          searchText,
                          specialityLabel,
                          regionLabel,
                        );

                        final sorted = _applySort(filtered);

                        if (sorted.isEmpty) {
                          return _buildEmptyState(
                            title: 'No listings found',
                            subtitle:
                                'Try clearing filters or searching a different keyword.',
                          );
                        }

                        return ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 24),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final listing = sorted[index];
                            final isSaved =
                                savedPaths.contains(listing.reference.path);

                            return _buildListingCard(
                              listing,
                              isSaved: isSaved,
                              onToggleSaved: () => _toggleSaved(
                                listingRef: listing.reference,
                                isSaved: isSaved,
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

  Widget _buildListingCard(
    SubbyListingsRecord listing, {
    required bool isSaved,
    required VoidCallback onToggleSaved,
  }) {
    final theme = FlutterFlowTheme.of(context);

    final String name = listing.name;
    final String speciality = listing.speciality;

    final String area = [
      listing.city ?? '',
      listing.province ?? '',
    ].where((s) => s.trim().isNotEmpty).join(', ');

    final double rating = listing.rating ?? 0.0;
    final int jobs = listing.jobsCompleted ?? 0;
    final bool isVerified = listing.isVerified == true;

    final String heroPhoto = (listing.heroPhotoUrl ?? '').isNotEmpty
        ? (listing.heroPhotoUrl ?? '')
        : ((listing.photoUrls ?? const <String>[]).isNotEmpty
            ? (listing.photoUrls ?? const <String>[]).first
            : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: heroPhoto.isNotEmpty
                ? Image.network(heroPhoto, fit: BoxFit.cover)
                : Icon(Icons.handyman_rounded, size: 24, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardNameStyle(theme),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded,
                          size: 16, color: theme.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  speciality,
                  style: _cardMetaStyle(theme),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: theme.secondaryText),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardMetaStyle(theme),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (rating > 0) ...[
                      Icon(Icons.star_rounded, size: 16, color: theme.primary),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1),
                          style: _cardSmallStyle(theme)),
                      const SizedBox(width: 6),
                    ],
                    if (jobs > 0)
                      Text(
                        rating > 0 ? '• $jobs jobs' : '$jobs jobs',
                        style: _cardMetaStyle(theme),
                      ),
                    if (rating <= 0 && jobs <= 0)
                      Text('New', style: _cardMetaStyle(theme)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              InkWell(
                onTap: onToggleSaved,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.alternate, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: isSaved ? theme.primary : theme.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  context.pushNamed(
                    'listingDetailPage',
                    queryParameters: {
                      'listingRef': serializeParam(
                        listing.reference,
                        ParamType.DocumentReference,
                      ),
                    }.withoutNulls,
                  );
                },
                child: Text(
                  'View',
                  style: theme.labelMedium.override(
                    fontFamily: theme.labelMediumFamily,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubbyLoader() {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Loading subbies…',
            style: theme.bodySmall.override(
              fontFamily: theme.bodySmallFamily,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, color: theme.secondaryText, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.titleMedium
                    .override(fontFamily: theme.titleMediumFamily),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.bodySmall.override(
                  fontFamily: theme.bodySmallFamily,
                  color: theme.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState({required String title, required String subtitle}) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.warning_amber_rounded, size: 44, color: theme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  theme.titleSmall.override(fontFamily: theme.titleSmallFamily),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.bodySmall.override(
                fontFamily: theme.bodySmallFamily,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
