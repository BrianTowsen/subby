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

/// JoinProjectView — redeem a project invite code (e.g. SUB-4K7KQ2).
///
/// Counterpart of InviteMemberView: an invited person (office staff, the
/// homeowner/client) signs in with a plain Subby login — no Network listing —
/// enters the code here, and claimProjectInvite creates their
/// project_members doc server-side. On success we set the active project and
/// open it.
///
/// Use [showJoinProjectSheet] to present as a bottom sheet (e.g. from the
/// More page), or embed JoinProjectView as a page widget.

import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinProjectView extends StatefulWidget {
  const JoinProjectView({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<JoinProjectView> createState() => _JoinProjectViewState();
}

class _JoinProjectViewState extends State<JoinProjectView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: const _JoinProjectSheet(embedded: true),
    );
  }
}

/// Opens the join flow as a bottom sheet (used by MorePageView).
Future<void> showJoinProjectSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _JoinProjectSheet(),
    ),
  );
}

class _JoinProjectSheet extends StatefulWidget {
  const _JoinProjectSheet({this.embedded = false});

  final bool embedded;

  @override
  State<_JoinProjectSheet> createState() => _JoinProjectSheetState();
}

class _JoinProjectSheetState extends State<_JoinProjectSheet> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _spark = Color(0xFFE7E247);
  static const Color _sparkInk = Color(0xFF1E282E);
  static const Color _warn = Color(0xFFAC0C0C);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const String _kActiveProjectPath = 'subby_active_project_path';
  static const String _kPendingInviteCode = 'subby_pending_invite_code';
  static const String _kProjectDetailRoute = 'ProjectDetailPage';
  static const String _kAddListingRoute = 'addListingPage';

  final TextEditingController _codeCtl = TextEditingController();
  bool _joining = false;
  bool _needsListing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillSavedCode();
  }

  // A provider who was told to register first gets their code pre-filled
  // when they come back to this sheet.
  Future<void> _prefillSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_kPendingInviteCode) ?? '').trim();
    if (saved.isNotEmpty && mounted && _codeCtl.text.trim().isEmpty) {
      setState(() => _codeCtl.text = saved);
    }
  }

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_joining) return;
    final raw = _codeCtl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter the invite code you were sent.');
      return;
    }
    setState(() {
      _joining = true;
      _needsListing = false;
      _error = null;
    });
    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('claimProjectInvite').call(<String, dynamic>{
        'code': raw,
      });
      final data = Map<String, dynamic>.from(result.data as Map);

      // Service-provider invite, but no Network listing yet: the invite is
      // NOT consumed. Save the code and route them to registration — they
      // come back here afterwards with the code pre-filled.
      if (data['needsListing'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kPendingInviteCode, raw);
        if (!mounted) return;
        setState(() {
          _joining = false;
          _needsListing = true;
          _error = null;
        });
        return;
      }

      final projectPath = (data['projectPath'] ?? '').toString();
      final projectName = (data['projectName'] ?? 'the project').toString();
      final alreadyMember = data['alreadyMember'] == true;

      if (projectPath.isEmpty) {
        throw Exception('missing projectPath');
      }

      // Remember as the active project (same contract the rest of the app
      // uses to resolve "current project"), and clear any saved invite code.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveProjectPath, projectPath);
      await prefs.remove(_kPendingInviteCode);

      if (!mounted) return;

      showAppToast(
        context,
        alreadyMember
            ? 'You’re already on $projectName.'
            : 'Welcome aboard — you’ve joined $projectName.',
        true,
      );

      final projectRef = FirebaseFirestore.instance.doc(projectPath);

      // Grab the router BEFORE popping the sheet — this context is defunct
      // once the sheet route is gone.
      final router = GoRouter.of(context);
      if (widget.embedded) {
        // Embedded page stays mounted behind the pushed route — reset so a
        // second code can be redeemed later.
        setState(() {
          _joining = false;
          _codeCtl.clear();
        });
      } else {
        Navigator.of(context).pop();
      }

      router.pushNamed(
        _kProjectDetailRoute,
        queryParameters: <String, dynamic>{
          'projectRef': serializeParam(projectRef, ParamType.DocumentReference),
        }.withoutNulls,
        extra: <String, dynamic>{
          'projectRef': projectRef,
        },
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = e.message ?? 'That code didn’t work. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = 'That code didn’t work. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: widget.embedded
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.embedded)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          const Text('Join a project',
              style: TextStyle(
                fontFamily: _displayFont,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
              )),
          const SizedBox(height: 3),
          const Text(
            'Been sent an invite code? Enter it below to get access to the '
            'project — no Network listing needed.',
            style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: _inkMute,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codeCtl,
            autofocus: !widget.embedded,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\- ]')),
              LengthLimitingTextInputFormatter(12),
            ],
            onSubmitted: (_) => _join(),
            style: const TextStyle(
              fontFamily: _displayFont,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: _ink,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'SUB-4K7KQ2',
              hintStyle: const TextStyle(
                fontFamily: _displayFont,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: _faint,
              ),
              filled: true,
              fillColor: _surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _warn,
                )),
          ],
          if (_needsListing) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('One more step — register on the Network',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    'This invite adds you to the project team as a service '
                    'provider, so your business needs a Subby Network '
                    'listing first. Your code is saved — it will be filled '
                    'in here when you come back.',
                    style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: _inkMute,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        final router = GoRouter.of(context);
                        if (!widget.embedded) {
                          Navigator.of(context).pop();
                        }
                        router.pushNamed(_kAddListingRoute);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: _paper,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text('Register my business',
                          style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _joining ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: _spark,
                foregroundColor: _sparkInk,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _joining
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(_sparkInk),
                      ),
                    )
                  : const Text('Join project',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _sparkInk,
                      )),
            ),
          ),
        ],
      ),
    );
    if (widget.embedded) return SingleChildScrollView(child: content);
    return SafeArea(top: false, child: SingleChildScrollView(child: content));
  }
}
