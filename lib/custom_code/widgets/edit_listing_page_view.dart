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

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import '/auth/firebase_auth/auth_util.dart';

class EditListingPageView extends StatefulWidget {
  const EditListingPageView({
    super.key,
    this.width,
    this.height,

    /// ✅ Pass this from HomePage when user has a listing
    this.listingRef,

    /// ✅ Optional override if your collection name differs
    this.listingCollectionName,

    /// ✅ Ownership fields
    this.listingOwnerRefField,
    this.listingOwnerIdField,

    /// ✅ Route to return to after deleting (defaults to 'dashboardPage')
    this.dashboardRouteName,
  });

  final double? width;
  final double? height;

  final DocumentReference? listingRef;

  final String? listingCollectionName;
  final String? listingOwnerRefField;
  final String? listingOwnerIdField;
  final String? dashboardRouteName;

  @override
  State<EditListingPageView> createState() => _EditListingPageViewState();
}

class _EditListingPageViewState extends State<EditListingPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF181C27);
  static const Color _inkSoft = Color(0xFF181C27);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _surface2 = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFFFE718); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF181C27);
  static const Color _calm = Color(0xFF9C8A12);
  static const Color _calmInk = Color(0xFFFFFFFF);
  // Status
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / warning
  static const Color _steel = Color(0xFF9DA8B5);
  static const Color _coral =
      Color(0xFFC8102E); // legacy red — error/destructive
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
  static const double _vPad = _pageHPad;

  static const double _cardRadius = _rLarge;

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _hairline, width: 1),
      );

  // ---------------------------------------------------------
  // Form state (MATCH AddListing)
  // ---------------------------------------------------------
  int _selectedTabIndex = 0; // 0..3

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsCtrl = TextEditingController();
  final TextEditingController _suburbCtrl = TextEditingController();

  String _selectedProvince = 'Select province';
  String _selectedRegion = 'Select region';
  String _selectedSpeciality = 'Select speciality';

  bool _saving = false;
  bool _deleting = false;
  bool _didHydrate = false;

  // Hero photo (edit): existing url + optional new pick / removal.
  String _existingHeroUrl = '';
  Uint8List? _heroBytes;
  String? _heroFileName;
  bool _removeHero = false;

  // ---------------------------------------------------------
  // Typography (locked palette — explicit family + colour)
  // ---------------------------------------------------------
  TextStyle get _titleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle get _subtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        color: _inkMute,
      );

  TextStyle get _sectionTitleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _tabTextStyle({required bool selected}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: selected ? _paper : _inkMute,
      );

  TextStyle get _fieldTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: _ink,
      );

  TextStyle get _hintTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        color: _inkMute,
      );

  TextStyle get _labelStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _inkMute,
      );

  TextStyle get _primaryBtnTextStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _sparkInk, // ink-on-yellow
      );

  // ---------------------------------------------------------
  // Listing type labels (match AddListing)
  // ---------------------------------------------------------
  String get _listingTypeLabel {
    switch (_selectedTabIndex) {
      case 0:
        return 'Professionals';
      case 1:
        return 'Trades';
      case 2:
        return 'Suppliers';
      case 3:
      default:
        return 'Associations';
    }
  }

  // ---------------------------------------------------------
  // Dropdown data (same as AddListing)
  // ---------------------------------------------------------
  static const String _placeholderProvince = 'Select province';
  static const String _placeholderRegion = 'Select region';
  static const String _placeholderSpeciality = 'Select speciality';

  static const List<String> _provinces = [
    _placeholderProvince,
    'Gauteng',
    'Western Cape',
    'KwaZulu-Natal',
    'Eastern Cape',
    'Free State',
    'North West',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
  ];

  static const Map<String, List<String>> _regionsByProvince = {
    'Gauteng': [
      'Johannesburg',
      'Pretoria',
      'Centurion',
      'Midrand',
      'Sandton',
      'Soweto',
      'East Rand',
      'West Rand',
      'Vaal',
    ],
    'Western Cape': [
      'Cape Town',
      'Stellenbosch',
      'Somerset West',
      'Paarl',
      'George',
      'Knysna',
      'Hermanus',
    ],
    'KwaZulu-Natal': [
      'Durban',
      'Umhlanga',
      'Pietermaritzburg',
      'Ballito',
      'Richards Bay',
    ],
    'Eastern Cape': [
      'Gqeberha (Port Elizabeth)',
      'East London',
      'Mthatha',
    ],
    'Free State': [
      'Bloemfontein',
      'Welkom',
    ],
    'North West': [
      'Rustenburg',
      'Mahikeng',
      'Potchefstroom',
    ],
    'Limpopo': [
      'Polokwane',
      'Tzaneen',
      'Thohoyandou',
    ],
    'Mpumalanga': [
      'Nelspruit (Mbombela)',
      'Witbank (eMalahleni)',
      'Secunda',
    ],
    'Northern Cape': [
      'Kimberley',
      'Upington',
    ],
  };

  static const Map<String, List<String>> _subcategories = {
    'Professionals': [
      'Architect',
      'Structural engineer',
      'Quantity surveyor',
      'Interior designer',
      'Project manager',
      'Land surveyor',
    ],
    'Trades': [
      'Builder',
      'Electrician',
      'Plumber',
      'Tiler',
      'Painter',
      'Carpenter',
      'Roofer',
      'Glazier',
    ],
    'Suppliers': [
      'Building materials',
      'Hardware store',
      'Timber & roofing',
      'Windows & doors',
      'Kitchens & cupboards',
      'Paint & coatings',
      'Plumbing supplies',
    ],
    'Associations': [
      'Master Builders Association',
      'NHBRC',
      'Electrical Contractors Association',
      'Plumbing Industry Board',
    ],
  };

  List<String> get _currentRegions {
    if (_selectedProvince == _placeholderProvince) {
      return const <String>[_placeholderRegion];
    }
    final list = _regionsByProvince[_selectedProvince] ?? const <String>[];
    if (list.isEmpty) return const <String>[_placeholderRegion];
    return <String>[_placeholderRegion, ...list];
  }

  List<String> get _currentSpecialities {
    final label = _listingTypeLabel;
    final list = _subcategories[label] ?? const <String>[];
    if (list.isEmpty) return const <String>[_placeholderSpeciality];
    return <String>[_placeholderSpeciality, ...list];
  }

  // ---------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------

  // ✅ Toast (locked palette)
  void _toast(String message, {bool error = false}) {
    if (!mounted) return;

    final IconData icon =
        error ? Icons.error_outline_rounded : Icons.check_rounded;

    final Color accent = error ? _coral : _ink;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevation: 0,
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rLarge),
            side: BorderSide(
              color: error ? _coral.withOpacity(0.35) : _hairlineOnSurface,
              width: 1,
            ),
          ),
          duration: const Duration(milliseconds: 1400),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<DocumentReference?> _findMyListingRef() async {
    final userRef = currentUserReference;
    final uid = currentUserUid;

    if (userRef == null && (uid == null || uid.isEmpty)) return null;

    final coll = (widget.listingCollectionName ?? 'subby_listings').trim();
    final ownerRefField = (widget.listingOwnerRefField ?? 'ownerRef').trim();
    final ownerIdField = (widget.listingOwnerIdField ?? 'ownerId').trim();

    final colRef = FirebaseFirestore.instance.collection(coll);

    if (userRef != null && ownerRefField.isNotEmpty) {
      final snap =
          await colRef.where(ownerRefField, isEqualTo: userRef).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first.reference;
    }

    if (uid != null && uid.isNotEmpty && ownerIdField.isNotEmpty) {
      final snap =
          await colRef.where(ownerIdField, isEqualTo: uid).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first.reference;
    }

    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadListingDoc() async {
    DocumentReference? ref = widget.listingRef;
    ref ??= await _findMyListingRef();
    if (ref == null) return null;

    final snap = await ref.get();
    if (!snap.exists) return null;
    return snap as DocumentSnapshot<Map<String, dynamic>>;
  }

  int _tabIndexFromCategory(String category) {
    final c = category.trim();
    if (c == 'Professionals') return 0;
    if (c == 'Trades') return 1;
    if (c == 'Suppliers') return 2;
    if (c == 'Associations') return 3;
    return 0;
  }

  void _hydrateFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (_didHydrate) return;

    String s(dynamic v) => (v == null) ? '' : v.toString().trim();
    final data = doc.data() ?? <String, dynamic>{};

    final category = s(data['category']);
    _selectedTabIndex = _tabIndexFromCategory(category);

    _nameCtrl.text = s(data['name']);
    _aboutCtrl.text = s(data['about']);
    _phoneCtrl.text = s(data['phoneNumber']);
    _whatsCtrl.text = s(data['whatsappNumber']);
    _emailCtrl.text = s(data['email']);
    _suburbCtrl.text = s(data['suburb']);
    _existingHeroUrl = s(data['heroPhotoUrl']);

    final prov = s(data['province']);
    final city = s(data['city']);
    final spec = s(data['speciality']);

    _selectedProvince = _provinces.contains(prov) ? prov : (_provinces.first);

    // ✅ ensure region is valid for selected province
    final regions = _regionsByProvince[_selectedProvince] ?? const <String>[];
    _selectedRegion = regions.contains(city) ? city : _placeholderRegion;

    // ✅ Speciality must match current category list
    final currentSpecs = _subcategories[_listingTypeLabel] ?? const <String>[];
    _selectedSpeciality =
        currentSpecs.contains(spec) ? spec : _placeholderSpeciality;

    _didHydrate = true;
  }

  // ---------------------------------------------------------
  // Hero photo (FilePicker + FirebaseStorage; uploaded on save)
  // ---------------------------------------------------------
  Future<void> _pickHeroPhoto() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final Uint8List? bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        _toast('Could not read that image. Try again.', error: true);
        return;
      }
      setState(() {
        _heroBytes = bytes;
        _heroFileName = f.name;
        _removeHero = false;
      });
    } catch (e) {
      debugPrint('\u26a0\ufe0f pick hero failed: $e');
      _toast('Could not pick image.', error: true);
    }
  }

  Widget _buildHeroPhotoPicker() {
    final hasNew = _heroBytes != null && _heroBytes!.isNotEmpty;
    final hasExisting = !_removeHero && _existingHeroUrl.isNotEmpty;
    final showImage = hasNew || hasExisting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _saving ? null : _pickHeroPhoto,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(_cardRadius),
              border: Border.all(color: _hairlineOnSurface, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasNew
                ? Image.memory(_heroBytes!, fit: BoxFit.cover)
                : hasExisting
                    ? Image.network(_existingHeroUrl, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              size: 30, color: _inkMute),
                          const SizedBox(height: 8),
                          Text('Add a cover photo', style: _hintTextStyle),
                        ],
                      ),
          ),
        ),
        if (showImage) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _saving ? null : _pickHeroPhoto,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _heroBytes = null;
                          _heroFileName = null;
                          _removeHero = true;
                        }),
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _inkMute,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final about = _aboutCtrl.text.trim();

    if (name.isEmpty) {
      _toast('Please enter your business name.', error: true);
      return false;
    }
    if (_selectedProvince == _placeholderProvince) {
      _toast('Please select a province.', error: true);
      return false;
    }
    if (_selectedRegion == _placeholderRegion) {
      _toast('Please select a city / region.', error: true);
      return false;
    }
    if (_selectedSpeciality == _placeholderSpeciality) {
      _toast('Please select a speciality.', error: true);
      return false;
    }
    if (about.isEmpty) {
      _toast('Please add a short description (About).', error: true);
      return false;
    }
    return true;
  }

  Future<void> _save(DocumentReference ref) async {
    if (_saving) return;
    if (!_validate()) return;

    setState(() => _saving = true);

    try {
      final now = Timestamp.now();

      final name = _nameCtrl.text.trim();
      final about = _aboutCtrl.text.trim();

      final phone = _phoneCtrl.text.trim();
      final whatsapp = _whatsCtrl.text.trim();
      final email = _emailCtrl.text.trim();

      final province = _selectedProvince.trim();
      final city = _selectedRegion.trim();
      final suburb = _suburbCtrl.text.trim();

      final category = _listingTypeLabel;
      final speciality = _selectedSpeciality.trim();

      final categorySlug = functions.slugify(category);
      final specialitySlug = functions.slugify(speciality);
      final provinceSlug = functions.slugify(province);

      // Upload new hero photo (optional) -> users/<uid>/listings/<id>/...
      String? newHeroUrl;
      if (_heroBytes != null && _heroBytes!.isNotEmpty) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final rawName =
            (_heroFileName?.isNotEmpty ?? false) ? _heroFileName! : 'hero.jpg';
        final safeName =
            p.basename(rawName).replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
        final storagePath =
            'users/$currentUserUid/listings/${ref.id}/hero_${ts}_$safeName';
        final contentType =
            lookupMimeType(safeName, headerBytes: _heroBytes) ?? 'image/jpeg';
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        await storageRef.putData(
          _heroBytes!,
          SettableMetadata(contentType: contentType),
        );
        newHeroUrl = await storageRef.getDownloadURL();
      }

      final updateData = <String, dynamic>{
        'name': name,
        'about': about,
        'category': category,
        'categorySlug': categorySlug,
        'speciality': speciality,
        'specialitySlug': specialitySlug,
        'province': province,
        'provinceSlug': provinceSlug,
        'city': city,
        if (suburb.isNotEmpty)
          'suburb': suburb
        else
          'suburb': FieldValue.delete(),
        if (phone.isNotEmpty)
          'phoneNumber': phone
        else
          'phoneNumber': FieldValue.delete(),
        if (whatsapp.isNotEmpty)
          'whatsappNumber': whatsapp
        else
          'whatsappNumber': FieldValue.delete(),
        if (email.isNotEmpty) 'email': email else 'email': FieldValue.delete(),
        if (newHeroUrl != null) 'heroPhotoUrl': newHeroUrl,
        if (newHeroUrl != null) 'photoUrls': <String>[newHeroUrl],
        if (newHeroUrl == null && _removeHero)
          'heroPhotoUrl': FieldValue.delete(),
        if (newHeroUrl == null && _removeHero) 'photoUrls': FieldValue.delete(),
        'ownerName': currentUserDisplayName,
        'ownerPhotoUrl': currentUserPhoto,
        'updatedAt': now,
      };

      await ref.update(updateData);

      if (!mounted) return;
      _toast('Listing updated!');
      context.pop();
    } catch (e) {
      debugPrint('⚠️ save listing failed: $e');
      _toast('Save failed. Check rules/connection.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteListing(DocumentReference ref) async {
    if (_saving || _deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rLarge),
        ),
        title: const Text(
          'Delete listing?',
          style: TextStyle(
            fontFamily: _displayFont,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: _ink,
          ),
        ),
        content: const Text(
          'This permanently removes your listing. This cannot be undone.',
          style: TextStyle(
            fontFamily: _bodyFont,
            fontSize: 14,
            color: _inkMute,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 14,
                color: _inkMute,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 14,
                color: _coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      // Best-effort: clean up this listing's Storage files (non-blocking).
      try {
        final folder = FirebaseStorage.instance
            .ref()
            .child('users/$currentUserUid/listings/${ref.id}');
        final listed = await folder.listAll();
        for (final item in listed.items) {
          await item.delete();
        }
      } catch (_) {
        // ignore storage cleanup failures — they must not block the delete
      }

      // Hard delete the listing document.
      await ref.delete();

      if (!mounted) return;
      _toast('Listing deleted.');

      // Replace with Dashboard so it rebuilds fresh (Add/Edit label updates).
      context.pushReplacementNamed(
        (widget.dashboardRouteName ?? 'dashboardPage').trim(),
        extra: <String, dynamic>{
          kTransitionInfoKey: const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.leftToRight,
            duration: Duration(milliseconds: 260),
          ),
        },
      );
    } catch (e) {
      debugPrint('⚠️ delete listing failed: $e');
      if (mounted) {
        setState(() => _deleting = false);
        _toast('Delete failed. Check rules/connection.', error: true);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _whatsCtrl.dispose();
    _suburbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ✅ remove SafeArea white bands: handle insets manually
    final insets = MediaQuery.of(context).padding;
    final topInset = insets.top;
    final bottomInset = insets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: _paper,
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _loadListingDoc(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _ink),
                );
              }

              final doc = snapshot.data;
              if (doc == null) return _buildEmptyState();

              _hydrateFromDoc(doc);
              final listingRef = doc.reference;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- TOP BAR ----------------
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(_hPad, topInset + _vPad, _hPad, 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(_rMed),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(_rMed),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: _ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit Listing', style: _titleStyle),
                              const SizedBox(height: 2),
                              Text(
                                'Update your directory profile',
                                style: _subtitleStyle,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _saving ? null : () => _save(listingRef),
                          borderRadius: BorderRadius.circular(_rMed),
                          child: Opacity(
                            opacity: _saving ? 0.65 : 1,
                            child: Container(
                              height: 38,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: _spark,
                                borderRadius: BorderRadius.circular(_rMed),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _saving
                                        ? Icons.hourglass_top_rounded
                                        : Icons.check_rounded,
                                    size: 18,
                                    color: _sparkInk,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _saving ? 'Saving' : 'Save',
                                    style: _primaryBtnTextStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------------- LISTING TYPE (contained surface block) --
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(_rLarge),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Listing type', style: _sectionTitleStyle),
                          const SizedBox(height: 10),
                          _buildTypeTabs(),
                          const SizedBox(height: 10),
                          Text(
                            'You are editing a ${_listingTypeLabel.toLowerCase()} listing.',
                            style: _subtitleStyle,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------------- FORM ----------------
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          _hPad, 0, _hPad, bottomInset + 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: 'Photo',
                            child: _buildHeroPhotoPicker(),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Business details',
                            child: Column(
                              children: [
                                _field(
                                  label: 'Name *',
                                  controller: _nameCtrl,
                                  hint: 'e.g. Acme Builders',
                                ),
                                const SizedBox(height: 12),
                                _dropdownField(
                                  label: 'Speciality *',
                                  value: _selectedSpeciality,
                                  items: _currentSpecialities,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedSpeciality = v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'About *',
                                  controller: _aboutCtrl,
                                  hint: 'Short description of your services',
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Contact',
                            child: Column(
                              children: [
                                _field(
                                  label: 'Phone number',
                                  controller: _phoneCtrl,
                                  hint: 'e.g. 082 123 4567',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'WhatsApp number',
                                  controller: _whatsCtrl,
                                  hint: 'e.g. 082 123 4567',
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'Email',
                                  controller: _emailCtrl,
                                  hint: 'e.g. hello@company.co.za',
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Location',
                            child: Column(
                              children: [
                                _dropdownField(
                                  label: 'Province *',
                                  value: _selectedProvince,
                                  items: _provinces,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _selectedProvince = v;
                                      _selectedRegion = _placeholderRegion;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                _dropdownField(
                                  label: 'City / Region *',
                                  value:
                                      _currentRegions.contains(_selectedRegion)
                                          ? _selectedRegion
                                          : _placeholderRegion,
                                  items: _currentRegions,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _selectedRegion = v);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  label: 'Suburb (optional)',
                                  controller: _suburbCtrl,
                                  hint: 'e.g. Sandton',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildPrimaryButton(
                            label: _saving ? 'Saving…' : 'Save changes',
                            icon: _saving
                                ? Icons.hourglass_top_rounded
                                : Icons.check_rounded,
                            onTap: (_saving || _deleting)
                                ? () {}
                                : () => _save(listingRef),
                            disabled: _saving || _deleting,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tip: keep your description short and specific — this helps you rank better in search.',
                            style: _subtitleStyle,
                          ),
                          const SizedBox(height: 18),
                          // ---- Delete listing (destructive) ----
                          InkWell(
                            onTap: (_saving || _deleting)
                                ? null
                                : () => _deleteListing(listingRef),
                            borderRadius: BorderRadius.circular(_rMed),
                            child: Container(
                              height: 48,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _coral.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(_rMed),
                                border: Border.all(
                                  color: _coral.withOpacity(0.55),
                                  width: 1,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _deleting
                                        ? Icons.hourglass_top_rounded
                                        : Icons.delete_outline_rounded,
                                    size: 20,
                                    color: _coral,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _deleting ? 'Deleting…' : 'Delete listing',
                                    style: const TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 15,
                                      color: _coral,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
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
  }

  // =========================================================
  // UI helpers (match AddListing)
  // =========================================================
  Widget _buildTypeTabs() {
    final tabs = ['Professionals', 'Trades', 'Suppliers', 'Associations'];

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = _selectedTabIndex == i;

              return Padding(
                padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = i;
                      _selectedSpeciality = _placeholderSpeciality;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: selected ? _ink : _paper,
                      borderRadius: BorderRadius.circular(_rPill),
                      border: Border.all(
                        color: selected ? _ink : _hairlineOnSurface,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style: _tabTextStyle(selected: selected),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_rMed),
            border: Border.all(color: _hairlineOnSurface, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: _fieldTextStyle,
            cursorColor: _ink,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: _hintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isPlaceholder = value.startsWith('Select ');
    final Color selectedColor = isPlaceholder ? _inkMute : _ink;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_rMed),
            border: Border.all(color: _hairlineOnSurface, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _inkMute),
              dropdownColor: _paper,
              style: _fieldTextStyle.copyWith(color: selectedColor),
              items: items.map((s) {
                final bool itemPlaceholder = s.startsWith('Select ');
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(
                    s,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _fieldTextStyle.copyWith(
                      color: itemPlaceholder ? _inkMute : _ink,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(_rMed),
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: disabled ? _surface : _spark,
          borderRadius: BorderRadius.circular(_rMed),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: disabled ? _inkMute : _sparkInk),
            const SizedBox(width: 8),
            Text(
              label,
              style: disabled
                  ? _primaryBtnTextStyle.copyWith(color: _inkMute)
                  : _primaryBtnTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_rLarge),
            border: Border.all(color: _hairlineOnSurface),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 40, color: _inkMute),
              const SizedBox(height: 10),
              const Text(
                'No listing found',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: _ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'We couldn’t find a listing linked to your account.',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 14,
                  color: _inkMute,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(_rMed),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: _spark,
                    borderRadius: BorderRadius.circular(_rMed),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Go back',
                    style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 14,
                      color: _sparkInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
