import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/screens/booking/provider_bookings_screen.dart';
import 'package:munasabati/screens/booking/provider_dashboard_screen.dart';
import 'package:munasabati/screens/profile/views/profile_screen.dart';
import 'package:munasabati/screens/booking/provider_service_management_screen.dart';

class ProviderEntryPoint extends StatefulWidget {
  const ProviderEntryPoint({super.key});

  @override
  State<ProviderEntryPoint> createState() => _ProviderEntryPointState();
}

class _ProviderEntryPointState extends State<ProviderEntryPoint> {
  final List _pages = const [
    ProviderDashboardScreen(),
    ProviderServiceManagementScreen(),
    ProviderBookingsScreen(),
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
                    Theme.of(context).brightness == Brightness.dark ? 0.3 : 1),
            BlendMode.srcIn),
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
          transitionBuilder: (child, animation, secondAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondAnimation,
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
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard, color: primaryColor),
                label: context.tr('dashboard'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.business_outlined),
                activeIcon: const Icon(Icons.business, color: primaryColor),
                label: context.tr('my_services'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                activeIcon:
                    const Icon(Icons.calendar_today, color: primaryColor),
                label: AppLocalizations.of(context).myBookings,
              ),
              BottomNavigationBarItem(
                icon: svgIcon("assets/icons/Profile.svg", color: unselectedColor),
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
