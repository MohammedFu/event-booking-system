import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/route/screen_export.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  final List<Widget> _pages = const [
    BookingHomeScreen(),
    ServiceListingScreen(),
    BookingBookmarksScreen(),
    ProfileScreen(),
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unselectedColor = Theme.of(context)
            .textTheme
            .bodySmall
            ?.color
            ?.withOpacity(0.7) ??
        Colors.grey;

    SvgPicture svgIcon(String src, {Color? color}) {
      return SvgPicture.asset(
        src,
        height: 24,
        colorFilter: ColorFilter.mode(
          color ??
              Theme.of(context).iconTheme.color!.withOpacity(
                    Theme.of(context).brightness == Brightness.dark ? 0.3 : 1,
                  ),
          BlendMode.srcIn,
        ),
      );
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: PageTransitionSwitcher(
          duration: defaultDuration,
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(top: defaultPadding / 2),
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : const Color(0xFF101015),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index != _currentIndex) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : const Color(0xFF101015),
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 12,
            selectedItemColor: primaryColor,
            unselectedItemColor: unselectedColor,
            items: [
              BottomNavigationBarItem(
                icon: svgIcon("assets/icons/Shop.svg", color: unselectedColor),
                activeIcon:
                    svgIcon("assets/icons/Shop.svg", color: primaryColor),
                label: AppLocalizations.of(context).book,
              ),
              BottomNavigationBarItem(
                icon:
                    svgIcon("assets/icons/Category.svg", color: unselectedColor),
                activeIcon:
                    svgIcon("assets/icons/Category.svg", color: primaryColor),
                label: AppLocalizations.of(context).discover,
              ),
              BottomNavigationBarItem(
                icon:
                    svgIcon("assets/icons/Bookmark.svg", color: unselectedColor),
                activeIcon:
                    svgIcon("assets/icons/Bookmark.svg", color: primaryColor),
                label: AppLocalizations.of(context).bookmark,
              ),
              BottomNavigationBarItem(
                icon:
                    svgIcon("assets/icons/Profile.svg", color: unselectedColor),
                activeIcon:
                    svgIcon("assets/icons/Profile.svg", color: primaryColor),
                label: AppLocalizations.of(context).profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
