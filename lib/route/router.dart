import 'package:flutter/material.dart';
import 'package:munasabati/entry_point.dart';
import 'package:munasabati/models/booking_models.dart';

import 'screen_export.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case splashScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      );
    case onbordingScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const OnBordingScreen(),
      );
    case logInScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    case selectLanguageScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SelectLanguageScreen(),
      );
    case bookingHomeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookingHomeScreen(),
      );
    case serviceListingScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final serviceType = settings.arguments as ServiceType?;
          return ServiceListingScreen(serviceType: serviceType);
        },
      );
    case serviceDetailScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final service = settings.arguments as ServiceModel?;
          if (service == null) {
            return const Scaffold(
              body: Center(child: Text('Service not found')),
            );
          }
          return ServiceDetailScreen(service: service);
        },
      );
    case dateTimePickerScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final service = settings.arguments as ServiceModel?;
          if (service == null) {
            return const Scaffold(
              body: Center(child: Text('Service not found')),
            );
          }
          return DateTimePickerScreen(service: service);
        },
      );
    case bookingCartScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookingCartScreen(),
      );
    case bookingConfirmationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookingConfirmationScreen(),
      );
    case myBookingsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const MyBookingsScreen(),
      );
    case bookingDetailScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final booking = settings.arguments as BookingModel?;
          if (booking == null) {
            return const Scaffold(
              body: Center(child: Text('Booking not found')),
            );
          }
          return BookingDetailScreen(booking: booking);
        },
      );
    case providerDashboardScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProviderDashboardScreen(),
      );
    case providerBookingsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProviderBookingsScreen(),
      );
    case providerAvailabilityScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final service = settings.arguments as ServiceModel?;
          if (service == null) {
            return const Scaffold(
              body: Center(child: Text('Service not found')),
            );
          }
          return ProviderAvailabilityScreen(
            serviceId: service.id,
            serviceTitle: service.title,
          );
        },
      );
    case providerPricingRulesScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final service = settings.arguments as ServiceModel?;
          if (service == null) {
            return const Scaffold(
              body: Center(child: Text('Service not found')),
            );
          }
          return ProviderPricingRulesScreen(service: service);
        },
      );
    case providerServiceManagementScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProviderServiceManagementScreen(),
      );
    case providerEntryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProviderEntryPoint(),
      );
    case bookingSearchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookingSearchScreen(),
      );
    case bookingNotificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookingNotificationsScreen(),
      );
    case bookingReviewsScreenRoute:
      return MaterialPageRoute(
        builder: (context) {
          final args = settings.arguments as Map<String, String>?;
          return BookingReviewsScreen(
            serviceId: args?['serviceId'] ?? '',
            serviceTitle: args?['serviceTitle'] ?? '',
          );
        },
      );
    case bookingBookmarksScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookingBookmarksScreen(),
      );
    case bookingSuccessScreenRoute:
      return MaterialPageRoute(
        builder: (context) =>
            BookingSuccessScreen(booking: settings.arguments as BookingModel?),
      );
    case authScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      );
    case userPreferencesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const UserPreferencesScreen(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const OnBordingScreen(),
      );
  }
}
