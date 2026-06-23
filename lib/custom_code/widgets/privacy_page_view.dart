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

  // ── Content helpers (locked palette) ───────────────────────────────
  TextStyle _h2Style() => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.2,
        color: _ink,
      );

  TextStyle _pStyle() => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.55,
        color: _inkMute,
      );

  Widget _h2(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: _h2Style()),
      );

  Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: _pStyle()),
      );

  Widget _b(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 10),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: Text(text, style: _pStyle())),
          ],
        ),
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
                    _p('This Privacy Policy explains how Subby ("we", "us") collects, uses and protects your personal information when you use the Subby app. We process personal information in line with the Protection of Personal Information Act, 2013 (POPIA). For the purposes of POPIA, Subby is the Responsible Party for the information described here.'),
                    _h2('1. Information we collect'),
                    _b('Account information: your email address and, where you provide it, your name and phone number, managed through our authentication provider.'),
                    _b('Project content: information you add to your projects, such as project details, to-do and snag lists, budgets, quotes and the photos you upload.'),
                    _b('Listing information: if you create or claim a provider listing, the business details, contact information and photos you provide.'),
                    _b('Usage and device information: basic technical information needed to run the app, such as device type and app activity, including data generated when the app crashes or errors.'),
                    _b('Support information: messages you send us when you ask for help.'),
                    _h2('2. How we use your information'),
                    _p('We use your personal information to create and manage your account; provide the project tools and directory features; display your listings and let users contact providers; respond to support requests; keep the app secure and prevent abuse; improve and maintain the service; and comply with our legal obligations. We process your information on the basis of your consent, the performance of our agreement with you, our legitimate interests in operating the service, and compliance with the law.'),
                    _h2('3. When you contact a provider'),
                    _p('When you use the Call, WhatsApp or Email buttons to contact a provider, the app opens your own phone, messaging or email app. Your communication then takes place directly between you and the provider through those services, under their own terms and privacy practices.'),
                    _h2('4. Sharing your information'),
                    _p('We do not sell your personal information. We share it only where needed:'),
                    _b('With service providers who host and run the app on our behalf, including Google Firebase, which provides our authentication, database and storage.'),
                    _b('With other users, where you choose to make information public — for example a provider listing.'),
                    _b('Where required by law, or to protect rights, safety or the security of the service.'),
                    _h2('5. Where your information is stored'),
                    _p('Subby runs on Google Firebase. Your information may be stored and processed on servers operated by Google, which may be located outside South Africa. Where personal information is transferred across borders, we take steps consistent with POPIA to ensure it receives an adequate level of protection.'),
                    _h2('6. Security'),
                    _p('We use reasonable technical and organisational measures, including access controls and platform security features, to protect your personal information. No system is completely secure, so we cannot guarantee absolute security, but we work to protect your data and to respond appropriately to any incident.'),
                    _h2('7. How long we keep your information'),
                    _p('We keep your personal information for as long as your account is active and as needed to provide the service, and thereafter only for as long as required for legal, accounting or legitimate business purposes. When information is no longer needed, we delete or de-identify it.'),
                    _h2('8. Your rights under POPIA'),
                    _p('You have the right to ask what personal information we hold about you; ask us to correct or update it; ask us to delete it, subject to legal limits; object to certain processing; and withdraw consent where we rely on it. You can exercise these rights, or delete your account, from within the app or by contacting us. You also have the right to lodge a complaint with the Information Regulator.'),
                    _h2('9. Children'),
                    _p('Subby is intended for adults. We do not knowingly collect personal information from children under 18. If you believe a child has provided us with personal information, please contact us so we can remove it.'),
                    _h2('10. Changes to this Policy'),
                    _p('We may update this Privacy Policy from time to time. We will update the date shown at the top of this page and, where appropriate, notify you in the app.'),
                    _h2('11. Contact us'),
                    _p('For privacy questions or to exercise your rights, contact us at privacy@subby.co.za.'),
                    _p('You may also contact the Information Regulator (South Africa):'),
                    _b('Website: inforegulator.org.za'),
                    _b('Complaints: POPIAComplaints@inforegulator.org.za'),
                    _b('Enquiries: enquiries@inforegulator.org.za'),
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
