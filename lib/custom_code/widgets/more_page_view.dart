// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
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

  // ✅ Route names (adjust if your FF route names differ)
  static const String _termsRouteName = 'termsPage';
  static const String _privacyRouteName = 'privacyPage';

  static const String _homeRouteName = 'homePage';
  static const String _exploreRouteName = 'explorePage';
  static const String _savedRouteName = 'savedPage';
  static const String _profileRouteName = 'profilePage';

  // =========================================================
  // ✅ TYPOGRAPHY (THEME TOKENS ONLY)
  // =========================================================

  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900, // 🔥 Extra bold
      letterSpacing: 0.2,
    );
  }

  TextStyle _pageSubtitle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  TextStyle _headerTitleOnPrimary(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: t.titleLargeFamily,
        color: Colors.white,
      );

  TextStyle _sectionTitleStyle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
      );

  TextStyle _tileTitle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  TextStyle _tileSubtitle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
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
          color: theme.primaryBackground,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: theme.alternate, width: 1),
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
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.alternate, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: theme.primary),
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
            Icon(
              Icons.chevron_right_rounded,
              color: theme.secondaryText,
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
        color: theme.primaryBackground,
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
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: theme.primaryBackground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ FIX (was _pageTitle)
                      Text('Subby', style: _appTitleStyle(theme)),
                      const SizedBox(height: 2),
                      Text('More', style: _pageSubtitle(theme)),
                    ],
                  ),
                ],
              ),
            ),

            // Primary header band
            Container(
              width: double.infinity,
              color: theme.primary,
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
                                content: Text(
                                  'Add a support page later.',
                                  style: theme.bodyMedium.override(
                                    fontFamily: theme.bodyMediumFamily,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: theme.primary,
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
