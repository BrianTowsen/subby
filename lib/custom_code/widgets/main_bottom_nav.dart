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

import 'package:flutter/services.dart'; // HapticFeedback (medium impact on tab tap)

import '/custom_code/widgets/index.dart'; // (kept if FF expects it)

// Subby bottom nav — matches DashboardPageView (Option C).
// Three destinations only — More lives in the top-right menu button, not here.
// Place at the bottom of your page scaffolds. Set `currentIndex` per page
// (0 Projects · 1 Directory · 2 Account) so the right tab lights up, and pass
// the FF route names for the tabs you want it to navigate to.
//
// Tapping a tab calls context.goNamed(route) (root switch). Empty routes and
// taps on the already-active tab are ignored.
//
// UPDATE (this revision):
//   • Active tab pill is now INK (#29343A) with a WHITE icon (was the sage
//     green pill).
//   • The bar is a BRIGHT-WHITE ELEVATED shell — hairline top border plus a
//     soft upward drop shadow — to match the DetailTaskView dock treatment.

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

  /// 0 Projects · 1 Directory · 2 Account
  final int currentIndex;

  final String? projectsRouteName;
  final String? directoryRouteName;
  final String? accountRouteName;

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF808789); // active pill + active label
  static const Color _faint = Color(0xFF93A3AC); // inactive
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface =
      Color(0xFFECF0F2); // top hairline (matches dock)
  // ────────────────────────────────────────────────────────────────────

  static const double _barHeight = 72;

  // Active pill — INK on every tab (icon rendered white inside it).
  Color _activeColorFor(int index) => _ink;

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

  void _handleTap(int index) {
    // Medium haptic on every tab tap.
    HapticFeedback.mediumImpact();

    if (index == widget.currentIndex) return;

    final route = (_routeFor(index) ?? '').trim();
    if (route.isEmpty) return;

    // Fade between tabs — no slide. Slowed to 320ms so the cross-fade reads.
    context.goNamed(
      route,
      extra: <String, dynamic>{
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: Duration(milliseconds: 320),
        ),
      },
    );
  }

  Widget _navItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final bool selected = index == widget.currentIndex;
    final Color color = selected ? _ink : _faint;
    // Active icon sits inside the ink pill → render it white.
    final Color iconColor = selected ? _paper : _faint;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(index),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: selected
                    ? const EdgeInsets.symmetric(horizontal: 18, vertical: 3)
                    : EdgeInsets.zero,
                decoration: selected
                    ? BoxDecoration(
                        color: _activeColorFor(index),
                        borderRadius: BorderRadius.circular(999),
                      )
                    : null,
                child: Icon(selected ? activeIcon : inactiveIcon,
                    size: selected ? 22 : 23, color: iconColor),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: widget.width ?? double.infinity,
      height: (widget.height ?? _barHeight) + bottomInset,
      // Bright-white ELEVATED shell — hairline top border + soft upward shadow
      // (matches the DetailTaskView dock).
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(top: BorderSide(color: Color(0xFFEAEEF0), width: 1)),
      ),
      // Three roomy tabs — a little extra horizontal inset keeps them centred.
      // top:12 gives the pill + icons more breathing room from the top edge.
      padding:
          EdgeInsets.only(top: 12, bottom: bottomInset, left: 24, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _navItem(
            index: 0,
            activeIcon: Icons.grid_view_rounded,
            inactiveIcon: Icons.grid_view_outlined,
            label: 'Projects',
          ),
          _navItem(
            index: 1,
            activeIcon: Icons.contacts_rounded,
            inactiveIcon: Icons.contacts_outlined,
            label: 'Directory',
          ),
          _navItem(
            index: 2,
            activeIcon: Icons.person_rounded,
            inactiveIcon: Icons.person_outline_rounded,
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
