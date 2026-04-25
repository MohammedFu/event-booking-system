import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:provider/provider.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      await auth.forgotPassword(_emailController.text.trim());

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetLinkSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.25,
                  minHeight: 120,
                ),
                child: Image.asset(
                  "assets/images/signUp.jpg",
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: defaultPadding * 2),
              if (_emailSent) ...[
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: primaryColor,
                      ),
                      const SizedBox(height: defaultPadding),
                      Text(
                        l10n.resetLinkSent,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      Text(
                        l10n.resetPasswordInstructions,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.back),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  l10n.resetPassword,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: defaultPadding / 2),
                Text(l10n.resetPasswordInstructions),
                const SizedBox(height: defaultPadding * 2),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterYourEmail;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return l10n.pleaseEnterValidEmail;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    onFieldSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.send),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
