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
    this.listingRef,
    this.listingCollectionName,
    this.listingOwnerRefField,
    this.listingOwnerIdField,
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
  // ─── SUBBY PALETTE — DIRECTORY (amber / sunshine) ──────────────────
  static const Color _amber = Color(0xFF29343A); // accent
  static const Color _inkMute = Color(0xFF566670); // labels
  static const Color _faint = Color(0xFF93A3AC); // subtitles / helpers
  static const Color _coral = Color(0xFF566670); // destructive
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _orange = Color(
      0xFF5D737E); // DS green: leading icons / active bookmark (was orange #EB7A02)
  static const Color _green = Color(0xFF5D737E); // DS: verified / info
  static const Color _gold = Color(0xFF5D737E); // DS: rating stars
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _rule = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 24;
  static const double _vPad = 14;

  // ---------------------------------------------------------
  // Form state
  // ---------------------------------------------------------
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _aboutCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsCtrl = TextEditingController();
  final TextEditingController _suburbCtrl = TextEditingController();
  final TextEditingController _servicesCtrl = TextEditingController();
  final TextEditingController _associationsCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();

  String _listingType = 'Professionals';
  String _selectedProvince = 'Select province';
  String _selectedRegion = 'Select region';
  String _selectedSpeciality = 'Select speciality';

  bool _saving = false;
  bool _deleting = false;
  bool _didHydrate = false;

  String _existingHeroUrl = '';
  Uint8List? _heroBytes;
  String? _heroFileName;
  bool _removeHero = false;

  // ---------------------------------------------------------
  // Typography
  // ---------------------------------------------------------
  TextStyle get _titleStyle => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: _amber,
        height: 1.05,
      );

  TextStyle get _subtitleStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _faint,
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

  TextStyle get _hintStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF93A3AC),
      );

  TextStyle get _helperStyle => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _faint,
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _rule, width: 1)),
  );

  // ---------------------------------------------------------
  // Data
  // ---------------------------------------------------------
  static const List<String> _listingTypes = [
    'Professionals',
    'Trades',
    'Suppliers',
    'Associations',
  ];

  String get _listingTypeLabel => _listingType;

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
    final list = _subcategories[_listingTypeLabel] ?? const <String>[];
    if (list.isEmpty) return const <String>[_placeholderSpeciality];
    return <String>[_placeholderSpeciality, ...list];
  }

  // ---------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------
  List<String> _parseList(String raw) =>
      raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: error ? _coral : _amber,
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          duration: const Duration(milliseconds: 1600),
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

  void _hydrateFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (_didHydrate) return;

    String s(dynamic v) => (v == null) ? '' : v.toString().trim();
    final data = doc.data() ?? <String, dynamic>{};

    final category = s(data['category']);
    _listingType =
        _listingTypes.contains(category) ? category : _listingTypes.first;

    _nameCtrl.text = s(data['name']);
    _aboutCtrl.text = s(data['about']);
    _phoneCtrl.text = s(data['phoneNumber']);
    _whatsCtrl.text = s(data['whatsappNumber']);
    _emailCtrl.text = s(data['email']);
    _suburbCtrl.text = s(data['suburb']);
    _existingHeroUrl = s(data['heroPhotoUrl']);

    List<String> sList(dynamic v) => (v is List)
        ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    _servicesCtrl.text = sList(data['services']).join(', ');
    _associationsCtrl.text = sList(data['associations']).join(', ');
    _hoursCtrl.text = s(data['openingHours']);

    final prov = s(data['province']);
    final city = s(data['city']);
    final spec = s(data['speciality']);

    _selectedProvince = _provinces.contains(prov) ? prov : _placeholderProvince;

    final regions = _regionsByProvince[_selectedProvince] ?? const <String>[];
    _selectedRegion = regions.contains(city) ? city : _placeholderRegion;

    final currentSpecs = _subcategories[_listingTypeLabel] ?? const <String>[];
    _selectedSpeciality =
        currentSpecs.contains(spec) ? spec : _placeholderSpeciality;

    _didHydrate = true;
  }

  // ---------------------------------------------------------
  // Hero photo
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

      final services = _parseList(_servicesCtrl.text);
      final associations = _parseList(_associationsCtrl.text);
      final openingHours = _hoursCtrl.text.trim();

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
        'services': services.isNotEmpty ? services : FieldValue.delete(),
        'associations':
            associations.isNotEmpty ? associations : FieldValue.delete(),
        if (openingHours.isNotEmpty)
          'openingHours': openingHours
        else
          'openingHours': FieldValue.delete(),
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
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete listing?',
          style: TextStyle(
            fontFamily: _displayFont,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _amber,
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
                fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      try {
        final folder = FirebaseStorage.instance
            .ref()
            .child('users/$currentUserUid/listings/${ref.id}');
        final listed = await folder.listAll();
        for (final item in listed.items) {
          await item.delete();
        }
      } catch (_) {}

      await ref.delete();

      if (!mounted) return;
      _toast('Listing deleted.');

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
    _servicesCtrl.dispose();
    _associationsCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: _paper,
          child: SafeArea(
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              future: _loadListingDoc(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _amber),
                  );
                }

                final doc = snapshot.data;
                if (doc == null) return _buildEmptyState();

                _hydrateFromDoc(doc);
                final listingRef = doc.reference;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(_hPad, _vPad, _hPad, _vPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backButton(),
                      const SizedBox(height: 20),
                      Text('Edit listing', style: _titleStyle),
                      const SizedBox(height: 8),
                      Text('Update your directory profile.',
                          style: _subtitleStyle),
                      const SizedBox(height: 30),
                      _uSelect(
                        label: 'Listing type',
                        icon: Icons.workspace_premium_outlined,
                        value: _listingType,
                        items: _listingTypes,
                        onChanged: (v) => setState(() {
                          _listingType = v;
                          _selectedSpeciality = _placeholderSpeciality;
                        }),
                      ),
                      _photoRow(),
                      _uText(
                        label: 'Name *',
                        controller: _nameCtrl,
                        icon: Icons.storefront_outlined,
                        hint: 'e.g. Acme Builders',
                      ),
                      _uSelect(
                        label: 'Speciality *',
                        icon: Icons.handyman_outlined,
                        value: _selectedSpeciality,
                        items: _currentSpecialities,
                        onChanged: (v) =>
                            setState(() => _selectedSpeciality = v),
                      ),
                      _uText(
                        label: 'About *',
                        controller: _aboutCtrl,
                        icon: Icons.notes_outlined,
                        hint: 'Short description of your services…',
                        maxLines: 4,
                      ),
                      _uText(
                        label: 'Services',
                        controller: _servicesCtrl,
                        icon: Icons.checklist_rounded,
                        hint: 'New installations, Geyser repairs, COC…',
                        maxLines: 2,
                      ),
                      _uText(
                        label: 'Associations',
                        controller: _associationsCtrl,
                        icon: Icons.verified_outlined,
                        hint: 'Master Builders Association, ECA…',
                      ),
                      _uText(
                        label: 'Phone number',
                        controller: _phoneCtrl,
                        icon: Icons.call_outlined,
                        hint: 'e.g. 082 123 4567',
                        keyboardType: TextInputType.phone,
                      ),
                      _uText(
                        label: 'WhatsApp number',
                        controller: _whatsCtrl,
                        icon: Icons.chat_outlined,
                        hint: 'e.g. 082 123 4567',
                        keyboardType: TextInputType.phone,
                      ),
                      _uText(
                        label: 'Email',
                        controller: _emailCtrl,
                        icon: Icons.mail_outlined,
                        hint: 'e.g. hello@company.co.za',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _uText(
                        label: 'Opening hours',
                        controller: _hoursCtrl,
                        icon: Icons.schedule_rounded,
                        hint: 'e.g. 07:00 – 18:00',
                      ),
                      _uSelect(
                        label: 'Province *',
                        icon: Icons.map_outlined,
                        value: _selectedProvince,
                        items: _provinces,
                        onChanged: (v) => setState(() {
                          _selectedProvince = v;
                          _selectedRegion = _placeholderRegion;
                        }),
                      ),
                      _uSelect(
                        label: 'City / Region *',
                        icon: Icons.location_city_outlined,
                        value: _currentRegions.contains(_selectedRegion)
                            ? _selectedRegion
                            : _placeholderRegion,
                        items: _currentRegions,
                        onChanged: (v) => setState(() => _selectedRegion = v),
                      ),
                      const SizedBox(height: 30),
                      _primaryButton(
                        label: _saving ? 'Saving…' : 'Save changes',
                        icon: _saving
                            ? Icons.hourglass_top_rounded
                            : Icons.check_rounded,
                        onTap: (_saving || _deleting)
                            ? null
                            : () => _save(listingRef),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (_saving || _deleting)
                                ? null
                                : () => _deleteListing(listingRef),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _deleting
                                        ? Icons.hourglass_top_rounded
                                        : Icons.delete_outline_rounded,
                                    size: 18,
                                    color: _coral,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _deleting ? 'Deleting…' : 'Delete listing',
                                    style: const TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _coral,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Keep your description short and specific to rank better.',
                          textAlign: TextAlign.center,
                          style: _helperStyle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI helpers
  // =========================================================
  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pop(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            border: Border.all(color: _hairline),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: _inkMute),
        ),
      ),
    );
  }

  Widget _uText({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final multiline = maxLines > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: multiline ? 3 : 0),
                child: Icon(icon, size: 19, color: _orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !_saving,
                  cursorColor: _amber,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: _valueStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: _hintStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uSelect({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    final isPlaceholder = safeValue.startsWith('Select ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 19, color: _orange),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: safeValue,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: _paper,
                    icon:
                        const Icon(Icons.expand_more_rounded, color: _inkMute),
                    style: isPlaceholder ? _hintStyle : _valueStyle,
                    items: items
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                              style: e.startsWith('Select ')
                                  ? _hintStyle
                                  : _valueStyle,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v == null) return;
                            onChanged(v);
                          },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoRow() {
    final hasNew = _heroBytes != null && _heroBytes!.isNotEmpty;
    final hasExisting = !_removeHero && _existingHeroUrl.isNotEmpty;
    final showImage = hasNew || hasExisting;

    Widget thumb() {
      if (hasNew) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(_heroBytes!,
              width: 44, height: 44, fit: BoxFit.cover),
        );
      }
      if (hasExisting) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(_existingHeroUrl,
              width: 44, height: 44, fit: BoxFit.cover),
        );
      }
      return const Icon(Icons.add_a_photo_outlined, size: 19, color: _orange);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COVER PHOTO', style: _uLabelStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              thumb(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  showImage ? 'Current cover' : 'Add a cover photo',
                  style: showImage ? _valueStyle : _hintStyle,
                ),
              ),
              GestureDetector(
                onTap: _saving ? null : _pickHeroPhoto,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _amber,
                  ),
                ),
              ),
              if (showImage) ...[
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: _saving
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
                      fontWeight: FontWeight.w800,
                      color: _faint,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Opacity(
          opacity: onTap == null ? 0.7 : 1,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: _paper),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _paper,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 40, color: _faint),
            const SizedBox(height: 12),
            const Text(
              'No listing found',
              style: TextStyle(
                fontFamily: _displayFont,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _amber,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn’t find a listing linked to your account.',
              style: _helperStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _primaryButton(
              label: 'Go back',
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
