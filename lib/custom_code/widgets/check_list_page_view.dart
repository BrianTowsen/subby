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

import 'package:intl/intl.dart';
import '/auth/firebase_auth/auth_util.dart';

/// CheckListPageView — Construction Quality Check List.
///
/// Two screens managed internally: START (first-run template chooser) → LIST
/// (the working checklist). Mirrors ProjectTimelinePageView: pick a floor-config
/// template to load the standard trade sequence, and EVERY trade section becomes
/// a check-list category. Ticking a check stamps who signed it off and when.
class CheckListPageView extends StatefulWidget {
  const CheckListPageView({
    super.key,
    this.width,
    this.height,
    this.projectRef,
    this.projectName,
  });

  final double? width;
  final double? height;
  final DocumentReference? projectRef;
  final String? projectName;

  @override
  State<CheckListPageView> createState() => _CheckListPageViewState();
}

class _Stamp {
  final String by;
  final String at;
  const _Stamp(this.by, this.at);
}

class _CheckListPageViewState extends State<CheckListPageView> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF1E282E);
  static const Color _inkMute = Color(0xFF566670);
  static const Color _faint = Color(0xFF93A3AC);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFECF0F2);
  static const Color _band = Color(0xFFEDF1F3);
  static const Color _border = Color(0xFFEAEEF0);
  static const Color _line = Color(0xFFF2F5F6);
  static const Color _hairlineOnSurface = Color(0xFFDCE3E6);
  static const Color _chevron = Color(0xFFCBD8DD);
  static const Color _selTint = Color(0xFFE7EDF0);
  static const Color _green = Color(0xFF4E504F);
  static const Color _header = Color(0xFF3D4F66);

  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';
  // ────────────────────────────────────────────────────────────────────

  // Accent used for the ticked checkbox fill.
  static const Color _accent = _ink;

  // 'start' | 'list'
  String _screen = 'start';
  String _template = '';
  String _filter = 'all'; // 'all' | 'open' | 'done'

  final Set<String> _done = <String>{}; // "si:ci"
  final Set<int> _collapsed = <int>{}; // si
  final Map<String, _Stamp> _meta = <String, _Stamp>{}; // "si:ci" → who/when

  String get _projectName => (widget.projectName ?? '').trim().isNotEmpty
      ? widget.projectName!.trim()
      : 'Project';

  String get _currentUser {
    final n = (currentUserDisplayName).trim();
    return n.isEmpty ? 'You' : n;
  }

  // =================================================================
  // Templates — trade sequence per floor config (ported from Timeline)
  // =================================================================
  List<String> _sectionsFor(String key) {
    const gf = <String>[
      'Professional Services',
      'Site Preparation',
      'Site Establishment',
      'Earthworks & Excavation',
      'Brickwork & Concrete',
      'Structural Steel Works',
      'Suspended Roof Slab',
      'Roofing',
      'Plumbing & Drainage',
      'Electrical Works',
      'Plastering & Screeds',
      'Windows & Door Frames',
      'Waterproofing',
      'Ceilings & Partitioning',
      'Joinery & Carpentry',
      'Painting & Wall Covering',
      'Tiling',
      'Kitchen (Built-in Units)',
      'Built-in Cupboards',
      'Sanitary Fittings',
      'Floor Covering',
      'Electrical Fittings',
      'External Site Works',
      'Cleaning & Handover',
    ];
    const gf1 = <String>[
      'Professional Services',
      'Site Preparation',
      'Site Establishment',
      'Earthworks & Excavation',
      'Brickwork & Concrete',
      'Structural Steel Works',
      'Suspended Floor Slab',
      'Brickwork & Concrete (First Floor)',
      'Structural Steel Works (First Floor)',
      'Suspended Roof Slab',
      'Roofing',
      'Plumbing & Drainage',
      'Electrical Works',
      'Plastering & Screeds',
      'Windows & Door Frames',
      'Waterproofing',
      'Ceilings & Partitioning',
      'Joinery & Carpentry',
      'Painting & Wall Covering',
      'Tiling',
      'Balustrades & Railings',
      'Kitchen (Built-in Units)',
      'Built-in Cupboards',
      'Sanitary Fittings',
      'Floor Covering',
      'Electrical Fittings',
      'External Site Works',
      'Cleaning & Handover',
    ];
    const lgfgf = <String>[
      'Professional Services',
      'Site Preparation',
      'Site Establishment',
      'Earthworks & Excavation',
      'Shoring & Retaining Walls',
      'Brickwork & Concrete',
      'Structural Steel Works',
      'Suspended Floor Slab',
      'Brickwork & Concrete (Ground Floor)',
      'Structural Steel Works (Ground Floor)',
      'Suspended Roof Slab',
      'Roofing',
      'Plumbing & Drainage',
      'Electrical Works',
      'Plastering & Screeds',
      'Windows & Door Frames',
      'Waterproofing',
      'Ceilings & Partitioning',
      'Joinery & Carpentry',
      'Painting & Wall Covering',
      'Tiling',
      'Balustrades & Railings',
      'Kitchen (Built-in Units)',
      'Built-in Cupboards',
      'Sanitary Fittings',
      'Floor Covering',
      'Electrical Fittings',
      'External Site Works',
      'Cleaning & Handover',
    ];
    const lgfgf1 = <String>[
      'Professional Services',
      'Site Preparation',
      'Site Establishment',
      'Earthworks & Excavation',
      'Shoring & Retaining Walls',
      'Brickwork & Concrete',
      'Structural Steel Works',
      'Suspended Floor Slab 1',
      'Brickwork & Concrete (Ground Floor)',
      'Structural Steel Works (Ground Floor)',
      'Suspended Floor Slab 2',
      'Brickwork & Concrete (First Floor)',
      'Structural Steel Works (First Floor)',
      'Suspended Roof Slab',
      'Roofing',
      'Plumbing & Drainage',
      'Electrical Works',
      'Plastering & Screeds',
      'Windows & Door Frames',
      'Waterproofing',
      'Ceilings & Partitioning',
      'Joinery & Carpentry',
      'Painting & Wall Covering',
      'Tiling',
      'Balustrades & Railings',
      'Kitchen (Built-in Units)',
      'Built-in Cupboards',
      'Sanitary Fittings',
      'Floor Covering',
      'Electrical Fittings',
      'External Site Works',
      'Cleaning & Handover',
    ];
    switch (key) {
      case 'gf':
        return gf;
      case 'gf1':
        return gf1;
      case 'lgfgf':
        return lgfgf;
      case 'lgfgf1':
        return lgfgf1;
      default:
        return const <String>[];
    }
  }

  // Detailed QA checks per trade section (hold-point sub-items prefixed '   – ').
  static const Map<String, List<String>> _sectionChecks = {
    'Professional Services': [
      'Municipal building plans approved & stamped on site',
      'Home enrolled with NHBRC before construction starts',
      'Structural engineer appointed; designs & details issued',
      'Geotechnical report received; site classified (R/H/C/S/P)',
      'Competent-person appointments confirmed in writing',
      'Building contract signed & insurances in place',
    ],
    'Site Preparation': [
      'Site cleared of vegetation; topsoil stripped & stockpiled',
      'Existing structures demolished & rubble removed',
      'Site datum / benchmark established & recorded',
      'Trees & services to be retained protected',
      'Access for delivery vehicles confirmed',
      'Land surveyor: site boundaries & pegs verified against SG diagram',
    ],
    'Site Establishment': [
      'Boundary hoarding / fencing erected & secure',
      'Site board & statutory signage displayed',
      'Temporary water & electrical connection in place',
      'Site office, store & lock-up erected',
      'Ablution facilities provided for workforce',
      'Materials laydown & storage area set out',
      'Setting-out / survey pegs verified against approved plan',
      'Health & Safety file, risk assessment & OHS appointments on site (Construction Regs)',
      'Fall-protection plan in place; roof harnesses, lanyards & anchor points provided',
    ],
    'Earthworks & Excavation': [
      'Foundation trenches to engineer’s depth & width',
      'Founding stratum inspected & approved before pour',
      'Excavations to correct levels; sides shored where needed',
      'Bulk fill placed & compacted in layers',
      'No standing water or loose soil in trenches',
      'Engineer inspection: founding stratum approved before pour',
      'NHBRC inspection: foundations booked & passed',
      'Municipal inspection: foundation / trench passed',
      'Minimum foundation wall height achieved (≥150mm brickwork below DPC / to NHBRC & engineer detail)',
      'Soil poisoning / termite treatment applied to trenches & under surface bed',
      'Foundation concrete cubes taken & tested (strength records kept)',
    ],
    'Brickwork & Concrete': [
      'Foundation concrete mix & strength per spec',
      'DPC laid & lapped at correct level (≥150mm above ground)',
      'Brick type & strength approved; delivered dry',
      'Mortar mix correct; perpends & beds fully filled',
      'Brickforce every 4th course; walls plumb & level',
      'Cavity kept clean; wall ties at correct spacing',
      'Lintels over all openings with correct bearing',
      'Movement / expansion joints located per plan',
      'Engineer inspection: reinforcement approved before any pour',
      'NHBRC inspection: slab / DPC stage passed',
      'Municipal inspection: DPC / surface bed passed',
      '250µm USB damp-proof membrane laid & lapped under surface bed',
      'Surface bed reinforcement (ref mesh) at correct position & lap',
      'Weep holes provided over DPC & above all lintels',
      'Air bricks / sub-floor & cavity ventilation built in',
      'HOLD POINT — services coordinated before surface-bed pour',
      '   – Under-slab plumbing & sewer pipes laid, tested & correctly positioned',
      '   – Electrical conduit / sleeves & earth mat cast in',
      '   – DPM intact — not punctured by any penetration',
    ],
    'Structural Steel Works': [
      'Steel sections & grade match engineer’s drawing',
      'Welds & bolted connections complete & to spec',
      'Members plumb, level & correctly aligned',
      'Corrosion protection / galvanizing intact',
      'Baseplates & holding-down bolts grouted',
      'Engineer inspection: steelwork inspected & signed off',
    ],
    'Suspended Roof Slab': [
      'Formwork level, tight & adequately propped',
      'Reinforcement size, spacing & cover per drawing',
      'Conduits & services cast in before pour',
      'Concrete slump & strength tested (cubes taken)',
      'Slab cured; props left in place per engineer',
      'Engineer inspection: reinforcement & formwork approved before pour',
      'NHBRC inspection: suspended slab stage passed',
      'Roof-slab screed laid to correct fall for drainage; no ponding (checked before waterproofing)',
      'Roof-slab water outlets / rainwater downpipes correctly positioned, sized & clear; screed falls to each outlet',
      'Safety railings / edge protection to all open edges, stairwells & floor openings',
      'Scaffold access to upper level inspected & tagged (double-storey work)',
    ],
    'Roofing': [
      'Trusses / rafters certified & per approved design',
      'Trusses braced, tied down & fixed to wall plate',
      'Sisalation / insulation laid correctly',
      'Sheeting or tiles fixed; roof weathertight',
      'Ridges, valleys & flashings sealed',
      'Gutters & downpipes installed to fall',
      'Engineer inspection: roof structure / tie-downs signed off',
      'NHBRC inspection: roof stage passed',
      'Fascia & barge boards fixed straight & painted',
      'Ceiling / roof insulation to SANS 10400-XA R-value',
      'Roof work: harnesses clipped to anchor points; edge protection to eaves & openings',
    ],
    'Plumbing & Drainage': [
      'Sewer drainage laid to fall; air-pressure tested',
      'Water supply pipes pressure tested (≥600 kPa)',
      'Gullies, manholes & rodding eyes correctly placed',
      'Geyser / heat pump installed, secured & lagged',
      'Tanks (JoJo / septic / conservancy) watertight',
      'Municipal inspection: open-drain / drainage test passed',
      'Geyser safety per SANS 10254: drip tray, PRV, vacuum breaker & overflow piped outside',
    ],
    'Electrical Works': [
      'DB board installed, wired & clearly labelled',
      'Wiring in conduit; correct cable sizes used',
      'Plug points, switches & isolators per layout',
      'Earthing & bonding complete',
      'Installation ready for CoC inspection',
      'Plug point positions & heights marked and approved against layout',
      'TV / data / telephone point positions confirmed',
      'Light point & switch positions confirmed against layout',
      'Geyser & appliance point positions confirmed',
      'Air-conditioner points & solar / PV provisions positioned per layout',
    ],
    'Windows & Door Frames': [
      'Frames plumb, square & correct size',
      'Built in / fixed securely; gaps sealed',
      'Glazing per spec; safety glass where required',
      'Ironmongery fitted; sashes & doors operate freely',
    ],
    'Plastering & Screeds': [
      'Walls plumb; external corners square',
      'Plaster even thickness; no cracks or blisters',
      'Floor screeds laid to fall & correct level',
      'Screed well bonded; no hollow / drummy areas',
      'HOLD POINT — first fix complete before plastering',
      '   – Electrical chasing, conduit & boxes installed',
      '   – Plumbing pipes in walls installed & pressure tested',
      '   – Window & door frames built in / fixed',
      '   – Wall ties, lintels & Brickforce signed off',
      '   – Wet-area & balcony screeds laid to fall towards outlets / drains; no ponding',
    ],
    'Waterproofing': [
      'Wet-area membranes applied & turned up walls',
      'Flat roof / balcony torch-on system complete',
      'Parapets & box gutters waterproofed',
      'Flood test passed; guarantee / certificate issued',
      'Waterproofing under aluminium sliding door thresholds installed & lapped to floor',
      'Screed falls re-checked before membrane — water drains to outlets, no ponding',
    ],
    'Ceilings & Partitioning': [
      'Brandering / framing level at correct centres',
      'Ceiling boards fixed; joints flush & taped',
      'Bulkheads square, plumb & straight',
      'Cornices / trims fitted; insulation laid above',
      'HOLD POINT — before closing up the ceiling',
      '   – Roof watertight & roof space clear',
      '   – Ceiling wiring, downlight & fan points roughed in',
      '   – Geyser & plumbing in roof space complete & lagged',
      '   – Insulation laid to R-value before boards fixed',
    ],
    'Joinery & Carpentry': [
      'Timber grade & moisture content per spec',
      'Doors hung with even gaps; operate freely',
      'Skirtings & architraves fixed neat & tight',
      'Fixings concealed; surfaces ready for finish',
      'Garage / roller door installed, level & operating',
    ],
    'Painting & Wall Covering': [
      'Surfaces prepared, primed & sealed',
      'Correct number of coats; even coverage',
      'Cutting-in neat; no runs or missed patches',
      'Colours per approved schedule',
      'HOLD POINT — surfaces ready before painting',
      '   – Plaster cured, cracks filled & sanded',
      '   – Ceilings, cornices & bulkheads complete',
      '   – Second-fix carpentry & filling done',
    ],
    'Tiling': [
      'Substrate level, primed; falls set in wet areas',
      'Tile type & layout per approved setting-out',
      'Full adhesive bed; no hollow-sounding tiles',
      'Grout & silicone joints neat; movement joints where needed',
      'Vertical waterproofing to shower walls applied to full height before tiling',
      'HOLD POINT — substrates signed off before tiling',
      '   – Waterproofing cured & flood-tested',
      '   – Screeds cured, dry & laid to correct fall',
      '   – Plumbing & electrical boxes set to finished tile depth',
    ],
    'Kitchen (Built-in Units)': [
      'Units match approved layout & dimensions',
      'Cabinets level, plumb & secured to wall',
      'Tops fitted; joints sealed; cut-outs correct',
      'Doors & drawers aligned and operating',
      'Electrical points (stove/oven, hob isolator, plugs, extractor) positioned per kitchen layout',
      'Plumbing points (sink, dishwasher, washing machine) positioned per kitchen layout',
    ],
    'Built-in Cupboards': [
      'Carcasses level, plumb & secured',
      'Shelves, rails & drawers fitted',
      'Doors aligned with even gaps',
      'Finish & edging per spec',
    ],
    'Sanitary Fittings': [
      'Fittings match approved schedule',
      'Fixed level & secure; no leaks',
      'Taps / mixers operate; hot & cold correct',
      'Sealed to walls & floors with silicone',
      'HOLD POINT — install only after finishes',
      '   – Wall & floor tiling complete',
      '   – Waterproofing flood-tested & signed off',
    ],
    'Floor Covering': [
      'Substrate clean, dry & level',
      'Material per spec; layout / direction correct',
      'Laid flat; no lifting, gaps or squeaks',
      'Edge trims & thresholds fitted',
    ],
    'Electrical Fittings': [
      'Light fittings, plugs & switch plates fitted',
      'Positions & heights per plan',
      'All points tested & working',
      'Cover plates straight, clean & undamaged',
      'HOLD POINT — second fix only after finishes',
      '   – Painting complete & dry',
      '   – Wall tiling in wet areas complete',
    ],
    'External Site Works': [
      'Paving / driveways to correct level & fall',
      'Boundary walls, gates & fences complete',
      'Stormwater drains away from building',
      'Landscaping, topsoil & final grading done',
    ],
    'Cleaning & Handover': [
      'Builder’s clean complete throughout',
      'Snag list issued & closed out',
      'CoCs & certificates (electrical, plumbing, gas, glazing) handed over',
      'As-built plans, warranties & manuals provided',
      'Occupancy Certificate (Form 4) applied for',
      'NHBRC inspection: final inspection passed',
      'Municipal inspection: final / Occupancy Certificate passed',
      'Water & electricity meter readings recorded; keys scheduled & handed over',
      'NHBRC warranty explained (3-month, 12-month & 5-year structural cover)',
    ],
    'Shoring & Retaining Walls': [
      'Lateral support / shoring designed by engineer & installed',
      'Excavation faces stable; no collapse or undermining risk',
      'Retaining wall founding, reinforcement & cover per engineer',
      'Subsoil drainage & weep holes behind wall installed',
      'Below-ground tanking / waterproofing applied to retaining face',
      'Backfill placed & compacted in layers',
      'Engineer inspection: retaining wall signed off before backfill',
    ],
    'Suspended Floor Slab': [
      'Formwork level, tight & adequately propped',
      'Reinforcement size, spacing & cover per drawing',
      'Conduits, sleeves & services cast in before pour',
      'Concrete slump & strength tested (cubes taken)',
      'Slab cured; props left in place per engineer',
      'Safety railings / edge protection to all open edges, stairwells & openings',
      'Engineer inspection: reinforcement & formwork approved before pour',
      'NHBRC inspection: suspended slab stage passed',
    ],
    'Balustrades & Railings': [
      'Balustrade height & baluster spacing per SANS 10400-M (≥1.0m; gaps ≤100mm)',
      'Fixings secure; posts resist imposed handrail load',
      'Staircase handrails continuous & at correct height',
      'Glass balustrades: safety glass per spec',
      'Finish / corrosion protection applied',
    ],
  };

  // QA checks for a trade section — strips any parenthetical / dash suffix so
  // relabelled repeats (e.g. "Brickwork & Concrete (First Floor)") reuse the
  // base section's checks. Falls back to a generic set if unmapped.
  List<String> _checksFor(String name) {
    final base = name
        .replaceAll(RegExp(r'\s*\(.*\)\s*$'), '')
        .replaceAll(RegExp(r'\s+\d+\s*$'), '')
        .trim();
    return _sectionChecks[name] ??
        _sectionChecks[base] ??
        const <String>[
          'Materials on site & approved',
          'Work complete to specification',
          'Inspected & signed off',
        ];
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('professional')) return Icons.architecture_rounded;
    if (n.contains('site preparation')) return Icons.landscape_rounded;
    if (n.contains('site establishment')) return Icons.construction_rounded;
    if (n.contains('earthwork')) return Icons.terrain_rounded;
    if (n.contains('shoring') || n.contains('retaining'))
      return Icons.fence_rounded;
    if (n.contains('brickwork')) return Icons.view_module_rounded;
    if (n.contains('steel')) return Icons.hardware_rounded;
    if (n.contains('slab')) return Icons.layers_rounded;
    if (n.contains('roof')) return Icons.roofing_rounded;
    if (n.contains('plumbing') || n.contains('drainage'))
      return Icons.plumbing_rounded;
    if (n.contains('electrical')) return Icons.bolt_rounded;
    if (n.contains('plaster') || n.contains('screed'))
      return Icons.texture_rounded;
    if (n.contains('window') || n.contains('door frame'))
      return Icons.window_rounded;
    if (n.contains('waterproof')) return Icons.water_drop_rounded;
    if (n.contains('ceiling') || n.contains('partition'))
      return Icons.grid_view_rounded;
    if (n.contains('joinery') || n.contains('carpentry'))
      return Icons.carpenter_rounded;
    if (n.contains('paint')) return Icons.format_paint_rounded;
    if (n.contains('tiling')) return Icons.grid_on_rounded;
    if (n.contains('kitchen')) return Icons.countertops_rounded;
    if (n.contains('cupboard')) return Icons.door_sliding_rounded;
    if (n.contains('sanitary')) return Icons.wc_rounded;
    if (n.contains('floor covering')) return Icons.square_foot_rounded;
    if (n.contains('balustrade') || n.contains('railing'))
      return Icons.fence_rounded;
    if (n.contains('external')) return Icons.yard_rounded;
    if (n.contains('cleaning') || n.contains('handover'))
      return Icons.cleaning_services_rounded;
    return Icons.checklist_rounded;
  }

  String _templateName(String key) {
    switch (key) {
      case 'gf':
        return 'Ground Floor';
      case 'gf1':
        return 'Ground + First';
      case 'lgfgf':
        return 'Lower Ground + Ground';
      case 'lgfgf1':
        return 'Lower Ground + Ground + First';
      case 'scratch':
        return 'Custom';
      default:
        return 'Check List';
    }
  }

  // =================================================================
  // Mutations
  // =================================================================
  void _pickTemplate(String key) => setState(() {
        _template = key;
        _screen = 'list';
        _filter = 'all';
        _done.clear();
        _collapsed.clear();
        _meta.clear();
      });

  void _startScratch() => setState(() {
        _template = 'scratch';
        _screen = 'list';
        _filter = 'all';
        _done.clear();
        _collapsed.clear();
        _meta.clear();
      });

  void _changeTemplate() => setState(() => _screen = 'start');
  void _setFilter(String f) => setState(() => _filter = f);
  void _toggleCat(int si) => setState(() =>
      _collapsed.contains(si) ? _collapsed.remove(si) : _collapsed.add(si));

  String _stampNow() {
    final d = DateTime.now();
    return DateFormat('d MMM · HH:mm').format(d);
  }

  void _toggleItem(int si, int ci) {
    final k = '$si:$ci';
    setState(() {
      if (_done.contains(k)) {
        _done.remove(k);
        _meta.remove(k);
      } else {
        _done.add(k);
        _meta[k] = _Stamp(_currentUser, _stampNow());
      }
    });
  }

  // =================================================================
  // BUILD
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: _paper,
      child: _screen == 'start' ? _startScreen() : _listScreen(),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _paper.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: _paper),
          ),
        ),
      );

  // =================================================================
  // START / TEMPLATE CHOOSER
  // =================================================================
  Widget _startScreen() {
    final top = MediaQuery.of(context).viewPadding.top;
    final defs = <List<String>>[
      ['gf', 'Ground Floor', 'Single-storey new build'],
      ['gf1', 'Ground Floor + First Floor', 'Two-storey new build'],
      ['lgfgf', 'Lower Ground + Ground Floor', 'Basement & ground level'],
      ['lgfgf1', 'Lower Ground + Ground + First', 'Full three-level build'],
    ];
    final floorViz = <String, List<bool>>{
      'gf': [true],
      'gf1': [true, true],
      'lgfgf': [true, false],
      'lgfgf1': [true, true, false],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: _header,
          padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circleBtn(Icons.arrow_back_ios_new_rounded, () {
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
              }),
              const SizedBox(height: 16),
              Text('CHECK LIST',
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: _paper.withOpacity(0.5))),
              const SizedBox(height: 10),
              const Text('Start a\nchecklist',
                  style: TextStyle(
                      fontFamily: _display,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.05,
                      color: _paper)),
              const SizedBox(height: 9),
              Text(
                  'Pick a template to load the standard trade sections — or build your own from scratch.',
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: _paper.withOpacity(0.6))),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHOOSE A TEMPLATE',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _faint)),
                const SizedBox(height: 10),
                for (final d in defs)
                  _templateCard(d[0], d[1], d[2], floorViz[d[0]]!),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: const [
                    Expanded(child: Divider(color: _hairlineOnSurface)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFFB7C2C7))),
                    ),
                    Expanded(child: Divider(color: _hairlineOnSurface)),
                  ]),
                ),
                _scratchCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _templateCard(
      String key, String title, String sub, List<bool> floors) {
    final secs = _sectionsFor(key);
    final checks = secs.fold<int>(0, (a, n) => a + _checksFor(n).length);
    final meta = '${secs.length} sections · $checks checks';

    return InkWell(
      onTap: () => _pickTemplate(key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: const Color(0xFFEEF2F4),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < floors.length; i++) ...[
                  if (i > 0) const SizedBox(height: 3),
                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: floors[i] ? _ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                      border: floors[i]
                          ? null
                          : Border.all(color: _faint, width: 1.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontFamily: _display,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: _ink)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _faint)),
                const SizedBox(height: 5),
                Text(meta,
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: _green)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 20, color: _chevron),
        ]),
      ),
    );
  }

  Widget _scratchCard() => InkWell(
        onTap: _startScratch,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD8DD), width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F4),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded, size: 22, color: _inkMute),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Build from scratch',
                      style: TextStyle(
                          fontFamily: _display,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  SizedBox(height: 2),
                  Text('Start empty and add your own sections',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _faint)),
                ],
              ),
            ),
          ]),
        ),
      );

  // =================================================================
  // LIST / CHECKLIST (sections = categories)
  // =================================================================
  Widget _listScreen() {
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final isScratch = _template == 'scratch';
    final sections = isScratch ? const <String>[] : _sectionsFor(_template);

    // completion
    var total = 0, doneCount = 0;
    for (var si = 0; si < sections.length; si++) {
      final checks = _checksFor(sections[si]);
      total += checks.length;
      for (var ci = 0; ci < checks.length; ci++) {
        if (_done.contains('$si:$ci')) doneCount++;
      }
    }
    final pct = total > 0 ? (doneCount / total * 100).round() : 0;

    return Column(
      children: [
        // hero
        Container(
          width: double.infinity,
          color: _header,
          padding: EdgeInsets.fromLTRB(20, top + 14, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _circleBtn(Icons.arrow_back_ios_new_rounded, _changeTemplate),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(children: [
                      Text(_projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: _body,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _paper)),
                      const SizedBox(height: 2),
                      Text(_templateName(_template).toUpperCase(),
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: _paper.withOpacity(0.5))),
                    ]),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _changeTemplate,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: _paper.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999)),
                      child:
                          Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.swap_horiz_rounded, size: 15, color: _paper),
                        SizedBox(width: 5),
                        Text('Template',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _paper)),
                      ]),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COMPLETE',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: _paper.withOpacity(0.55))),
                    const SizedBox(height: 4),
                    Text('$pct%',
                        style: const TextStyle(
                            fontFamily: _display,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.0,
                            color: _paper)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$doneCount of $total checks complete',
                            style: TextStyle(
                                fontFamily: _body,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _paper.withOpacity(0.6))),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: total > 0 ? doneCount / total : 0,
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.18),
                            // "done" bar is WHITE on the ink hero.
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_paper),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        // body
        Expanded(
          child: isScratch
              ? _scratchEmpty()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 40 + bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _filterBar(),
                      const SizedBox(height: 16),
                      ..._buildCategories(sections),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _scratchEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _band, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.playlist_add_rounded,
                    size: 30, color: _inkMute),
              ),
              const SizedBox(height: 14),
              const Text('Empty checklist',
                  style: TextStyle(
                      fontFamily: _display,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink)),
              const SizedBox(height: 6),
              const Text('Add your first section to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _faint)),
            ],
          ),
        ),
      );

  Widget _filterBar() {
    Widget seg(String key, String label) {
      final on = _filter == key;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _setFilter(key),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? _paper : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: on
                    ? [
                        BoxShadow(
                            color: _ink.withOpacity(0.12),
                            blurRadius: 2,
                            offset: const Offset(0, 1))
                      ]
                    : null,
              ),
              child: Text(label,
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: on ? _ink : _faint)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        seg('all', 'All'),
        const SizedBox(width: 4),
        seg('open', 'Open'),
        const SizedBox(width: 4),
        seg('done', 'Done'),
      ]),
    );
  }

  bool _matches(bool isDone) =>
      _filter == 'all' || (_filter == 'open' ? !isDone : isDone);

  List<Widget> _buildCategories(List<String> sections) {
    final cards = <Widget>[];
    for (var si = 0; si < sections.length; si++) {
      final name = sections[si];
      final checks = _checksFor(name);
      final visible = <int>[];
      var catDone = 0;
      for (var ci = 0; ci < checks.length; ci++) {
        final d = _done.contains('$si:$ci');
        if (d) catDone++;
        if (_matches(d)) visible.add(ci);
      }
      if (visible.isEmpty) continue; // hidden by filter
      final open = !_collapsed.contains(si);

      cards.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleCat(si),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                color: _band,
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _paper, borderRadius: BorderRadius.circular(11)),
                    child: Icon(_iconFor(name), size: 20, color: _ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: _display,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: _ink)),
                        const SizedBox(height: 2),
                        Text(
                            catDone == checks.length
                                ? 'All checks complete'
                                : '${checks.length - catDone} outstanding',
                            style: const TextStyle(
                                fontFamily: _body,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _faint)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: catDone == checks.length ? _selTint : _paper,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('$catDone/${checks.length}',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: catDone == checks.length ? _ink : _inkMute)),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: _chevron),
                  ),
                ]),
              ),
            ),
          ),
          // rows
          if (open)
            Column(
              children: [
                for (var vi = 0; vi < visible.length; vi++)
                  _checkRow(si, visible[vi], checks[visible[vi]],
                      first: vi == 0),
              ],
            ),
        ]),
      ));
    }

    if (cards.isEmpty) {
      cards.add(Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Column(children: [
            const Text('Nothing here',
                style: TextStyle(
                    fontFamily: _display,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
            const SizedBox(height: 6),
            Text(
                _filter == 'done'
                    ? 'No checks ticked off yet.'
                    : 'Every check is complete.',
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _faint)),
          ]),
        ),
      ));
    }
    return cards;
  }

  Widget _checkRow(int si, int ci, String label, {bool first = false}) {
    final isDone = _done.contains('$si:$ci');
    final stamp = _meta['$si:$ci'];
    return Material(
      color: _paper,
      child: InkWell(
        onTap: () => _toggleItem(si, ci),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              border:
                  first ? null : const Border(top: BorderSide(color: _line))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone ? _accent : _paper,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: isDone ? _accent : _chevron,
                      width: isDone ? 1 : 1.5),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded, size: 15, color: _paper)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: isDone ? _faint : _ink,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null)),
                    if (isDone && stamp != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.task_alt_rounded,
                            size: 13, color: _green),
                        const SizedBox(width: 5),
                        Text('${stamp.by} · ${stamp.at}',
                            style: const TextStyle(
                                fontFamily: _body,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _faint)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
