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
import '/auth/firebase_auth/auth_util.dart';

class SubbyBottomNav extends StatefulWidget {
  const SubbyBottomNav({
    Key? key,
    this.width,
    this.height,
    required this.currentIndex, // 0..2 (SECTION TABS ONLY)
  }) : super(key: key);

  final double? width;
  final double? height;

  /// 0=Home (Directory start), 1=Explore, 2=Bookmarked
  final int currentIndex;

  @override
  State<SubbyBottomNav> createState() => _SubbyBottomNavState();
}

class _SubbyBottomNavState extends State<SubbyBottomNav> {
  // ✅ SECTION Route NAMES (ONLY 3)
  static const String _homeRouteName = 'homePage'; // Directory home/start
  static const String _exploreRouteName = 'explorePage';
  static const String _savedRouteName = 'savedPage';

  static const String _kSavedField = 'savedListingRefs';

  String _routeNameForIndex(int index) {
    if (index == 0) return _homeRouteName;
    if (index == 1) return _exploreRouteName;
    return _savedRouteName;
  }

  /// ✅ Fade transition for section tabs (Home/Explore/Bookmarked)
  void _go(int index) {
    if (index == widget.currentIndex) return;

    context.pushReplacementNamed(
      _routeNameForIndex(index),
      extra: {
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.fade,
          duration: Duration(milliseconds: 180),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // ✅ Content height of the bar (NOT including iPhone home-indicator inset)
    final double contentHeight = (widget.height ?? 74).clamp(64, 86).toDouble();

    // ✅ Include bottom safe-area INSIDE the painted background
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double totalHeight = contentHeight + bottomInset;

    final items = <_NavItemSpec>[
      _NavItemSpec('Home', Icons.home_outlined, Icons.home_rounded),
      _NavItemSpec('Explore', Icons.search_outlined, Icons.search_rounded),
      _NavItemSpec(
        'Bookmarked',
        Icons.bookmark_border_rounded,
        Icons.bookmark_rounded,
      ),
    ];

    final userRef = currentUserReference;
    final inactiveColor = theme.secondaryText.withOpacity(0.78);

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: totalHeight,
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, -6),
              color: Color(0x12000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // top divider line
            Container(
              height: 1,
              color: theme.alternate.withOpacity(0.7),
            ),

            // ✅ Main nav content area (fixed height)
            SizedBox(
              height: contentHeight - 1, // subtract divider
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SECTION TABS (3)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(items.length, (i) {
                          final spec = items[i];
                          final bool active = i == widget.currentIndex;

                          // Bookmarked tab with live count
                          if (i == 2 && userRef != null) {
                            return Expanded(
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: userRef.snapshots(),
                                builder: (context, snap) {
                                  int count = 0;
                                  final data = snap.data?.data()
                                      as Map<String, dynamic>?;

                                  if (data != null &&
                                      data[_kSavedField] is List) {
                                    count = (data[_kSavedField] as List).length;
                                  }

                                  return _FlatNavItem(
                                    label: spec.label,
                                    iconOff: spec.iconOff,
                                    iconOn: spec.iconOn,
                                    active: active,
                                    activeColor: theme.primary,
                                    inactiveColor: inactiveColor,
                                    badgeCount: count,
                                    onTap: () => _go(i),
                                  );
                                },
                              ),
                            );
                          }

                          return Expanded(
                            child: _FlatNavItem(
                              label: spec.label,
                              iconOff: spec.iconOff,
                              iconOn: spec.iconOn,
                              active: active,
                              activeColor: theme.primary,
                              inactiveColor: inactiveColor,
                              onTap: () => _go(i),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Painted safe-area spacer (keeps background to bottom edge)
            if (bottomInset > 0) SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }
}

class _NavItemSpec {
  final String label;
  final IconData iconOff;
  final IconData iconOn;
  _NavItemSpec(this.label, this.iconOff, this.iconOn);
}

/// Flat nav item with optional badge (Subby style)
class _FlatNavItem extends StatelessWidget {
  const _FlatNavItem({
    required this.label,
    required this.iconOff,
    required this.iconOn,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.badgeCount,
  });

  final String label;
  final IconData iconOff;
  final IconData iconOn;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int? badgeCount;

  TextStyle _navLabelStyle(FlutterFlowTheme theme, {required Color color}) {
    final base = theme.labelSmall;
    return base.copyWith(color: color);
  }

  TextStyle _badgeTextStyle(FlutterFlowTheme theme) {
    final base = theme.labelSmall;
    return base.copyWith(color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const double iconSize = 22;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? iconOn : iconOff,
                  size: iconSize,
                  color: active ? activeColor : inactiveColor,
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.secondaryBackground,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : badgeCount.toString(),
                        style: _badgeTextStyle(theme),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _navLabelStyle(
                theme,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
