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

// ===================================
// FILE: post_auth_gate_page_view.dart
// ===================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostAuthGatePageView extends StatefulWidget {
  const PostAuthGatePageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<PostAuthGatePageView> createState() => _PostAuthGatePageViewState();
}

class _PostAuthGatePageViewState extends State<PostAuthGatePageView>
    with SingleTickerProviderStateMixin {
  String? _error;
  bool _working = true;
  bool _handled = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // less-is-more system · ported from Clutch Putt · lime → yellow.
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F4);
  static const Color _hairlineOnSurface = Color(0xFFD7DCE3);
  // Brand accent — YELLOW. Always ink foreground, never white.
  static const Color _spark = Color(0xFFAEE03F); // primary CTA / ranked accent
  static const Color _sparkInk = Color(0xFF16202E);
  // Status
  static const Color _live =
      Color(0xFFFF6A2B); // orange — live / open-now / warning
  static const Color _coral = Color(0xFFE0531C);
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // ✅ Route names (MATCH FlutterFlow route names exactly)
  static const String kLoginRoute = 'login';
  static const String kHomeRoute = 'dashboardPage'; // ✅ UPDATED

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuth());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_handled) return;
    _handled = true;

    try {
      if (mounted) {
        setState(() {
          _working = true;
          _error = null;
        });
      }

      final user = FirebaseAuth.instance.currentUser;

      // 🔐 Not logged in → Login
      if (user == null) {
        if (!mounted) return;
        context.goNamed(kLoginRoute);
        return;
      }

      // ✅ Ensure users/<uid> exists
      final uid = user.uid;
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final now = Timestamp.now();

      final snap = await usersRef.get();
      final existing = snap.data() ?? <String, dynamic>{};

      if (!snap.exists) {
        await usersRef.set({
          'uid': uid,
          'email': (user.email ?? '').trim(),
          'phone_number': (user.phoneNumber ?? '').trim(),
          'created_time': now,
          'active': true,
        }, SetOptions(merge: true));
      } else {
        await usersRef.set({
          'uid': uid,
          'email': (user.email ?? (existing['email'] ?? '')).toString().trim(),
          'phone_number': (user.phoneNumber ??
                  (existing['phone_number'] ?? existing['phoneNumber'] ?? ''))
              .toString()
              .trim(),
          'active': existing['active'] ?? true,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      // ✅ ALWAYS go to Dashboard after auth
      context.goNamed(kHomeRoute);
    } catch (e) {
      debugPrint('PostAuthGatePageView error: $e');
      if (!mounted) return;

      setState(() {
        _working = false;
        _error = 'Could not finish sign-in. Check Firestore rules.';
      });

      _handled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 42, color: _coral),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _coral,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _handled = false;
                      _handleAuth();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _spark, // primary CTA — yellow
                      foregroundColor: _sparkInk, // ink-on-yellow, never white
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _sparkInk,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(_ink),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      _working
                          ? 'Welcome back. Just a moment…'
                          : 'Almost there…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: _inkMute,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
