import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final l10n = AppLocalizations.of(context);
    final isProvider = user?.role == UserRole.provider;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: defaultPadding * 1.5),
          if (!auth.isAuthenticated) ...[
            Text(
              'Sign in to manage your bookings, saved services, and notifications.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, authScreenRoute),
              child: Text(l10n.login),
            ),
          ] else ...[
            _SectionTitle(title: l10n.account),
            _MenuTile(
              icon: Icons.event_note_outlined,
              label: l10n.myBookings,
              onTap: () => Navigator.pushNamed(context, myBookingsScreenRoute),
            ),
            _MenuTile(
              icon: Icons.bookmark_outline,
              label: l10n.savedServices,
              onTap: () =>
                  Navigator.pushNamed(context, bookingBookmarksScreenRoute),
            ),
            _MenuTile(
              icon: Icons.notifications_none_outlined,
              label: l10n.notifications,
              onTap: () => Navigator.pushNamed(
                context,
                bookingNotificationsScreenRoute,
              ),
            ),
            _MenuTile(
              icon: Icons.tune_rounded,
              label: l10n.preferences,
              onTap: () => Navigator.pushNamed(
                context,
                userPreferencesScreenRoute,
              ),
            ),
            if (isProvider) ...[
              _SectionTitle(title: context.tr('dashboard')),
              _MenuTile(
                icon: Icons.dashboard_outlined,
                label: context.tr('dashboard'),
                onTap: () => Navigator.pushNamed(
                  context,
                  providerEntryPointScreenRoute,
                ),
              ),
              _MenuTile(
                icon: Icons.business_center_outlined,
                label: context.tr('my_services'),
                onTap: () => Navigator.pushNamed(
                  context,
                  providerServiceManagementScreenRoute,
                ),
              ),
            ],
          ],
          const SizedBox(height: defaultPadding),
          _SectionTitle(title: l10n.settings),
          _MenuTile(
            icon: Icons.language_outlined,
            label: l10n.language,
            onTap: () => Navigator.pushNamed(context, selectLanguageScreenRoute),
          ),
          if (auth.isAuthenticated) ...[
            const SizedBox(height: defaultPadding),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    logInScreenRoute,
                    (route) => false,
                  );
                }
              },
              icon: SvgPicture.asset(
                "assets/icons/Logout.svg",
                height: 20,
                width: 20,
                colorFilter: const ColorFilter.mode(
                  errorColor,
                  BlendMode.srcIn,
                ),
              ),
              label: Text(
                l10n.logOut,
                style: const TextStyle(color: errorColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: errorColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final hasUser = user != null;
    final initials = hasUser
        ? user!.fullName
            .trim()
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join()
        : 'G';

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: primaryColor.withOpacity(0.15),
            child: Text(
              initials.isEmpty ? 'G' : initials,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUser ? user!.fullName : 'Guest account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasUser ? user!.email : 'Sign in to sync your bookings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (user?.isVerified == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ED573).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocalizations.of(context).verified,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF1F8A4D),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding / 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding / 2),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: primaryColor),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
