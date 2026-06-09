// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ======================= SubbyBottomNav (FULL FILE) =======================
//
// App-shell bottom navigation. The active tab is shown as a pill in that area's
// accent (Home = ink, Explore = saffron, Saved = orange, More = steel) with the
// icon sitting ON the pill in the readable foreground. Inactive tabs are muted.
//
// PARAMETERS (match the FlutterFlow definition — nothing to add):
//   * width, height   - the standard required pair (height is accepted but the
//                       bar sizes itself; pass anything).
//   * currentIndex    - which tab is active on THIS page:
//                       0 Home . 1 Explore . 2 Saved . 3 More
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
    this.currentIndex, // 0 Home . 1 Explore . 2 Saved . 3 More
  });

  final double? width;
  final double? height;
  final int? currentIndex;

  @override
  State<SubbyBottomNav> createState() => _SubbyBottomNavState();
}

class _SubbyBottomNavState extends State<SubbyBottomNav> {
  // PALETTE (matches the app)
  static const Color _ink = Color(0xFF2B3443);
  static const Color _inkMute = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _hairline = Color(0xFFE3E4E8);
  static const Color _orange = Color(0xFFFF7A00);
  static const Color _saffron = Color(0xFFF1BC16);
  static const Color _steel = Color(0xFF9EA3B0);

  static const String _bodyFont = 'Inter';

  // ROUTES (edit to your real FlutterFlow page names)
  static const String _routeHome = 'homePage';
  static const String _routeExplore = 'explorePage';
  static const String _routeSaved = 'savedPage';
  static const String _routeMore = 'morePage';

  @override
  Widget build(BuildContext context) {
    final sel = (widget.currentIndex ?? 0).clamp(0, 3);

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
                  route: _routeHome,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 1,
                  label: 'Explore',
                  icon: Icons.explore_rounded,
                  accent: _saffron,
                  onAccent: _ink,
                  route: _routeExplore,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 2,
                  label: 'Saved',
                  icon: Icons.bookmark_rounded,
                  accent: _orange,
                  onAccent: _ink,
                  route: _routeSaved,
                ),
              ),
              Expanded(
                child: _tab(
                  active: sel == 3,
                  label: 'More',
                  icon: Icons.menu_rounded,
                  accent: _steel,
                  onAccent: _ink,
                  route: _routeMore,
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
    required String route,
  }) {
    return InkWell(
      onTap: () => _navigate(route),
      borderRadius: BorderRadius.circular(16),
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

  void _navigate(String route) {
    final target = route.trim();
    if (target.isEmpty) return;

    // Tab semantics: switch branch rather than stack pages. go_router's
    // goNamed replaces the location; fall back to pushNamed if the name
    // isn't registered for go.
    try {
      context.goNamed(target);
    } catch (_) {
      try {
        context.pushNamed(target);
      } catch (_) {
        // route name not found - update the _route* constants above
      }
    }
  }
}
