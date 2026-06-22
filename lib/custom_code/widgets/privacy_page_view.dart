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

import 'package:intl/intl.dart';

class PrivacyPageView extends StatefulWidget {
  const PrivacyPageView({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<PrivacyPageView> createState() => _PrivacyPageViewState();
}

class _PrivacyPageViewState extends State<PrivacyPageView> {
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
  static const Color _coral = Color(0xFFE5771E);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;

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

  TextStyle _body(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: _ink,
      );

  TextStyle _hint(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: _inkMute,
      );

  // Minimal circular back button (matches AddProjectsPageView).
  Widget _backButton() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.safePop(),
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _hairline),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: _inkMute,
            ),
          ),
        ),
      );

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
            // Back button
            Padding(
              padding: EdgeInsets.fromLTRB(_hPad, topInset + _vPad, _hPad, 0),
              child: Row(
                children: [
                  _backButton(),
                  const Spacer(),
                ],
              ),
            ),

            // Big title + subtitle (no section band)
            Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, 20, _hPad, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy Policy', style: _pageTitle(theme)),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                    style: _pageSubtitle(theme),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(_hPad, 20, _hPad, bottomInset + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: _hairlineOnSurface,
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                    Text(
                      'Add your Privacy Policy text here.',
                      style: _body(theme),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Include what data you collect (if any), how it is used, and who it is shared with.',
                      style: _hint(theme),
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
}
