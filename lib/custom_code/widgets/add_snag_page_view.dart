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

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

class AddSnagPageView extends StatefulWidget {
  const AddSnagPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<AddSnagPageView> createState() => _AddSnagPageViewState();
}

class _AddSnagPageViewState extends State<AddSnagPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with ToDoListPageView / DetailTaskPageView (DS slate system).
  // Lime retired: tints → neutral surface, attention → clay, info → green.
  static const Color _ink = Color(0xFF323F4D);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  static const Color _teal = Color(0xFF323F4D);
  static const Color _tealTint =
      Color(0xFFEEF1F4); // DS: lime tint → neutral surface
  static const Color _live =
      Color(0xFFCC4B3C); // DS: lime → clay (high / attention)
  static const Color _green = Color(0xFF1F8A5B); // DS: in-progress / info
  static const Color _coral = Color(0xFFCC4B3C);
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();

  DocumentReference? _projectRef;
  bool _resolved = false;

  String _severity = 'minor'; // 'minor' | 'major' | 'critical'
  DateTime? _dueDate;

  // Each entry: { 'url', 'type' ('image'|'video'), 'storagePath' }
  final List<Map<String, dynamic>> _media = [];

  // The snag is assigned to a TEAM MEMBER on the project (a listing record).
  DocumentReference?
      _assignedListingRef; // -> project_listings / subby_listings
  String _assignedListingName = '';
  String _assignedListingSubtitle = '';

  bool _uploading = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    // 1) projectRef from the route query (Snag List passes this), else prefs.
    _projectRef = _readRefFromRoute('projectRef', 'projects');
    if (_projectRef == null) _loadActiveProject();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  DocumentReference? _readRefFromRoute(String key, String fallbackCollection) {
    try {
      final qp = GoRouterState.of(context).uri.queryParameters;
      var s = (qp[key] ?? '').trim();
      if (s.isEmpty) return null;
      s = s.replaceAll('"', '');
      if (s.startsWith('{')) {
        final m = RegExp(r'([A-Za-z0-9_]+/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)')
            .firstMatch(s);
        if (m != null) s = m.group(1)!;
      }
      if (s.contains('/')) return FirebaseFirestore.instance.doc(s);
      return FirebaseFirestore.instance.collection(fallbackCollection).doc(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty || !mounted) return;
    setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.safePop();
    }
  }

  // =========================================================
  // Typography
  // =========================================================
  TextStyle _uLabel() => const TextStyle(
        fontFamily: _bodyFont,
        color: _inkMute,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      );

  TextStyle _fieldText() => const TextStyle(
        fontFamily: _bodyFont,
        color: _ink,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      );

  static const BoxDecoration _uRule = BoxDecoration(
    border: Border(bottom: BorderSide(color: _hairline, width: 1)),
  );

  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
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
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _inkMute),
          ),
        ),
      );

  // =========================================================
  // Media: pick (image/video) + upload to Storage
  // =========================================================
  Future<void> _pickMedia() async {
    if (_uploading || _saving) return;
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('Select a project first.');
      return;
    }
    FocusScope.of(context).unfocus();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media, // images + videos
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _uploading = true);

      for (final f in result.files) {
        final Uint8List? bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;

        final rawName = (f.name.isNotEmpty ? f.name : 'media');
        final fileName = p.basename(rawName);
        final safeName = fileName.replaceAll(RegExp(r'[^\w\.\- ]+'), '_');
        final ts = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'projects/${projectRef.id}/snags/${ts}_$safeName';

        final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
            'application/octet-stream';
        final kind = contentType.startsWith('video') ? 'video' : 'image';

        final ref = FirebaseStorage.instance.ref().child(storagePath);
        await ref.putData(bytes, SettableMetadata(contentType: contentType));
        final url = await ref.getDownloadURL();

        _media.add({'url': url, 'type': kind, 'storagePath': storagePath});
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('🔥 Snag media upload failed: $e');
      _toast('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeMedia(int index) {
    final item = _media[index];
    final storagePath = (item['storagePath'] ?? '').toString();
    if (storagePath.isNotEmpty) {
      FirebaseStorage.instance.ref().child(storagePath).delete().catchError(
            (e) => debugPrint('⚠️ media delete skipped: $e'),
          );
    }
    setState(() => _media.removeAt(index));
  }

  Widget _mediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PHOTOS & VIDEO', style: _uLabel()),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_radius),
                    border:
                        Border.all(color: const Color(0xFFC7D0DA), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _uploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_teal),
                              ),
                            )
                          : const Icon(Icons.add_a_photo_outlined,
                              size: 22, color: _teal),
                      const SizedBox(height: 3),
                      Text(_uploading ? '…' : 'Add',
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _inkMute)),
                    ],
                  ),
                ),
              ),
              for (int i = 0; i < _media.length; i++) ...[
                const SizedBox(width: 10),
                _mediaThumb(i),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _mediaThumb(int i) {
    final item = _media[i];
    final url = (item['url'] ?? '').toString();
    final isVideo = (item['type'] ?? 'image') == 'video';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _hairlineOnSurface),
            color: _surface,
            image: (!isVideo && url.isNotEmpty)
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: isVideo
              ? const Center(
                  child: Icon(Icons.play_circle_fill_rounded,
                      size: 26, color: Colors.white))
              : null,
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeMedia(i),
            child: Container(
              width: 22,
              height: 22,
              decoration:
                  const BoxDecoration(color: _ink, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 14, color: _paper),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Underline fields
  // =========================================================
  Widget _uText({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final multiline = maxLines > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _uLabel()),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: multiline ? 3 : 0),
                child: Icon(icon, size: 19, color: _teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: !_saving,
                  cursorColor: _teal,
                  maxLines: maxLines,
                  validator: validator,
                  style: _fieldText(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontFamily: _bodyFont,
                        color: Color(0xCC5A6675),
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                    errorStyle: const TextStyle(
                        fontFamily: _bodyFont,
                        color: _coral,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Severity selector. Critical = clay, Major = ink, Minor = faint.
  Color _sevColor(String k) =>
      k == 'critical' ? _live : (k == 'minor' ? _faint : _ink);

  Widget _severityField() {
    Widget pill(String key, String label) {
      final sel = _severity == key;
      final c = _sevColor(key);
      return GestureDetector(
        onTap: () => setState(() => _severity = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color:
                sel && key == 'critical' ? const Color(0x29CC4B3C) : _surface,
            borderRadius: BorderRadius.circular(999),
            border: sel ? Border.all(color: c, width: 1.5) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 12,
              fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
              color: sel ? c : _faint,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: _uRule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEVERITY', style: _uLabel()),
          const SizedBox(height: 10),
          Row(
            children: [
              pill('minor', 'Minor'),
              const SizedBox(width: 8),
              pill('major', 'Major'),
              const SizedBox(width: 8),
              pill('critical', 'Critical'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dueDateField() {
    final label =
        _dueDate == null ? 'Select date' : dateTimeFormat('d MMM y', _dueDate!);
    return GestureDetector(
      onTap: _saving ? null : _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: _uRule,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DUE DATE', style: _uLabel()),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 19, color: _teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: _fieldText()
                        .copyWith(color: _dueDate == null ? _inkMute : _ink),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFC7D0DA)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignField() {
    final hasPick = _assignedListingRef != null;
    return GestureDetector(
      onTap: _saving ? null : _pickListing,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASSIGN TO TEAM MEMBER', style: _uLabel()),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasPick ? _tealTint : _surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: hasPick
                      ? Text(
                          _initials(_assignedListingName),
                          style: const TextStyle(
                              fontFamily: _displayFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink),
                        )
                      : const Icon(Icons.person_outline_rounded,
                          size: 20, color: _faint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasPick
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_assignedListingName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: _displayFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF323F4D))),
                            const SizedBox(height: 2),
                            Text(
                                _assignedListingSubtitle.isEmpty
                                    ? 'Added to project'
                                    : _assignedListingSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: _bodyFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _faint)),
                          ],
                        )
                      : const Text('Choose a team member on this project',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _inkMute)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFC7D0DA)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '–';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // =========================================================
  // Assign-to picker (project_listings for this project)
  // =========================================================
  Future<void> _pickListing() async {
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('Select a project first.');
      return;
    }
    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      backgroundColor: _paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _hairlineOnSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Assign to team member',
                    style: TextStyle(
                        fontFamily: _displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _ink)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('project_listings')
                        .where('projectRef', isEqualTo: projectRef)
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_teal)),
                            ),
                          ),
                        );
                      }
                      final docs = snap.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'No team members on this project yet. Add one from the Directory first.',
                            style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _faint),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: _hairline),
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          final name =
                              (d['title'] ?? d['name'] ?? 'Team member')
                                  .toString();
                          final subtitle = (d['subtitle'] ??
                                  d['ratingText'] ??
                                  'Added to project')
                              .toString();
                          final listingRef =
                              d['listingRef'] as DocumentReference?;
                          final selected =
                              listingRef?.path == _assignedListingRef?.path;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _assignedListingRef =
                                    listingRef ?? docs[i].reference;
                                _assignedListingName = name;
                                _assignedListingSubtitle = subtitle;
                              });
                              Navigator.of(ctx).pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _tealTint,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(_initials(name),
                                        style: const TextStyle(
                                            fontFamily: _displayFont,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _ink)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _displayFont,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF323F4D))),
                                        const SizedBox(height: 2),
                                        Text(subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontFamily: _bodyFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _faint)),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color:
                                        selected ? _teal : _hairlineOnSurface,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // Due date picker (slate themed)
  // =========================================================
  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: _teal,
              onPrimary: _paper,
              onSurface: _ink,
              surface: _paper,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _paper,
              headerBackgroundColor: _teal,
              headerForegroundColor: _paper,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _teal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _dueDate = picked);
  }

  // =========================================================
  // Save
  // =========================================================
  Future<void> _save() async {
    if (_saving || _uploading) return;
    final projectRef = _projectRef;
    if (projectRef == null) {
      _toast('No project selected.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final now = Timestamp.now();
      final firstImage = _media.firstWhere(
        (m) => (m['type'] ?? 'image') == 'image',
        orElse: () => const {},
      );
      final photoUrl = (firstImage['url'] ?? '').toString();

      final docRef = FirebaseFirestore.instance.collection('snags').doc();
      await docRef.set(<String, dynamic>{
        'projectRef': projectRef,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'severity': _severity,
        'status': 'open',
        'dueDate': _dueDate == null ? null : Timestamp.fromDate(_dueDate!),
        'media': _media,
        'photoUrl': photoUrl, // SnagListPageView reads this
        'assignedListingRef': _assignedListingRef,
        'assignedListingName': _assignedListingName,
        'assignedToName': _assignedListingName, // SnagList back-compat
        'readByListingAt': null, // stamped when the team member opens it
        'createdBy': currentUserReference,
        'createdByName': currentUserDisplayName,
        'createdAt': now,
        'updatedAt': now,
      }.withoutNulls);

      if (!mounted) return;
      _toast('Snag added.');
      _handleBack(); // back to the Snag List (its stream refreshes)
    } catch (e) {
      debugPrint('🔥 Add snag failed: $e');
      if (mounted) _toast('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _ink,
          content: Text(msg,
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  color: _paper,
                  fontWeight: FontWeight.w700)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 96),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _minBack(),
                    const SizedBox(height: 16),
                    const Text('Add Snag',
                        style: TextStyle(
                            fontFamily: _displayFont,
                            color: _ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            height: 1.05,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Log a defect with photos, video & details',
                        style: TextStyle(
                            fontFamily: _bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _faint)),
                    const SizedBox(height: 22),
                    _mediaSection(),
                    const SizedBox(height: 6),
                    _uText(
                      label: 'Title',
                      controller: _titleCtrl,
                      icon: Icons.title_rounded,
                      hint: 'e.g. Cracked tile in ensuite',
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Give the snag a title'
                          : null,
                    ),
                    _uText(
                      label: 'Description',
                      controller: _descCtrl,
                      icon: Icons.notes_rounded,
                      hint: 'What is wrong, and where exactly…',
                      maxLines: 3,
                    ),
                    _uText(
                      label: 'Area / Room',
                      controller: _areaCtrl,
                      icon: Icons.place_outlined,
                      hint: 'e.g. Master Ensuite',
                    ),
                    _severityField(),
                    _dueDateField(),
                    _assignField(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(_radius),
                  child: Opacity(
                    opacity: (_saving || _uploading) ? 0.7 : 1,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_saving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_paper)),
                            )
                          else
                            const Icon(Icons.add_rounded,
                                color: _paper, size: 20),
                          const SizedBox(width: 9),
                          Text(_saving ? 'Saving…' : 'Add Snag',
                              style: const TextStyle(
                                  fontFamily: _bodyFont,
                                  color: _paper,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
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
