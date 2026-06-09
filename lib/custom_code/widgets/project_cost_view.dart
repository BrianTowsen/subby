// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProjectCostView extends StatefulWidget {
  const ProjectCostView({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ProjectCostView> createState() => _ProjectCostViewState();
}

class _ProjectCostViewState extends State<ProjectCostView>
    with SingleTickerProviderStateMixin {
  static const double _hPad = 24;
  static const double _vPad = 24;
  static const double _radius = 16;
  static const double _gap = 12;

  // ✅ subtle sliver breathing room (no clipping)
  static const double _sliverSidePad = 2;
  static const double _sliverTopGap = 8;

  // ✅ IMPORTANT: sticky header must be tall enough for a shadowed card
  static const double _stickyTabsHeight = 92;

  // ✅ content padding moved INSIDE containers so scrollbar can sit on the edge
  static const double _contentHPad = _hPad + _sliverSidePad;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  late TabController _tabController;

  DocumentReference? _projectRef;

  // Expanded state per section
  final Set<String> _expandedCategoryKeysBudget = {};
  final Set<String> _expandedCategoryKeysInvoices = {};
  final Set<String> _expandedCategoryKeysSpend = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActiveProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString(_kActiveProjectPath) ?? '').trim();
    if (path.isEmpty) return;

    if (mounted) {
      setState(() => _projectRef = FirebaseFirestore.instance.doc(path));
    }
  }

  // -----------------------------
  // Back navigation (safe)
  // -----------------------------
  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  // -----------------------------
  // Theme helpers
  // -----------------------------
  Color _projectCostColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).projectCostColour as Color?;
      return c ?? theme.primary;
    } catch (_) {
      return theme.primary;
    }
  }

  // -----------------------------
  // Typography (token + explicit family)
  // -----------------------------
  TextStyle _titleStyle(FlutterFlowTheme theme) {
    return theme.titleLarge.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    );
  }

  TextStyle _subtitleStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: theme.bodySmallFamily,
      color: theme.secondaryText,
    );
  }

  TextStyle _sectionTitleStyle(FlutterFlowTheme theme) {
    return theme.titleSmall.override(
      fontFamily: theme.titleSmallFamily,
      fontWeight: FontWeight.w800,
      color: theme.primaryText,
    );
  }

  TextStyle _rowTitleStyle(FlutterFlowTheme theme) {
    return theme.bodyMedium.override(
      fontFamily: theme.bodyMediumFamily,
      fontWeight: FontWeight.w900,
      color: theme.primaryText,
    );
  }

  TextStyle _rowMetaStyle(FlutterFlowTheme theme) {
    return theme.bodySmall.override(
      fontFamily: theme.bodySmallFamily,
      color: theme.secondaryText,
    );
  }

  TextStyle _pillTextStyle(FlutterFlowTheme theme) {
    return theme.labelSmall.override(
      fontFamily: theme.labelSmallFamily,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
  }

  // -----------------------------
  // Formatting
  // -----------------------------
  String _fmtDate(DateTime d) => DateFormat('d MMM').format(d);

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final withSep = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'R$withSep';
  }

  String _pct(double v) => '${(v.clamp(0.0, 1.0) * 100).round()}%';

  // ---------------------------------------
  // ✅ Subby card shell (match Timeline)
  // ---------------------------------------
  Widget _subbyCardShell({
    required FlutterFlowTheme theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: theme.alternate.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _divider(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      height: 1.5,
      color: theme.alternate.withOpacity(0.75),
    );
  }

  Widget _pill(
    FlutterFlowTheme theme, {
    required String text,
    required Color bg,
    required Color fg,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(text, style: _pillTextStyle(theme).copyWith(color: fg)),
        ],
      ),
    );
  }

  Widget _progressBar(
    FlutterFlowTheme theme, {
    required double value,
    required Color fillColor,
  }) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: v,
          backgroundColor: theme.alternate.withOpacity(0.55),
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      ),
    );
  }

  // -----------------------------
  // Sticky tabs card
  // -----------------------------
  Widget _buildTabs(FlutterFlowTheme theme, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(6),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: theme.secondaryText,
          labelStyle: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle: theme.bodyMedium.override(
            fontFamily: theme.bodyMediumFamily,
            fontWeight: FontWeight.w800,
          ),
          tabs: const [
            Tab(text: 'Budget'),
            Tab(text: 'Invoices'),
            Tab(text: 'Spend'),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Mock data (UI only)
  // -----------------------------
  List<_CostCategory> _mockBudgetCategories() {
    return const [
      _CostCategory(
        key: 'planning',
        title: 'Planning & Permits',
        icon: Icons.description_rounded,
        lines: [
          _CostLine('Architect / drawings', 14500.0, 1.0),
          _CostLine('Municipal permits', 6200.0, 1.0),
          _CostLine('Engineering', 9800.0, 0.55),
        ],
      ),
      _CostCategory(
        key: 'site',
        title: 'Site Prep',
        icon: Icons.construction_rounded,
        lines: [
          _CostLine('Site clearing', 9800.0, 1.0),
          _CostLine('Temporary fencing', 7200.0, 0.4),
          _CostLine('Skip / rubble removal', 2600.0, 0.2),
        ],
      ),
      _CostCategory(
        key: 'foundation',
        title: 'Foundations',
        icon: Icons.foundation_rounded,
        lines: [
          _CostLine('Excavation', 20000.0, 0.3),
          _CostLine('Concrete work', 24000.0, 0.0),
          _CostLine('Rebar & steel', 11600.0, 0.0),
        ],
      ),
      _CostCategory(
        key: 'structure',
        title: 'Structure',
        icon: Icons.account_tree_rounded,
        lines: [
          _CostLine('Bricks / blocks', 48200.0, 0.0),
          _CostLine('Labour (structure)', 34200.0, 0.0),
        ],
      ),
    ];
  }

  List<_InvoiceItem> _mockInvoices() {
    return [
      _InvoiceItem(
        title: 'Architect Invoice #102',
        vendor: 'Studio North',
        amount: 8500.0,
        date: DateTime(2026, 1, 7),
        paid: true,
      ),
      _InvoiceItem(
        title: 'Site Clearing Invoice #44',
        vendor: 'Cape Earthworks',
        amount: 9800.0,
        date: DateTime(2026, 1, 14),
        paid: true,
      ),
      _InvoiceItem(
        title: 'Temporary Fencing Deposit',
        vendor: 'SecureFence',
        amount: 1800.0,
        date: DateTime(2026, 1, 16),
        paid: false,
      ),
      _InvoiceItem(
        title: 'Excavation Progress Claim',
        vendor: 'Cape Earthworks',
        amount: 6000.0,
        date: DateTime(2026, 1, 23),
        paid: false,
      ),
    ];
  }

  List<_SpendTx> _mockSpend() {
    return [
      _SpendTx(
        title: 'Cement bags (x20)',
        merchant: 'BuildIt',
        amount: 2380.0,
        date: DateTime(2026, 1, 21),
        category: 'Foundations',
      ),
      _SpendTx(
        title: 'Rebar offcut',
        merchant: 'SteelMart',
        amount: 640.0,
        date: DateTime(2026, 1, 22),
        category: 'Foundations',
      ),
      _SpendTx(
        title: 'Site consumables',
        merchant: 'Builders Warehouse',
        amount: 420.0,
        date: DateTime(2026, 1, 18),
        category: 'Site Prep',
      ),
      _SpendTx(
        title: 'Transport / delivery',
        merchant: 'Courier',
        amount: 280.0,
        date: DateTime(2026, 1, 18),
        category: 'Site Prep',
      ),
    ];
  }

  // -----------------------------
  // Summary cards
  // -----------------------------
  Widget _buildTopSummary(FlutterFlowTheme theme, Color accent) {
    final cats = _mockBudgetCategories();
    final totalBudget = cats.fold<double>(
      0.0,
      (sum, c) => sum + c.lines.fold<double>(0.0, (s, l) => s + l.amount),
    );

    final committed = cats.fold<double>(
      0.0,
      (sum, c) =>
          sum +
          c.lines.fold<double>(0.0, (s, l) => s + (l.amount * l.progress)),
    );

    final spent = _mockSpend().fold<double>(0.0, (s, t) => s + t.amount);
    final remaining = (totalBudget - spent).clamp(0.0, double.infinity);

    final budgetProgress =
        totalBudget <= 0 ? 0.0 : (spent / totalBudget).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: _sectionTitleStyle(theme)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryStat(
                    theme: theme,
                    accent: accent,
                    label: 'Budget',
                    value: _money(totalBudget),
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryStat(
                    theme: theme,
                    accent: theme.success,
                    label: 'Spent',
                    value: _money(spent),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryStat(
                    theme: theme,
                    accent: theme.tertiary,
                    label: 'Committed',
                    value: _money(committed),
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryStat(
                    theme: theme,
                    accent: accent,
                    label: 'Remaining',
                    value: _money(remaining),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _progressBar(theme,
                      value: budgetProgress, fillColor: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_pct(budgetProgress)} used',
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat({
    required FlutterFlowTheme theme,
    required Color accent,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _rowMetaStyle(theme)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    fontFamily: theme.bodyMediumFamily,
                    fontWeight: FontWeight.w900,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Budget tab
  // -----------------------------
  Widget _buildBudgetTab(FlutterFlowTheme theme, Color accent) {
    final cats = _mockBudgetCategories();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
      children: [
        const SizedBox(height: 12),
        _buildTopSummary(theme, accent),
        const SizedBox(height: 12),
        Column(
          children: List.generate(cats.length, (i) {
            final c = cats[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i == cats.length - 1 ? 0 : _gap),
              child: _buildCategoryCardBudget(theme, accent, c),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCategoryCardBudget(
      FlutterFlowTheme theme, Color accent, _CostCategory c) {
    final isExpanded = _expandedCategoryKeysBudget.contains(c.key);

    final total = c.lines.fold<double>(0.0, (s, l) => s + l.amount);
    final committed =
        c.lines.fold<double>(0.0, (s, l) => s + (l.amount * l.progress));
    final prog = total <= 0 ? 0.0 : (committed / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCategoryKeysBudget.remove(c.key);
              } else {
                _expandedCategoryKeysBudget.add(c.key);
              }
            });
          },
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(c.icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: _rowTitleStyle(theme)),
                        const SizedBox(height: 4),
                        Text(
                          '${_money(committed)} committed • ${_money(total)} budget',
                          style: _rowMetaStyle(theme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _pill(
                    theme,
                    text: _pct(prog),
                    bg: accent.withOpacity(0.12),
                    fg: accent,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.secondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _progressBar(theme, value: prog, fillColor: accent),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                _divider(theme),
                const SizedBox(height: 10),
                ...c.lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildBudgetLine(theme, accent, l),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetLine(
      FlutterFlowTheme theme, Color accent, _CostLine line) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: theme.alternate.withOpacity(0.9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(line.title, style: _rowTitleStyle(theme)),
              ),
              const SizedBox(width: 10),
              Text(
                _money(line.amount),
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w900,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _progressBar(
                  theme,
                  value: line.progress,
                  fillColor: accent,
                ),
              ),
              const SizedBox(width: 10),
              _pill(
                theme,
                text: _pct(line.progress),
                bg: accent.withOpacity(0.12),
                fg: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Invoices tab
  // -----------------------------
  Widget _buildInvoicesTab(FlutterFlowTheme theme, Color accent) {
    final invoices = _mockInvoices();
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
      children: [
        const SizedBox(height: 12),
        _buildInvoicesSummary(theme, accent, invoices),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
          child: Column(
            children: List.generate(invoices.length, (i) {
              final inv = invoices[i];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i == invoices.length - 1 ? 0 : _gap),
                child: _buildInvoiceCard(theme, accent, inv),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesSummary(
      FlutterFlowTheme theme, Color accent, List<_InvoiceItem> invoices) {
    final total = invoices.fold<double>(0.0, (s, i) => s + i.amount);
    final paid =
        invoices.where((i) => i.paid).fold<double>(0.0, (s, i) => s + i.amount);
    final outstanding = (total - paid).clamp(0.0, double.infinity);
    final prog = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: _subbyCardShell(
        theme: theme,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoices', style: _sectionTitleStyle(theme)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _summaryStat(
                    theme: theme,
                    accent: theme.success,
                    label: 'Paid',
                    value: _money(paid),
                    icon: Icons.verified_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryStat(
                    theme: theme,
                    accent: accent,
                    label: 'Outstanding',
                    value: _money(outstanding),
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _progressBar(theme,
                        value: prog, fillColor: theme.success)),
                const SizedBox(width: 10),
                Text(
                  '${_pct(prog)} paid',
                  style: theme.bodySmall.override(
                    fontFamily: theme.bodySmallFamily,
                    color: theme.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
      FlutterFlowTheme theme, Color accent, _InvoiceItem inv) {
    final pillColor = inv.paid ? theme.success : accent;

    return _subbyCardShell(
      theme: theme,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: pillColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              inv.paid
                  ? Icons.receipt_long_rounded
                  : Icons.receipt_long_outlined,
              color: pillColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowTitleStyle(theme)),
                const SizedBox(height: 4),
                Text(
                  '${inv.vendor} • ${_fmtDate(inv.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _rowMetaStyle(theme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(inv.amount),
                style: theme.bodyMedium.override(
                  fontFamily: theme.bodyMediumFamily,
                  fontWeight: FontWeight.w900,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              _pill(
                theme,
                text: inv.paid ? 'Paid' : 'Due',
                bg: pillColor.withOpacity(0.12),
                fg: pillColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Spend tab
  // -----------------------------
  Widget _buildSpendTab(FlutterFlowTheme theme, Color accent) {
    final txs = _mockSpend();
    txs.sort((a, b) => b.date.compareTo(a.date));

    final total = txs.fold<double>(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
          child: _subbyCardShell(
            theme: theme,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spend', style: _sectionTitleStyle(theme)),
                      const SizedBox(height: 6),
                      Text('Total spend to date', style: _rowMetaStyle(theme)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Text(
                    _money(total),
                    style: theme.titleSmall.override(
                      fontFamily: theme.titleSmallFamily,
                      fontWeight: FontWeight.w900,
                      color: theme.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
          child: Column(
            children: List.generate(txs.length, (i) {
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i == txs.length - 1 ? 0 : _gap),
                child: _buildSpendCard(theme, accent, txs[i]),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendCard(FlutterFlowTheme theme, Color accent, _SpendTx t) {
    return _subbyCardShell(
      theme: theme,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.alternate.withOpacity(0.9)),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowTitleStyle(theme)),
                const SizedBox(height: 4),
                Text(
                  '${t.merchant} • ${t.category} • ${_fmtDate(t.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _rowMetaStyle(theme),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _money(t.amount),
            style: theme.bodyMedium.override(
              fontFamily: theme.bodyMediumFamily,
              fontWeight: FontWeight.w900,
              color: theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Build page
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _projectCostColor(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: theme.primaryBackground,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _handleBack,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.alternate.withOpacity(0.9),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Cost',
                            style: _titleStyle(theme).copyWith(
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Budget, invoices and spend tracking',
                            style: _subtitleStyle(theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, inner) {
                    return [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: _sliverTopGap),
                      ),

                      // Project preview (wired)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: _contentHPad),
                            child: _projectRef == null
                                ? _subbyCardShell(
                                    theme: theme,
                                    child: Text(
                                      'No project selected.',
                                      style: theme.bodyMedium.override(
                                        fontFamily: theme.bodyMediumFamily,
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  )
                                : StreamBuilder<DocumentSnapshot<Object?>>(
                                    stream: _projectRef!.snapshots(),
                                    builder: (context, snap) {
                                      final raw = snap.data?.data();
                                      final data = raw is Map<String, dynamic>
                                          ? raw
                                          : <String, dynamic>{};

                                      final name = (data['name'] ??
                                              data['projectName'] ??
                                              data['title'] ??
                                              'Project')
                                          .toString();

                                      return _subbyCardShell(
                                        theme: theme,
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.14),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                Icons.folder_rounded,
                                                color: accent,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme.titleMedium
                                                        .override(
                                                      fontFamily: theme
                                                          .titleMediumFamily,
                                                      color: theme.primaryText,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Cost dashboard (UI) • Wire Firestore next',
                                                    style: theme.bodySmall
                                                        .override(
                                                      fontFamily:
                                                          theme.bodySmallFamily,
                                                      color:
                                                          theme.secondaryText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),

                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          minHeight: _stickyTabsHeight,
                          maxHeight: _stickyTabsHeight,
                          child: Container(
                            color: theme.primaryBackground,
                            padding: const EdgeInsets.only(bottom: 12),
                            alignment: Alignment.bottomCenter,
                            child: _buildTabs(theme, accent),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBudgetTab(theme, accent),
                      _buildInvoicesTab(theme, accent),
                      _buildSpendTab(theme, accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Sticky header delegate (pinned tabs)
// ============================================================================
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

// ============================================================================
// Mock models (UI only)
// ============================================================================
class _CostLine {
  final String title;
  final double amount; // ✅ double
  final double progress; // 0..1
  const _CostLine(this.title, this.amount, this.progress);
}

class _CostCategory {
  final String key;
  final String title;
  final IconData icon;
  final List<_CostLine> lines;

  const _CostCategory({
    required this.key,
    required this.title,
    required this.icon,
    required this.lines,
  });
}

class _InvoiceItem {
  final String title;
  final String vendor;
  final double amount; // ✅ double
  final DateTime date;
  final bool paid;

  _InvoiceItem({
    required this.title,
    required this.vendor,
    required this.amount,
    required this.date,
    required this.paid,
  });
}

class _SpendTx {
  final String title;
  final String merchant;
  final double amount; // ✅ double
  final DateTime date;
  final String category;

  _SpendTx({
    required this.title,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
  });
}
