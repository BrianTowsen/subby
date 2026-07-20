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

import 'package:intl/intl.dart';

class TermsPageView extends StatefulWidget {
  const TermsPageView({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<TermsPageView> createState() => _TermsPageViewState();
}

class _TermsPageViewState extends State<TermsPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with DashboardPageView / AddProjectsPageView.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF1E282E); // text, chrome
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC); // muted labels, chevrons
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF1E282E);
  // Status
  static const Color _live = Color(0xFF4E504F); // orange — live / warning
  static const Color _coral = Color(0xFF4E504F);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 10;

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
                  Text('Terms of Service', style: _pageTitle(theme)),
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
                    _p('These Terms of Use ("Terms") govern your access to and use of the Subby mobile application and related services ("Subby", "we", "us"). By creating an account or using Subby, you agree to these Terms. If you do not agree, please do not use the app.'),
                    _h2('1. About Subby'),
                    _p('Subby is a South African platform with two main features: (a) project tools that help you plan and manage a home building or renovation project — timelines, to-do and snag lists, and budget and quote tracking; and (b) a directory that helps you find and contact contractors, tradespeople and service providers. Subby is a tool and a directory only. We are not a building contractor, estate agent, or professional adviser.'),
                    _h2('2. Eligibility'),
                    _p('You must be at least 18 years old and able to enter into a legally binding agreement under South African law to use Subby. By using the app you confirm that you meet these requirements.'),
                    _h2('3. Your account'),
                    _p('You are responsible for keeping your login details secure and for all activity under your account. Please tell us promptly if you suspect unauthorised use. You agree to provide accurate information and to keep it up to date.'),
                    _h2('4. Acceptable use'),
                    _p('You agree not to use Subby for any unlawful purpose; post false, misleading, defamatory or infringing content; upload content you do not have the right to share; attempt to gain unauthorised access to the app or to other users\' accounts; scrape, copy or harvest listings or data; or interfere with the operation or security of the service. We may remove content and suspend accounts that breach these Terms.'),
                    _h2('5. The directory and service providers'),
                    _p('Listings in the directory are provided by service providers or compiled from available sources. We do not employ, endorse, vet, certify or guarantee any provider, and we are not a party to any agreement you enter into with them.'),
                    _p('You are responsible for satisfying yourself about a provider\'s suitability, qualifications, registrations (for example NHBRC enrolment where applicable), insurance, pricing and references before engaging them. Any contract for building or related work is between you and the provider directly. To the extent permitted by law, Subby is not responsible for the quality, safety, legality or outcome of any work, goods or services arranged through the directory.'),
                    _h2('6. Provider listings'),
                    _p('If you list a business on Subby, you confirm that you are authorised to do so and that the information you provide is accurate and lawful. You grant us a licence to display and promote your listing within the app. We may edit, decline or remove listings at our discretion, including where information appears inaccurate, unlawful, or in breach of these Terms.'),
                    _h2('7. Project tools and estimates'),
                    _p('The project, budget and quote features are planning aids only. Cost figures, timelines and quantities are indicative and may not reflect actual prices or site conditions. They are not professional, financial, engineering or legal advice. You remain responsible for your own decisions and for obtaining appropriate professional advice.'),
                    _h2('8. Your content'),
                    _p('You keep ownership of the content you add to Subby, such as project details, photos and notes. You grant us a licence to host, store, process and display that content for the purpose of operating the service. You are responsible for the content you upload and for having the rights to share it.'),
                    _h2('9. Intellectual property'),
                    _p('Subby — including its name, design, software and the content we provide — is owned by us or our licensors and is protected by law. You may not copy, modify, distribute or create derivative works from it except as allowed by these Terms or applicable law.'),
                    _h2('10. Availability'),
                    _p('We aim to keep Subby available and working, but we provide it "as is" and "as available". We do not guarantee that it will be uninterrupted, error-free, or that data will never be lost. We may change, suspend or discontinue features at any time.'),
                    _h2('11. Limitation of liability'),
                    _p('To the maximum extent permitted by law, Subby and its operators will not be liable for any indirect, incidental or consequential loss, or for loss of profit, data or goodwill, arising from your use of the app or your dealings with service providers. Nothing in these Terms limits any liability that cannot be excluded under South African law, including under the Consumer Protection Act.'),
                    _h2('12. Indemnity'),
                    _p('To the extent permitted by law, you agree to indemnify us against claims, losses and costs arising from your breach of these Terms, your content, or your dealings with other users or service providers.'),
                    _h2('13. Suspension and termination'),
                    _p('You may stop using Subby and delete your account at any time. We may suspend or terminate your access if you breach these Terms or use the app in a way that may harm other users, providers or us.'),
                    _h2('14. Changes to these Terms'),
                    _p('We may update these Terms from time to time. We will update the date shown at the top of this page, and significant changes may be notified in the app. Continued use after changes means you accept the updated Terms.'),
                    _h2('15. Governing law'),
                    _p('These Terms are governed by the laws of the Republic of South Africa, and the South African courts have jurisdiction over any dispute, subject to your rights under the Consumer Protection Act.'),
                    _h2('16. Contact us'),
                    _p('Questions about these Terms? Contact us at support@subby.co.za.'),
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
