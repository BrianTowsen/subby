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

// ======================= MainBottomNav (FULL FILE) =======================
//
// App-shell bottom navigation, styled to MATCH SubbyBottomNav. The active tab
// is shown as a navy pill (navy fill, white icon) with the icon sitting ON the
// pill in the readable foreground. Inactive tabs are muted. Three tabs:
//   0 Projects . 1 Directory . 2 Account
//
// PARAMETERS (matches the FlutterFlow definition):
//   * width, height        - standard pair (height accepted; bar sizes itself).
//   * currentIndex         - which tab is active on THIS page (0..2).
//   * projectsRouteName / directoryRouteName / accountRouteName
//                          - FF route names; leave null to disable that tab.
//
// Tapping a tab calls context.goNamed(route) (root switch). Empty routes and
// taps on the already-active tab are ignored.
//
// ANDROID SAFE AREA: the row is wrapped in SafeArea(top:false) so the system
// inset (gesture bar / 3-button nav) is reserved automatically; `minimum:
// bottom 8` is a floor for devices with no inset. Place the bar at the very
// bottom of the page, full-bleed, so it owns the inset.

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({
    super.key,
    this.width,
    this.height,
    this.currentIndex = 0,

    // Route names (FF). Leave null to disable navigation for that tab.
    this.projectsRouteName,
    this.directoryRouteName,
    this.accountRouteName,
  });

  final double? width;
  final double? height;

  /// 0 Projects . 1 Directory . 2 Account
  final int currentIndex;

  final String? projectsRouteName;
  final String? directoryRouteName;
  final String? accountRouteName;

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  // PALETTE (matches SubbyBottomNav)
  static const Color _ink = Color(0xFF16202E);
  static const Color _inkMute = Color(0xFF5A6675);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _hairline = Color(0xFFEEF1F4);

  static const String _bodyFont = 'Inter';

  // Tab nav fades in; the 180ms select delay + medium haptic mirror
  // SubbyBottomNav so both bars feel identical on tap.
  static const Duration _selectDelay = Duration(milliseconds: 180);

  late int _selectedIndex;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex.clamp(0, 2);
  }

  @override
  void didUpdateWidget(covariant MainBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.currentIndex.clamp(0, 2);
    if (next != _selectedIndex && mounted) {
      setState(() => _selectedIndex = next);
    }
  }

  String? _routeFor(int index) {
    switch (index) {
      case 0:
        return widget.projectsRouteName;
      case 1:
        return widget.directoryRouteName;
      case 2:
        return widget.accountRouteName;
      default:
        return null;
    }
  }

  Future<void> _handleTap(int index) async {
    index = index.clamp(0, 2);
    // Re-tap of the current tab, or a tap while a switch is in flight, is a
    // silent no-op.
    if (_navigating || index == widget.currentIndex) return;

    // Tab switch = medium tactile tick (fires before the select delay).
    HapticFeedback.mediumImpact();

    setState(() {
      _selectedIndex = index;
      _navigating = true;
    });

    final route = (_routeFor(index) ?? '').trim();
    if (route.isEmpty) {
      setState(() => _navigating = false);
      return;
    }

    try {
      await Future.delayed(_selectDelay);
      if (!mounted) return;

      // All tab navigation fades in.
      context.goNamed(
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
      debugPrint('MainBottomNav navigation failed: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _navigating = false);
      });
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
                  label: 'Projects',
                  icon: Icons.grid_view_rounded,
                  index: 0,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 1,
                  label: 'Directory',
                  icon: Icons.contacts_rounded,
                  index: 1,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 2,
                  label: 'Account',
                  icon: Icons.person_rounded,
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
    required int index,
  }) {
    return InkWell(
      onTap: () => _handleTap(index),
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
                color: active ? _ink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? _paper : _inkMute,
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
}
