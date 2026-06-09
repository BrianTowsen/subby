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

// ✅ Share support (Clipboard copy)
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

  /// Document reference for the selected listing (from ListingResultsPage)
  final DocumentReference? listingRef;

  @override
  State<ListingDetailPageView> createState() => _ListingDetailPageViewState();
}

class _ListingDetailPageViewState extends State<ListingDetailPageView> {
  static const double _hPad = 24;

  // Bottom fixed CTA
  static const double _bottomCtaContainerHeight = 86;

  // users/<uid>.savedListingRefs : List<DocRef(subby_listings)>
  static const String _kSavedField = 'savedListingRefs';

  // ---- Mock fallback data (will be overridden by Firestore if present) ----
  final String _fallbackName = 'Precision Electrical';
  final String _fallbackTrade = 'Electrician';
  final String _fallbackArea = 'Sandton, Gauteng';

  // Service Provider fallbacks (used ONLY if providerRef exists but profile fields are missing)
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

  // Prevent “infinite spinner” if the first snapshot never arrives
  static const Duration _maxInitialLoad = Duration(seconds: 8);
  bool _showSlowLoadFallback = false;

  // ===========================
  // ✅ ADD TO PROJECT (WIRED)
  // ===========================
  DocumentReference? _selectedProjectRef; // persisted selection
  String? _selectedProjectName;

  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Trust cluster note: on this screen yellow (_spark) is reserved for the
  // primary CTAs only (bottom "Add to Project" + sheet "Add"); the OPEN-now
  // state uses gold (_live); verified + rating are neutral ink. So yellow and
  // gold never sit adjacent here — the collision risk is resolved by hierarchy.
  //
  // Neutrals
  static const Color _ink = Color(0xFF2B3443);
  static const Color _inkSoft = Color(0xFF2B3443);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _surface2 = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFF1BC16); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF2B3443);
  static const Color _calm = Color(0xFFB8910F);
  static const Color _calmInk = Color(0xFFFFFFFF);
  // Status
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / warning
  static const Color _liveInk =
      Color(0xFF7A5300); // gold-on-tint text (legible)
  static const Color _steel = Color(0xFF9EA3B0);
  static const Color _coral = Color(0xFFC8102E); // legacy red — closed/error
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

  // =========================================================
  // ✅ TYPOGRAPHY (locked palette — explicit family + colour)
  //    Signatures keep (FlutterFlowTheme t) so call sites are unchanged.
  // =========================================================
  TextStyle _titleMedium(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle _titleSmall(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _bodyMedium(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _ink,
      );

  TextStyle _bodySmall(FlutterFlowTheme t, {Color? color}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        color: color ?? _inkMute,
      );

  TextStyle _labelLarge(FlutterFlowTheme t, {Color? color}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? _ink,
      );

  TextStyle _labelMedium(FlutterFlowTheme t, {Color? color}) => TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? _ink,
      );

  TextStyle get _ratingNumStyle => const TextStyle(
        fontFamily: _monoFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _ink,
        fontFeatures: [FontFeature.tabularFigures()],
      );
  // =========================================================

  @override
  void initState() {
    super.initState();
    Future.delayed(_maxInitialLoad, () {
      if (!mounted) return;
      setState(() => _showSlowLoadFallback = true);
    });
  }

  // =========================================================
  // ✅ Subby card/tile styling (MATCH HomePageView tiles)
  // =========================================================
  static const double _cardRadius = _rLarge;

  // Swiss/less-is-more: hairlines, not shadows.
  List<BoxShadow> _subbyTileShadow() => const <BoxShadow>[];

  // ✅ IMPORTANT: HomePageView tiles use primaryBackground + alternate border + subtle shadow
  BoxDecoration _subbyCardDecoration(
    FlutterFlowTheme theme, {
    Color? color,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color ?? _paper,
      borderRadius: BorderRadius.circular(_cardRadius),
      border: Border.all(color: _hairline, width: 1),
      boxShadow: shadow ? _subbyTileShadow() : const [],
    );
  }

  // ===========================
  // BOOKMARK (SAVE LISTING)
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
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rMed),
            side: BorderSide(color: _hairline, width: 1),
          ),
          duration: const Duration(milliseconds: 1400),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _ink.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  wasSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 16,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  wasSaved ? 'Saved to bookmarks' : 'Removed from bookmarks',
                  style: _bodySmall(theme, color: _ink),
                ),
              ),
            ],
          ),
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

      _showBookmarkSnack(wasSaved: !currentlySaved);
    } catch (e) {
      debugPrint('⚠️ toggle bookmark failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update bookmark.')),
      );
    }
  }

  // ===========================
  // SHARE LISTING (Clipboard)
  // ===========================
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

    final text = parts.join('\n');

    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;

      final theme = FlutterFlowTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rMed),
            side: BorderSide(color: _hairline, width: 1),
          ),
          content: Text(
            'Listing details copied. You can now paste and share.',
            style: _bodySmall(theme, color: _ink),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share right now.')),
      );
    }
  }

  // ===========================
  // ✅ CONTACT (Subby style + only shows if fields exist)
  // ===========================
  Future<void> _copyToClipboard(String label, String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      final theme = FlutterFlowTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rMed),
            side: BorderSide(color: _hairline, width: 1),
          ),
          content: Text(
            '$label copied',
            style: _bodySmall(theme, color: _ink),
          ),
          duration: const Duration(milliseconds: 1100),
        ),
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------
  // Launch contact actions (dialer / WhatsApp / email)
  // ---------------------------------------------------------
  Future<void> _launchUri(Uri uri, {required String failMessage}) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failMessage)));
      }
    } catch (e) {
      debugPrint('\u26a0\ufe0f launch failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failMessage)));
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
    // wa.me needs international digits, no '+' or spaces.
    var n = _digitsPlus(number).replaceAll('+', '');
    if (n.isEmpty) return;
    // ZA local format (0xx...) -> 27xx...
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

  Widget _contactButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // ✅ Match Home tile style: primaryBackground + alternate border
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_rMed),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(_rMed),
            border: Border.all(color: _hairline, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _ink),
              const SizedBox(width: 8),
              Text(label, style: _labelMedium(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String phone,
    required String whatsapp,
    required String email,
  }) {
    final theme = FlutterFlowTheme.of(context);

    final p = phone.trim();
    final w = whatsapp.trim();
    final e = email.trim();

    final hasAny = p.isNotEmpty || w.isNotEmpty || e.isNotEmpty;
    if (!hasAny) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _subbyCardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(_rMed),
                  border: Border.all(color: _hairline, width: 1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.call_rounded, size: 18, color: _ink),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Contact', style: _titleSmall(theme))),
              InkWell(
                onTap: () {
                  final first = (p.isNotEmpty)
                      ? ('Phone', p)
                      : (w.isNotEmpty)
                          ? ('WhatsApp', w)
                          : ('Email', e);
                  _copyToClipboard(first.$1, first.$2);
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _hairline, width: 1),
                  ),
                  child: Text(
                    'Copy',
                    style: _labelMedium(theme, color: _ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (p.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: _inkMute),
                const SizedBox(width: 8),
                Expanded(child: Text(p, style: _bodySmall(theme))),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (w.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 16, color: _inkMute),
                const SizedBox(width: 8),
                Expanded(child: Text(w, style: _bodySmall(theme))),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (e.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: _inkMute),
                const SizedBox(width: 8),
                Expanded(child: Text(e, style: _bodySmall(theme))),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (p.isNotEmpty)
                _contactButton(
                  theme: theme,
                  icon: Icons.call_rounded,
                  label: 'Call',
                  onTap: () => _launchPhone(p),
                ),
              if (p.isNotEmpty && (w.isNotEmpty || e.isNotEmpty))
                const SizedBox(width: 10),
              if (w.isNotEmpty)
                _contactButton(
                  theme: theme,
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  onTap: () => _launchWhatsApp(w),
                ),
              if (w.isNotEmpty && e.isNotEmpty) const SizedBox(width: 10),
              if (e.isNotEmpty)
                _contactButton(
                  theme: theme,
                  icon: Icons.email_rounded,
                  label: 'Email',
                  onTap: () => _launchEmail(e),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================
  // ✅ ADD TO PROJECT (FIRESTORE WIRED) ✅ NO INDEX REQUIRED
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

  bool _projectIsArchived(Map<String, dynamic> data) {
    final v = data['archived'];
    return v == true;
  }

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
    final theme = FlutterFlowTheme.of(context);

    try {
      final dup = await FirebaseFirestore.instance
          .collection('project_listings')
          .where('projectRef', isEqualTo: projectRef)
          .where('listingRef', isEqualTo: listingRef)
          .limit(1)
          .get();

      if (dup.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_rMed),
              side: BorderSide(color: _hairline, width: 1),
            ),
            content: Text(
              'Already added to this project.',
              style: _bodySmall(theme, color: _ink),
            ),
            duration: const Duration(milliseconds: 1300),
          ),
        );
        return;
      }

      // ✅ FIX: write BOTH subtitle keys so ProjectDetailPageView always shows it
      await FirebaseFirestore.instance.collection('project_listings').add({
        'projectRef': projectRef,
        'listingRef': listingRef,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': addedBy,
        'title': title,

        // ✅ Main key that ProjectDetailPageView reads:
        'subtitle': subTitle,

        // ✅ Back-compat if anything else reads this:
        'subTitle': subTitle,

        'ratingText': ratingText,
        'photoUrl': photoUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rMed),
            side: BorderSide(color: _hairline, width: 1),
          ),
          content: Text(
            'Added to project.',
            style: _bodySmall(theme, color: _ink),
          ),
          duration: const Duration(milliseconds: 1300),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ addListingToProject failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add to project.')),
      );
    }
  }

  Future<void> _showAddToProjectSheet({
    required DocumentReference listingRef,
    required String title,
    required String subTitle,
    required String ratingText,
    required String photoUrl,
  }) async {
    final theme = FlutterFlowTheme.of(context);

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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: _paper,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(_rLarge)),
              border: Border.all(color: _hairline, width: 1),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 18),
                child: StatefulBuilder(
                  builder: (context, setLocal) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _hairline,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(_rMed),
                                border: Border.all(color: _hairline, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.playlist_add_rounded,
                                size: 18,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Add to Project',
                                  style: _titleSmall(theme)),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _paper,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: _hairline, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.close_rounded,
                                    size: 18, color: _ink),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose which project to add this listing to.',
                          style: _bodySmall(theme),
                        ),
                        const SizedBox(height: 14),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _projectsQuery(userRef).snapshots(),
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration:
                                    _subbyCardDecoration(theme, shadow: false),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(_ink),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Loading projects…',
                                        style: _bodySmall(theme)),
                                  ],
                                ),
                              );
                            }

                            if (snap.hasError) {
                              final err = snap.error;
                              debugPrint('❌ projectsQuery error: $err');

                              String hint = 'Please try again.';
                              final msg = err.toString().toLowerCase();
                              if (msg.contains('permission-denied')) {
                                hint =
                                    'Permission denied (check Firestore rules).';
                              } else if (msg.contains('failed-precondition')) {
                                hint = 'Missing index / query not supported.';
                              } else if (msg.contains('requires an index')) {
                                hint = 'This query requires a Firestore index.';
                              }

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration:
                                    _subbyCardDecoration(theme, shadow: false),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        size: 18, color: _ink),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Could not load projects.',
                                              style: _bodySmall(theme)),
                                          const SizedBox(height: 4),
                                          Text(hint, style: _bodySmall(theme)),
                                        ],
                                      ),
                                    ),
                                  ],
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
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration:
                                    _subbyCardDecoration(theme, shadow: false),
                                child: Row(
                                  children: [
                                    Icon(Icons.folder_off_outlined,
                                        size: 18, color: _inkMute),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text('No projects yet.',
                                          style: _bodySmall(theme)),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    (MediaQuery.of(context).size.height * 0.45)
                                        .clamp(260.0, 420.0),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final d = docs[i];
                                  final data = d.data();
                                  final pName = _projectNameFrom(data);
                                  final pRef = d.reference;

                                  final bool selected =
                                      (selectedRef?.path == pRef.path);

                                  return InkWell(
                                    onTap: () {
                                      selectedRef = pRef;
                                      selectedName = pName;
                                      setLocal(() {});
                                    },
                                    borderRadius:
                                        BorderRadius.circular(_rLarge),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _paper,
                                        borderRadius:
                                            BorderRadius.circular(_rLarge),
                                        border: Border.all(
                                          color: selected ? _ink : _hairline,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: _surface,
                                              borderRadius:
                                                  BorderRadius.circular(_rMed),
                                              border: Border.all(
                                                  color: _hairline, width: 1),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              selected
                                                  ? Icons.check_circle_rounded
                                                  : Icons.folder_open_rounded,
                                              size: 18,
                                              color: selected ? _ink : _inkMute,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              pName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: _bodyMedium(theme),
                                            ),
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: _hairline, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: _paper,
                                  elevation: 0,
                                ),
                                child: Text('Cancel',
                                    style: _labelLarge(theme, color: _ink)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (selectedRef == null)
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _spark,
                                  foregroundColor: _sparkInk,
                                  disabledBackgroundColor: _surface,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(_rMed),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text('Add',
                                    style:
                                        _labelLarge(theme, color: _sparkInk)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _circleTopButton({
    required FlutterFlowTheme theme,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          shape: BoxShape.circle,
          border: Border.all(color: _hairline, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: iconColor ?? _inkMute),
      ),
    );
  }

  Widget _pill({
    required FlutterFlowTheme theme,
    required Widget child,
    Color? borderColor,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor ?? _paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? _hairline, width: 1),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

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
              Icon(Icons.error_outline, color: _coral, size: 40),
              const SizedBox(height: 12),
              Text('Listing not found.', style: _bodyMedium(theme)),
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
                        Icon(Icons.wifi_off_rounded, color: _inkMute, size: 38),
                        const SizedBox(height: 10),
                        Text('Still loading…',
                            style:
                                _bodyMedium(theme).copyWith(color: _inkMute)),
                        const SizedBox(height: 10),
                        Text(
                          'Check your connection or Firestore rules.',
                          style: _bodySmall(theme),
                        ),
                      ],
                    )
                  : CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_ink),
                      strokeWidth: 2,
                    ),
            );
          }

          final raw = (snap.data!.data() as Map<String, dynamic>?) ??
              <String, dynamic>{};

          String _readString(String k) => (raw[k] ?? '').toString().trim();
          int? _readInt(String k) => raw[k] is int ? raw[k] as int : null;

          List<String> _readStringList(String k) {
            final v = raw[k];
            if (v is List) {
              return v
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            return <String>[];
          }

          DocumentReference? _readDocRef(String k) {
            final v = raw[k];
            if (v is DocumentReference) return v;
            return null;
          }

          final String name = _readString('name').isNotEmpty
              ? _readString('name')
              : _fallbackName;

          final String category = _readString('category').isNotEmpty
              ? _readString('category')
              : _fallbackTrade;

          final String categorySlug = _readString('categorySlug').isNotEmpty
              ? _readString('categorySlug')
              : functions.slugify(category);

          final String province = _readString('province');
          final String city = _readString('city');

          final String provinceSlug = _readString('provinceSlug').isNotEmpty
              ? _readString('provinceSlug')
              : functions.slugify(province);

          final String area = [
            if (city.isNotEmpty) city,
            if (province.isNotEmpty) province,
          ].join(', ');

          final String displayArea = area.isNotEmpty ? area : _fallbackArea;

          final double rating =
              (raw['rating'] is num) ? (raw['rating'] as num).toDouble() : 0.0;

          final int reviews =
              _readInt('reviewCount') ?? _readInt('reviews') ?? 0;
          final bool hasReviews = reviews > 0;

          final List<String> associations = _readStringList('associations');

          final String aboutText = _readString('about').isNotEmpty
              ? _readString('about')
              : _aboutText;

          final List<String> servicesFromDb = _readStringList('services');
          final List<String> safeServices =
              servicesFromDb.isNotEmpty ? servicesFromDb : _services;

          final String openingHours = _readString('openingHours').isNotEmpty
              ? _readString('openingHours')
              : '07:00 – 18:00';

          final bool openNow =
              (raw['openNow'] == true) || (raw['isOpen'] == true);

          final String listingPhone = _readString('phoneNumber');
          final String listingWhatsapp = _readString('whatsappNumber');
          final String listingEmail = _readString('email');

          final DocumentReference? providerRef = _readDocRef('providerRef');

          final bool isVerified = raw['isVerified'] == true;

          final List<String> listingPhotos = _readStringList('photoUrls');

          final String heroPhotoUrl = _readString('heroPhotoUrl').isNotEmpty
              ? _readString('heroPhotoUrl')
              : (listingPhotos.isNotEmpty ? listingPhotos.first : '');

          final List<String> galleryPhotos = listingPhotos.isNotEmpty
              ? listingPhotos
              : (heroPhotoUrl.isNotEmpty
                  ? <String>[heroPhotoUrl]
                  : const <String>[]);

          final String ownerName = _readString('ownerName');
          final String ownerPhotoUrl = _readString('ownerPhotoUrl');

          final double bottomScrollPad = _bottomCtaContainerHeight + 18;
          final Color tabAccent = _ink;

          final double bannerHeight =
              (MediaQuery.sizeOf(context).height * 0.36).clamp(260.0, 360.0);

          final listingRef = widget.listingRef!;

          // ✅ Denormalized fields for project_listings
          final String plTitle = name;
          final String plSubTitle = [
            category,
            if (displayArea.isNotEmpty) displayArea
          ].where((s) => s.trim().isNotEmpty).join(' • ');
          final String plRatingText = hasReviews
              ? '${rating.toStringAsFixed(1)} • $reviews reviews'
              : 'No reviews yet';
          final String plPhotoUrl = heroPhotoUrl;

          return DefaultTabController(
            length: 5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: bannerHeight,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.zero,
                                  child: Image.network(
                                    heroPhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, st) => Container(
                                      color: _surface,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: _inkMute,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: topInset + 10,
                                  left: 14,
                                  child: _circleTopButton(
                                    theme: theme,
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: () => context.safePop(),
                                    iconColor: _inkMute,
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
                                              theme: theme,
                                              icon:
                                                  Icons.bookmark_border_rounded,
                                              onTap: () => context
                                                  .pushNamed('loginPage'),
                                              iconColor: _inkMute,
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
                                                theme: theme,
                                                icon: saved
                                                    ? Icons.bookmark_rounded
                                                    : Icons
                                                        .bookmark_border_rounded,
                                                iconColor:
                                                    saved ? _ink : _inkMute,
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
                                        theme: theme,
                                        icon: Icons.share_rounded,
                                        onTap: () => _shareListing(
                                          name: name,
                                          category: category,
                                          area: displayArea,
                                          listingRef: listingRef,
                                        ),
                                        iconColor: _inkMute,
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
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  _hPad, 14, _hPad, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          context.pushNamed(
                                            'listingResultsPage',
                                            queryParameters: {
                                              'category': serializeParam(
                                                category,
                                                ParamType.String,
                                              ),
                                              'categorySlug': serializeParam(
                                                categorySlug,
                                                ParamType.String,
                                              ),
                                              if (provinceSlug.isNotEmpty)
                                                'provinceSlug': serializeParam(
                                                  provinceSlug,
                                                  ParamType.String,
                                                ),
                                              if (province.isNotEmpty)
                                                'province': serializeParam(
                                                  province,
                                                  ParamType.String,
                                                ),
                                              if (city.isNotEmpty)
                                                'city': serializeParam(
                                                  city,
                                                  ParamType.String,
                                                ),
                                            }.withoutNulls,
                                          );
                                        },
                                        borderRadius:
                                            BorderRadius.circular(_rMed),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            category,
                                            style: _bodyMedium(theme).copyWith(
                                              color: _ink,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          if (hasReviews) ...[
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 18,
                                              color: _ink,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: _ratingNumStyle,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '($reviews)',
                                              style: _bodySmall(theme),
                                            ),
                                          ] else ...[
                                            Text(
                                              'No reviews yet',
                                              style: _bodySmall(theme),
                                            ),
                                          ],
                                          const SizedBox(width: 10),
                                          _pill(
                                            theme: theme,
                                            bgColor: openNow
                                                ? _live.withOpacity(0.14)
                                                : _surface,
                                            borderColor: openNow
                                                ? _live.withOpacity(0.30)
                                                : _hairlineOnSurface,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  openNow
                                                      ? Icons
                                                          .check_circle_outline_rounded
                                                      : Icons.cancel_outlined,
                                                  size: 14,
                                                  color: openNow
                                                      ? _live
                                                      : _inkMute,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  openNow ? 'Open' : 'Closed',
                                                  style: _bodySmall(
                                                    theme,
                                                    color: openNow
                                                        ? _liveInk
                                                        : _inkMute,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 10),
                                            _pill(
                                              theme: theme,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.verified_rounded,
                                                      size: 16, color: _ink),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Verified',
                                                    style: _bodySmall(
                                                      theme,
                                                      color: _ink,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: _titleMedium(theme),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 16, color: _inkMute),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          displayArea,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: _bodySmall(theme),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildContactCard(
                                    phone: listingPhone,
                                    whatsapp: listingWhatsapp,
                                    email: listingEmail,
                                  ),
                                  if (ownerName.isNotEmpty ||
                                      ownerPhotoUrl.isNotEmpty) ...[
                                    const SizedBox(height: 18),
                                    Text('Service Provider',
                                        style: _titleSmall(theme)),
                                    const SizedBox(height: 10),
                                    _buildOwnerSection(
                                      name: ownerName,
                                      photoUrl: ownerPhotoUrl,
                                    ),
                                  ] else if (providerRef != null) ...[
                                    const SizedBox(height: 18),
                                    Text('Service Provider',
                                        style: _titleSmall(theme)),
                                    const SizedBox(height: 10),
                                    _buildProviderSection(
                                      providerRef: providerRef,
                                      fallbackName:
                                          '$_fallbackProviderName $_fallbackProviderSurname',
                                      fallbackPhotoUrl: _fallbackProviderPhoto,
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  TabBar(
                                    isScrollable: true,
                                    labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    labelColor: tabAccent,
                                    unselectedLabelColor: _inkMute,
                                    indicatorColor: tabAccent,
                                    indicatorWeight: 2,
                                    labelStyle: _bodySmall(theme, color: _ink),
                                    unselectedLabelStyle: _bodySmall(theme),
                                    tabs: const [
                                      Tab(child: Text('About')),
                                      Tab(child: Text('Services')),
                                      Tab(child: Text('Gallery')),
                                      Tab(child: Text('Location')),
                                      Tab(child: Text('Associations')),
                                    ],
                                  ),
                                ],
                              ),
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: _subbyCardDecoration(theme),
                              child: Text(aboutText, style: _bodySmall(theme)),
                            ),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: safeServices.map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _paper,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _hairline,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: _bodySmall(theme, color: _ink),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: galleryPhotos.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: Center(
                                      child: Text('No photos yet',
                                          style: _bodySmall(theme)),
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
                                    itemBuilder: (context, i) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              _cardRadius),
                                          border: Border.all(
                                              color: _hairline, width: 1),
                                          boxShadow: _subbyTileShadow(),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              _cardRadius),
                                          child: Image.network(
                                            galleryPhotos[i],
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, st) =>
                                                Container(
                                              color: _surface,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: _inkMute,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: _subbyCardDecoration(theme),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined,
                                          size: 18, color: _inkMute),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          displayArea,
                                          style: _bodySmall(theme),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule_rounded,
                                          size: 18, color: _inkMute),
                                      const SizedBox(width: 8),
                                      Text(openingHours,
                                          style: _bodySmall(theme)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.fromLTRB(
                              _hPad, 18, _hPad, bottomScrollPad),
                          children: [
                            if (associations.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: _subbyCardDecoration(theme),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 18, color: _inkMute),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'No associations listed yet.',
                                        style: _bodySmall(theme),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: associations.map((assoc) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _paper,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _hairline,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_outlined,
                                            size: 14, color: _ink),
                                        const SizedBox(width: 6),
                                        Text(
                                          assoc,
                                          style: _bodySmall(theme, color: _ink),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: Container(
                      height: _bottomCtaContainerHeight,
                      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 16),
                      decoration: const BoxDecoration(
                        color: _paper,
                        border: Border(
                          top: BorderSide(color: _hairline, width: 1),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddToProjectSheet(
                            listingRef: listingRef,
                            title: plTitle,
                            subTitle: plSubTitle,
                            ratingText: plRatingText,
                            photoUrl: plPhotoUrl,
                          ),
                          icon: const Icon(
                            Icons.playlist_add_rounded,
                            size: 20,
                            color: _sparkInk,
                          ),
                          label: Text(
                            'Add to Project',
                            style: _labelLarge(theme, color: _sparkInk),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _spark,
                            foregroundColor: _sparkInk,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_rMed),
                            ),
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

  // ===========================
  // PROVIDER SECTION (NO CLAIM / NO "NOT LINKED YET")
  // ===========================
  Widget _buildOwnerSection({
    required String name,
    required String photoUrl,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Listing owner';
    final img = photoUrl.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _subbyCardDecoration(theme),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: img.isNotEmpty
                ? Image.network(
                    img,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, st) => _ownerAvatarFallback(theme),
                  )
                : _ownerAvatarFallback(theme),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _bodyMedium(theme),
                ),
                const SizedBox(height: 2),
                Text('Service provider', style: _bodySmall(theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerAvatarFallback(FlutterFlowTheme theme) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _paper,
        shape: BoxShape.circle,
        border: Border.all(color: _hairline, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.person_outline_rounded, color: _inkMute),
    );
  }

  Widget _buildProviderSection({
    required DocumentReference? providerRef,
    required String fallbackName,
    required String fallbackPhotoUrl,
  }) {
    final theme = FlutterFlowTheme.of(context);

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

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: _subbyCardDecoration(theme),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  img,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, st) => Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: _hairline, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.person_outline_rounded, color: _inkMute),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyMedium(theme),
                    ),
                    const SizedBox(height: 2),
                    Text('Service provider', style: _bodySmall(theme)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
