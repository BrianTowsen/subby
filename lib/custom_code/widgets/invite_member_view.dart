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

/// InviteMemberView — invite people onto a project WITHOUT them registering
/// a listing on the Network/Directory (office staff, the homeowner/client).
///
/// Generates a short join code (e.g. SUB-4K7KQ2) via the createProjectInvite
/// cloud function. The invitee installs Subby, signs in, and redeems the code
/// (More → Join a project, or JoinProjectView). Membership itself is only
/// ever created server-side by claimProjectInvite.
///
/// Use [showInviteMemberSheet] to present this as a bottom sheet from the
/// Project Team section.

import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// FlutterFlow-embeddable wrapper. Reads the active project from shared
/// preferences (same contract as InviteView) when used as a page widget.
class InviteMemberView extends StatefulWidget {
  const InviteMemberView({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  State<InviteMemberView> createState() => _InviteMemberViewState();
}

class _InviteMemberViewState extends State<InviteMemberView> {
  static const String _kActiveProjectPath = 'subby_active_project_path';

  DocumentReference? _projectRef;
  String _projectName = 'Project';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isNotEmpty) {
      final ref = FirebaseFirestore.instance.doc(path);
      try {
        final snap = await ref.get();
        final d = snap.data() as Map<String, dynamic>? ?? const {};
        _projectName = (d['name'] ?? d['projectName'] ?? 'Project').toString();
      } catch (_) {}
      _projectRef = ref;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 1.8),
        ),
      );
    }
    if (_projectRef == null) {
      return const Center(
        child: Text('No active project selected.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
      );
    }
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: _InviteMemberSheet(
        projectRef: _projectRef!,
        projectName: _projectName,
        embedded: true,
      ),
    );
  }
}

/// Update this once a web landing / app link for invites exists.
const String kSubbyInviteHint = 'Open Subby → More → Join a project';

/// Opens the invite flow as a bottom sheet (used by the ADMIN tiles'
/// manage sheet). Pass [fixedRole] ('office' | 'client' | 'provider') to
/// lock the role and hide the picker; [showPendingList] hides the pending
/// invites list when the caller (AdminMembersView) already shows it.
Future<void> showInviteMemberSheet(
  BuildContext context, {
  required DocumentReference projectRef,
  String? projectName,
  String? fixedRole,
  bool showPendingList = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _InviteMemberSheet(
        projectRef: projectRef,
        projectName: projectName ?? 'Project',
        fixedRole: fixedRole,
        showPendingList: showPendingList,
      ),
    ),
  );
}

class _InviteMemberSheet extends StatefulWidget {
  const _InviteMemberSheet({
    required this.projectRef,
    required this.projectName,
    this.fixedRole,
    this.showPendingList = true,
    this.embedded = false,
  });

  final DocumentReference projectRef;
  final String projectName;
  final String? fixedRole;
  final bool showPendingList;
  final bool embedded;

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
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

  String _role = 'office';
  bool _canViewCost = false;
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _companyCtl = TextEditingController();

  bool get _isProvider => _role == 'provider';
  bool get _roleLocked => widget.fixedRole != null;

  @override
  void initState() {
    super.initState();
    if (widget.fixedRole != null) _role = widget.fixedRole!;
  }

  bool _creating = false;
  String? _error;

  // Result state
  String? _code;
  String? _invitePath;

  @override
  void dispose() {
    _nameCtl.dispose();
    _companyCtl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_creating) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createProjectInvite');
      final result = await callable.call(<String, dynamic>{
        'projectPath': widget.projectRef.path,
        'role': _role,
        'permissions': {'viewCost': _canViewCost},
        'inviteeName': _nameCtl.text.trim(),
        'displayCompany': (_role == 'office' || _role == 'foreman')
            ? _companyCtl.text.trim()
            : '',
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      setState(() {
        _code = (data['code'] ?? '').toString();
        _invitePath = (data['invitePath'] ?? '').toString();
        _creating = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = e.message ?? 'Could not create the invite.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = 'Could not create the invite. Please try again.';
      });
    }
  }

  String get _shareMessage {
    final who = _nameCtl.text.trim();
    final greet = who.isEmpty ? 'Hi!' : 'Hi $who!';
    if (_isProvider) {
      return '$greet You’ve been invited to join the team on '
          '“${widget.projectName}” via Subby. Sign in to the Subby app '
          '(register your business on the Network if you haven’t yet), '
          'then: $kSubbyInviteHint and enter this code: $_code '
          '(valid 14 days).';
    }
    return '$greet You’ve been added to “${widget.projectName}” '
        'on Subby. Sign in to the Subby app, then: $kSubbyInviteHint and '
        'enter this code: $_code (valid 14 days).';
  }

  Future<void> _copyCode() async {
    final c = _code;
    if (c == null) return;
    await Clipboard.setData(ClipboardData(text: c));
    if (!mounted) return;
    showAppToast(context, 'Code copied.', true);
  }

  Future<void> _shareWhatsApp() async {
    final uri =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_shareMessage)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _shareMessage));
      if (!mounted) return;
      showAppToast(context, 'Message copied — paste it anywhere.', true);
    }
  }

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: _shareMessage));
    if (!mounted) return;
    showAppToast(context, 'Invite message copied.', true);
  }

  Future<void> _revoke(DocumentReference inviteRef) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('revokeProjectInvite')
          .call(<String, dynamic>{'invitePath': inviteRef.path});
      if (!mounted) return;
      showAppToast(context, 'Invite revoked.', true);
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Could not revoke the invite.', false);
    }
  }

  // ── UI pieces ──────────────────────────────────────────────────────

  Widget _sheetShell({required Widget child}) {
    final content = Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: widget.embedded
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: child,
    );
    if (widget.embedded) return SingleChildScrollView(child: content);
    return SafeArea(top: false, child: SingleChildScrollView(child: content));
  }

  Widget _grabber() => widget.embedded
      ? const SizedBox.shrink()
      : Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: _faint,
          ),
        ),
      );

  Widget _roleChip({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? _spark.withOpacity(0.22) : _surface,
            border: Border.all(
              color: selected ? _sparkInk : Colors.transparent,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: _ink),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  )),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: _inkMute,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: _bodyFont,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: _faint,
        ),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );

  Widget _pendingInvites() {
    if (!widget.showPendingList) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('project_invites')
          .where('projectRef', isEqualTo: widget.projectRef)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        var docs = snap.data?.docs ?? const [];
        if (widget.fixedRole != null) {
          docs = docs
              .where((d) => (d.data()['role'] ?? '') == widget.fixedRole)
              .toList();
        }
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            _label('Pending invites'),
            ...docs.map((d) {
              final data = d.data();
              final code = (data['code'] ?? '').toString();
              final role = (data['role'] ?? '').toString();
              final name = (data['inviteeName'] ?? '').toString().trim();
              final roleLabel = role == 'office'
                  ? 'Office / team'
                  : role == 'foreman'
                      ? 'Site foreman'
                      : role == 'client'
                          ? 'Client (view-only)'
                          : role == 'provider'
                              ? 'Service provider'
                              : role;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: _hairline, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? code : '$name · $code',
                            style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleLabel,
                            style: const TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _revoke(d.reference),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: _warn),
                      tooltip: 'Revoke invite',
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _formView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(),
        Text(_isProvider ? 'Invite a service provider' : 'Invite to project',
            style: const TextStyle(
              fontFamily: _displayFont,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _ink,
            )),
        const SizedBox(height: 3),
        Text(
          _isProvider
              ? 'They join the project team with their Subby Network '
                  'listing. If they aren’t registered yet, the code walks '
                  'them through registration first.'
              : 'They only need a Subby login — no Network listing required.',
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: _inkMute,
          ),
        ),
        const SizedBox(height: 18),
        if (!_roleLocked) ...[
          _label('Role'),
          Row(children: [
            _roleChip(
              value: 'office',
              title: 'Office / Team',
              subtitle: 'Tasks, site book, snags, documents & quotes.',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(width: 10),
            _roleChip(
              value: 'client',
              title: 'Client / Owner',
              subtitle: 'Follows progress: timeline & documents, view-only.',
              icon: Icons.visibility_outlined,
            ),
          ]),
          const SizedBox(height: 16),
        ],
        if (!_isProvider) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Can view costs',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        )),
                    SizedBox(height: 2),
                    Text('Project cost & quote amounts stay hidden unless on.',
                        style: TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _faint,
                        )),
                  ],
                ),
              ),
              Switch(
                value: _canViewCost,
                activeColor: _sparkInk,
                activeTrackColor: _spark,
                onChanged: (v) => setState(() => _canViewCost = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        _label('Their name (optional)'),
        TextField(
          controller: _nameCtl,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          decoration: _fieldDecoration(_isProvider
              ? 'e.g. Piet from ABC Plumbing'
              : 'e.g. Jane from the office'),
        ),
        if (_role == 'office' || _role == 'foreman') ...[
          const SizedBox(height: 14),
          _label('Acting for (company shown on their updates)'),
          TextField(
            controller: _companyCtl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            decoration: _fieldDecoration('e.g. BuildCo Construction'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(
                fontFamily: _bodyFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _warn,
              )),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _creating ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: _spark,
              foregroundColor: _sparkInk,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(_sparkInk),
                    ),
                  )
                : const Text('Create invite code',
                    style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: _sparkInk,
                    )),
          ),
        ),
        _pendingInvites(),
      ],
    );
  }

  Widget _codeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(),
        Text('Invite ready',
            style: const TextStyle(
              fontFamily: _displayFont,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _ink,
            )),
        const SizedBox(height: 3),
        Text(
          'Share this code. It’s valid for 14 days and works once.',
          style: const TextStyle(
            fontFamily: _bodyFont,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _inkMute,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _copyCode,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _spark.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _spark, width: 1.2),
            ),
            child: Column(
              children: [
                Text(_code ?? '',
                    style: const TextStyle(
                      fontFamily: _displayFont,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                      color: _ink,
                    )),
                const SizedBox(height: 6),
                const Text('Tap to copy',
                    style: TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _inkMute,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _shareWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: _paper,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 17),
                  label: const Text('WhatsApp',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _copyMessage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _hairline, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy message',
                      style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _code = null;
              _invitePath = null;
              _nameCtl.clear();
            }),
            child: const Text('Create another invite',
                style: TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _inkMute,
                )),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sheetShell(child: _code == null ? _formView() : _codeView());
  }
}
