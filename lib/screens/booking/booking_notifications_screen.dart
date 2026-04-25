import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/notification_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/screens/booking/notification_detail_screen.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/booking_cache_service.dart';
import 'package:provider/provider.dart';

class BookingNotificationsScreen extends StatefulWidget {
  const BookingNotificationsScreen({super.key});

  @override
  State<BookingNotificationsScreen> createState() =>
      _BookingNotificationsScreenState();
}

class _BookingNotificationsScreenState
    extends State<BookingNotificationsScreen> {
  final ApiServiceReal _api = ApiServiceReal();
  final BookingCacheService _cache = BookingCacheService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (context.read<AuthProvider>().isAuthenticated) {
      _loadNotifications();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.getNotifications();
    if (!mounted) return;

    if (response.success && response.data != null) {
      await _cache.cacheNotifications(userId, response.data!);
      if (!mounted) return;

      setState(() {
        _notifications = response.data!;
        _error = null;
        _isLoading = false;
      });
      return;
    }

    final cachedNotifications = await _cache.getNotifications(userId);
    if (!mounted) return;

    setState(() {
      _notifications = cachedNotifications ?? [];
      _error = cachedNotifications == null
          ? response.error ?? context.tr('notifications_load_error')
          : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: defaultPadding),
                Text(
                  context.tr('notifications_sign_in_hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, authScreenRoute),
                  child: Text(l10n.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty
                ? null
                : () async {
                    final response = await _api.markAllNotificationsRead();
                    if (!mounted || !response.success) return;
                    final updatedNotifications = _notifications
                        .map((n) => NotificationModel(
                              id: n.id,
                              userId: n.userId,
                              type: n.type,
                              title: n.title,
                              body: n.body,
                              data: n.data,
                              isRead: true,
                              createdAt: n.createdAt,
                            ))
                        .toList();
                    if (userId != null) {
                      await _cache.cacheNotifications(
                        userId,
                        updatedNotifications,
                      );
                    }
                    if (!mounted) return;
                    setState(() {
                      _notifications = updatedNotifications;
                    });
                  },
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: defaultPadding),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Theme.of(context).disabledColor),
                          const SizedBox(height: defaultPadding),
                          Text(l10n.noNotifications,
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(defaultPadding),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return _NotificationTile(
                            notification: notif,
                            onTap: () async {
                              if (!notif.isRead) {
                                final response =
                                    await _api.markNotificationRead(notif.id);
                                if (!context.mounted || !response.success) {
                                  return;
                                }
                                final updatedNotification = NotificationModel(
                                  id: notif.id,
                                  userId: notif.userId,
                                  type: notif.type,
                                  title: notif.title,
                                  body: notif.body,
                                  data: notif.data,
                                  isRead: true,
                                  createdAt: notif.createdAt,
                                );
                                final updatedNotifications =
                                    List<NotificationModel>.from(
                                  _notifications,
                                )..[index] = updatedNotification;
                                if (userId != null) {
                                  await _cache.cacheNotifications(
                                    userId,
                                    updatedNotifications,
                                  );
                                }
                                if (!context.mounted) return;
                                setState(() {
                                  _notifications = updatedNotifications;
                                });
                              }

                              final selectedNotification =
                                  _notifications[index];
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationDetailScreen(
                                    notification: selectedNotification,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  String _timeAgo(DateTime dt, BuildContext context) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${AppLocalizations.of(context).translate('minutes_ago_suffix')}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}${AppLocalizations.of(context).translate('hours_ago_suffix')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}${AppLocalizations.of(context).translate('days_ago_suffix')}';
    }
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final presentation = notification.presentation(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.iconColor.withOpacity(0.1),
        child: Icon(notification.iconData,
            color: notification.iconColor, size: 20),
      ),
      title: Text(
        presentation.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
      ),
      subtitle: presentation.body != null
          ? Text(presentation.body!,
              maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_timeAgo(notification.createdAt, context),
              style: Theme.of(context).textTheme.bodySmall),
          if (!notification.isRead)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: defaultPadding / 2,
        vertical: defaultPadding / 4,
      ),
    );
  }
}
