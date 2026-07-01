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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

// ─────────────────────────────────────────────────────────────────────
// UPDATE (this revision):
//   • "Mark as done" now uses the shared, centred "warning"-style dialog
//     (the same module as Delete) but in GREEN: a 62px green-tinted badge
//     with a task_alt icon, 22-radius card, an optional completion-note
//     field, a filled GREEN "Mark done" confirm + outlined "Cancel" over a
//     55%-black scrim. (Replaces the old plain AlertDialog.)
//   • Read receipt is GREEN and means the ASSIGNED LISTING has VIEWED the
//     task — stamped (_maybeStampReadReceipt) only when the listing's owner
//     opens this screen. Shows "Read d MMM · HH:mm" (green) or "Not read
//     yet" (faint). (Unchanged this revision — clarified here.)
//   • Edit action REMOVED — the header only exposes Delete for the task's
//     creator (task.createdBy == currentUserReference).
//   • Snackbars — every successful mutation (start / mark done / reopen /
//     checklist toggle) shows "Task updated."; a delete shows
//     "Task deleted.". (Uses the standard ink snackbar = _toast.)
// ─────────────────────────────────────────────────────────────────────

class DetailTaskPageView extends StatefulWidget {
  const DetailTaskPageView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<DetailTaskPageView> createState() => _DetailTaskPageViewState();
}

class _DetailTaskPageViewState extends State<DetailTaskPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
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
      Color(0xFFCC4B3C); // DS: lime → clay (high/attention)
  static const Color _coral =
      Color(0xFFCC4B3C); // DS: → clay (destructive/error)
  static const Color _navy = Color(0xFF323F4D);
  static const Color _green =
      Color(0xFF166341); // DS: to-do / in-progress / info / mark-done
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _radius = 12;

  static const String _kActiveTaskPath = 'subby_active_task_path';

  DocumentReference? _taskRef;
  bool _resolved = false;
  bool _refLoading = true;

  bool _stampDone = false; // read-receipt conclusively handled — stop retrying
  bool _stampInFlight = false; // a stamp attempt is currently awaiting
  bool _working = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    _taskRef = _readRefFromRoute('taskRef', 'tasks');
    if (_taskRef == null) {
      _loadActiveTask();
    } else {
      _refLoading = false;
    }
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

  Future<void> _loadActiveTask() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveTaskPath) ?? '').trim();
    if (!mounted) return;
    setState(() {
      _taskRef = path.isEmpty ? null : FirebaseFirestore.instance.doc(path);
      _refLoading = false;
    });
  }

  // =========================================================
  // READ RECEIPT — stamp when the assigned LISTING's owner views this task.
  //
  // Driven by the live StreamBuilder snapshot rather than a one-shot
  // first-frame callback: the doc data is already in hand (no extra read), and
  // the attempt is retried on each snapshot until it conclusively succeeds or
  // proves the viewer isn't the owner. A transient auth-not-ready state
  // (currentUserReference still null on a cold open / deep-link) or a network
  // blip no longer permanently suppresses the receipt — it simply retries on
  // the next snapshot. The green "Read …" line reflects this stamp; until it
  // exists the row shows "Not read yet".
  // =========================================================
  Future<void> _maybeStampReadReceipt(
      DocumentReference ref, Map<String, dynamic> data) async {
    if (_stampDone || _stampInFlight) return;
    _stampInFlight = true;
    try {
      if (data['readByListingAt'] != null) {
        _stampDone = true; // already stamped by someone — stop trying
        return;
      }
      final me = currentUserReference;
      if (me == null) return; // auth not ready yet — retry on next snapshot

      // Prefer the owner ref denormalized onto the task at assign time; fall
      // back to resolving it live (handles assignedListingRef pointing at a
      // project_listings doc instead of a subby_listings doc).
      DocumentReference? ownerRef =
          data['assignedListingOwnerRef'] as DocumentReference?;
      if (ownerRef == null) {
        final listingRef = data['assignedListingRef'] as DocumentReference?;
        if (listingRef != null) {
          ownerRef = await _resolveListingOwner(listingRef);
        }
      }

      // Only the ASSIGNED listing's owner stamps the receipt.
      if (ownerRef == null || ownerRef.path != me.path) {
        _stampDone = true; // not the owner (auth present) — never stamp
        return;
      }

      await ref.update(<String, dynamic>{
        'readByListingAt': FieldValue.serverTimestamp(),
        'readByListingUserRef': me,
      });
      _stampDone = true;
    } catch (e) {
      debugPrint('⚠️ Read-receipt stamp skipped: $e');
      // _stampDone stays false → a later snapshot retries.
    } finally {
      _stampInFlight = false;
    }
  }

  // Resolves the listing OWNER's user ref from an assigned-listing ref, whether
  // that ref points at a subby_listings doc (has ownerRef) or a project_listings
  // doc (only has listingRef → follow it to the subby_listings doc).
  Future<DocumentReference?> _resolveListingOwner(
      DocumentReference listingRef) async {
    try {
      final snap = await listingRef.get();
      final d = (snap.data() as Map<String, dynamic>? ?? {});
      final owner = (d['ownerRef'] ?? d['providerRef']) as DocumentReference?;
      if (owner != null) return owner;

      final inner = d['listingRef'] as DocumentReference?;
      if (inner != null) {
        final innerSnap = await inner.get();
        final id = (innerSnap.data() as Map<String, dynamic>? ?? {});
        return (id['ownerRef'] ?? id['providerRef']) as DocumentReference?;
      }
    } catch (e) {
      debugPrint('⚠️ resolve listing owner failed: $e');
    }
    return null;
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.safePop();
    }
  }

  // ✅ Is the signed-in user the one who created this task?
  bool _isOwner(Map<String, dynamic> d) {
    final me = currentUserReference;
    if (me == null) return false;
    final createdByRef = d['createdBy'] as DocumentReference?;
    if (createdByRef != null) return createdByRef.path == me.path;
    // Fallback for older records that only stored a name.
    final createdByName = (d['createdByName'] ?? '').toString().trim();
    final myName = (currentUserDisplayName).trim();
    return createdByName.isNotEmpty &&
        myName.isNotEmpty &&
        createdByName == myName;
  }

  // =========================================================
  // Labels / colors
  // =========================================================
  String _statusLabel(String s) {
    switch (s) {
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Done';
      case 'todo':
      default:
        return 'To Do';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'in_progress':
        return _paper; // white on solid green
      case 'done':
        return _faint;
      case 'todo':
      default:
        return _ink;
    }
  }

  Color _statusTint(String s) {
    switch (s) {
      case 'in_progress':
        return _green; // solid green fill
      case 'done':
        return _surface;
      case 'todo':
      default:
        return _tealTint; // neutral surface
    }
  }

  String _priorityLabel(String s) {
    switch (s) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      case 'med':
      default:
        return 'Medium';
    }
  }

  Color _priorityColor(String s) =>
      s == 'high' ? _live : (s == 'low' ? _faint : _teal);
  Color _priorityTint(String s) => s == 'high'
      ? const Color(0x33CC4B3C)
      : (s == 'low' ? _surface : _tealTint);

  Widget _softPill(String text,
      {required Color fg, required Color bg, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(text,
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ],
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
  // Mutations
  // =========================================================
  Future<void> _setStatus(String next, {Map<String, dynamic>? extra}) async {
    final ref = _taskRef;
    if (ref == null || _working) return;
    setState(() => _working = true);
    try {
      await ref.update(<String, dynamic>{
        'status': next,
        if (next == 'in_progress') 'startedAt': FieldValue.serverTimestamp(),
        if (next == 'done') 'doneAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?extra,
      });
      if (mounted) _toast('Task updated.'); // ✅ update snackbar
    } catch (e) {
      debugPrint('🔥 Task status update failed: $e');
      _toast('Could not update. Please try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _toggleChecklist(
      List<Map<String, dynamic>> checklist, int index) async {
    final ref = _taskRef;
    if (ref == null) return;
    final updated = checklist
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    updated[index]['done'] = !(updated[index]['done'] == true);
    try {
      await ref.update(<String, dynamic>{
        'checklist': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _toast('Task updated.'); // ✅ update snackbar
    } catch (e) {
      debugPrint('🔥 Checklist toggle failed: $e');
    }
  }

  // ✅ Mark as done — now uses the shared centred "warning"-style dialog,
  // recoloured GREEN, with an optional completion note.
  Future<void> _markDone() async {
    final ref = _taskRef;
    if (ref == null || _working) return;
    FocusScope.of(context).unfocus();

    final controller = TextEditingController();
    final confirmed = await _showCompleteDialog(controller: controller);

    if (confirmed != true) return;
    await _setStatus('done', extra: {
      'completionNote': controller.text.trim(),
      'doneBy': currentUserReference,
    });
  }

  // Centred affirmative confirm dialog — the shared "warning" module in GREEN
  // (mirrors _showDeleteDialog: green badge, 22-radius card, filled green
  // confirm + outlined cancel, 55%-black scrim) plus a completion-note field.
  Future<bool?> _showCompleteDialog(
      {required TextEditingController controller}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          child: Container(
            width: 322,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 54,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _green.withOpacity(0.24), width: 1),
                  ),
                  child: const Icon(Icons.task_alt_rounded,
                      color: _green, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mark as done?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontSize: 18,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This task moves to Done. Add a completion note if you like.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    fontSize: 14,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  cursorColor: _green,
                  style: const TextStyle(
                      fontFamily: _bodyFont, fontSize: 14, color: _navy),
                  decoration: InputDecoration(
                    hintText: 'e.g. Done — photos attached',
                    hintStyle: const TextStyle(
                        fontFamily: _bodyFont, color: _faint, fontSize: 14),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Mark done',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFCDD6E2), width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: _ink,
        content: Text(msg,
            style: const TextStyle(
                fontFamily: _bodyFont,
                color: _paper,
                fontWeight: FontWeight.w700)),
      ));
  }

  // =========================================================
  // Build
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (_refLoading) {
      return _shell(
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_teal)),
          ),
        ),
      );
    }

    final ref = _taskRef;
    if (ref == null) {
      return _shell(
        child: Padding(
          padding: const EdgeInsets.all(_hPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _minBack(),
              const SizedBox(height: 18),
              const Text('No task selected',
                  style: TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _ink)),
              const SizedBox(height: 6),
              const Text('Open this page from a task in the list.',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _faint)),
            ],
          ),
        ),
      );
    }

    return _shell(
      child: StreamBuilder<DocumentSnapshot<Object?>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_teal)),
              ),
            );
          }
          final raw = snap.data?.data();
          final d = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          // Retry the read-receipt stamp off the live snapshot (auth + Firestore
          // are warm once data has arrived) until it conclusively resolves.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _maybeStampReadReceipt(ref, d));
          return _content(ref, d);
        },
      ),
    );
  }

  Widget _shell({required Widget child}) => Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: _paper,
        child: SafeArea(top: true, bottom: true, child: child),
      );

  Widget _minBack() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _hairline)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: _inkMute),
          ),
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 21, color: color),
          ),
        ),
      );

  Widget _content(DocumentReference ref, Map<String, dynamic> d) {
    final title = (d['title'] ?? 'Task').toString();
    final description = (d['description'] ?? '').toString();
    final status = (d['status'] ?? 'todo').toString();
    final priority = (d['priority'] ?? 'med').toString();
    final listingName = (d['assignedListingName'] ?? '').toString();
    final isOwner = _isOwner(d); // ✅ gate Delete

    final checklist = <Map<String, dynamic>>[];
    final rawCl = d['checklist'];
    if (rawCl is List) {
      for (final c in rawCl) {
        if (c is Map) checklist.add(Map<String, dynamic>.from(c));
      }
    }
    final doneCount = checklist.where((c) => c['done'] == true).length;

    final attachments = <Map<String, dynamic>>[];
    final rawAtt = d['attachments'];
    if (rawAtt is List) {
      for (final a in rawAtt) {
        if (a is Map) attachments.add(Map<String, dynamic>.from(a));
      }
    }

    final due = _asDate(d['dueDate']);
    final readAt = _asDate(d['readByListingAt']);
    final createdByName = (d['createdByName'] ?? '').toString();
    final createdAt = _asDate(d['createdAt']);
    final completionNote = (d['completionNote'] ?? '').toString();

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_hPad, 6, _hPad, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _minBack(),
                  // ✅ Only the task's creator can delete it. (Edit removed.)
                  if (isOwner)
                    _iconBtn(Icons.delete_outline_rounded, _coral,
                        () => _confirmDelete(ref, title))
                  else
                    const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.15,
                      color: _navy)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _softPill(_statusLabel(status),
                      fg: _statusColor(status),
                      bg: _statusTint(status),
                      icon: status == 'in_progress'
                          ? Icons.play_arrow_rounded
                          : (status == 'done'
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked)),
                  const SizedBox(width: 8),
                  _softPill(_priorityLabel(priority),
                      fg: _priorityColor(priority),
                      bg: _priorityTint(priority)),
                ],
              ),
              const SizedBox(height: 14),
              // Due
              _metaRow(
                leading: const Icon(Icons.calendar_month_outlined,
                    size: 19, color: _faint),
                title: due == null
                    ? 'No due date'
                    : dateTimeFormat('d MMM y', due),
                trailingLabel: _dueHint(due, status),
                trailingColor: _dueColor(due, status),
              ),
              // Team member + read receipt
              if (listingName.trim().isNotEmpty)
                _assignedListingRow(listingName, readAt),
              // Checklist
              if (checklist.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CHECKLIST',
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            color: _inkMute,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                    Text('$doneCount of ${checklist.length}',
                        style: const TextStyle(
                            fontFamily: _bodyFont,
                            color: _teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: checklist.isEmpty ? 0 : doneCount / checklist.length,
                    minHeight: 6,
                    backgroundColor: _surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(_teal),
                  ),
                ),
                for (int i = 0; i < checklist.length; i++)
                  _checklistRow(checklist, i),
              ],
              // Attachments
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('ATTACHMENTS',
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        color: _inkMute,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final a in attachments) _attachThumb(a)],
                ),
              ],
              // Description
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(description,
                    style: const TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: _inkMute)),
              ],
              // Footer meta
              const SizedBox(height: 12),
              Text(
                createdByName.isEmpty
                    ? 'Added ${createdAt == null ? '' : dateTimeFormat('d MMM', createdAt)}'
                    : 'Added by $createdByName${createdAt == null ? '' : ' · ${dateTimeFormat('d MMM', createdAt)}'}',
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _faint),
              ),
              if (status == 'done' && completionNote.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: _green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(completionNote,
                            style: const TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _inkMute)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _dock(status)),
      ],
    );
  }

  Widget _metaRow({
    required Widget leading,
    required String title,
    String? trailingLabel,
    Color? trailingColor,
    bool divider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _hairline, width: 1)))
          : null,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
          ),
          if (trailingLabel != null && trailingLabel.isNotEmpty)
            Text(trailingLabel,
                style: TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trailingColor ?? _faint)),
        ],
      ),
    );
  }

  // Assigned LISTING row + green read receipt (Read … / Not read yet).
  Widget _assignedListingRow(String name, DateTime? readAt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline, width: 1))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _tealTint, borderRadius: BorderRadius.circular(9)),
            child: Text(_initials(name),
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _navy)),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded, size: 14, color: _teal),
                  ],
                ),
                if (readAt != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // ✅ Read receipt is GREEN — the listing has viewed it.
                      const Icon(Icons.done_all_rounded,
                          size: 14, color: _green),
                      const SizedBox(width: 5),
                      Text('Read ${dateTimeFormat('d MMM · HH:mm', readAt)}',
                          style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _green)),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.remove_done_rounded,
                          size: 14, color: _faint),
                      const SizedBox(width: 5),
                      const Text('Not read yet',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _faint)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Text('Team member',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _faint)),
        ],
      ),
    );
  }

  Widget _personRow(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline, width: 1))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: _surface, shape: BoxShape.circle),
            child: Text(_initials(name),
                style: const TextStyle(
                    fontFamily: _displayFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _inkMute)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _navy)),
          ),
          const Text('Assignee',
              style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _faint)),
        ],
      ),
    );
  }

  Widget _checklistRow(List<Map<String, dynamic>> checklist, int i) {
    final done = checklist[i]['done'] == true;
    final text = (checklist[i]['text'] ?? '').toString();
    return InkWell(
      onTap: () => _toggleChecklist(checklist, i),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 20,
              color: done ? _teal : const Color(0xFFC7D0DA),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: done ? _faint : _navy,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachThumb(Map<String, dynamic> a) {
    final isImage = (a['type'] ?? 'file') == 'image';
    final url = (a['url'] ?? '').toString();
    final name = (a['name'] ?? 'file').toString();
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toUpperCase()
        : 'FILE';
    return GestureDetector(
      onTap: () {
        if (url.isNotEmpty) launchURL(url);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hairlineOnSurface),
          image: (isImage && url.isNotEmpty)
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
        ),
        child: isImage
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_rounded,
                      size: 18, color: _inkMute),
                  const SizedBox(height: 2),
                  Text(ext,
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: _faint)),
                ],
              ),
      ),
    );
  }

  // ---- Dock: stepper + action ----
  Widget _dock(String status) {
    return Container(
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: _hairline, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepper(status),
            const SizedBox(height: 12),
            _primaryAction(status),
            if (status == 'in_progress') ...[
              const SizedBox(height: 8),
              const Text('Add a completion note (optional) when you finish',
                  style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _faint)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepper(String status) {
    final idx = status == 'done' ? 2 : (status == 'in_progress' ? 1 : 0);
    Widget node(String label, int i) {
      final active = i <= idx;
      return Text(label,
          style: TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? _teal : const Color(0xFFC7D0DA)));
    }

    Widget bar(bool active) => Expanded(
          child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: active ? _teal : _hairline),
        );

    return Row(
      children: [
        node('To Do', 0),
        bar(idx >= 1),
        Row(
          children: [
            if (idx == 1)
              Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                      color: _teal, shape: BoxShape.circle)),
            node('In Progress', 1),
          ],
        ),
        bar(idx >= 2),
        node('Done', 2),
      ],
    );
  }

  Widget _primaryAction(String status) {
    String label;
    IconData icon;
    VoidCallback onTap;
    Color bg = _teal;

    switch (status) {
      case 'todo':
        label = 'Start Task';
        icon = Icons.play_arrow_rounded;
        onTap = () => _setStatus('in_progress');
        break;
      case 'in_progress':
        label = 'Mark as Done';
        icon = Icons.task_alt_rounded;
        onTap = _markDone;
        break;
      case 'done':
      default:
        label = 'Reopen Task';
        icon = Icons.replay_rounded;
        bg = _surface;
        onTap = () => _setStatus('todo', extra: {'completionNote': ''});
        break;
    }

    final isGhost = status == 'done';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _working ? null : onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Opacity(
          opacity: _working ? 0.7 : 1,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_radius),
              border: isGhost ? Border.all(color: _hairlineOnSurface) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_working)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isGhost ? _ink : _paper)),
                  )
                else
                  Icon(icon, size: 20, color: isGhost ? _ink : _paper),
                const SizedBox(width: 9),
                Text(label,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isGhost ? _ink : _paper)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Delete — shared "delete warning" dialog (clay): centred card, clay badge,
  // 22-radius, filled clay confirm + outlined cancel, 55%-black scrim.
  // =========================================================
  Future<void> _confirmDelete(DocumentReference ref, String title) async {
    FocusScope.of(context).unfocus();
    await _showDeleteDialog(
      icon: Icons.delete_rounded,
      title: 'Delete this task?',
      message: '“$title” will be permanently removed. This can’t be undone.',
      confirmLabel: 'Delete task',
      onConfirm: () => _deleteTask(ref),
    );
  }

  Future<void> _deleteTask(DocumentReference ref) async {
    try {
      await ref.delete();
      if (!mounted) return;
      _toast('Task deleted.'); // ✅ delete snackbar
      _handleBack();
    } catch (e) {
      debugPrint('🔥 Delete task failed: $e');
      if (mounted) _toast('Could not delete. Please try again.');
    }
  }

  // Centred destructive confirm dialog — shared "delete warning" module.
  Future<void> _showDeleteDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 34),
          child: Container(
            width: 322,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 54,
                  offset: const Offset(0, 22),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _coral.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _coral.withOpacity(0.22), width: 1),
                  ),
                  child: Icon(icon, color: _coral, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _displayFont,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    fontSize: 18,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    fontSize: 14,
                    color: _inkMute,
                  ),
                ),
                const SizedBox(height: 22),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await onConfirm();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _coral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _paper,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFCDD6E2), width: 1.4),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- helpers ----
  DateTime? _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String _dueHint(DateTime? due, String status) {
    if (due == null) return '';
    if (status == 'done') return 'Done';
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days < 0) return 'Overdue ${-days}d';
    if (days == 0) return 'Due today';
    return 'Due in ${days}d';
  }

  Color _dueColor(DateTime? due, String status) {
    if (due == null || status == 'done') return _faint;
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    return days < 0 ? _live : (days == 0 ? _teal : _faint);
  }
}
