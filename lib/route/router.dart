import 'package:flutter/material.dart';
import 'package:munasabati/entry_point.dart';
import 'package:munasabati/models/booking_models.dart';

import 'screen_export.dart';

// Yuo will get 50+ screens and more once you have the full template
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

// NotificationPermissionScreen()
// PreferredLanguageScreen()
// SelectLanguageScreen()
// SignUpVerificationScreen()
// ProfileSetupScreen()
// VerificationMethodScreen()
// OtpScreen()
// SetNewPasswordScreen()
// DoneResetPasswordScreen()
// TermsOfServicesScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFingerprintScreen()
// SetupFaceIdScreen()
// OnSaleScreen()
// BannerLStyle2()
// BannerLStyle3()
// BannerLStyle4()
// SearchScreen()
// SearchHistoryScreen()
// NotificationsScreen()
// EnableNotificationScreen()
// NoNotificationScreen()
// NotificationOptionsScreen()
// ProductInfoScreen()
// ShippingMethodsScreen()
// ProductReviewsScreen()
// SizeGuideScreen()
// BrandScreen()
// CartScreen()
// EmptyCartScreen()
// PaymentMethodScreen()
// ThanksForOrderScreen()
// CurrentPasswordScreen()
// EditUserInfoScreen()
// OrdersScreen()
// OrderProcessingScreen()
// OrderDetailsScreen()
// CancleOrderScreen()
// DelivereOrdersdScreen()
// AddressesScreen()
// NoAddressScreen()
// AddNewAddressScreen()
// ServerErrorScreen()
// NoInternetScreen()
// ChatScreen()
// DiscoverWithImageScreen()
// SubDiscoverScreen()
// AddNewCardScreen()
// EmptyPaymentScreen()
// GetHelpScreen()

// ℹ️ All the comments screen are included in the full template
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

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
    // case preferredLanuageScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const PreferredLanguageScreen(),
    //   );
    case logInScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case signUpScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
    // case profileSetupScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ProfileSetupScreen(),
    //   );
    case passwordRecoveryScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PasswordRecoveryScreen(),
      );
    // case verificationMethodScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const VerificationMethodScreen(),
    //   );
    // case otpScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OtpScreen(),
    //   );
    // case newPasswordScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SetNewPasswordScreen(),
    //   );
    // case doneResetPasswordScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const DoneResetPasswordScreen(),
    //   );
    // case termsOfServicesScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const TermsOfServicesScreen(),
    //   );
    // case noInternetScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const NoInternetScreen(),
    //   );
    // case serverErrorScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ServerErrorScreen(),
    //   );
    // case signUpVerificationScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SignUpVerificationScreen(),
    //   );
    // case setupFingerprintScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SetupFingerprintScreen(),
    //   );
    // case setupFaceIdScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SetupFaceIdScreen(),
    //   );
    // Shopping routes commented out - converting to booking-only app
    // case productDetailsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) {
    //       bool isProductAvailable = settings.arguments as bool? ?? true;
    //       return ProductDetailsScreen(isProductAvailable: isProductAvailable);
    //     },
    //   );
    // case productReviewsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ProductReviewsScreen(),
    //   );
    // case addReviewsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const AddReviewScreen(),
    //   );
    case homeScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      );
    // case brandScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const BrandScreen(),
    //   );
    // case discoverWithImageScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const DiscoverWithImageScreen(),
    //   );
    // case subDiscoverScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SubDiscoverScreen(),
    //   );
    case discoverScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const DiscoverScreen(),
      );
    // Shopping routes commented out - converting to booking-only app
    // case onSaleScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OnSaleScreen(),
    //   );
    // case kidsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const KidsScreen(),
    //   );
    case searchScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      );
    // case searchHistoryScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const SearchHistoryScreen(),
    //   );
    case bookmarkScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const BookmarkScreen(),
      );
    case entryPointScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EntryPoint(),
      );
    case profileScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      );
    // case getHelpScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const GetHelpScreen(),
    //   );
    // case chatScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ChatScreen(),
    //   );
    case userInfoScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const UserInfoScreen(),
      );
    // case currentPasswordScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CurrentPasswordScreen(),
    //   );
    // case editUserInfoScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const EditUserInfoScreen(),
    //   );
    case notificationsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      );
    case noNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NoNotificationScreen(),
      );
    case enableNotificationScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EnableNotificationScreen(),
      );
    case notificationOptionsScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const NotificationOptionsScreen(),
      );
    case selectLanguageScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const SelectLanguageScreen(),
      );
    // case noAddressScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const NoAddressScreen(),
    //   );
    case addressesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const AddressesScreen(),
      );
    // case addNewAddressesScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const AddNewAddressScreen(),
    //   );
    // Shopping orders routes commented out - converting to booking-only app
    // case ordersScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OrdersScreen(),
    //   );
    // case orderProcessingScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OrderProcessingScreen(),
    //   );
    // case orderDetailsScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const OrderDetailsScreen(),
    //   );
    // case cancleOrderScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CancleOrderScreen(),
    //   );
    // case deliveredOrdersScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const DelivereOrdersdScreen(),
    //   );
    // case cancledOrdersScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CancledOrdersScreen(),
    //   );
    case preferencesScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const PreferencesScreen(),
      );
    // case emptyPaymentScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const EmptyPaymentScreen(),
    //   );
    case emptyWalletScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const EmptyWalletScreen(),
      );
    case walletScreenRoute:
      return MaterialPageRoute(
        builder: (context) => const WalletScreen(),
      );
    // Shopping cart route commented out - converting to booking-only app
    // case cartScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const CartScreen(),
    //   );
    // case paymentMethodScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const PaymentMethodScreen(),
    //   );
    // case addNewCardScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const AddNewCardScreen(),
    //   );
    // case thanksForOrderScreenRoute:
    //   return MaterialPageRoute(
    //     builder: (context) => const ThanksForOrderScreen(),
    //   );

    // Booking System Routes
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
        builder: (context) => const BookingSuccessScreen(),
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
        builder: (context) => const BookingSuccessScreen(),
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
        // Make a screen for undefine
        builder: (context) => const OnBordingScreen(),
      );
  }
}
