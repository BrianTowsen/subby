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

import '/flutter_flow/custom_functions.dart' as functions;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailPageView extends StatefulWidget {
  const ListingDetailPageView({
    super.key,
    this.width,
    this.height,
    this.listingRef,
  });

  final double? width;
  final double? height;
  final DocumentReference? listingRef;

  @override
  State<ListingDetailPageView> createState() => _ListingDetailPageViewState();
}

class _ListingDetailPageViewState extends State<ListingDetailPageView> {
  // ─── SUBBY PALETTE — DIRECTORY (amber / sunshine) ──────────────────
  static const Color _amber = Color(0xFF323F4D); // accent: title, value, CTA
  static const Color _sunshine = Color(0xFFC7E87A); // secondary highlight
  static const Color _inkMute = Color(0xFF5A6675); // labels
  static const Color _faint = Color(0xFF93A0B0); // subtitles / meta
  static const Color _coral = Color(0xFFC24A1A); // error
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _rule = Color(0xFFE2E7EE);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 24;

  static const double _bottomCtaContainerHeight = 86;
  static const String _kSavedField = 'savedListingRefs';

  final String _fallbackName = 'Precision Electrical';
  final String _fallbackTrade = 'Electrician';
  final String _fallbackArea = 'Sandton, Gauteng';
  final String _fallbackProviderName = 'Guy';
  final String _fallbackProviderSurname = 'Smith';
  final String _fallbackProviderPhoto =
      'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg';

  final List<String> _services = const [
    'New installations',
    'Geyser installation & repairs',
    'DB board upgrades',
    'Compliance certificates (COC)',
    'Emergency call-outs',
  ];

  final String _aboutText =
      'We are a registered electrical company specialising in residential and '
      'light commercial projects across Sandton and surrounding areas. '
      'Fully insured, accredited, and available 24/7 for emergency call-outs.';

  static const Duration _maxInitialLoad = Duration(seconds: 8);
  bool _showSlowLoadFallback = false;

  DocumentReference? _selectedProjectRef;
  String? _selectedProjectName;

  TextStyle get _titleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: _amber,
        height: 1.05,
      );

  TextStyle get _uLabelStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      );

  TextStyle get _valueStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _amber,
      );

  TextStyle get _bodyStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _inkMute,
        height: 1.6,
      );

  TextStyle get _metaStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _faint,
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _rule, width: 1)),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(_maxInitialLoad, () {
      if (!mounted) return;
      setState(() => _showSlowLoadFallback = true);
    });
  }

  // ===========================
  // BOOKMARK
  // ===========================
  DocumentReference? _currentUserRefOrNull() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  bool _isListingSaved({
    required Map<String, dynamic> userData,
    required DocumentReference listingRef,
  }) {
    final v = userData[_kSavedField];
    if (v is List) {
      return v
          .whereType<DocumentReference>()
          .any((r) => r.path == listingRef.path);
    }
    return false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: _amber,
          content: Text(msg,
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  Future<void> _toggleBookmark({
    required DocumentReference listingRef,
    required bool currentlySaved,
  }) async {
    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }
    try {
      await userRef.set(
        {
          _kSavedField: currentlySaved
              ? FieldValue.arrayRemove([listingRef])
              : FieldValue.arrayUnion([listingRef]),
        },
        SetOptions(merge: true),
      );
      _snack(currentlySaved ? 'Removed from bookmarks' : 'Saved to bookmarks');
    } catch (e) {
      debugPrint('⚠️ toggle bookmark failed: $e');
      _snack('Could not update bookmark.');
    }
  }

  Future<void> _shareListing({
    required String name,
    required String category,
    required String area,
    required DocumentReference listingRef,
  }) async {
    final parts = <String>[
      name,
      if (category.trim().isNotEmpty) category.trim(),
      if (area.trim().isNotEmpty) area.trim(),
      'Listing ID: ${listingRef.id}',
    ];
    try {
      await Clipboard.setData(ClipboardData(text: parts.join('\n')));
      _snack('Listing details copied. You can now paste and share.');
    } catch (_) {
      _snack('Unable to share right now.');
    }
  }

  // ===========================
  // CONTACT
  // ===========================
  Future<void> _launchUri(Uri uri, {required String failMessage}) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack(failMessage);
    } catch (e) {
      debugPrint('\u26a0\ufe0f launch failed: $e');
      _snack(failMessage);
    }
  }

  String _digitsPlus(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _launchPhone(String phone) async {
    final n = _digitsPlus(phone);
    if (n.isEmpty) return;
    await _launchUri(Uri(scheme: 'tel', path: n),
        failMessage: 'No dialer available.');
  }

  Future<void> _launchWhatsApp(String number) async {
    var n = _digitsPlus(number).replaceAll('+', '');
    if (n.isEmpty) return;
    if (n.startsWith('0')) n = '27${n.substring(1)}';
    await _launchUri(Uri.parse('https://wa.me/$n'),
        failMessage: 'Could not open WhatsApp.');
  }

  Future<void> _launchEmail(String email) async {
    final e = email.trim();
    if (e.isEmpty) return;
    await _launchUri(Uri(scheme: 'mailto', path: e),
        failMessage: 'No email app available.');
  }

  // ===========================
  // ADD TO PROJECT
  // ===========================
  Query<Map<String, dynamic>> _projectsQuery(DocumentReference userRef) {
    return FirebaseFirestore.instance
        .collection('projects')
        .where('ownerRef', isEqualTo: userRef);
  }

  String _projectNameFrom(Map<String, dynamic> data) {
    final n = (data['name'] ?? '').toString().trim();
    return n.isNotEmpty ? n : 'Untitled Project';
  }

  bool _projectIsArchived(Map<String, dynamic> data) =>
      data['archived'] == true;

  int _updatedAtMillis(Map<String, dynamic> data) {
    final v = data['updatedAt'];
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is DateTime) return v.millisecondsSinceEpoch;
    return 0;
  }

  Future<void> _addListingToProject({
    required DocumentReference projectRef,
    required DocumentReference listingRef,
    required DocumentReference addedBy,
    required String title,
    required String subTitle,
    required String ratingText,
    required String photoUrl,
  }) async {
    try {
      final dup = await FirebaseFirestore.instance
          .collection('project_listings')
          .where('projectRef', isEqualTo: projectRef)
          .where('listingRef', isEqualTo: listingRef)
          .limit(1)
          .get();

      if (dup.docs.isNotEmpty) {
        _snack('Already added to this project.');
        return;
      }

      await FirebaseFirestore.instance.collection('project_listings').add({
        'projectRef': projectRef,
        'listingRef': listingRef,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': addedBy,
        'title': title,
        'subtitle': subTitle,
        'subTitle': subTitle,
        'ratingText': ratingText,
        'photoUrl': photoUrl,
      });

      _snack('Added to project.');
    } catch (e) {
      debugPrint('⚠️ addListingToProject failed: $e');
      _snack('Could not add to project.');
    }
  }

  Future<void> _showAddToProjectSheet({
    required DocumentReference listingRef,
    required String title,
    required String subTitle,
    required String ratingText,
    required String photoUrl,
  }) async {
    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }

    DocumentReference? selectedRef = _selectedProjectRef;
    String? selectedName = _selectedProjectName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 18),
              child: StatefulBuilder(
                builder: (context, setLocal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Add to Project',
                                style: TextStyle(
                                  fontFamily: _displayFont,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _amber,
                                )),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded,
                                color: _inkMute),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Choose which project to add this listing to.',
                          style: _metaStyle),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _projectsQuery(userRef).snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _amber),
                              ),
                            );
                          }
                          final rawDocs = snap.data?.docs ?? const [];
                          final docs = rawDocs
                              .where((d) => !_projectIsArchived(d.data()))
                              .toList()
                            ..sort((a, b) => _updatedAtMillis(b.data())
                                .compareTo(_updatedAtMillis(a.data())));

                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child:
                                  Text('No projects yet.', style: _metaStyle),
                            );
                          }

                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  (MediaQuery.of(context).size.height * 0.45)
                                      .clamp(220.0, 400.0),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final d = docs[i];
                                final pName = _projectNameFrom(d.data());
                                final pRef = d.reference;
                                final selected = selectedRef?.path == pRef.path;
                                return InkWell(
                                  onTap: () {
                                    selectedRef = pRef;
                                    selectedName = pName;
                                    setLocal(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: _uRule,
                                    child: Row(
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.folder_open_outlined,
                                          size: 19,
                                          color: selected ? _amber : _faint,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(pName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: selected
                                                  ? _valueStyle
                                                  : const TextStyle(
                                                      fontFamily: _bodyFont,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _inkMute,
                                                    )),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (selectedRef == null)
                              ? null
                              : () async {
                                  Navigator.of(ctx).pop();
                                  setState(() {
                                    _selectedProjectRef = selectedRef;
                                    _selectedProjectName = selectedName;
                                  });
                                  await _addListingToProject(
                                    projectRef: selectedRef!,
                                    listingRef: listingRef,
                                    addedBy: userRef,
                                    title: title,
                                    subTitle: subTitle,
                                    ratingText: ratingText,
                                    photoUrl: photoUrl,
                                  );
                                },
                          borderRadius: BorderRadius.circular(999),
                          child: Opacity(
                            opacity: selectedRef == null ? 0.5 : 1,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _amber,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Center(
                                child: Text('Add to project',
                                    style: TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleTopButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _paper,
          shape: BoxShape.circle,
          border: Border.all(color: _hairline, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: _inkMute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

    if (widget.listingRef == null) {
      return SizedBox(
        width: width,
        height: height,
        child: Container(
          color: _paper,
          padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: _coral, size: 40),
              const SizedBox(height: 12),
              Text('Listing not found.', style: _valueStyle),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.listingRef!.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Container(
              color: _paper,
              alignment: Alignment.center,
              child: _showSlowLoadFallback
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: _faint, size: 38),
                        const SizedBox(height: 10),
                        Text('Still loading…', style: _metaStyle),
                      ],
                    )
                  : const CircularProgressIndicator(
                      color: _amber, strokeWidth: 2),
            );
          }

          final raw = (snap.data!.data() as Map<String, dynamic>?) ??
              <String, dynamic>{};

          String readString(String k) => (raw[k] ?? '').toString().trim();
          int? readInt(String k) => raw[k] is int ? raw[k] as int : null;

          List<String> readStringList(String k) {
            final v = raw[k];
            if (v is List) {
              return v
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            return <String>[];
          }

          DocumentReference? readDocRef(String k) {
            final v = raw[k];
            if (v is DocumentReference) return v;
            return null;
          }

          final String name = readString('name').isNotEmpty
              ? readString('name')
              : _fallbackName;
          final String category = readString('category').isNotEmpty
              ? readString('category')
              : _fallbackTrade;
          final String categorySlug = readString('categorySlug').isNotEmpty
              ? readString('categorySlug')
              : functions.slugify(category);
          final String speciality = readString('speciality');
          final String suburb = readString('suburb');
          final String province = readString('province');
          final String city = readString('city');
          final String provinceSlug = readString('provinceSlug').isNotEmpty
              ? readString('provinceSlug')
              : functions.slugify(province);
          final String area = [
            if (suburb.isNotEmpty) suburb,
            if (city.isNotEmpty) city,
            if (province.isNotEmpty) province,
          ].join(', ');
          final String displayArea = area.isNotEmpty ? area : _fallbackArea;

          final double rating =
              (raw['rating'] is num) ? (raw['rating'] as num).toDouble() : 0.0;
          final int reviews = readInt('reviewCount') ?? readInt('reviews') ?? 0;
          final bool hasReviews = reviews > 0;

          final List<String> associations = readStringList('associations');
          final String aboutText =
              readString('about').isNotEmpty ? readString('about') : _aboutText;
          final List<String> servicesFromDb = readStringList('services');
          final List<String> safeServices =
              servicesFromDb.isNotEmpty ? servicesFromDb : _services;
          final String openingHours = readString('openingHours').isNotEmpty
              ? readString('openingHours')
              : '07:00 – 18:00';
          final bool openNow =
              (raw['openNow'] == true) || (raw['isOpen'] == true);

          final String listingPhone = readString('phoneNumber');
          final String listingWhatsapp = readString('whatsappNumber');
          final String listingEmail = readString('email');

          // Consolidated onto ownerRef (the field the app actually writes &
          // queries). providerRef/claimedAt are retired; backfill ownerRef
          // from providerRef before deleting those fields in Firestore.
          final DocumentReference? ownerRef = readDocRef('ownerRef');
          final bool isVerified = raw['isVerified'] == true;

          final List<String> listingPhotos = readStringList('photoUrls');
          final String heroPhotoUrl = readString('heroPhotoUrl').isNotEmpty
              ? readString('heroPhotoUrl')
              : (listingPhotos.isNotEmpty ? listingPhotos.first : '');
          final List<String> galleryPhotos = listingPhotos.isNotEmpty
              ? listingPhotos
              : (heroPhotoUrl.isNotEmpty ? <String>[heroPhotoUrl] : const []);

          final String ownerName = readString('ownerName');
          final String ownerPhotoUrl = readString('ownerPhotoUrl');

          final double bottomScrollPad = _bottomCtaContainerHeight + 18;
          final double bannerHeight =
              (MediaQuery.sizeOf(context).height * 0.32).clamp(220.0, 320.0);
          final listingRef = widget.listingRef!;

          final String plTitle = name;
          final String plSubTitle = [
            category,
            if (displayArea.isNotEmpty) displayArea
          ].where((s) => s.trim().isNotEmpty).join(' • ');
          final String plRatingText = hasReviews
              ? '${rating.toStringAsFixed(1)} • $reviews reviews'
              : 'No reviews yet';

          return DefaultTabController(
            length: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, _) {
                      return [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: bannerHeight,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                heroPhotoUrl.isNotEmpty
                                    ? Image.network(
                                        heroPhotoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, st) => Container(
                                          color: _surface,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: _faint,
                                              size: 40),
                                        ),
                                      )
                                    : Container(
                                        color: _surface,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.image_outlined,
                                            color: _faint, size: 40),
                                      ),
                                Positioned(
                                  top: topInset + 10,
                                  left: 14,
                                  child: _circleTopButton(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: () => context.safePop(),
                                  ),
                                ),
                                Positioned(
                                  top: topInset + 10,
                                  right: 14,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final userRef =
                                              _currentUserRefOrNull();
                                          if (userRef == null) {
                                            return _circleTopButton(
                                              icon:
                                                  Icons.bookmark_border_rounded,
                                              onTap: () => context
                                                  .pushNamed('loginPage'),
                                            );
                                          }
                                          return StreamBuilder<
                                              DocumentSnapshot>(
                                            stream: userRef.snapshots(),
                                            builder: (context, userSnap) {
                                              final userData =
                                                  (userSnap.data?.data() as Map<
                                                          String, dynamic>?) ??
                                                      <String, dynamic>{};
                                              final saved = _isListingSaved(
                                                userData: userData,
                                                listingRef: listingRef,
                                              );
                                              return _circleTopButton(
                                                icon: saved
                                                    ? Icons.bookmark_rounded
                                                    : Icons
                                                        .bookmark_border_rounded,
                                                onTap: () => _toggleBookmark(
                                                  listingRef: listingRef,
                                                  currentlySaved: saved,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      _circleTopButton(
                                        icon: Icons.share_rounded,
                                        onTap: () => _shareListing(
                                          name: name,
                                          category: category,
                                          area: displayArea,
                                          listingRef: listingRef,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            color: _paper,
                            padding:
                                const EdgeInsets.fromLTRB(_hPad, 18, _hPad, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // meta row
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    if (hasReviews)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 17, color: _amber),
                                          const SizedBox(width: 4),
                                          Text(rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _amber,
                                              )),
                                          const SizedBox(width: 5),
                                          Text('($reviews)', style: _metaStyle),
                                        ],
                                      )
                                    else
                                      Text('No reviews yet', style: _metaStyle),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: openNow
                                            ? _sunshine.withOpacity(0.18)
                                            : _surface,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            openNow
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_outlined,
                                            size: 13,
                                            color: openNow ? _amber : _faint,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(openNow ? 'Open now' : 'Closed',
                                              style: TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    openNow ? _coral : _faint,
                                              )),
                                        ],
                                      ),
                                    ),
                                    if (isVerified)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.verified_rounded,
                                              size: 15, color: _amber),
                                          SizedBox(width: 4),
                                          Text('Verified',
                                              style: TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _amber,
                                              )),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(name, style: _titleStyle),
                                if (speciality.isNotEmpty ||
                                    category.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.handyman_outlined,
                                          size: 16, color: _amber),
                                      const SizedBox(width: 8),
                                      if (speciality.isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            speciality,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: _bodyFont,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _amber,
                                            ),
                                          ),
                                        ),
                                      if (speciality.isNotEmpty &&
                                          category.isNotEmpty &&
                                          category != speciality) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                              color: _faint,
                                              shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(category, style: _metaStyle),
                                      ],
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: _faint),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child:
                                          Text(displayArea, style: _metaStyle),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                if (listingPhone.isNotEmpty ||
                                    listingWhatsapp.isNotEmpty ||
                                    listingEmail.isNotEmpty) ...[
                                  Text('CONTACT', style: _uLabelStyle),
                                  if (listingPhone.isNotEmpty)
                                    _contactRow(
                                      icon: Icons.call_outlined,
                                      value: listingPhone,
                                      onTap: () => _launchPhone(listingPhone),
                                    ),
                                  if (listingWhatsapp.isNotEmpty)
                                    _contactRow(
                                      icon: Icons.chat_outlined,
                                      value: listingWhatsapp,
                                      onTap: () =>
                                          _launchWhatsApp(listingWhatsapp),
                                    ),
                                  if (listingEmail.isNotEmpty)
                                    _contactRow(
                                      icon: Icons.mail_outlined,
                                      value: listingEmail,
                                      onTap: () => _launchEmail(listingEmail),
                                    ),
                                  const SizedBox(height: 18),
                                ],
                                if (ownerName.isNotEmpty ||
                                    ownerPhotoUrl.isNotEmpty) ...[
                                  Text('SERVICE PROVIDER', style: _uLabelStyle),
                                  _providerRow(
                                    name: ownerName.isNotEmpty
                                        ? ownerName
                                        : 'Listing owner',
                                    photoUrl: ownerPhotoUrl,
                                  ),
                                  const SizedBox(height: 18),
                                ] else if (ownerRef != null) ...[
                                  Text('SERVICE PROVIDER', style: _uLabelStyle),
                                  _buildProviderSection(
                                    providerRef: ownerRef,
                                    fallbackName:
                                        '$_fallbackProviderName $_fallbackProviderSurname',
                                    fallbackPhotoUrl: _fallbackProviderPhoto,
                                  ),
                                  const SizedBox(height: 18),
                                ],
                                const TabBar(
                                  isScrollable: true,
                                  labelPadding: EdgeInsets.only(right: 22),
                                  tabAlignment: TabAlignment.start,
                                  labelColor: _amber,
                                  unselectedLabelColor: _faint,
                                  indicatorColor: _amber,
                                  indicatorWeight: 2,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  labelStyle: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  unselectedLabelStyle: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  tabs: [
                                    Tab(text: 'About'),
                                    Tab(text: 'Services'),
                                    Tab(text: 'Gallery'),
                                    Tab(text: 'Location'),
                                    Tab(text: 'Associations'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [Text(aboutText, style: _bodyStyle)],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: safeServices
                                  .map((s) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: _surface,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(s,
                                            style: const TextStyle(
                                              fontFamily: _bodyFont,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _inkMute,
                                            )),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: galleryPhotos.isEmpty
                              ? [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 24),
                                      child: Text('No photos yet',
                                          style: _metaStyle),
                                    ),
                                  ),
                                ]
                              : [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: galleryPhotos.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemBuilder: (context, i) => ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        galleryPhotos[i],
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, st) => Container(
                                          color: _surface,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: _faint),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 18, color: _faint),
                                const SizedBox(width: 8),
                                Expanded(
                                    child:
                                        Text(displayArea, style: _bodyStyle)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    size: 18, color: _faint),
                                const SizedBox(width: 8),
                                Text(openingHours, style: _bodyStyle),
                              ],
                            ),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [
                            if (associations.isEmpty)
                              Text('No associations listed yet.',
                                  style: _bodyStyle)
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: associations
                                    .map((assoc) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: _surface,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.verified_outlined,
                                                  size: 14,
                                                  color: _amber),
                                              const SizedBox(width: 6),
                                              Text(assoc,
                                                  style: const TextStyle(
                                                    fontFamily: _bodyFont,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _inkMute,
                                                  )),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: _bottomCtaContainerHeight,
                    padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 18),
                    decoration: const BoxDecoration(
                      color: _paper,
                      border:
                          Border(top: BorderSide(color: _hairline, width: 1)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAddToProjectSheet(
                          listingRef: listingRef,
                          title: plTitle,
                          subTitle: plSubTitle,
                          ratingText: plRatingText,
                          photoUrl: heroPhotoUrl,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _amber,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.playlist_add_rounded,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Add to Project',
                                  style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  Widget _contactRow({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: _uRule,
        child: Row(
          children: [
            Icon(icon, size: 19, color: _amber),
            const SizedBox(width: 10),
            Expanded(child: Text(value, style: _valueStyle)),
            const Icon(Icons.chevron_right_rounded, color: _rule),
          ],
        ),
      ),
    );
  }

  Widget _providerRow({required String name, required String photoUrl}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _uRule,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: photoUrl.trim().isNotEmpty
                ? Image.network(photoUrl,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, st) => _avatarFallback())
                : _avatarFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _valueStyle),
                const SizedBox(height: 2),
                Text('Service provider', style: _metaStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _surface,
        shape: BoxShape.circle,
        border: Border.all(color: _hairline, width: 1),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person_outline_rounded, color: _faint),
    );
  }

  Widget _buildProviderSection({
    required DocumentReference? providerRef,
    required String fallbackName,
    required String fallbackPhotoUrl,
  }) {
    if (providerRef == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: providerRef.snapshots(),
      builder: (context, snap) {
        final data =
            (snap.data?.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        final displayName = (data['display_name'] ?? '').toString().trim();
        final surname = (data['surname'] ?? '').toString().trim();
        final photoUrl = (data['photo_url'] ?? '').toString().trim();
        final name = (displayName.isNotEmpty || surname.isNotEmpty)
            ? [displayName, surname].where((e) => e.isNotEmpty).join(' ')
            : fallbackName;
        final img = photoUrl.isNotEmpty ? photoUrl : fallbackPhotoUrl;
        return _providerRow(name: name, photoUrl: img);
      },
    );
  }
}
