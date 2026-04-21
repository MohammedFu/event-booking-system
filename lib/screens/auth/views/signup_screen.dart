import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/screens/auth/views/components/sign_up_form.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.consumer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.registrationFailed),
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

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Navigate based on selected role
      if (_selectedRole == UserRole.provider) {
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
      final errorMsg =
          auth.error ?? AppLocalizations.of(context).registrationFailed;
      // Check for specific error types and show user-friendly message
      final l10n = AppLocalizations.of(context);
      String userMessage;
      if (errorMsg.toLowerCase().contains('timeout') ||
          errorMsg.toLowerCase().contains('connection')) {
        userMessage = l10n.errorServerConnection;
      } else if (errorMsg.toLowerCase().contains('already exists') ||
          errorMsg.toLowerCase().contains('duplicate') ||
          errorMsg.toLowerCase().contains('409')) {
        userMessage = l10n.errorEmailExists;
      } else if (errorMsg.toLowerCase().contains('network')) {
        userMessage = l10n.errorNetwork;
      } else if (errorMsg.toLowerCase().contains('validation') ||
          errorMsg.toLowerCase().contains('invalid')) {
        userMessage = l10n.errorValidation;
      } else {
        userMessage = '${l10n.registrationFailed}: $errorMsg';
      }
      _showErrorDialog(userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/signUp.jpg",
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).letsGetStarted,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    AppLocalizations.of(context).signUpDesc,
                  ),
                  const SizedBox(height: defaultPadding),
                  SignUpForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) {
                      setState(() {
                        _selectedRole = role;
                      });
                    },
                  ),
                  const SizedBox(height: defaultPadding),
                  Row(
                    children: [
                      Checkbox(
                        onChanged: (value) {},
                        value: false,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text:
                                "${AppLocalizations.of(context).iAgreeWithThe} ",
                            children: [
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushNamed(
                                        context, termsOfServicesScreenRoute);
                                  },
                                text:
                                    " ${AppLocalizations.of(context).termsOfService} ",
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text:
                                    "& ${AppLocalizations.of(context).privacyPolicy}.",
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: defaultPadding * 2),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context).continueLabel),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).doYouHaveAccount),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, logInScreenRoute);
                        },
                        child: Text(AppLocalizations.of(context).logIn),
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
