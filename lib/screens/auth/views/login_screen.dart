import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _error;

  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _rememberMe = rememberMe;
        _emailController.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loginFailed),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_savedEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await _saveLoginInfo();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      final auth = context.read<AuthProvider>();
      final userRole = auth.user?.role;

      // Navigate based on user role
      if (userRole == UserRole.provider) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          providerEntryPointScreenRoute,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          entryPointScreenRoute,
          (route) => false,
        );
      }
    } else if (mounted) {
      final errorMsg = auth.error ?? AppLocalizations.of(context).loginFailed;
      // Check for specific error types and show user-friendly message
      final l10n = AppLocalizations.of(context);
      String userMessage;
      if (errorMsg.toLowerCase().contains('timeout') ||
          errorMsg.toLowerCase().contains('connection')) {
        userMessage = l10n.errorServerConnection;
      } else if (errorMsg.toLowerCase().contains('invalid') ||
          errorMsg.toLowerCase().contains('unauthorized') ||
          errorMsg.toLowerCase().contains('401')) {
        userMessage = l10n.errorWrongCredentials;
      } else if (errorMsg.toLowerCase().contains('network')) {
        userMessage = l10n.errorNetwork;
      } else {
        userMessage = '${l10n.loginFailed}: $errorMsg';
      }
      _showErrorDialog(userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: size.height * 0.35,
                minHeight: 150,
              ),
              child: Image.asset(
                "assets/images/signUp.jpg",
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).welcomeBack,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    AppLocalizations.of(context).loginDesc,
                  ),
                  const SizedBox(height: defaultPadding),
                  LogInForm(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    rememberMe: _rememberMe,
                    onRememberMeChanged: (value) {
                      setState(() => _rememberMe = value);
                    },
                  ),
                  Align(
                    child: TextButton(
                      child: Text(AppLocalizations.of(context).forgotPassword),
                      onPressed: () {
                        Navigator.pushNamed(
                            context, passwordRecoveryScreenRoute);
                      },
                    ),
                  ),
                  SizedBox(
                    height:
                        size.height > 700 ? defaultPadding * 2 : defaultPadding,
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context).logIn),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).dontHaveAccount),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, signUpScreenRoute);
                        },
                        child: Text(AppLocalizations.of(context).signUp),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
