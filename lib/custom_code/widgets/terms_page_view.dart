// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;

  // ---------------- TYPOGRAPHY (HomePageView baseline) ----------------
  // Page title (“Subby”): titleLarge
  TextStyle _appTitleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900, // 🔥 Extra bold
      letterSpacing: 0.2,
    );
  }

  // Subtitle: bodySmall (secondaryText)
  TextStyle _pageSubtitle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  // Section titles: titleMedium
  TextStyle _sectionTitle(FlutterFlowTheme t) => t.titleMedium.override(
        fontFamily: t.titleMediumFamily,
      );

  // Body: bodyMedium
  TextStyle _body(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
      );

  // Small/meta: bodySmall (secondaryText)
  TextStyle _meta(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: t.bodySmallFamily,
        color: t.secondaryText,
      );

  // Hint: bodyMedium + secondaryText (keeps baseline families; reads well)
  TextStyle _hint(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: t.bodyMediumFamily,
        color: t.secondaryText,
      );

  // Header title on primary band: titleLarge (white)
  TextStyle _headerTitleOnPrimary(FlutterFlowTheme t) => t.titleLarge.override(
        fontFamily: t.titleLargeFamily,
        color: Colors.white,
        fontWeight: FontWeight.w900,
      );
  // -------------------------------------------------------------------

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
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.safePop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.secondaryBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.alternate, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ FIX: use existing title style
                      Text('Subby', style: _appTitleStyle(theme)),
                      const SizedBox(height: 2),
                      Text('Terms of Service', style: _pageSubtitle(theme)),
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
              child: Text(
                'Terms of Service',
                style: _headerTitleOnPrimary(theme),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(_hPad, 16, _hPad, bottomInset + 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: theme.alternate),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last updated: ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                        style: _meta(theme),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Add your Terms of Service text here.',
                        style: _body(theme),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tip: Keep this content short in-app, and link to the full policy if you prefer.',
                        style: _hint(theme),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
