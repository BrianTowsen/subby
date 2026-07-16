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

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/auth/firebase_auth/auth_util.dart';

/// CheckListPageView — Construction Quality Check List.
///
/// START (template chooser) -> LIST (working, editable checklist).
/// Pick a floor-config template to load the standard trade sections; every
/// trade section becomes a check-list category. Ticking a check stamps who
/// signed it off and when. The list is fully editable (rename / add / delete /
/// reorder sections and checks) and persists to the device.
///
/// v3 checklist content: every section resequenced into strict site order
/// (hold points and inspections placed BEFORE the work they gate), Dept of
/// Labour compliance block added (Annexure 2 notification, construction work
/// permit, COIDA, H&S spec), and dedicated upper-floor brickwork keys so
/// storeys above ground don't repeat foundation / DPC / surface-bed checks.
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

// ── mutable, id-keyed model ──
class _Chk {
  final String id;
  String label;
  bool sub;
  bool done;
  String? by;
  String? at;
  _Chk(this.id, this.label,
      {this.sub = false, this.done = false, this.by, this.at});

  Map<String, dynamic> toMap() =>
      {'id': id, 'label': label, 'sub': sub, 'done': done, 'by': by, 'at': at};
  static _Chk fromMap(Map m) => _Chk(
        (m['id'] ?? '').toString(),
        (m['label'] ?? '').toString(),
        sub: m['sub'] == true,
        done: m['done'] == true,
        by: m['by']?.toString(),
        at: m['at']?.toString(),
      );
}

class _Sec {
  final String id;
  String name;
  List<_Chk> checks;
  _Sec(this.id, this.name, this.checks);

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'checks': checks.map((c) => c.toMap()).toList()};
  static _Sec fromMap(Map m) => _Sec(
        (m['id'] ?? '').toString(),
        (m['name'] ?? 'Section').toString(),
        ((m['checks'] as List?) ?? const [])
            .whereType<Map>()
            .map(_Chk.fromMap)
            .toList(),
      );
}

class _CheckListPageViewState extends State<CheckListPageView>
    with SingleTickerProviderStateMixin {
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
  static const Color _yellow = Color(0xFFE7E247); // tick + active pill

  static const String _display = 'Inter Tight';
  static const String _body = 'Inter';

  // NOTE: bumped from subby_checklist_v2 so devices holding the old saved
  // list load the new v3 content. Revert to _v2 if you'd rather keep any
  // in-progress ticks on site (the old list will then show until Reset).
  static const String _kSaved = 'subby_checklist_v3';

  String _screen = 'start'; // 'start' | 'list'
  String _template = '';
  bool _editing = false;
  bool _showBanner = false;
  final Set<String> _collapsed = <String>{};
  List<_Sec> _sections = <_Sec>[];
  late TabController _tab; // 0 All | 1 Open | 2 Done
  int _seq = 0;

  String _nid() {
    _seq += 1;
    return 'k${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  String get _projectName => (widget.projectName ?? '').trim().isNotEmpty
      ? widget.projectName!.trim()
      : 'Project';
  String get _currentUser {
    final n = (currentUserDisplayName).trim();
    return n.isEmpty ? 'You' : n;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSaved);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final list = (decoded['sections'] as List?) ?? const [];
      final secs = list.whereType<Map>().map(_Sec.fromMap).toList();
      if (secs.isEmpty && (decoded['template'] ?? '') != 'scratch') return;
      if (!mounted) return;
      setState(() {
        _template = (decoded['template'] ?? 'custom').toString();
        _sections = secs;
        _screen = 'list';
        _collapseAll();
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kSaved,
          jsonEncode({
            'template': _template,
            'sections': _sections.map((s) => s.toMap()).toList(),
          }));
    } catch (_) {}
  }

  void _collapseAll() {
    _collapsed
      ..clear()
      ..addAll(_sections.map((s) => s.id));
  }

  // =================================================================
  // Templates
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
      'Cleaning & Handover'
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
      'Cleaning & Handover'
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
      'Cleaning & Handover'
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
      'Cleaning & Handover'
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

  static const Map<String, List<String>> _sectionChecks = {
    'Professional Services': [
      'Municipal building plans approved & stamped on site',
      'Home enrolled with NHBRC before construction starts',
      'Structural engineer appointed; designs & details issued',
      'Geotechnical report received; site classified (R/H/C/S/P)',
      'Building contract signed & insurances in place',
      'Dept of Labour notified of construction work (Annexure 2) before work starts',
      'Construction work permit obtained where required (Construction Regs 2014)',
      'Contractor COIDA registered; letter of good standing on file',
      'Client H&S specification issued; contractor H&S plan approved',
      'Competent-person appointments confirmed in writing',
      'Municipality notified of commencement (48 hrs before start)',
    ],
    'Site Preparation': [
      'Land surveyor: site boundaries & pegs verified against SG diagram',
      'Trees & services to be retained protected',
      'Existing structures demolished & rubble removed',
      'Site cleared of vegetation; topsoil stripped & stockpiled',
      'Site datum / benchmark established & recorded',
      'Access for delivery vehicles confirmed',
    ],
    'Site Establishment': [
      'Boundary hoarding / fencing erected & secure',
      'Site board & statutory signage displayed',
      'Copy of DoL notification (Annexure 2) & OHS Act signage displayed on site',
      'Temporary water & electrical connection in place',
      'Site office, store & lock-up erected',
      'Ablution facilities provided for workforce',
      'Materials laydown & storage area set out',
      'Security / access control in place',
      'First aid kit & fire extinguishers on site',
      'Health & Safety file, risk assessment & OHS appointments on site (Construction Regs)',
      'Fall-protection plan in place; roof harnesses, lanyards & anchor points provided',
      'Setting-out / survey pegs verified against approved plan',
    ],
    'Earthworks & Excavation': [
      'Excavations to correct levels; sides shored where needed',
      'Foundation trenches to engineer’s depth & width',
      'No standing water or loose soil in trenches',
      'Engineer inspection: founding stratum approved before pour',
      'NHBRC inspection: foundations booked & passed',
      'Municipal inspection: foundation / trench passed',
      'Soil poisoning / termite treatment applied to trenches & under surface bed',
      'Bulk fill placed & compacted in layers',
    ],
    'Brickwork & Concrete': [
      'Engineer inspection: reinforcement approved before any pour',
      'Foundation concrete mix & strength per spec',
      'Foundation concrete cubes taken & tested (strength records kept)',
      'Minimum foundation wall height achieved (≥150mm brickwork below DPC / to NHBRC & engineer detail)',
      'DPC laid & lapped at correct level (≥150mm above ground)',
      'HOLD POINT — services coordinated before surface-bed pour',
      ' – Under-slab plumbing & sewer pipes laid, tested & correctly positioned',
      ' – Electrical conduit / sleeves & earth mat cast in',
      ' – 250µm USB damp-proof membrane laid & lapped under surface bed',
      ' – DPM intact — not punctured by any penetration',
      ' – Surface bed reinforcement (ref mesh) at correct position & lap',
      'Municipal inspection: DPC / surface bed passed',
      'NHBRC inspection: slab / DPC stage passed',
      'Brick type & strength approved; delivered dry',
      'Mortar mix correct; perpends & beds fully filled',
      'Brickforce every 4th course; walls plumb & level',
      'Cavity kept clean; wall ties at correct spacing',
      'Weep holes provided over DPC & above all lintels',
      'Air bricks / sub-floor & cavity ventilation built in',
      'Lintels over all openings with correct bearing',
      'Movement / expansion joints located per plan',
    ],
    'Brickwork & Concrete (First Floor)': [
      'Brick type & strength approved; delivered dry',
      'Mortar mix correct; perpends & beds fully filled',
      'Brickforce every 4th course; walls plumb & level',
      'Cavity kept clean; wall ties at correct spacing',
      'Lintels over all openings with correct bearing',
      'Weep holes provided above all lintels',
      'Movement / expansion joints located per plan',
      'Gables & beam filling complete',
      'Wall plate level & secured',
    ],
    'Brickwork & Concrete (Ground Floor)': [
      'Brick type & strength approved; delivered dry',
      'Mortar mix correct; perpends & beds fully filled',
      'Brickforce every 4th course; walls plumb & level',
      'Cavity kept clean; wall ties at correct spacing',
      'Lintels over all openings with correct bearing',
      'Weep holes provided above all lintels',
      'Movement / expansion joints located per plan',
    ],
    'Structural Steel Works': [
      'Steel sections & grade match engineer’s drawing',
      'Members plumb, level & correctly aligned',
      'Welds & bolted connections complete & to spec',
      'Baseplates & holding-down bolts grouted',
      'Corrosion protection / galvanizing intact',
      'Engineer inspection: steelwork inspected & signed off',
    ],
    'Shoring & Retaining Walls': [
      'Lateral support / shoring designed by engineer & installed',
      'Excavation faces stable; no collapse or undermining risk',
      'Retaining wall founding, reinforcement & cover per engineer',
      'Below-ground tanking / waterproofing applied to retaining face',
      'Subsoil drainage & weep holes behind wall installed',
      'Engineer inspection: retaining wall signed off before backfill',
      'Backfill placed & compacted in layers',
    ],
    'Suspended Floor Slab': [
      'Formwork level, tight & adequately propped',
      'Reinforcement size, spacing & cover per drawing',
      'Conduits, sleeves & services cast in before pour',
      'Engineer inspection: reinforcement & formwork approved before pour',
      'Concrete slump & strength tested (cubes taken)',
      'Slab cured; props left in place per engineer',
      'NHBRC inspection: suspended slab stage passed',
      'Safety railings / edge protection to all open edges, stairwells & openings',
      'Scaffold access to upper level inspected & tagged',
    ],
    'Suspended Roof Slab': [
      'Formwork level, tight & adequately propped',
      'Reinforcement size, spacing & cover per drawing',
      'Conduits & services cast in before pour',
      'Engineer inspection: reinforcement & formwork approved before pour',
      'Concrete slump & strength tested (cubes taken)',
      'Slab cured; props left in place per engineer',
      'NHBRC inspection: suspended slab stage passed',
      'Safety railings / edge protection to all open edges, stairwells & floor openings',
      'Roof-slab screed laid to correct fall for drainage; no ponding (checked before waterproofing)',
      'Roof-slab water outlets / rainwater downpipes correctly positioned, sized & clear; screed falls to each outlet',
      'Scaffold access to upper level inspected & tagged (double-storey work)',
    ],
    'Roofing': [
      'Trusses / rafters certified & per approved design',
      'Trusses braced, tied down & fixed to wall plate',
      'Engineer inspection: roof structure / tie-downs signed off (A19)',
      'Roof work: harnesses clipped to anchor points; edge protection to eaves & openings',
      'Sisalation / insulation laid correctly',
      'Sheeting or tiles fixed; roof weathertight',
      'Ridges, valleys & flashings sealed',
      'NHBRC inspection: roof stage passed',
      'Fascia & barge boards fixed straight & painted',
      'Gutters & downpipes installed to fall',
      'Ceiling / roof insulation to SANS 10400-XA R-value',
    ],
    'Plumbing & Drainage': [
      'Sewer drainage laid to fall; air-pressure tested',
      'Gullies, manholes & rodding eyes correctly placed',
      'Municipal inspection: open-drain / drainage test passed before closing',
      'Water supply pipes pressure tested (≥600 kPa)',
      'Geyser / heat pump installed, secured & lagged',
      'Geyser safety per SANS 10254: drip tray, PRV, vacuum breaker & overflow piped outside',
      'Tanks (JoJo / septic / conservancy) watertight',
    ],
    'Electrical Works': [
      'Plug point positions & heights marked and approved against layout',
      'Light point & switch positions confirmed against layout',
      'TV / data / telephone point positions confirmed',
      'Geyser & appliance point positions confirmed',
      'Air-conditioner points & solar / PV provisions positioned per layout',
      'Wiring in conduit; correct cable sizes used',
      'DB board installed, wired & clearly labelled',
      'Plug points, switches & isolators per layout',
      'Earthing & bonding complete',
      'Installation ready for CoC inspection',
    ],
    'Plastering & Screeds': [
      'HOLD POINT — first fix complete before plastering',
      ' – Electrical chasing, conduit & boxes installed',
      ' – Plumbing pipes in walls installed & pressure tested',
      ' – Window & door frames built in / fixed',
      ' – Wall ties, lintels & Brickforce signed off',
      'Walls plumb; external corners square',
      'Plaster even thickness; no cracks or blisters',
      'Floor screeds laid to fall & correct level',
      'Wet-area & balcony screeds laid to fall towards outlets / drains; no ponding',
      'Screed well bonded; no hollow / drummy areas',
    ],
    'Windows & Door Frames': [
      'Frames plumb, square & correct size',
      'Built in / fixed securely; gaps sealed',
      'Glazing per spec; safety glass where required',
      'Ironmongery fitted; sashes & doors operate freely',
    ],
    'Waterproofing': [
      'Screed falls re-checked before membrane — water drains to outlets, no ponding',
      'Wet-area membranes applied & turned up walls',
      'Waterproofing under aluminium sliding door thresholds installed & lapped to floor',
      'Flat roof / balcony torch-on system complete',
      'Parapets & box gutters waterproofed',
      'Flood test passed; guarantee / certificate issued',
    ],
    'Ceilings & Partitioning': [
      'HOLD POINT — before closing up the ceiling',
      ' – Roof watertight & roof space clear',
      ' – Ceiling wiring, downlight & fan points roughed in',
      ' – Geyser & plumbing in roof space complete & lagged',
      ' – Insulation laid to R-value before boards fixed',
      'Brandering / framing level at correct centres',
      'Ceiling boards fixed; joints flush & taped',
      'Bulkheads square, plumb & straight',
      'Cornices / trims fitted; insulation laid above',
    ],
    'Joinery & Carpentry': [
      'Timber grade & moisture content per spec',
      'Doors hung with even gaps; operate freely',
      'Skirtings & architraves fixed neat & tight',
      'Fixings concealed; surfaces ready for finish',
      'Garage / roller door installed, level & operating',
    ],
    'Painting & Wall Covering': [
      'HOLD POINT — surfaces ready before painting',
      ' – Plaster cured, cracks filled & sanded',
      ' – Ceilings, cornices & bulkheads complete',
      ' – Second-fix carpentry & filling done',
      'Surfaces prepared, primed & sealed',
      'Correct number of coats; even coverage',
      'Cutting-in neat; no runs or missed patches',
      'Colours per approved schedule',
    ],
    'Tiling': [
      'HOLD POINT — substrates signed off before tiling',
      ' – Waterproofing cured & flood-tested',
      ' – Screeds cured, dry & laid to correct fall',
      ' – Plumbing & electrical boxes set to finished tile depth',
      'Vertical waterproofing to shower walls applied to full height before tiling',
      'Substrate level, primed; falls set in wet areas',
      'Tile type & layout per approved setting-out',
      'Full adhesive bed; no hollow-sounding tiles',
      'Grout & silicone joints neat; movement joints where needed',
    ],
    'Balustrades & Railings': [
      'Balustrade height & baluster spacing per SANS 10400-M (≥1.0m; gaps ≤100mm)',
      'Fixings secure; posts resist imposed handrail load',
      'Staircase handrails continuous & at correct height',
      'Glass balustrades: safety glass per spec',
      'Finish / corrosion protection applied',
    ],
    'Kitchen (Built-in Units)': [
      'Electrical points (stove/oven, hob isolator, plugs, extractor) positioned per kitchen layout',
      'Plumbing points (sink, dishwasher, washing machine) positioned per kitchen layout',
      'Units match approved layout & dimensions',
      'Cabinets level, plumb & secured to wall',
      'Tops fitted; joints sealed; cut-outs correct',
      'Doors & drawers aligned and operating',
    ],
    'Built-in Cupboards': [
      'Carcasses level, plumb & secured',
      'Shelves, rails & drawers fitted',
      'Doors aligned with even gaps',
      'Finish & edging per spec',
    ],
    'Sanitary Fittings': [
      'HOLD POINT — install only after finishes',
      ' – Wall & floor tiling complete',
      ' – Waterproofing flood-tested & signed off',
      'Fittings match approved schedule',
      'Fixed level & secure; no leaks',
      'Taps / mixers operate; hot & cold correct',
      'Sealed to walls & floors with silicone',
    ],
    'Floor Covering': [
      'Substrate clean, dry & level',
      'Material per spec; layout / direction correct',
      'Laid flat; no lifting, gaps or squeaks',
      'Edge trims & thresholds fitted',
    ],
    'Electrical Fittings': [
      'HOLD POINT — second fix only after finishes',
      ' – Painting complete & dry',
      ' – Wall tiling in wet areas complete',
      'Light fittings, plugs & switch plates fitted',
      'Positions & heights per plan',
      'All points tested & working',
      'Cover plates straight, clean & undamaged',
    ],
    'External Site Works': [
      'Stormwater drains away from building',
      'Paving / driveways to correct level & fall',
      'Boundary walls, gates & fences complete',
      'Landscaping, topsoil & final grading done',
    ],
    'Cleaning & Handover': [
      'Builder’s clean complete throughout',
      'Snag list issued & closed out',
      'CoCs & certificates (electrical, plumbing, gas, glazing) handed over',
      'NHBRC inspection: final inspection passed',
      'Occupancy Certificate (Form 4) applied for',
      'Municipal inspection: final / Occupancy Certificate passed',
      'As-built plans, warranties & manuals provided',
      'NHBRC warranty explained (3-month, 12-month & 5-year structural cover)',
      'Water & electricity meter readings recorded; keys scheduled & handed over',
    ],
  };

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

  List<_Sec> _materialize(String key) {
    final names = key == 'scratch' ? const <String>[] : _sectionsFor(key);
    return names.map((name) {
      final checks = _checksFor(name).map((raw) {
        final sub = RegExp(r'^\s').hasMatch(raw);
        return _Chk(_nid(), raw.trim(), sub: sub);
      }).toList();
      return _Sec(_nid(), name, checks);
    }).toList();
  }

  String _stampNow() => DateFormat('d MMM · HH:mm').format(DateTime.now());

  // =================================================================
  // Mutations
  // =================================================================
  void _pickTemplate(String key) {
    setState(() {
      _template = key;
      _sections = _materialize(key);
      _screen = 'list';
      _editing = false;
      _showBanner = true;
      _tab.index = 0;
      _collapseAll();
    });
    _save();
  }

  void _startScratch() {
    setState(() {
      _template = 'scratch';
      _sections = <_Sec>[];
      _screen = 'list';
      _editing = true;
      _showBanner = false;
      _tab.index = 0;
      _collapsed.clear();
    });
    _save();
  }

  void _resetDefault() {
    final key = const ['gf', 'gf1', 'lgfgf', 'lgfgf1'].contains(_template)
        ? _template
        : 'gf';
    setState(() {
      _sections = _materialize(key);
      _template = key;
      _editing = false;
      _showBanner = true;
      _collapseAll();
    });
    _save();
  }

  void _changeTemplate() => setState(() {
        _screen = 'start';
        _editing = false;
      });
  void _toggleEdit() => setState(() => _editing = !_editing);
  void _dismissBanner() => setState(() => _showBanner = false);

  void _toggleAll() {
    final anyClosed = _sections.any((s) => _collapsed.contains(s.id));
    setState(() {
      if (anyClosed) {
        _collapsed.clear();
      } else {
        _collapseAll();
      }
    });
  }

  void _toggleCat(String id) => setState(() =>
      _collapsed.contains(id) ? _collapsed.remove(id) : _collapsed.add(id));

  void _toggleCheck(_Chk c) {
    setState(() {
      if (c.done) {
        c.done = false;
        c.by = null;
        c.at = null;
      } else {
        c.done = true;
        c.by = _currentUser;
        c.at = _stampNow();
      }
    });
    _save();
  }

  void _renameSection(_Sec s, String v) {
    s.name = v;
    _save();
  }

  void _deleteSection(_Sec s) {
    setState(() => _sections.remove(s));
    _save();
  }

  void _moveSection(int i, int dir) {
    final j = i + dir;
    if (j < 0 || j >= _sections.length) return;
    setState(() {
      final t = _sections[i];
      _sections[i] = _sections[j];
      _sections[j] = t;
    });
    _save();
  }

  void _addSection() {
    setState(() {
      final s = _Sec(_nid(), 'New section', <_Chk>[]);
      _sections.add(s);
      _collapsed.remove(s.id);
    });
    _save();
  }

  void _addCheck(_Sec s) {
    setState(() {
      _collapsed.remove(s.id);
      s.checks.add(_Chk(_nid(), 'New check'));
    });
    _save();
  }

  void _renameCheck(_Chk c, String v) {
    c.label = v;
    _save();
  }

  void _deleteCheck(_Sec s, _Chk c) {
    setState(() => s.checks.remove(c));
    _save();
  }

  // Counts
  int get _total => _sections.fold(0, (a, s) => a + s.checks.length);
  int get _doneCount =>
      _sections.fold(0, (a, s) => a + s.checks.where((c) => c.done).length);

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
    final defs = <List<dynamic>>[
      [
        'gf',
        'Ground Floor',
        'Single-storey new build',
        <bool>[true]
      ],
      [
        'gf1',
        'Ground Floor + First Floor',
        'Two-storey new build',
        <bool>[true, true]
      ],
      [
        'lgfgf',
        'Lower Ground + Ground Floor',
        'Basement & ground level',
        <bool>[true, false]
      ],
      [
        'lgfgf1',
        'Lower Ground + Ground + First',
        'Full three-level build',
        <bool>[true, true, false]
      ],
    ];
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
                for (final dfn in defs)
                  _templateCard(dfn[0] as String, dfn[1] as String,
                      dfn[2] as String, dfn[3] as List<bool>),
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
  // LIST
  // =================================================================
  Widget _listScreen() {
    return Column(
      children: [
        _hero(),
        Expanded(
          child: _editing
              ? _editor()
              : (_sections.isEmpty ? _emptyState() : _viewBody()),
        ),
      ],
    );
  }

  Widget _hero() {
    final top = MediaQuery.of(context).viewPadding.top;
    final total = _total;
    final done = _doneCount;
    final outstanding = total - done;
    final pct = total > 0 ? (done / total * 100).round() : 0;
    return Container(
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
                  Text('CHECK LIST',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: _paper.withOpacity(0.5))),
                ]),
              ),
            ),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: _paper.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.checklist_rounded, size: 14, color: _paper),
                const SizedBox(width: 5),
                Text('$total ${total == 1 ? 'check' : 'checks'}',
                    style: const TextStyle(
                        fontFamily: _body,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _paper)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OUTSTANDING',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: _paper.withOpacity(0.55))),
                const SizedBox(height: 4),
                Text('$outstanding ${outstanding == 1 ? 'check' : 'checks'}',
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
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$done done',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _paper.withOpacity(0.6))),
                  const SizedBox(height: 2),
                  Text('$pct% complete',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _paper.withOpacity(0.45))),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── view body: controls + pill tabs + sliding content ──
  Widget _viewBody() {
    return Column(
      children: [
        if (_showBanner) _banner(),
        Container(
          color: _paper,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _editPill(),
                const SizedBox(width: 14),
                InkWell(
                  onTap: _toggleAll,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        _sections.any((s) => _collapsed.contains(s.id))
                            ? Icons.unfold_more_rounded
                            : Icons.unfold_less_rounded,
                        size: 16,
                        color: _inkMute),
                    const SizedBox(width: 5),
                    Text(
                        _sections.any((s) => _collapsed.contains(s.id))
                            ? 'Expand all'
                            : 'Collapse all',
                        style: const TextStyle(
                            fontFamily: _body,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _inkMute)),
                  ]),
                ),
              ]),
              const SizedBox(height: 11),
              _pillTabs(),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _pane('all'),
              _pane('open'),
              _pane('done'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _banner() => Container(
        width: double.infinity,
        color: _band,
        padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
        child: Row(children: [
          const Icon(Icons.bookmark_added_rounded, size: 17, color: _green),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
                'Template loaded — tap a section to open its checks, then tick each item to stamp who signed it off.',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: _inkMute)),
          ),
          const SizedBox(width: 8),
          InkWell(
              onTap: _dismissBanner,
              child: const Icon(Icons.close_rounded, size: 17, color: _faint)),
        ]),
      );

  Widget _editPill() => InkWell(
        onTap: _toggleEdit,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: _yellow, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.tune_rounded, size: 14, color: _ink),
            SizedBox(width: 4),
            Text('Edit list',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _ink)),
          ]),
        ),
      );

  Widget _pillTabs() {
    const labels = ['All', 'Open', 'Done'];
    final total = _total, done = _doneCount;
    final counts = [total, total - done, done];
    final current = _tab.index;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(999)),
      child: LayoutBuilder(builder: (context, c) {
        final segW = c.maxWidth / 3;
        return Stack(children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment((-1 + current).toDouble(), 0),
            child: Container(
              width: segW,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 3,
                      offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
          Row(
              children: List.generate(3, (i) {
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tab.animateTo(i),
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(labels[i],
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 12.5,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color: active ? _ink : _faint)),
                    const SizedBox(width: 5),
                    Text('${counts[i]}',
                        style: TextStyle(
                            fontFamily: _body,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (active ? _ink : _faint).withOpacity(0.75))),
                  ]),
                ),
              ),
            );
          })),
        ]);
      }),
    );
  }

  bool _matches(String fk, bool done) =>
      fk == 'all' || (fk == 'open' ? !done : done);

  Widget _pane(String fk) {
    final cards = <Widget>[];
    for (var si = 0; si < _sections.length; si++) {
      final sec = _sections[si];
      final visible = sec.checks.where((c) => _matches(fk, c.done)).toList();
      if (visible.isEmpty) continue;
      cards.add(_categoryCard(sec, visible));
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
                fk == 'done'
                    ? 'No checks ticked off yet.'
                    : (fk == 'open'
                        ? 'Every check is complete.'
                        : 'No sections yet.'),
                style: const TextStyle(
                    fontFamily: _body,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _faint)),
          ]),
        ),
      ));
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: cards,
    );
  }

  Widget _categoryCard(_Sec sec, List<_Chk> visible) {
    final checks = sec.checks;
    final catDone = checks.where((c) => c.done).length;
    final allDone = checks.isNotEmpty && catDone == checks.length;
    final open = !_collapsed.contains(sec.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleCat(sec.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              color: _band,
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: _paper, borderRadius: BorderRadius.circular(11)),
                  child: Icon(_iconFor(sec.name), size: 20, color: _ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sec.name,
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
                          checks.isEmpty
                              ? 'No checks yet'
                              : (allDone
                                  ? 'All checks complete'
                                  : '${checks.length - catDone} outstanding'),
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
                      color: allDone ? _selTint : _paper,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text('$catDone/${checks.length}',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: allDone ? _ink : _inkMute)),
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
        if (open)
          Column(children: [
            for (var vi = 0; vi < visible.length; vi++)
              _checkRow(visible[vi], first: vi == 0),
          ]),
      ]),
    );
  }

  Widget _checkRow(_Chk c, {bool first = false}) {
    return Material(
      color: _paper,
      child: InkWell(
        onTap: () => _toggleCheck(c),
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
                  color: c.done ? _yellow : _paper,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: c.done ? _yellow : _chevron,
                      width: c.done ? 1 : 1.5),
                ),
                child: c.done
                    ? const Icon(Icons.check_rounded, size: 15, color: _ink)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: c.sub ? 14 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.label,
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: c.done ? _faint : _ink,
                              decoration:
                                  c.done ? TextDecoration.lineThrough : null)),
                      if (c.done && (c.by != null)) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.task_alt_rounded,
                              size: 13, color: _green),
                          const SizedBox(width: 5),
                          Text('${c.by} · ${c.at}',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── empty state ──
  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            const Text('Add sections and checks to build your own list.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _faint)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _toggleEdit,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                    color: _ink, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.add_rounded, size: 17, color: _paper),
                  SizedBox(width: 7),
                  Text('Build list',
                      style: TextStyle(
                          fontFamily: _body,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _paper)),
                ]),
              ),
            ),
          ]),
        ),
      );

  // ── editor ──
  Widget _editor() {
    return Column(children: [
      Container(
        color: _band,
        padding: const EdgeInsets.fromLTRB(20, 11, 20, 11),
        child: Row(children: [
          const Icon(Icons.edit_note_rounded, size: 17, color: _green),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
                'Editing — rename anything, add or remove checks and sections, reorder with the arrows.',
                style: TextStyle(
                    fontFamily: _body,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: _inkMute)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _toggleEdit,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: _yellow, borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.check_rounded, size: 15, color: _ink),
                SizedBox(width: 4),
                Text('Done',
                    style: TextStyle(
                        fontFamily: _body,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            for (var i = 0; i < _sections.length; i++) _editSectionCard(i),
            InkWell(
              onTap: _addSection,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFCBD8DD), width: 1.5)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_rounded, size: 18, color: _ink),
                      SizedBox(width: 7),
                      Text('Add section',
                          style: TextStyle(
                              fontFamily: _display,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                    ]),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _resetDefault,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.restart_alt_rounded, size: 17, color: _faint),
                      SizedBox(width: 7),
                      Text('Reset to default',
                          style: TextStyle(
                              fontFamily: _body,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _inkMute)),
                    ]),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _editSectionCard(int i) {
    final sec = _sections[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          color: _band,
          child: Row(children: [
            Icon(_iconFor(sec.name), size: 18, color: _ink),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('sec_${sec.id}'),
                initialValue: sec.name,
                onChanged: (v) => _renameSection(sec, v),
                style: const TextStyle(
                    fontFamily: _display,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Section name',
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                ),
              ),
            ),
            InkWell(
                onTap: () => _moveSection(i, -1),
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    size: 18, color: i == 0 ? _hairlineOnSurface : _faint)),
            InkWell(
                onTap: () => _moveSection(i, 1),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: i == _sections.length - 1
                        ? _hairlineOnSurface
                        : _faint)),
            const SizedBox(width: 4),
            InkWell(
                onTap: () => _deleteSection(sec),
                child: const Icon(Icons.delete_rounded,
                    size: 18, color: Color(0xFFB7C2C7))),
          ]),
        ),
        for (final c in sec.checks)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _line))),
            child: Row(children: [
              const Icon(Icons.radio_button_unchecked_rounded,
                  size: 9, color: _chevron),
              const SizedBox(width: 9),
              Expanded(
                child: TextFormField(
                  key: ValueKey('chk_${c.id}'),
                  initialValue: c.label,
                  onChanged: (v) => _renameCheck(c, v),
                  style: const TextStyle(
                      fontFamily: _body,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Check item',
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
              ),
              InkWell(
                  onTap: () => _deleteCheck(sec, c),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFFB7C2C7))),
            ]),
          ),
        InkWell(
          onTap: () => _addCheck(sec),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _line))),
            child: Row(children: const [
              Icon(Icons.add_rounded, size: 16, color: _inkMute),
              SizedBox(width: 7),
              Text('Add check',
                  style: TextStyle(
                      fontFamily: _body,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _inkMute)),
            ]),
          ),
        ),
      ]),
    );
  }
}
