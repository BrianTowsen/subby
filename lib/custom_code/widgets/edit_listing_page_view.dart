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

import 'index.dart'; // Imports other custom widgets

import '/flutter_flow/custom_functions.dart' as functions;

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/actions/index.dart';

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
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _coral = Color(0xFF566670); // destructive
  static const Color _warn =
      Color(0xFFAC0C0C); // warning / destructive accent (brown)
  static const Color _rule = Color(0xFFCBD8DD);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF2F3A4C);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF4E504F);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

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

  // The listing is loaded ONCE. Creating this future inside build() would
  // re-fetch on every rebuild — e.g. when the keyboard opens (MediaQuery
  // insets change) — flashing the loading spinner and killing text-field
  // focus, which looks like the page "reloading" on every tap.
  late Future<DocumentSnapshot<Map<String, dynamic>>?> _listingFuture;

  @override
  void initState() {
    super.initState();
    _listingFuture = _loadListingDoc();
  }

  String _existingHeroUrl = '';
  Uint8List? _heroBytes;
  String? _heroFileName;
  bool _removeHero = false;

  static const String _placeholderProvince = 'Select province';
  static const String _placeholderRegion = 'Select region';
  static const String _placeholderSpeciality = 'Select speciality';

  static const List<String> _listingTypes = [
    'Professionals',
    'Trades',
    'Suppliers',
    'Associations',
  ];

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
    'Eastern Cape': ['Gqeberha (Port Elizabeth)', 'East London', 'Mthatha'],
    'Free State': ['Bloemfontein', 'Welkom'],
    'North West': ['Rustenburg', 'Mahikeng', 'Potchefstroom'],
    'Limpopo': ['Polokwane', 'Tzaneen', 'Thohoyandou'],
    'Mpumalanga': ['Nelspruit (Mbombela)', 'Witbank (eMalahleni)', 'Secunda'],
    'Northern Cape': ['Kimberley', 'Upington'],
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

  List<String> get _currentRegions =>
      _regionsByProvince[_selectedProvince] ?? const <String>[];

  String get _listingTypeLabel => _listingType;

  // ---------------------------------------------------------
  // Firestore helpers
  // ---------------------------------------------------------
  List<String> _parseList(String raw) => raw
      .split(RegExp(r'[,\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    showAppToast(context, message, !error);
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
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Please enter your business name.', error: true);
      return false;
    }
    if (_selectedSpeciality == _placeholderSpeciality) {
      _toast('Please pick a speciality.', error: true);
      return false;
    }
    if (_aboutCtrl.text.trim().isEmpty) {
      _toast('Please add a short description.', error: true);
      return false;
    }
    if (_selectedProvince == _placeholderProvince) {
      _toast('Please pick a province.', error: true);
      return false;
    }
    if (_selectedRegion == _placeholderRegion) {
      _toast('Please pick a city / region.', error: true);
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

    final confirmed = await _showDeleteDialog(
      icon: Icons.delete_rounded,
      title: 'Delete this listing?',
      message:
          'Your listing and its cover photo will be permanently removed. This can’t be undone.',
      confirmLabel: 'Delete listing',
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

  // Centered destructive confirm dialog — shared "delete warning" module
  // (matches DocumentUploadPageView._showDeleteDialog).
  Future<bool?> _showDeleteDialog({
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 54,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _warn.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: _warn, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _warn,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _rule, width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  // ---------------------------------------------------------
  // Bottom-sheet picker (matches Add Listing)
  // ---------------------------------------------------------
  Future<String?> _pickFromSheet(
      String title, List<String> items, String current) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Text(title,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: _ink,
                  )),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: items.where((e) => !e.startsWith('Select ')).map((e) {
                  final selected = e == current;
                  return InkWell(
                    onTap: () => Navigator.of(ctx).pop(e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF3F6F7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(e,
                              style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 16,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected ? _ink : _inkMute,
                              )),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: _ink, size: 20),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  // Lift the focused field above the on-screen keyboard.
  void _ensureFocusedVisible() {
    Future.delayed(const Duration(milliseconds: 250), () {
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          color: _steel,
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            future: _listingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _paper),
                );
              }

              final doc = snapshot.data;
              if (doc == null) return _buildEmptyState(topInset);

              _hydrateFromDoc(doc);
              final listingRef = doc.reference;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _masthead(topInset),
                  Expanded(
                    child: Container(
                      color: _paper,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(_hPad, 22, _hPad,
                            24 + MediaQuery.of(context).padding.bottom),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _uLabel('LISTING TYPE'),
                            const SizedBox(height: 10),
                            _selectCard(
                              icon: Icons.workspace_premium_outlined,
                              value: _listingType,
                              onTap: () async {
                                final v = await _pickFromSheet('Listing type',
                                    _listingTypes, _listingType);
                                if (v != null) {
                                  setState(() {
                                    _listingType = v;
                                    _selectedSpeciality =
                                        _placeholderSpeciality;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            _uLabel('COVER PHOTO'),
                            const SizedBox(height: 10),
                            _coverRow(),
                            const SizedBox(height: 20),
                            _uLabel('DETAILS'),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: _paper,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _hairline),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(children: [
                                _textField('Name *', Icons.storefront_outlined,
                                    _nameCtrl, 'e.g. Acme Builders'),
                                _pickerField(
                                  'Speciality *',
                                  Icons.handyman_outlined,
                                  _selectedSpeciality,
                                  () async {
                                    final list = _subcategories[_listingType] ??
                                        const [];
                                    final v = await _pickFromSheet('Speciality',
                                        list, _selectedSpeciality);
                                    if (v != null) {
                                      setState(() => _selectedSpeciality = v);
                                    }
                                  },
                                ),
                                _textField(
                                    'About *',
                                    Icons.notes_outlined,
                                    _aboutCtrl,
                                    'Short description of your services…',
                                    maxLines: 3),
                                _textField(
                                    'Services',
                                    Icons.checklist_rounded,
                                    _servicesCtrl,
                                    'New installations, Geyser repairs, COC…',
                                    maxLines: 2),
                                _textField(
                                    'Associations',
                                    Icons.verified_outlined,
                                    _associationsCtrl,
                                    'Master Builders Association, ECA…'),
                                _textField('Phone number', Icons.call_outlined,
                                    _phoneCtrl, 'e.g. 082 123 4567',
                                    keyboard: TextInputType.phone),
                                _textField(
                                    'WhatsApp number',
                                    Icons.chat_outlined,
                                    _whatsCtrl,
                                    'e.g. 082 123 4567',
                                    keyboard: TextInputType.phone),
                                _textField('Email', Icons.mail_outlined,
                                    _emailCtrl, 'e.g. hello@company.co.za',
                                    keyboard: TextInputType.emailAddress),
                                _textField(
                                    'Opening hours',
                                    Icons.schedule_rounded,
                                    _hoursCtrl,
                                    'e.g. 07:00 – 18:00'),
                                _pickerField(
                                  'Province *',
                                  Icons.map_outlined,
                                  _selectedProvince,
                                  () async {
                                    final v = await _pickFromSheet('Province',
                                        _provinces, _selectedProvince);
                                    if (v != null) {
                                      setState(() {
                                        _selectedProvince = v;
                                        _selectedRegion = _placeholderRegion;
                                      });
                                    }
                                  },
                                ),
                                _pickerField(
                                  'City / Region *',
                                  Icons.location_city_outlined,
                                  _selectedRegion,
                                  () async {
                                    if (_currentRegions.isEmpty) {
                                      _toast('Pick a province first.');
                                      return;
                                    }
                                    final v = await _pickFromSheet(
                                        'City / Region',
                                        _currentRegions,
                                        _selectedRegion);
                                    if (v != null) {
                                      setState(() => _selectedRegion = v);
                                    }
                                  },
                                  divider: false,
                                ),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            InkWell(
                              onTap: (_saving || _deleting)
                                  ? null
                                  : () => _save(listingRef),
                              borderRadius: BorderRadius.circular(10),
                              child: Opacity(
                                opacity: _saving ? 0.6 : 1,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                      color: _lime,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          _saving
                                              ? Icons.hourglass_top_rounded
                                              : Icons.check_rounded,
                                          size: 18,
                                          color: _ink),
                                      const SizedBox(width: 8),
                                      Text(_saving ? 'Saving…' : 'Save changes',
                                          style: const TextStyle(
                                              fontFamily: _bodyFont,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: _ink)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: (_saving || _deleting)
                                      ? null
                                      : () => _deleteListing(listingRef),
                                  borderRadius: BorderRadius.circular(10),
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
                                          _deleting
                                              ? 'Deleting…'
                                              : 'Delete listing',
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
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Keep your description short and specific.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: _bodyFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _faint,
                                ),
                              ),
                            ),
                          ],
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
  }

  // =========================================================
  // UI helpers
  // =========================================================
  Widget _uLabel(String text) => Text(text,
      style: const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      ));

  Widget _selectCard({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hairline),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: _slate),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink))),
            const Icon(Icons.expand_more_rounded, color: _faint),
          ]),
        ),
      );

  Widget _coverRow() {
    final hasNew = _heroBytes != null && _heroBytes!.isNotEmpty;
    final hasExisting = !_removeHero && _existingHeroUrl.isNotEmpty;
    final showImage = hasNew || hasExisting;

    Widget thumb() {
      if (hasNew) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(_heroBytes!,
              width: 76, height: 76, fit: BoxFit.cover),
        );
      }
      if (hasExisting) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(_existingHeroUrl,
              width: 76, height: 76, fit: BoxFit.cover),
        );
      }
      return Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hairlineOnSurface, width: 1.5),
        ),
        child: const Icon(Icons.add_a_photo_outlined, size: 24, color: _faint),
      );
    }

    return Row(children: [
      InkWell(
        onTap: _saving ? null : _pickHeroPhoto,
        borderRadius: BorderRadius.circular(10),
        child: thumb(),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showImage ? 'Current cover' : 'Add a cover photo',
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: showImage ? _ink : _faint,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: _saving ? null : _pickHeroPhoto,
                child: const Text('Change',
                    style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    )),
              ),
              if (showImage) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _saving
                      ? null
                      : () => setState(() {
                            _heroBytes = null;
                            _heroFileName = null;
                            _removeHero = true;
                          }),
                  child: const Text('Remove',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _faint,
                      )),
                ),
              ],
            ]),
          ],
        ),
      ),
    ]);
  }

  Widget _pickerField(
      String label, IconData icon, String value, VoidCallback onTap,
      {bool divider = true}) {
    final isPlaceholder = value.startsWith('Select ');
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: _hairline))
              : null,
        ),
        child: Row(children: [
          Icon(icon, size: 19, color: _slate),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _faint)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPlaceholder ? _faint : _ink)),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, color: _faint),
        ]),
      ),
    );
  }

  Widget _textField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboard,
    bool divider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border:
            divider ? const Border(bottom: BorderSide(color: _hairline)) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 19, color: _slate),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _faint)),
              const SizedBox(height: 2),
              TextField(
                controller: controller,
                onTap: _ensureFocusedVisible,
                maxLines: maxLines,
                keyboardType: keyboard,
                enabled: !_saving,
                cursorColor: _ink,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hint,
                  hintStyle: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _faint),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

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
                  onTap: () => context.safePop(),
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
                  child: Text('EDIT LISTING',
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
            const SizedBox(height: 16),
            const Text('Edit listing',
                style: TextStyle(
                  fontFamily: _displayFont,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.0,
                  color: _paper,
                )),
            const SizedBox(height: 8),
            Text('Update your network profile.',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _paper.withOpacity(0.55),
                )),
          ],
        ),
      );

  Widget _buildEmptyState(double topInset) {
    return Container(
      color: _paper,
      child: SafeArea(
        child: Center(
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
                    color: _ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We couldn’t find a listing linked to your account.',
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _faint,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => context.safePop(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                        color: _lime, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Go back',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
