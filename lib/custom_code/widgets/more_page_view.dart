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
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with DashboardPageView / AddProjectsPageView.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374); // text, chrome
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  // Status
  static const Color _live = Color(0xFFE5771E); // orange — live / warning
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;

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
  TextStyle _pageTitle(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: _displayFont,
        color: _ink,
        fontWeight: FontWeight.w900,
        fontSize: 30,
        lineHeight: 1.05,
        letterSpacing: -0.5,
      );

  TextStyle _pageSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  // Uppercase micro-label section heads (matches AddProjectsPageView).
  TextStyle _sectionLabel(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      );

  TextStyle _rowTitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: _ink,
      );

  TextStyle _rowSubtitle(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  // =========================================================
  // ✅ ROW LOOK — minimal underline rule (matches AddProjects fields
  //    + Dashboard condensed rows). Bare teal icon, no surface chip.
  // =========================================================
  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: _hairlineOnSurface, width: 1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: _teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _rowTitle(theme)),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(subtitle, style: _rowSubtitle(theme)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _faint, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // Close the slide-over panel (matches the swipe-to-dismiss gesture).
  Widget _closeButton() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _hairline),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.close_rounded, size: 18, color: _inkMute),
          ),
        ),
      );

  Widget _sectionLabelRow(String text) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text.toUpperCase(), style: _sectionLabel(theme)),
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
      // ✅ FIX: wrap in Material so every Text has a Material ancestor.
      // Without this, the title / subtitle / section labels (which aren't
      // inside an InkWell+Material like the rows are) render with the
      // yellow debug double-underline when this view is shown without a
      // Scaffold/Material parent (e.g. as a slide-over panel).
      child: Material(
        color: _paper,
        child: Container(
          color: _paper,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: teal mark + close
              Padding(
                padding: EdgeInsets.fromLTRB(_hPad, topInset + _vPad, _hPad, 0),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 22,
                        color: _paper,
                      ),
                    ),
                    const Spacer(),
                    _closeButton(),
                  ],
                ),
              ),

              // Big title + subtitle (no section band)
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 20, _hPad, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('More', style: _pageTitle(theme)),
                    const SizedBox(height: 8),
                    Text(
                      'Jump anywhere, or read the legal bits.',
                      style: _pageSubtitle(theme),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(_hPad, 18, _hPad, bottomInset + 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabelRow('Quick access'),
                      _row(
                        icon: Icons.home_outlined,
                        title: 'Home',
                        subtitle: 'Browse categories & locations',
                        onTap: () => context.goNamed(_homeRouteName),
                      ),
                      _row(
                        icon: Icons.search_outlined,
                        title: 'Explore',
                        subtitle: 'Search and filter listings',
                        onTap: () => context.goNamed(_exploreRouteName),
                      ),
                      _row(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Saved',
                        subtitle: 'Your bookmarked listings',
                        onTap: () => context.goNamed(_savedRouteName),
                      ),
                      _row(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        subtitle: 'Your account details',
                        onTap: () => context.goNamed(_profileRouteName),
                      ),
                      const SizedBox(height: 26),
                      _sectionLabelRow('Legal'),
                      _row(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => context.pushNamed(_termsRouteName),
                      ),
                      _row(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => context.pushNamed(_privacyRouteName),
                      ),
                      const SizedBox(height: 26),
                      _sectionLabelRow('Support'),
                      _row(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
