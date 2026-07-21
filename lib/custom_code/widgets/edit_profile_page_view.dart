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

// ✅ Auth helpers (currentUserReference, currentUserEmail, etc.)
import '/auth/firebase_auth/auth_util.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePageView extends StatefulWidget {
  const EditProfilePageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<EditProfilePageView> createState() => _EditProfilePageViewState();
}

class _EditProfilePageViewState extends State<EditProfilePageView> {
  // ─── SUBBY PALETTE (LOCK) — synced with DashboardPageView v6 ───────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _hairline = Color(0xFFEAEEF0);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _steel = Color(0xFF3D4F66); // hero background
  static const Color _accent = Color(0xFFE7E247); // primary CTA fill
  static const Color _coral = Color(0xFF566670);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  bool _prefilled = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  static const double _hPad = 20;

  // Streams are created ONCE, not per build(). Creating them inside build()
  // meant every rebuild (e.g. the keyboard opening when you tap a field)
  // handed each StreamBuilder a brand-new stream, which reset it to its
  // waiting state and remounted the whole form — so the field lost focus and
  // the keyboard closed before you could type. (FIX 4)
  final Stream<User?> _authStream = FirebaseAuth.instance.authStateChanges();

  Stream<UsersRecord>? _userStream;
  String? _userStreamKey;

  Stream<UsersRecord> _userDocStream(DocumentReference ref) {
    if (_userStream == null || _userStreamKey != ref.path) {
      _userStreamKey = ref.path;
      _userStream = UsersRecord.getDocument(ref);
    }
    return _userStream!;
  }

  // Resolve the caller's users/{uid} doc. Prefer the FlutterFlow ref, fall
  // back to the live FirebaseAuth uid so a transient null on the auth stream
  // never trips the spurious "Not signed in" toast. (FIX 2)
  DocumentReference<Object?>? _resolveUserRef() {
    final ff = currentUserReference;
    if (ff != null) return ff;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      return FirebaseFirestore.instance.collection('users').doc(uid);
    }
    return null;
  }

  // =========================================================
  // TYPOGRAPHY
  // =========================================================
  TextStyle _uLabelStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  TextStyle _fieldTextStyle(FlutterFlowTheme t) => t.bodyMedium.override(
        fontFamily: _bodyFont,
        color: _ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        letterSpacing: 0.0,
      );

  TextStyle _snackTextStyle(FlutterFlowTheme t) => t.bodySmall.override(
        fontFamily: _bodyFont,
        color: _paper,
        fontWeight: FontWeight.w700,
      );

  Widget _heroCircle(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );

  void _showToast(String message, {bool success = true}) {
    if (!mounted) return;
    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          elevation: 0,
          backgroundColor: const Color(0xFF3D4F66),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide.none,
          ),
          duration: const Duration(milliseconds: 1700),
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: _paper.withOpacity(0.16), shape: BoxShape.circle),
                child: Icon(
                  success ? Icons.check_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _paper,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: _snackTextStyle(theme))),
            ],
          ),
        ),
      );
  }

  // =========================================================
  // MINIMAL UNDERLINE FIELD — keyboard action = Done (blue tick)
  // =========================================================
  Widget _uText({
    required FlutterFlowTheme theme,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    bool divider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: _hairline, width: 1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabelStyle(theme)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 19, color: _ink),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onTap: _ensureFocusedVisible,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: onSubmitted,
                  validator: validator,
                  cursorColor: _steel,
                  style: _fieldTextStyle(theme),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: theme.bodyMedium.override(
                      fontFamily: _bodyFont,
                      color: _inkMute.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.0,
                    ),
                    errorStyle: theme.bodySmall.override(
                      fontFamily: _bodyFont,
                      color: _coral,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primarySave(FlutterFlowTheme theme) {
    return GestureDetector(
      onTap: _saving ? null : _saveProfile,
      child: Opacity(
        opacity: _saving ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_ink),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18, color: _ink),
                    const SizedBox(width: 8),
                    Text('Save Profile',
                        style: theme.labelLarge.override(
                          fontFamily: _bodyFont,
                          color: _ink,
                          fontWeight: FontWeight.w900,
                        )),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  // =========================================================
  // ✅ CHANGE PHOTO — pick → upload to Storage → save photo_url
  // Requires the storage.rules block for users/{uid}/** (owner write). (FIX 3)
  // =========================================================
  Future<void> _changePhoto() async {
    if (_uploadingPhoto) return;
    final userRef = _resolveUserRef();
    final user = FirebaseAuth.instance.currentUser;
    if (userRef == null || user == null) {
      _showToast('Not signed in.', success: false);
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);

      final bytes = await picked.readAsBytes();
      final ref =
          FirebaseStorage.instance.ref().child('users/${user.uid}/profile.jpg');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();

      // Use the generated helper so the backing-field name is always correct.
      await userRef.update(createUsersRecordData(photoUrl: url));
      try {
        await user.updatePhotoURL(url);
      } catch (_) {}

      if (!mounted) return;
      _showToast('Photo updated.');
    } catch (e) {
      if (!mounted) return;
      _showToast('Could not update photo: $e', success: false);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    // Prefer the FlutterFlow ref, fall back to the live FirebaseAuth uid so a
    // transient null never shows the spurious "Not signed in" toast. (FIX 2)
    final userRef = _resolveUserRef();
    if (userRef == null) {
      _showToast('Not signed in. Please log in again.', success: false);
      return;
    }

    setState(() => _saving = true);
    try {
      final displayName = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      // Write via the generated helper so the Firestore keys always match the
      // UsersRecord backing fields — fixes the phone number coming back blank
      // after save when the raw key didn't match the schema field. (FIX 1)
      await userRef.update(createUsersRecordData(
        displayName: displayName,
        phoneNumber: phone,
      ));
      if (!mounted) return;
      _showToast('Profile updated.', success: true);
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      _showToast('Failed to save: $e', success: false);
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Steel hero ────────────────────────────────────────────────────────
  Widget _hero() => Container(
        width: double.infinity,
        color: _steel,
        padding: EdgeInsets.fromLTRB(
            _hPad, MediaQuery.of(context).padding.top + 8, _hPad, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _heroCircle(
                    Icons.arrow_back_ios_new_rounded, () => context.safePop()),
                Expanded(
                  child: Center(
                    child: Text('PROFILE & ACCOUNT',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _paper.withOpacity(0.55))),
                  ),
                ),
                const SizedBox(width: 38, height: 38),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Edit profile',
                style: TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.0,
                    color: _paper)),
            const SizedBox(height: 8),
            Text('Update your name and contact details.',
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _paper.withOpacity(0.6))),
          ],
        ),
      );

  // Empty-state avatar (shared look with ProfilePageView) + camera badge.
  Widget _avatarBlock(FlutterFlowTheme theme, String displayName, String email,
      String photoUrl) {
    final initials = Center(
      child: Text(
        _initials(displayName),
        style: const TextStyle(
          fontFamily: _bodyFont,
          color: _steel,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _changePhoto,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent, width: 2.2),
                    ),
                    child: ClipOval(
                      child: _uploadingPhoto
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_steel),
                                ),
                              ),
                            )
                          : (photoUrl.isNotEmpty
                              ? Image.network(photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => initials)
                              : initials),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _surface, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          size: 13, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName.isEmpty ? 'Your name' : displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleMedium.override(
                        fontFamily: _displayFont,
                        color: _ink,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall
                        .override(fontFamily: _bodyFont, color: _inkMute)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _changePhoto,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.upload_rounded, size: 15, color: _steel),
                      SizedBox(width: 5),
                      Text('Change photo',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _steel)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title.toUpperCase(),
      style: const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      ));

  Widget _messageState(
    FlutterFlowTheme theme,
    double width,
    double height, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: _paper,
        child: Column(
          children: [
            _hero(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(_hPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: _inkMute, size: 34),
                      const SizedBox(height: 12),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: theme.titleMedium.override(
                              fontFamily: _displayFont,
                              fontWeight: FontWeight.w900,
                              color: _ink)),
                      const SizedBox(height: 6),
                      Text(body,
                          textAlign: TextAlign.center,
                          style: theme.bodySmall.override(
                              fontFamily: _bodyFont, color: _inkMute)),
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

  // Lift the focused field above the on-screen keyboard.
  void _ensureFocusedVisible() {
    Future.delayed(const Duration(milliseconds: 250), () {
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final double width = widget.width ?? MediaQuery.sizeOf(context).width;
    final double height = widget.height ?? MediaQuery.sizeOf(context).height;

    return SizedBox(
      width: width,
      height: height,
      child: StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, authSnap) {
          final userRef = _resolveUserRef();

          if (authSnap.connectionState == ConnectionState.waiting) {
            return _messageState(theme, width, height,
                icon: Icons.lock_outline,
                title: 'You are not signed in.',
                body: 'Please log in to edit your profile.');
          }
          if (authSnap.data == null || userRef == null) {
            _prefilled = false;
            _saving = false;
            return _messageState(theme, width, height,
                icon: Icons.lock_outline,
                title: 'You are not signed in.',
                body: 'Please log in to edit your profile.');
          }

          return StreamBuilder<UsersRecord>(
            stream: _userDocStream(userRef),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final stillSignedIn = FirebaseAuth.instance.currentUser != null;
                if (!stillSignedIn) {
                  _prefilled = false;
                  _saving = false;
                  return _messageState(theme, width, height,
                      icon: Icons.lock_outline,
                      title: 'You are not signed in.',
                      body: 'Please log in to edit your profile.');
                }
                return _messageState(theme, width, height,
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load profile right now.',
                    body: 'Please try again in a moment.');
              }

              final userDoc = snapshot.data;
              if (!_prefilled && userDoc != null) {
                _nameController.text = userDoc.displayName;
                _phoneController.text = userDoc.phoneNumber;
                _prefilled = true;
              }

              final displayName = userDoc?.displayName ?? '';
              final email = userDoc?.email ?? (currentUserEmail ?? '');
              final photoUrl = userDoc?.photoUrl ?? '';

              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  color: _paper,
                  child: Column(
                    children: [
                      _hero(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(_hPad, 20, _hPad, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _avatarBlock(theme, displayName, email, photoUrl),
                              const SizedBox(height: 26),
                              _sectionHeader('Details'),
                              const SizedBox(height: 10),
                              Form(
                                key: _formKey,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _paper,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _hairline),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _uText(
                                        theme: theme,
                                        label: 'Display name',
                                        controller: _nameController,
                                        focusNode: _nameFocus,
                                        icon: Icons.person_outline_rounded,
                                        hint: 'Your name',
                                        onSubmitted: (_) =>
                                            FocusScope.of(context)
                                                .requestFocus(_phoneFocus),
                                        validator: (v) {
                                          final s = (v ?? '').trim();
                                          if (s.isEmpty) {
                                            return 'Please enter your name.';
                                          }
                                          if (s.length < 2) {
                                            return 'Name is too short.';
                                          }
                                          return null;
                                        },
                                      ),
                                      _uText(
                                        theme: theme,
                                        label: 'Phone number',
                                        controller: _phoneController,
                                        focusNode: _phoneFocus,
                                        icon: Icons.phone_outlined,
                                        hint: 'e.g. 0813151789',
                                        keyboardType: TextInputType.phone,
                                        onSubmitted: (_) => _saveProfile(),
                                        divider: false,
                                        validator: (v) {
                                          final s = (v ?? '').trim();
                                          if (s.isEmpty) {
                                            return 'Please enter your phone number.';
                                          }
                                          if (s.length < 8) {
                                            return 'Phone number looks too short.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              _primarySave(theme),
                              const SizedBox(height: 14),
                              Center(
                                child: GestureDetector(
                                  onTap:
                                      _saving ? null : () => context.safePop(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text('Cancel',
                                        style: theme.bodyMedium.override(
                                          fontFamily: _bodyFont,
                                          color: _inkMute,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
