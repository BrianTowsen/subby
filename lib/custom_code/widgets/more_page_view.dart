// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class MorePageView extends StatefulWidget {
  const MorePageView({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<MorePageView> createState() => _MorePageViewState();
}

class _MorePageViewState extends State<MorePageView> {
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;

  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF14243F);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFE3E4E8);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _hairlineOnSurface = Color(0xFFD0D2D8);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFFFE74C); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF14243F);
  // Status
  static const Color _live =
      Color(0xFFFFB000); // gold — live / open-now / warning
  static const Color _coral = Color(0xFFC8102E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // ✅ Route names (adjust if your FF route names differ)
  static const String _termsRouteName = 'termsPage';
  static const String _privacyRouteName = 'privacyPage';

  static const String _homeRouteName = 'homePage';
  static const String _exploreRouteName = 'explorePage';
  static const String _savedRouteName = 'savedPage';
  static const String _profileRouteName = 'profilePage';

  // =========================================================
  // ✅ TYPOGRAPHY (locked palette — explicit family + colour)
  //    Signatures unchanged so all call sites compile as-is.
  // =========================================================

  TextStyle _appTitleStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.05,
        color: _ink,
      );

  TextStyle _pageSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  // Band is now a neutral contained surface → ink foreground, never white.
  TextStyle _headerTitleOnPrimary(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _tileTitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _tileSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _inkMute,
      );

  // =========================================================
  // ✅ TILE LOOK (MATCH HomePageView Directory tiles)
  // =========================================================
  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline, width: 1),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.03),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _hairlineOnSurface, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: _ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _tileTitle(theme)),
                  if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: _tileSubtitle(theme)),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _inkMute,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: _sectionTitleStyle(theme)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    // ✅ Avoid white SafeArea bands: apply padding manually
    final insets = MediaQuery.of(context).padding;
    final topInset = insets.top;
    final bottomInset = insets.bottom;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar (Home-style)
            Padding(
              padding: EdgeInsets.fromLTRB(_hPad, topInset + _vPad, _hPad, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _ink, // ink chip
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: _paper, // white icon on ink
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subby', style: _appTitleStyle(theme)),
                      const SizedBox(height: 2),
                      Text('More', style: _pageSubtitle(theme)),
                    ],
                  ),
                ],
              ),
            ),

            // Section band — saturated brand fill becomes a neutral contained
            // surface; foreground flips to ink (per SUBBY PALETTE rule).
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(
                  bottom: BorderSide(color: _hairlineOnSurface, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 16),
              child: Text('Menu', style: _headerTitleOnPrimary(theme)),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(_hPad, 16, _hPad, bottomInset + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Quick access'),
                    Column(
                      children: [
                        _tile(
                          icon: Icons.home_outlined,
                          title: 'Home',
                          subtitle: 'Browse categories & locations',
                          onTap: () => context.goNamed(_homeRouteName),
                        ),
                        const SizedBox(height: 12),
                        _tile(
                          icon: Icons.search_outlined,
                          title: 'Explore',
                          subtitle: 'Search and filter listings',
                          onTap: () => context.goNamed(_exploreRouteName),
                        ),
                        const SizedBox(height: 12),
                        _tile(
                          icon: Icons.bookmark_border_rounded,
                          title: 'Saved',
                          subtitle: 'Your bookmarked listings',
                          onTap: () => context.goNamed(_savedRouteName),
                        ),
                        const SizedBox(height: 12),
                        _tile(
                          icon: Icons.person_outline,
                          title: 'Profile',
                          subtitle: 'Your account details',
                          onTap: () => context.goNamed(_profileRouteName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Legal'),
                    Column(
                      children: [
                        _tile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          onTap: () => context.pushNamed(_termsRouteName),
                        ),
                        const SizedBox(height: 12),
                        _tile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () => context.pushNamed(_privacyRouteName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Support'),
                    Column(
                      children: [
                        _tile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'FAQs and contact options',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Add a support page later.',
                                  style: TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _paper,
                                  ),
                                ),
                                backgroundColor: _ink,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
