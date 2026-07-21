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

import '/flutter_flow/custom_functions.dart' as functions;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingResultsPageView extends StatefulWidget {
  const ListingResultsPageView({
    super.key,
    this.width,
    this.height,
    this.province,
    this.city,
    this.speciality,
    this.category,
    this.searchText,
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
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF2F3A4C);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF4E504F);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _rule = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

  String _sortBy = 'A–Z';
  bool _verifiedOnly = false;
  double _minRating = 0.0;

  bool get _hasActiveFilters => _verifiedOnly || _minRating > 0.0;

  final GlobalKey _sortKey = GlobalKey();

  static const String _kSavedField = 'savedListingRefs';

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
    'west rand': ['roodepoort', 'krugersdorp', 'randfontein', 'carletonville'],
    'vaal': ['vanderbijlpark', 'vereeniging', 'sasolsburg', 'meyerton'],
    'gqeberha (port elizabeth)': ['gqeberha', 'port elizabeth'],
    'nelspruit (mbombela)': ['nelspruit', 'mbombela'],
    'witbank (emalahleni)': ['witbank', 'emalahleni'],
    'cape town': ['cape town', 'durbanville', 'bellville', 'milnerton'],
    'durban': ['durban', 'umhlanga', 'pinetown'],
  };

  // ----------------------------
  // Helpers (unchanged logic)
  // ----------------------------
  String _norm(String input) =>
      input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
    if (keywords != null) {
      for (final k in keywords) {
        final kk = _norm(k);
        if (kk.isNotEmpty && blob.contains(kk)) return true;
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
    out = out.where((l) => _matchesRegionClient(l, regionParam)).toList();
    if (_norm(searchText).isNotEmpty) {
      out = out.where((l) => _matchesSearch(l, searchText)).toList();
    }
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
    if (_verifiedOnly) out = out.where((l) => l.isVerified == true).toList();
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
      case 'Z–A':
        out.sort((a, b) => cmpString(b.name, a.name));
        break;
      case 'A–Z':
      default:
        out.sort((a, b) => cmpString(a.name, b.name));
        break;
    }
    return out;
  }

  RelativeRect _menuPositionFor(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (box == null) return const RelativeRect.fromLTRB(24, 120, 24, 0);
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
      color: _paper,
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
  // BOOKMARK
  // ===========================
  DocumentReference? _currentUserRefOrNull() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  Set<String> _savedPathsFromUserDoc(Map<String, dynamic> userData) {
    final v = userData[_kSavedField];
    if (v is List) {
      return v.whereType<DocumentReference>().map((r) => r.path).toSet();
    }
    return <String>{};
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
    } catch (e) {
      debugPrint('⚠️ toggleSaved failed: $e');
    }
  }

  Future<void> _openFiltersSheet() async {
    bool tempVerified = _verifiedOnly;
    double tempMinRating = _minRating;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, modalSetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                22, 18, 22, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: _ink)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close_rounded, color: _inkMute),
                      onPressed: () => Navigator.pop(context)),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: tempVerified,
                  activeColor: _ink,
                  onChanged: (v) => modalSetState(() => tempVerified = v),
                  title: const Text('Verified only',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _inkMute)),
                ),
                const Divider(height: 1, thickness: 1, color: _rule),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(children: [
                    const Text('Minimum rating',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _inkMute)),
                    const Spacer(),
                    Text(tempMinRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                  ]),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _ink,
                    inactiveTrackColor: _rule,
                    thumbColor: _ink,
                    overlayColor: _ink.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: tempMinRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    onChanged: (v) => modalSetState(() => tempMinRating = v),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => modalSetState(() {
                        tempVerified = false;
                        tempMinRating = 0.0;
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _inkMute,
                        side: const BorderSide(color: _rule, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reset',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _inkMute)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: _ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _ink)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _verifiedOnly = tempVerified;
      _minRating = tempMinRating;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

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

    final userRef = _currentUserRefOrNull();

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _steel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Steel masthead ──
            Container(
              width: double.infinity,
              color: _steel,
              padding: EdgeInsets.fromLTRB(_hPad, topInset + 10, _hPad, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _circleButton(
                        Icons.arrow_back_ios_new_rounded, () => context.pop()),
                    Expanded(
                      child: Center(
                        child: Text('RESULTS',
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
                  Text(title,
                      style: const TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.08,
                        color: _paper,
                      )),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: _paper.withOpacity(0.55)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _paper.withOpacity(0.55),
                          )),
                    ),
                  ]),
                ],
              ),
            ),
            // ── White content ──
            Expanded(
              child: Container(
                color: _paper,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 16),
                      child: Row(children: [
                        Expanded(
                          child: InkWell(
                            key: _sortKey,
                            onTap: _openSortMenu,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const Icon(Icons.sort_rounded,
                                    size: 18, color: _slate),
                                const SizedBox(width: 8),
                                Text(_sortBy,
                                    style: const TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _ink)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _openFiltersSheet,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const Icon(Icons.tune_rounded,
                                    size: 18, color: _slate),
                                const SizedBox(width: 8),
                                const Text('Filters',
                                    style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _ink)),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                          color: _slate,
                                          shape: BoxShape.circle)),
                                ],
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: userRef?.snapshots(),
                        builder: (context, userSnap) {
                          final userData = (userSnap.data?.data()
                                  as Map<String, dynamic>?) ??
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
                                return query.orderBy('name');
                              },
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return _buildEmptyState(
                                  icon: Icons.warning_amber_rounded,
                                  title: 'Couldn’t load listings',
                                  subtitle:
                                      'This can happen while indexes are building or if permissions block reads.',
                                );
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: _ink));
                              }
                              final allListings = snapshot.data ??
                                  const <SubbyListingsRecord>[];
                              final filtered = _applyClientFilters(allListings,
                                  searchText, specialityLabel, regionLabel);
                              final sorted = _applySort(filtered);
                              if (sorted.isEmpty) {
                                return _buildEmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: 'No listings found',
                                  subtitle:
                                      'Try clearing filters or searching a different keyword.',
                                );
                              }
                              return ListView.builder(
                                padding: EdgeInsets.fromLTRB(_hPad, 0, _hPad,
                                    24 + MediaQuery.of(context).padding.bottom),
                                physics: const BouncingScrollPhysics(),
                                itemCount: sorted.length,
                                itemBuilder: (context, index) {
                                  final listing = sorted[index];
                                  final isSaved = savedPaths
                                      .contains(listing.reference.path);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildListingCard(
                                      listing,
                                      isSaved: isSaved,
                                      onToggleSaved: () => _toggleSaved(
                                        listingRef: listing.reference,
                                        isSaved: isSaved,
                                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(
    SubbyListingsRecord listing, {
    required bool isSaved,
    required VoidCallback onToggleSaved,
  }) {
    final String name = listing.name;
    final String speciality = listing.speciality;
    final String area = [listing.city ?? '', listing.province ?? '']
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    final double rating = listing.rating ?? 0.0;
    final int jobs = listing.jobsCompleted ?? 0;
    final bool isVerified = listing.isVerified == true;
    final String heroPhoto = (listing.heroPhotoUrl ?? '').isNotEmpty
        ? (listing.heroPhotoUrl ?? '')
        : ((listing.photoUrls ?? const <String>[]).isNotEmpty
            ? (listing.photoUrls ?? const <String>[]).first
            : '');
    String metaLine = area;
    if (jobs > 0) metaLine = area.isEmpty ? '$jobs jobs' : '$area · $jobs jobs';

    return InkWell(
      onTap: () {
        context.pushNamed(
          'listingDetailPage',
          queryParameters: {
            'listingRef':
                serializeParam(listing.reference, ParamType.DocumentReference),
          }.withoutNulls,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hairline),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(10)),
            child: heroPhoto.isNotEmpty
                ? Image.network(heroPhoto, fit: BoxFit.cover)
                : const Icon(Icons.handyman_rounded, size: 22, color: _slate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(name,
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
                    const Icon(Icons.verified_rounded, size: 15, color: _slate),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(speciality,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _inkMute)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: _faint),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(metaLine,
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
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (rating > 0)
                Row(children: [
                  const Icon(Icons.star_rounded, size: 16, color: _slate),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                ])
              else
                const Text('New',
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _faint)),
              const SizedBox(height: 8),
              InkWell(
                onTap: onToggleSaved,
                customBorder: const CircleBorder(),
                child: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 20,
                    color: isSaved ? _slate : const Color(0xFFC6D0D5)),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _faint),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _ink)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _faint)),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
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
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );
}
