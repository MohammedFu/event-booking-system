import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/locale_provider.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/route/router.dart' as router;
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:munasabati/services/dio_client.dart';
import 'package:munasabati/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dioClient.initialize();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
      onGenerateRoute: router.generateRoute,
      initialRoute: splashScreenRoute,
    );
  }
}
