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

import 'package:flutter/services.dart'; // HapticFeedback (LIGHT impact on tab tap)

// Subby bottom nav — matches DashboardPageView (Option C).
// Three destinations only — More lives in the top-right menu button, not here.
// Place at the bottom of your page scaffolds. Set `currentIndex` per page
// (0 Projects · 1 Directory · 2 Account) so the right tab lights up, and pass
// the FF route names for the tabs you want it to navigate to.
//
// Tapping a tab calls context.goNamed(route) (root switch). Empty routes are
// ignored. Taps on the already-active tab still give feedback (pill press +
// haptic) but do not navigate.
//
// UPDATE (this revision):
//   • Haptic is now LIGHT impact (was medium) on every tab tap.
//   • The active INK pill (#3D4F66) now SLIDES horizontally to the tapped tab
//     with a springy curve, and the tapped icon does a quick press "pop".
//     (Previously the pill just appeared under the active tab with a route
//     cross-fade.)

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

class _MainBottomNavState extends State<MainBottomNav>
    with SingleTickerProviderStateMixin {
  // ─── SUBBY PALETTE (LOCK) ──────────────────────────────────────────
  static const Color _ink = Color(0xFF3D4F66); // active pill + active label
  static const Color _faint = Color(0xFF93A3AC); // inactive
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _surface =
      Color(0xFFECF0F2); // top hairline (matches dock)
  // ────────────────────────────────────────────────────────────────────

  static const double _barHeight = 72;
  static const int _tabCount = 3;

  // Pill geometry (matches the old selected pill: 22px icon + 18/3 padding).
  static const double _pillWidth = 58;
  static const double _pillHeight = 34;

  // Which tab the pill currently sits on. Seeded from currentIndex, then
  // driven locally so the pill can slide immediately on tap (before the route
  // rebuild lands).
  late int _pillIndex = widget.currentIndex;

  // Press "pop" on the tapped icon.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(covariant MainBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      setState(() => _pillIndex = widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
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

  void _handleTap(int index) {
    // LIGHT haptic on every tab tap.
    HapticFeedback.lightImpact();

    // Slide the pill + fire the press pop immediately (even on the active tab).
    setState(() => _pillIndex = index);
    _pop.forward(from: 0);

    if (index == widget.currentIndex) return;

    final route = (_routeFor(index) ?? '').trim();
    if (route.isEmpty) return;

    // Fade between tabs — no slide. 320ms so the cross-fade reads.
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
    final bool selected = index == _pillIndex;
    final Color color = selected ? _ink : _faint;
    // Active icon sits inside the ink pill → render it white.
    final Color iconColor = selected ? _paper : _faint;

    // Press pop scales the tapped icon down and back.
    final Widget icon = Icon(selected ? activeIcon : inactiveIcon,
        size: selected ? 22 : 23, color: iconColor);

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
              SizedBox(
                height: _pillHeight,
                child: Center(
                  child: selected
                      ? ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1).animate(
                            TweenSequence<double>([
                              TweenSequenceItem(
                                  tween: Tween(begin: 1.0, end: 0.82)
                                      .chain(CurveTween(curve: Curves.easeOut)),
                                  weight: 40),
                              TweenSequenceItem(
                                  tween: Tween(begin: 0.82, end: 1.0)
                                      .chain(CurveTween(curve: Curves.easeOut)),
                                  weight: 60),
                            ]).animate(_pop),
                          ),
                          child: icon,
                        )
                      : icon,
                ),
              ),
              const SizedBox(height: 5),
              // Colour cross-fades between selected/unselected.
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                  letterSpacing: 0.0,
                ),
                child: Text(label),
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
        boxShadow: [
          BoxShadow(
            color: Color(0x0F29343A), // ~6% ink
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding:
          EdgeInsets.only(top: 12, bottom: bottomInset, left: 24, right: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double slotWidth = constraints.maxWidth / _tabCount;
          // Centre the pill within the destination slot.
          final double pillLeft =
              _pillIndex * slotWidth + (slotWidth - _pillWidth) / 2;

          return Stack(
            children: [
              // ── Sliding ink pill ─────────────────────────────────────
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack, // springy overshoot
                left: pillLeft,
                top: -2,
                width: _pillWidth,
                height: _pillHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // ── Tabs on top of the pill ──────────────────────────────
              Row(
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
                    label: 'Network',
                  ),
                  _navItem(
                    index: 2,
                    activeIcon: Icons.person_rounded,
                    inactiveIcon: Icons.person_outline_rounded,
                    label: 'Account',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
