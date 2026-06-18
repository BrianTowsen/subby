// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/services.dart'; // HapticFeedback

// ======================= SubbyBottomNav (FULL FILE) =======================
//
// App-shell bottom navigation. The active tab is shown as a pill in that area's
// accent (active tab = navy pill, white icon) with the
// icon sitting ON the pill in the readable foreground. Inactive tabs are muted.
//
// PARAMETERS (match the FlutterFlow definition — nothing to add):
//   * width, height   - the standard required pair (height is accepted but the
//                       bar sizes itself; pass anything).
//   * currentIndex    - which tab is active on THIS page:
//                       0 Home . 1 Explore . 2 Saved
//
// ROUTES are app-global, so they're constants here (not per-page params). Edit
// the four _route* values below to match your FlutterFlow page names.
//
// ANDROID SAFE AREA: the row is wrapped in SafeArea(top:false) so the system
// inset (Samsung gesture bar / 3-button nav) is reserved automatically; the
// `minimum: bottom 8` is a floor for devices with no inset. Place the bar at the
// very bottom of the page, full-bleed, so it owns the inset.

class SubbyBottomNav extends StatefulWidget {
  const SubbyBottomNav({
    super.key,
    this.width,
    this.height,
    this.currentIndex, // 0 Home . 1 Explore . 2 Saved
  });

  final double? width;
  final double? height;
  final int? currentIndex;

  @override
  State<SubbyBottomNav> createState() => _SubbyBottomNavState();
}

class _SubbyBottomNavState extends State<SubbyBottomNav> {
  // PALETTE (matches the app)
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _hairline = Color(0xFFEEF1F4);

  static const String _bodyFont = 'Inter';

  // ROUTES (edit to your real FlutterFlow page names)
  static const String _routeHome = 'homePage';
  static const String _routeExplore = 'explorePage';
  static const String _routeSaved = 'savedPage';

  // Tab nav FADES in (drill-down pages keep their default slide). The 180ms
  // select delay + light haptic mirror the app's other bottom bar.
  static const Duration _selectDelay = Duration(milliseconds: 180);

  late int _selectedIndex;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = (widget.currentIndex ?? 0).clamp(0, 2);
  }

  @override
  void didUpdateWidget(covariant SubbyBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = (widget.currentIndex ?? 0).clamp(0, 2);
    if (next != _selectedIndex && mounted) {
      setState(() => _selectedIndex = next);
    }
  }

  String _routeForIndex(int index) {
    switch (index) {
      case 1:
        return _routeExplore;
      case 2:
        return _routeSaved;
      default:
        return _routeHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selectedIndex.clamp(0, 2);

    return Container(
      width: widget.width ?? double.infinity,
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: _hairline, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // Floor so it never hugs the gesture bar; SafeArea adds the real
        // system inset on top of this where present (Samsung etc).
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _tab(
                  active: sel == 0,
                  label: 'Home',
                  icon: Icons.home_rounded,
                  accent: _ink,
                  onAccent: _paper,
                  index: 0,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 1,
                  label: 'Explore',
                  icon: Icons.explore_rounded,
                  accent: _ink,
                  onAccent: _paper,
                  index: 1,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 2,
                  label: 'Saved',
                  icon: Icons.bookmark_rounded,
                  accent: _ink,
                  onAccent: _paper,
                  index: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab({
    required bool active,
    required String label,
    required IconData icon,
    required Color accent,
    required Color onAccent,
    required int index,
  }) {
    return InkWell(
      onTap: () => _go(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? onAccent : _inkMute,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _bodyFont,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _ink : _inkMute,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _go(int index) async {
    index = index.clamp(0, 2);
    final cur = widget.currentIndex ?? 0;
    // Re-tap of the current tab, or a tap while a switch is in flight, is a
    // silent no-op.
    if (_navigating || index == cur) return;

    // Tab switch = medium tactile tick (fires before the select delay).
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedIndex = index;
      _navigating = true;
    });

    final route = _routeForIndex(index).trim();
    if (route.isEmpty) {
      setState(() => _navigating = false);
      return;
    }

    try {
      await Future.delayed(_selectDelay);
      if (!mounted) return;

      // FADE between tab pages. Drill-down pages (no bottom nav) keep their
      // own default slide transition.
      context.pushReplacementNamed(
        route,
        extra: {
          kTransitionInfoKey: const TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: Duration(milliseconds: 180),
          ),
        },
      );
    } catch (e) {
      debugPrint('SubbyBottomNav navigation failed: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _navigating = false);
      });
    }
  }
}
