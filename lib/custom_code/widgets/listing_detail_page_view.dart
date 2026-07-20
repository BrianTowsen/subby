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
  // ─── SUBBY PALETTE — DIRECTORY (Get-Quotes system) ─────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _coral = Color(0xFF4E504F);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _steel = Color(0xFF3D4F66);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _slate = Color(0xFF4E504F);
  static const Color _whatsapp = Color(0xFF25D366);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _rule = Color(0xFFDCE3E6);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const double _hPad = 22;

  static const double _bottomCtaContainerHeight = 92;
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
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: _ink,
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        duration: const Duration(milliseconds: 1400),
      ));
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
      debugPrint('⚠️ launch failed: $e');
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
  Query<Map<String, dynamic>> _projectsQuery(DocumentReference userRef) =>
      FirebaseFirestore.instance
          .collection('projects')
          .where('ownerRef', isEqualTo: userRef);

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
    await _showProjectPickerSheet(
      sheetTitle: 'Add to Project',
      sheetSubtitle: 'Choose which project to add this listing to.',
      ctaLabel: 'Add to project',
      ctaIcon: Icons.playlist_add_rounded,
      onConfirm: (projectRef) => _addListingToProject(
        projectRef: projectRef,
        listingRef: listingRef,
        addedBy: userRef,
        title: title,
        subTitle: subTitle,
        ratingText: ratingText,
        photoUrl: photoUrl,
      ),
    );
  }

  // ===========================
  // ADD TO PROJECT — PICKER
  // ===========================
  Future<void> _showProjectPickerSheet({
    required String sheetTitle,
    required String sheetSubtitle,
    required String ctaLabel,
    required IconData ctaIcon,
    required Future<void> Function(DocumentReference projectRef) onConfirm,
  }) async {
    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }
    DocumentReference? selectedRef = _selectedProjectRef;
    String? selectedName = _selectedProjectName;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                      offset: const Offset(0, 22)),
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
                      color: _ink.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _ink.withOpacity(0.22)),
                    ),
                    child: Icon(ctaIcon, color: _ink, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(sheetTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: _ink)),
                  const SizedBox(height: 8),
                  Text(sheetSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: _inkMute)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _projectsQuery(userRef).snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _ink)),
                        );
                      }
                      final rawDocs = snap.data?.docs ?? const [];
                      final docs = rawDocs
                          .where((d) => !_projectIsArchived(d.data()))
                          .toList()
                        ..sort((a, b) => _updatedAtMillis(b.data())
                            .compareTo(_updatedAtMillis(a.data())));
                      if (docs.isEmpty) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(children: const [
                                Icon(Icons.folder_off_outlined,
                                    size: 26, color: _faint),
                                SizedBox(height: 8),
                                Text('No projects yet',
                                    style: TextStyle(
                                        fontFamily: _displayFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _ink)),
                                SizedBox(height: 4),
                                Text(
                                    'Create a project first, then add this trade to it to request quotes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        height: 1.45,
                                        color: _inkMute)),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            _dialogButton(
                              label: 'Create a project',
                              icon: Icons.add_rounded,
                              filled: true,
                              fillColor: const Color(0xFF0CAC47),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _openCreateProject();
                              },
                            ),
                            const SizedBox(height: 10),
                            _dialogButton(
                              label: 'Cancel',
                              filled: false,
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        );
                      }
                      // ── PROJECT LIST ──
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('SELECT PROJECT',
                                style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: _inkMute)),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  (MediaQuery.of(context).size.height * 0.4)
                                      .clamp(180.0, 340.0),
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
                                        vertical: 13),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(color: _rule)),
                                    ),
                                    child: Row(children: [
                                      Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.folder_open_outlined,
                                          size: 19,
                                          color: selected ? _ink : _faint),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(pName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 16,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: selected
                                                    ? _ink
                                                    : _inkMute)),
                                      ),
                                    ]),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: selectedRef == null ? 0.5 : 1,
                            child: _dialogButton(
                              label: ctaLabel,
                              icon: ctaIcon,
                              filled: true,
                              onTap: selectedRef == null
                                  ? null
                                  : () async {
                                      Navigator.of(ctx).pop();
                                      setState(() {
                                        _selectedProjectRef = selectedRef;
                                        _selectedProjectName = selectedName;
                                      });
                                      await onConfirm(selectedRef!);
                                    },
                            ),
                          ),
                          const SizedBox(height: 10),
                          _dialogButton(
                            label: 'Cancel',
                            filled: false,
                            onTap: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Shared module button — filled = ink primary, else outline.
  Widget _dialogButton({
    required String label,
    IconData? icon,
    bool filled = true,
    Color fillColor = _ink,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? fillColor : _paper,
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(color: const Color(0xFFCBD8DD), width: 1.4),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: filled ? _paper : _ink),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: filled ? _paper : _ink)),
          ]),
        ),
      ),
    );
  }

  // Navigates to project creation (best-effort route; hint snack on failure).
  void _openCreateProject() {
    try {
      context.pushNamed('AddProjects');
    } catch (_) {
      _snack('Open My Projects to create a project.');
    }
  }

  // Resolves whether the trade is open right now. An explicit boolean on the
  // listing (openNow / isOpen) always wins; otherwise we parse the opening
  // hours string (e.g. "07:00 – 18:00", "7am - 6pm", "Closed", "24 hours")
  // and compare against the current local time.
  bool _computeOpenNow(Map<String, dynamic> raw, String hours) {
    if (raw['openNow'] is bool) return raw['openNow'] as bool;
    if (raw['isOpen'] is bool) return raw['isOpen'] as bool;

    final h = hours.trim().toLowerCase();
    if (h.isEmpty) return false;
    if (h.contains('24')) return true; // "24 hours", "open 24/7"
    if (h.contains('closed')) return false;

    // Split on en-dash, em-dash, hyphen or the word "to".
    final parts = h.split(RegExp(r'\s*(?:–|—|-|to)\s*'));
    if (parts.length < 2) return false;

    final open = _parseTimeOfDay(parts[0]);
    final close = _parseTimeOfDay(parts[1]);
    if (open == null || close == null) return false;

    final now = TimeOfDay.now();
    final nowM = now.hour * 60 + now.minute;
    final openM = open.hour * 60 + open.minute;
    var closeM = close.hour * 60 + close.minute;
    if (closeM <= openM) closeM += 24 * 60; // overnight (e.g. 18:00 – 02:00)
    final probe = nowM < openM ? nowM + 24 * 60 : nowM;
    return probe >= openM && probe < closeM;
  }

  // Parses "07:00", "7", "7am", "6:30 pm" → TimeOfDay (null if unparseable).
  TimeOfDay? _parseTimeOfDay(String s) {
    final t = s.trim().toLowerCase();
    final m = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(t);
    if (m == null) return null;
    var hh = int.tryParse(m.group(1) ?? '') ?? -1;
    final mm = int.tryParse(m.group(2) ?? '0') ?? 0;
    final ap = m.group(3);
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
    if (ap == 'pm' && hh < 12) hh += 12;
    if (ap == 'am' && hh == 12) hh = 0;
    return TimeOfDay(hour: hh, minute: mm);
  }

  // ===========================
  // RATING & REVIEWS
  // ===========================
  static const Color _warn = Color(0xFFAC0C0C); // gate-dialog red

  // A user may only rate a trade they have actually engaged: the gate passes
  // only if THIS user previously added THIS listing to one of their projects
  // (project_listings.addedBy == user & listingRef == listing).
  Future<bool> _hasAddedToProject({
    required DocumentReference listingRef,
    required DocumentReference userRef,
  }) async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('project_listings')
          .where('listingRef', isEqualTo: listingRef)
          .where('addedBy', isEqualTo: userRef)
          .limit(1)
          .get();
      return q.docs.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ rating gate check failed: $e');
      return false;
    }
  }

  Future<void> _onRateTapped({
    required DocumentReference listingRef,
    DocumentReference? providerRef,
    required String name,
  }) async {
    final userRef = _currentUserRefOrNull();
    if (userRef == null) {
      context.pushNamed('loginPage');
      return;
    }
    final allowed =
        await _hasAddedToProject(listingRef: listingRef, userRef: userRef);
    if (!mounted) return;
    if (!allowed) {
      await _showRatingGateDialog(name);
      return;
    }
    await _showRatingSheet(
        listingRef: listingRef, userRef: userRef, name: name);
  }

  // Warning gate — mirrors the shared confirm dialog, single dismiss action.
  Future<void> _showRatingGateDialog(String name) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: _paper, borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _warn.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _warn.withOpacity(0.22)),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: _warn, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Add to a project first',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontSize: 18,
                    color: _ink)),
            const SizedBox(height: 8),
            Text(
                'You can only rate a trade you’ve worked with. Add this listing to one of your projects, then rate them once the job’s underway.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    fontSize: 14,
                    color: _inkMute)),
            const SizedBox(height: 22),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(ctx),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _ink, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Got it',
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _paper)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Star + comment capture. Prefills the user's existing review if present.
  Future<void> _showRatingSheet({
    required DocumentReference listingRef,
    required DocumentReference userRef,
    required String name,
  }) async {
    final reviewRef = listingRef.collection('reviews').doc(userRef.id);
    int stars = 5;
    final commentCtl = TextEditingController();
    try {
      final prev = await reviewRef.get();
      final pd = prev.data() as Map<String, dynamic>?;
      if (pd != null) {
        if (pd['rating'] is num)
          stars = (pd['rating'] as num).round().clamp(1, 5);
        commentCtl.text = (pd['comment'] ?? '').toString();
      }
    } catch (_) {}
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                      offset: const Offset(0, 22)),
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
                      color: const Color(0xFFF2B01E).withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFF2B01E).withOpacity(0.28)),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Color(0xFFF2B01E), size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text('Rate $name',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: _displayFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: _ink)),
                  const SizedBox(height: 8),
                  const Text('Tap a star to set your rating.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _inkMute)),
                  const SizedBox(height: 16),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final on = i < stars;
                        return GestureDetector(
                          onTap: () => setLocal(() => stars = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                                on
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 40,
                                color: on ? const Color(0xFFF2B01E) : _rule),
                          ),
                        );
                      })),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _hairline)),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: commentCtl,
                      minLines: 3,
                      maxLines: 5,
                      cursorColor: _ink,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: _ink),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText:
                            'Share how the job went — quality, timekeeping, value…',
                        hintStyle: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _faint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _submitReview(
                          listingRef: listingRef,
                          userRef: userRef,
                          stars: stars,
                          comment: commentCtl.text,
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: _lime,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star_rounded, size: 18, color: _ink),
                              SizedBox(width: 8),
                              Text('Submit rating',
                                  style: TextStyle(
                                      fontFamily: _bodyFont,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: _ink)),
                            ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dialogButton(
                    label: 'Cancel',
                    filled: false,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Writes the user's review (one doc per user, keyed by uid) and keeps the
  // listing's rating/reviewCount aggregate in sync so Explore / Saved / list
  // cards (which read listing.rating) stay correct without a Cloud Function.
  Future<void> _submitReview({
    required DocumentReference listingRef,
    required DocumentReference userRef,
    required int stars,
    required String comment,
  }) async {
    final reviewRef = listingRef.collection('reviews').doc(userRef.id);
    try {
      final prev = await reviewRef.get();
      final prevData = prev.data() as Map<String, dynamic>?;
      final int? oldStars = (prevData?['rating'] is num)
          ? (prevData!['rating'] as num).round()
          : null;

      await reviewRef.set({
        'rating': stars,
        'comment': comment.trim(),
        'userRef': userRef,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!prev.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final lsnap = await tx.get(listingRef);
        final ld = (lsnap.data() as Map<String, dynamic>? ?? {});
        num sum = (ld['ratingSum'] is num) ? ld['ratingSum'] as num : 0;
        int count =
            (ld['reviewCount'] is num) ? (ld['reviewCount'] as num).toInt() : 0;
        if (oldStars == null) {
          sum += stars;
          count += 1;
        } else {
          sum += (stars - oldStars);
        }
        final double avg = count > 0 ? (sum / count) : 0;
        tx.update(listingRef, {
          'ratingSum': sum,
          'reviewCount': count,
          'rating': avg,
        });
      });
      _snack('Thanks — your rating was saved.');
    } catch (e) {
      debugPrint('⚠️ submit review failed: $e');
      _snack('Could not save your rating. Please try again.');
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _circleTopButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: _paper.withOpacity(0.14), shape: BoxShape.circle),
        child: Icon(icon, size: 17, color: iconColor ?? _paper),
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
            children: const [
              Icon(Icons.error_outline, color: _coral, size: 40),
              SizedBox(height: 12),
              Text('Listing not found.',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink)),
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
                  ? Column(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.wifi_off_rounded, color: _faint, size: 38),
                      SizedBox(height: 10),
                      Text('Still loading…',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _faint)),
                    ])
                  : const CircularProgressIndicator(
                      color: _ink, strokeWidth: 2),
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
          final String speciality = readString('speciality');
          final String suburb = readString('suburb');
          final String province = readString('province');
          final String city = readString('city');
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
          // Open/closed now derives from the opening hours when no explicit
          // openNow/isOpen boolean is set on the listing.
          final bool openNow = _computeOpenNow(raw, openingHours);

          final String listingPhone = readString('phoneNumber');
          final String listingWhatsapp = readString('whatsappNumber');
          final String listingEmail = readString('email');

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

          final double bottomScrollPad = _bottomCtaContainerHeight + 18;
          final listingRef = widget.listingRef!;

          final String plTitle = name;
          final String plSubTitle = [
            category,
            if (displayArea.isNotEmpty) displayArea
          ].where((s) => s.trim().isNotEmpty).join(' • ');
          final String plRatingText = hasReviews
              ? '${rating.toStringAsFixed(1)} • $reviews reviews'
              : 'No reviews yet';

          final String providerDisplay =
              ownerName.isNotEmpty ? ownerName : 'Listing owner';
          final String phoneForCard =
              listingPhone.isNotEmpty ? listingPhone : '—';

          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Steel hero with cover photo + scrim ──
                        Stack(
                          children: [
                            Positioned.fill(
                              child: heroPhotoUrl.isNotEmpty
                                  ? Image.network(heroPhotoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, st) =>
                                          Container(color: _steel))
                                  : Container(color: _steel),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x5A3A5966),
                                      Color(0x803A5966),
                                      Color(0xEB3A5966),
                                    ],
                                    stops: [0.0, 0.42, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  _hPad, topInset + 10, _hPad, 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _circleTopButton(
                                        icon: Icons.arrow_back_ios_new_rounded,
                                        onTap: () => context.safePop(),
                                      ),
                                      Row(children: [
                                        Builder(builder: (context) {
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
                                                iconColor:
                                                    saved ? _lime : _paper,
                                                onTap: () => _toggleBookmark(
                                                  listingRef: listingRef,
                                                  currentlySaved: saved,
                                                ),
                                              );
                                            },
                                          );
                                        }),
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
                                      ]),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      InkWell(
                                        onTap: () => _onRateTapped(
                                          listingRef: listingRef,
                                          providerRef: ownerRef,
                                          name: name,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: StreamBuilder<
                                            QuerySnapshot<
                                                Map<String, dynamic>>>(
                                          stream: listingRef
                                              .collection('reviews')
                                              .snapshots(),
                                          builder: (context, rvSnap) {
                                            final rvDocs =
                                                rvSnap.data?.docs ?? const [];
                                            final int liveCount =
                                                rvDocs.isNotEmpty
                                                    ? rvDocs.length
                                                    : reviews;
                                            double liveAvg = rating;
                                            if (rvDocs.isNotEmpty) {
                                              double sum = 0;
                                              for (final r in rvDocs) {
                                                final v = r.data()['rating'];
                                                if (v is num) {
                                                  sum += v.toDouble();
                                                }
                                              }
                                              liveAvg = sum / rvDocs.length;
                                            }
                                            final bool liveHas = liveCount > 0;
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded,
                                                    size: 16, color: _lime),
                                                const SizedBox(width: 4),
                                                Text(
                                                    liveHas
                                                        ? liveAvg
                                                            .toStringAsFixed(1)
                                                        : 'Rate this trade',
                                                    style: const TextStyle(
                                                        fontFamily: _bodyFont,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _paper)),
                                                if (liveHas) ...[
                                                  const SizedBox(width: 5),
                                                  Text('($liveCount)',
                                                      style: TextStyle(
                                                          fontFamily: _bodyFont,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: _paper
                                                              .withOpacity(
                                                                  0.55))),
                                                ],
                                                const SizedBox(width: 5),
                                                Icon(Icons.edit_outlined,
                                                    size: 13,
                                                    color: _paper
                                                        .withOpacity(0.6)),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 11, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: _paper.withOpacity(0.14),
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                    color: openNow
                                                        ? _lime
                                                        : _paper
                                                            .withOpacity(0.5),
                                                    shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                  openNow
                                                      ? 'Open now'
                                                      : 'Closed',
                                                  style: const TextStyle(
                                                      fontFamily: _bodyFont,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _paper)),
                                            ]),
                                      ),
                                      if (isVerified)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 11, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: _paper.withOpacity(0.14),
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.verified_rounded,
                                                    size: 14, color: _paper),
                                                SizedBox(width: 5),
                                                Text('Verified',
                                                    style: TextStyle(
                                                        fontFamily: _bodyFont,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: _paper)),
                                              ]),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(name,
                                      style: const TextStyle(
                                          fontFamily: _displayFont,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.6,
                                          height: 1.05,
                                          color: _paper)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(Icons.handyman_outlined,
                                        size: 16,
                                        color: _paper.withOpacity(0.7)),
                                    const SizedBox(width: 8),
                                    if (speciality.isNotEmpty)
                                      Flexible(
                                        child: Text(speciality,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: _paper)),
                                      ),
                                    if (speciality.isNotEmpty &&
                                        category.isNotEmpty &&
                                        category != speciality) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                          width: 3,
                                          height: 3,
                                          decoration: BoxDecoration(
                                              color: _paper.withOpacity(0.45),
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(category,
                                          style: TextStyle(
                                              fontFamily: _bodyFont,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _paper.withOpacity(0.55))),
                                    ],
                                  ]),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 16,
                                        color: _paper.withOpacity(0.55)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(displayArea,
                                          style: TextStyle(
                                              fontFamily: _bodyFont,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _paper.withOpacity(0.55))),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // ── White body (flush) ──
                        Container(
                          color: _paper,
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 22, _hPad, bottomScrollPad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _uLabel('CONTACT'),
                              const SizedBox(height: 10),
                              // ── Calling card (Quote-Request style) ──
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: _surface,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: _paper,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(_initials(providerDisplay),
                                        style: const TextStyle(
                                            fontFamily: _displayFont,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: _ink)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('SERVICE PROVIDER',
                                            style: TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                                color: _faint)),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          Flexible(
                                            child: Text(providerDisplay,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontFamily: _bodyFont,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: _ink)),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 5),
                                            const Icon(Icons.verified_rounded,
                                                size: 14, color: _ink),
                                          ],
                                        ]),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          const Icon(Icons.call_rounded,
                                              size: 13, color: _faint),
                                          const SizedBox(width: 5),
                                          Text(phoneForCard,
                                              style: const TextStyle(
                                                  fontFamily: _bodyFont,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _inkMute)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _round(Icons.call_rounded, _paper, _ink,
                                      () => _launchPhone(listingPhone)),
                                  const SizedBox(width: 8),
                                  _round(
                                      Icons.chat_rounded,
                                      _whatsapp,
                                      _paper,
                                      () => _launchWhatsApp(
                                          listingWhatsapp.isNotEmpty
                                              ? listingWhatsapp
                                              : listingPhone)),
                                ]),
                              ),
                              if (listingEmail.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () => _launchEmail(listingEmail),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                        color: _paper,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _hairline)),
                                    child: Row(children: [
                                      const Icon(Icons.mail_outlined,
                                          size: 19, color: _slate),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(listingEmail,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _ink)),
                                      ),
                                      const Icon(Icons.chevron_right_rounded,
                                          color: Color(0xFFC6D0D5)),
                                    ]),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              // ── Tabs (pills) ──
                              _DetailTabs(
                                aboutText: aboutText,
                                services: safeServices,
                                galleryPhotos: galleryPhotos,
                                area: displayArea,
                                hours: openingHours,
                                associations: associations,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── CTA bar ──
                // NOTE: no fixed height — the bar sizes to its content plus
                // the bottom safe-area inset, so the buttons keep their full
                // 52px height on devices with a home-indicator inset (a fixed
                // height minus a large inset was squashing them).
                Container(
                  padding: EdgeInsets.fromLTRB(_hPad, 14, _hPad,
                      14 + MediaQuery.of(context).padding.bottom),
                  decoration: const BoxDecoration(
                    color: _paper,
                    border: Border(top: BorderSide(color: _hairline)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showAddToProjectSheet(
                          listingRef: listingRef,
                          title: plTitle,
                          subTitle: plSubTitle,
                          ratingText: plRatingText,
                          photoUrl: heroPhotoUrl,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                              color: _lime,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.playlist_add_rounded,
                                  size: 18, color: _ink),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text('Add to Project',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: _bodyFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _ink)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _uLabel(String text) => Text(text,
      style: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: _inkMute));

  Widget _round(IconData icon, Color bg, Color fg, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: fg),
          ),
        ),
      );
}

// ── Tab strip + bodies (pills) ──
class _DetailTabs extends StatefulWidget {
  const _DetailTabs({
    required this.aboutText,
    required this.services,
    required this.galleryPhotos,
    required this.area,
    required this.hours,
    required this.associations,
  });

  final String aboutText;
  final List<String> services;
  final List<String> galleryPhotos;
  final String area;
  final String hours;
  final List<String> associations;

  @override
  State<_DetailTabs> createState() => _DetailTabsState();
}

class _DetailTabsState extends State<_DetailTabs> {
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _lime = Color(0xFFE7E247);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _slate = Color(0xFF4E504F);
  static const String _bodyFont = 'Inter';

  static const List<String> _tabs = [
    'About',
    'Services',
    'Gallery',
    'Location',
    'Associations',
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final on = i == _index;
              return Padding(
                padding: EdgeInsets.only(right: i == _tabs.length - 1 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: on ? _lime : _surface,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(_tabs[i],
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 12,
                            fontWeight: on ? FontWeight.w800 : FontWeight.w700,
                            color: on ? _ink : _inkMute)),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        _body(),
      ],
    );
  }

  Widget _pill(String s, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _ink),
            const SizedBox(width: 6),
          ],
          Text(s,
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _inkMute)),
        ]),
      );

  Widget _body() {
    switch (_index) {
      case 1:
        return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in widget.services) _pill(s)]);
      case 2:
        return widget.galleryPhotos.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('No photos yet',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _faint))),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.galleryPhotos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(widget.galleryPhotos[i],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, st) => Container(
                          color: _surface,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: _faint))),
                ),
              );
      case 3:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _hairline)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 18, color: _slate),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.area,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 18, color: _slate),
              const SizedBox(width: 8),
              Text(widget.hours,
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
            ]),
          ]),
        );
      case 4:
        return widget.associations.isEmpty
            ? const Text('No associations listed yet.',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _inkMute,
                    height: 1.6))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in widget.associations)
                    _pill(a, icon: Icons.verified_outlined)
                ],
              );
      case 0:
      default:
        return Text(widget.aboutText,
            style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _inkMute,
                height: 1.6));
    }
  }
}
