// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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
    final theme = FlutterFlowTheme.of(context);

    return SafeArea(
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: theme.primaryBackground,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 42, color: theme.error),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium.copyWith(
                      color: theme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _handled = false;
                      _handleAuth();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
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
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
