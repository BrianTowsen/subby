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
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  // Synced with DashboardPageView / AddProjectsPageView (flat teal system).
  // Inline = authoritative for this file. Grep `SUBBY PALETTE (LOCK)` to sync.
  //
  // Neutrals
  static const Color _ink = Color(0xFF017374); // text, chrome, accent
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _faint = Color(0xFF93A0B0);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFEEF1F4);
  static const Color _hairline = Color(0xFFEEF1F2);
  static const Color _hairlineOnSurface = Color(0xFFE2E7EE);
  // Brand accent — TEAL.
  static const Color _teal = Color(0xFF017374);
  static const Color _tealTint = Color(0xFFE3F4F2);
  // Status
  static const Color _live = Color(0xFFE5771E); // orange — spent / paid
  // Type
  static const String _displayFont = 'Inter Tight';
  static const String _bodyFont = 'Inter';
  static const String _monoFont = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  static const double _hPad = 24;
  static const double _vPad = 14;
  static const double _radius = 12;
  static const double _gap = 12;

  static const double _sliverTopGap = 4;
  static const double _stickyTabsHeight = 58;
  static const double _contentHPad = _hPad;

  static const String _kActiveProjectPath = 'subby_active_project_path';

  late TabController _tabController;

  DocumentReference? _projectRef;

  final Set<String> _expandedCategoryKeysBudget = {};

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

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  Color _projectCostColor(FlutterFlowTheme theme) {
    try {
      final c = (theme as dynamic).projectCostColour as Color?;
      return c ?? _ink;
    } catch (_) {
      return _ink;
    }
  }

  // =========================================================
  // ✅ TYPOGRAPHY (flat teal system)
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

  TextStyle _uLabel(FlutterFlowTheme t) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: _inkMute,
      );

  TextStyle _rowTitleStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: _ink,
      );

  TextStyle _rowMetaStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _faint,
      );

  TextStyle _moneyStyle(FlutterFlowTheme theme) => const TextStyle(
        fontFamily: _displayFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _ink,
      );

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

  Widget _flatCard(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(14), Color? fill}) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: fill ?? _paper,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _hairline),
        ),
        child: child,
      );

  Widget _progressBar(double value, Color fill) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: v,
          backgroundColor: _surface,
          valueColor: AlwaysStoppedAnimation<Color>(fill),
        ),
      ),
    );
  }

  Widget _softPill(String text, {required Color fg, required Color bg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: const TextStyle(
              fontFamily: _bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ).copyWith(color: fg)),
      );

  // -----------------------------
  // Underline tabs
  // -----------------------------
  Widget _buildTabs(FlutterFlowTheme theme, Color accent) {
    return Container(
      color: _paper,
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      alignment: Alignment.bottomLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.only(right: 24),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: _teal,
        indicatorWeight: 2,
        dividerColor: _hairlineOnSurface,
        labelColor: _teal,
        unselectedLabelColor: _faint,
        labelStyle: theme.bodyMedium.override(
            fontFamily: _bodyFont, fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: theme.bodyMedium.override(
            fontFamily: _bodyFont, fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Budget'),
          Tab(text: 'Invoices'),
          Tab(text: 'Spend'),
        ],
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
        icon: Icons.description_outlined,
        lines: [
          _CostLine('Architect / drawings', 14500.0, 1.0),
          _CostLine('Municipal permits', 6200.0, 1.0),
          _CostLine('Engineering', 9800.0, 0.55),
        ],
      ),
      _CostCategory(
        key: 'site',
        title: 'Site Prep',
        icon: Icons.construction_outlined,
        lines: [
          _CostLine('Site clearing', 9800.0, 1.0),
          _CostLine('Temporary fencing', 7200.0, 0.4),
          _CostLine('Skip / rubble removal', 2600.0, 0.2),
        ],
      ),
      _CostCategory(
        key: 'foundation',
        title: 'Foundations',
        icon: Icons.foundation_outlined,
        lines: [
          _CostLine('Excavation', 20000.0, 0.3),
          _CostLine('Concrete work', 24000.0, 0.0),
          _CostLine('Rebar & steel', 11600.0, 0.0),
        ],
      ),
      _CostCategory(
        key: 'structure',
        title: 'Structure',
        icon: Icons.account_tree_outlined,
        lines: [
          _CostLine('Bricks / blocks', 48200.0, 0.0),
          _CostLine('Labour (structure)', 34200.0, 0.0),
        ],
      ),
    ];
  }

  List<_InvoiceItem> _mockInvoices() {
    return [
      _InvoiceItem('Architect Invoice #102', 'Studio North', 8500.0,
          DateTime(2026, 1, 7), true),
      _InvoiceItem('Site Clearing Invoice #44', 'Cape Earthworks', 9800.0,
          DateTime(2026, 1, 14), true),
      _InvoiceItem('Temporary Fencing Deposit', 'SecureFence', 1800.0,
          DateTime(2026, 1, 16), false),
      _InvoiceItem('Excavation Progress Claim', 'Cape Earthworks', 6000.0,
          DateTime(2026, 1, 23), false),
    ];
  }

  List<_SpendTx> _mockSpend() {
    return [
      _SpendTx('Cement bags (x20)', 'BuildIt', 2380.0, DateTime(2026, 1, 21),
          'Foundations'),
      _SpendTx('Rebar offcut', 'SteelMart', 640.0, DateTime(2026, 1, 22),
          'Foundations'),
      _SpendTx('Site consumables', 'Builders Warehouse', 420.0,
          DateTime(2026, 1, 18), 'Site Prep'),
      _SpendTx('Transport / delivery', 'Courier', 280.0, DateTime(2026, 1, 18),
          'Site Prep'),
    ];
  }

  // -----------------------------
  // Clean stat tile (bordered, no shadow)
  // -----------------------------
  Widget _statTile(FlutterFlowTheme theme,
      {required String label,
      required String value,
      required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleLarge.override(
              fontFamily: _displayFont,
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  fontFamily: _bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _faint)),
        ],
      ),
    );
  }

  Widget _buildTopSummary(FlutterFlowTheme theme, Color accent) {
    final cats = _mockBudgetCategories();
    final totalBudget = cats.fold<double>(0.0,
        (sum, c) => sum + c.lines.fold<double>(0.0, (s, l) => s + l.amount));
    final committed = cats.fold<double>(
        0.0,
        (sum, c) =>
            sum +
            c.lines.fold<double>(0.0, (s, l) => s + (l.amount * l.progress)));
    final spent = _mockSpend().fold<double>(0.0, (s, t) => s + t.amount);
    final remaining = (totalBudget - spent).clamp(0.0, double.infinity);
    final budgetProgress =
        totalBudget <= 0 ? 0.0 : (spent / totalBudget).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _statTile(theme,
                      label: 'Budget',
                      value: _money(totalBudget),
                      valueColor: _teal)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile(theme,
                      label: 'Spent', value: _money(spent), valueColor: _live)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _statTile(theme,
                      label: 'Committed',
                      value: _money(committed),
                      valueColor: _teal)),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile(theme,
                      label: 'Remaining',
                      value: _money(remaining),
                      valueColor: _teal)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _progressBar(budgetProgress, _teal)),
              const SizedBox(width: 10),
              Text('${_pct(budgetProgress)} used',
                  style: const TextStyle(
                      fontFamily: _bodyFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _faint)),
            ],
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
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      children: [
        _buildTopSummary(theme, accent),
        Padding(
          padding: const EdgeInsets.fromLTRB(_contentHPad, 22, _contentHPad, 4),
          child: Text('CATEGORIES', style: _uLabel(theme)),
        ),
        ...List.generate(cats.length, (i) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                _contentHPad, i == 0 ? 4 : _gap, _contentHPad, 0),
            child: _buildCategoryCardBudget(theme, accent, cats[i]),
          );
        }),
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

    return _flatCard(
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
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
                  Icon(c.icon, color: _teal, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: _rowTitleStyle(theme)),
                        const SizedBox(height: 3),
                        Text('${_money(committed)} of ${_money(total)}',
                            style: _rowMetaStyle(theme)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(_pct(prog),
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _teal)),
                  const SizedBox(width: 6),
                  Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _faint),
                ],
              ),
              const SizedBox(height: 12),
              _progressBar(prog, _teal),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                Container(height: 1, color: _hairlineOnSurface),
                ...c.lines.map((l) => _buildBudgetLine(theme, l)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetLine(FlutterFlowTheme theme, _CostLine line) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(line.title,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink)),
          ),
          const SizedBox(width: 10),
          Text(_money(line.amount), style: _moneyStyle(theme)),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(_pct(line.progress),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontFamily: _bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _faint)),
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
    final total = invoices.fold<double>(0.0, (s, i) => s + i.amount);
    final paid =
        invoices.where((i) => i.paid).fold<double>(0.0, (s, i) => s + i.amount);
    final outstanding = (total - paid).clamp(0.0, double.infinity);
    final prog = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: _statTile(theme,
                          label: 'Paid',
                          value: _money(paid),
                          valueColor: _live)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statTile(theme,
                          label: 'Outstanding',
                          value: _money(outstanding),
                          valueColor: _teal)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _progressBar(prog, _live)),
                  const SizedBox(width: 10),
                  Text('${_pct(prog)} paid',
                      style: const TextStyle(
                          fontFamily: _bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _faint)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_contentHPad, 8, _contentHPad, 0),
          child: Column(
            children:
                invoices.map((inv) => _buildInvoiceRow(theme, inv)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRow(FlutterFlowTheme theme, _InvoiceItem inv) {
    final c = inv.paid ? _live : _teal;
    final tint = inv.paid ? const Color(0x1FE5771E) : _tealTint;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairlineOnSurface, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
              inv.paid
                  ? Icons.receipt_long_rounded
                  : Icons.receipt_long_outlined,
              color: c,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowTitleStyle(theme)),
                const SizedBox(height: 3),
                Text('${inv.vendor} · ${_fmtDate(inv.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowMetaStyle(theme)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_money(inv.amount), style: _moneyStyle(theme)),
              const SizedBox(height: 6),
              _softPill(inv.paid ? 'Paid' : 'Due', fg: c, bg: tint),
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
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _contentHPad),
          child: _flatCard(
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total spend to date', style: _rowMetaStyle(theme)),
                      const SizedBox(height: 4),
                      Text(_money(total),
                          style: theme.titleLarge.override(
                            fontFamily: _displayFont,
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.payments_outlined, color: _teal, size: 26),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_contentHPad, 8, _contentHPad, 0),
          child: Column(
            children: txs.map((t) => _buildSpendRow(theme, t)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendRow(FlutterFlowTheme theme, _SpendTx t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairlineOnSurface, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: _teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowTitleStyle(theme)),
                const SizedBox(height: 3),
                Text('${t.merchant} · ${t.category} · ${_fmtDate(t.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _rowMetaStyle(theme)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_money(t.amount), style: _moneyStyle(theme)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final accent = _projectCostColor(theme);

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(top: _vPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _minBack(),
                    const SizedBox(height: 18),
                    Text('Project Cost', style: _pageTitle(theme)),
                    const SizedBox(height: 8),
                    Text('Budget, invoices and spend',
                        style: _pageSubtitle(theme)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, inner) {
                    return [
                      const SliverToBoxAdapter(
                          child: SizedBox(height: _sliverTopGap)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              _contentHPad, 0, _contentHPad, 14),
                          child: _projectRef == null
                              ? _flatCard(Text('No project selected.',
                                  style: _rowMetaStyle(theme)))
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
                                    return _flatCard(
                                      Row(
                                        children: [
                                          const Icon(Icons.folder_open_rounded,
                                              color: _teal, size: 22),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        _rowTitleStyle(theme)),
                                                const SizedBox(height: 2),
                                                Text('Cost dashboard',
                                                    style:
                                                        _rowMetaStyle(theme)),
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
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          minHeight: _stickyTabsHeight,
                          maxHeight: _stickyTabsHeight,
                          child: _buildTabs(theme, accent),
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
    return SizedBox.expand(child: child);
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
  final double amount;
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
  final double amount;
  final DateTime date;
  final bool paid;
  _InvoiceItem(this.title, this.vendor, this.amount, this.date, this.paid);
}

class _SpendTx {
  final String title;
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  _SpendTx(this.title, this.merchant, this.amount, this.date, this.category);
}
