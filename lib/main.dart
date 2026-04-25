import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/locale_provider.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/route/router.dart' as router;
import 'package:munasabati/services/app_analytics_service.dart';
import 'package:munasabati/services/app_links_service.dart';
import 'package:munasabati/services/app_navigation.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:munasabati/services/dio_client.dart';
import 'package:munasabati/services/push_notification_service.dart';
import 'package:munasabati/services/realtime_booking_service.dart';
import 'package:munasabati/services/stripe_payment_service.dart';
import 'package:munasabati/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dioClient.initialize();

  final authProvider = AuthProvider();
  await authProvider.initialize();
  await PushNotificationService.instance.initialize();
  await AppAnalyticsService.instance.initialize();
  await AppLinksService.instance.initialize();
  await StripePaymentService.instance.initialize();
  PushNotificationService.instance.bindAuthProvider(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, auth, booking) {
            final provider = booking ?? BookingProvider();
            provider.bindAuthProvider(auth);
            PushNotificationService.instance.bindAuthProvider(auth);
            AppLinksService.instance.bindProviders(
              authProvider: auth,
              bookingProvider: provider,
            );
            RealtimeBookingService.instance.bindProviders(
              authProvider: auth,
              bookingProvider: provider,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppLinksService.instance.processPendingLink();
  });
}

// Thanks for using our template. You are using the free version of the template.
// 🔗 Full template: https://theflutterway.gumroad.com/l/fluttershop

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.lightTheme(context),
      // Dark theme is inclided in the Full template
      themeMode: ThemeMode.light,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: AppAnalyticsService.instance.navigatorObservers,
      onGenerateRoute: router.generateRoute,
      initialRoute: splashScreenRoute,
    );
  }
}
