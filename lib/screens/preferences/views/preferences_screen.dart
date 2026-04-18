import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';

import 'components/prederence_list_tile.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).cookiePreferences),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(AppLocalizations.of(context).reset),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: defaultPadding),
        child: Column(
          children: [
            PreferencesListTile(
              titleText: AppLocalizations.of(context).analytics,
              subtitleTxt: AppLocalizations.of(context).analyticsDesc,
              isActive: true,
              press: () {},
            ),
            const Divider(height: defaultPadding * 2),
            PreferencesListTile(
              titleText: AppLocalizations.of(context).personalizationCookie,
              subtitleTxt: AppLocalizations.of(context).personalizationDesc,
              isActive: false,
              press: () {},
            ),
            const Divider(height: defaultPadding * 2),
            PreferencesListTile(
              titleText: AppLocalizations.of(context).marketing,
              subtitleTxt: AppLocalizations.of(context).marketingDesc,
              isActive: false,
              press: () {},
            ),
            const Divider(height: defaultPadding * 2),
            PreferencesListTile(
              titleText: AppLocalizations.of(context).socialMediaCookies,
              subtitleTxt: AppLocalizations.of(context).socialMediaDesc,
              isActive: false,
              press: () {},
            ),
          ],
        ),
      ),
    );
  }
}
