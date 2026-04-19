import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';

class BookingNotificationsScreen extends StatefulWidget {
  const BookingNotificationsScreen({super.key});

  @override
  State<BookingNotificationsScreen> createState() =>
      _BookingNotificationsScreenState();
}

class _BookingNotificationsScreenState
    extends State<BookingNotificationsScreen> {
  final ApiServiceReal _api = ApiServiceReal();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final response = await _api.getNotifications(userId: 'user-consumer-1');
    if (response.success && response.data != null) {
      setState(() {
        _notifications = response.data!;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              _api.markAllNotificationsRead('user-consumer-1');
              setState(() {
                _notifications = _notifications
                    .map((n) => NotificationModel(
                          id: n.id,
                          userId: n.userId,
                          type: n.type,
                          title: n.title,
                          body: n.body,
                          data: n.data,
                          isRead: true,
                        ))
                    .toList();
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Theme.of(context).disabledColor),
                      const SizedBox(height: defaultPadding),
                      Text('No notifications',
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
                        onTap: () {
                          if (!notif.isRead) {
                            _api.markNotificationRead(notif.id);
                            setState(() {
                              _notifications[index] = NotificationModel(
                                id: notif.id,
                                userId: notif.userId,
                                type: notif.type,
                                title: notif.title,
                                body: notif.body,
                                data: notif.data,
                                isRead: true,
                              );
                            });
                          }
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

  IconData get _icon {
    switch (notification.type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'payment_received':
        return Icons.payment;
      case 'reminder':
        return Icons.notifications_active;
      case 'review_request':
        return Icons.rate_review;
      case 'provider_message':
        return Icons.message;
      case 'price_drop':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'booking_confirmed':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.red;
      case 'payment_received':
        return Colors.blue;
      case 'reminder':
        return Colors.orange;
      case 'review_request':
        return Colors.purple;
      case 'price_drop':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _iconColor.withOpacity(0.1),
        child: Icon(_icon, color: _iconColor, size: 20),
      ),
      title: Text(
        notification.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
      ),
      subtitle: notification.body != null
          ? Text(notification.body!,
              maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_timeAgo(notification.createdAt),
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
