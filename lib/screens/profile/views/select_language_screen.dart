import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/l10n/locale_provider.dart';

class SelectLanguageScreen extends StatelessWidget {
  const SelectLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          _LanguageTile(
            title: l10n.english,
            subtitle: 'English',
            locale: const Locale('en'),
            isSelected: localeProvider.locale.languageCode == 'en',
            onTap: () => localeProvider.setLocale(const Locale('en')),
          ),
          const SizedBox(height: defaultPadding),
          _LanguageTile(
            title: l10n.arabic,
            subtitle: 'العربية',
            locale: const Locale('ar'),
            isSelected: localeProvider.locale.languageCode == 'ar',
            onTap: () => localeProvider.setLocale(const Locale('ar')),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        side: BorderSide(
          color: isSelected
              ? primaryColor
              : Theme.of(context).dividerColor,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: primaryColor)
          : null,
    );
  }
}
