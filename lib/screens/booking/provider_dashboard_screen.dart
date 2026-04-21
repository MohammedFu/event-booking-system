import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    await auth.syncCurrentUser(silent: true);
    if (!mounted) return;

    await bookingProvider.fetchProviderDashboardData();
  }

  Future<void> _updateBookingStatus(
    BookingModel booking,
    BookingStatus status,
  ) async {
    if (booking.items.isEmpty) return;

    final provider = context.read<BookingProvider>();
    final success = await provider.updateProviderBookingStatus(
      bookingItemId: booking.items.first.id,
      status: status,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? context.tr('error_fetch_bookings')),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    await _fetchData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == BookingStatus.confirmed
              ? context.tr('accepted_booking', params: {
                  'event': booking.eventName ?? context.tr('event'),
                })
              : context.tr('rejected_booking', params: {
                  'event': booking.eventName ?? context.tr('event'),
                }),
        ),
        backgroundColor: status == BookingStatus.confirmed
            ? const Color(0xFF2ED573)
            : errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isProvider = auth.user?.role == UserRole.provider;

    if (!isProvider) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('provider_dashboard')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(
              context.tr('provider_access_only'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('provider_dashboard')),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          final stats = provider.providerDashboard;
          final pendingRequests = provider.providerBookings
              .where((booking) => booking.status == BookingStatus.pending)
              .take(5)
              .toList();
          final hasDashboardData = stats.totalBookings > 0 ||
              stats.pendingBookings > 0 ||
              pendingRequests.isNotEmpty;

          if (provider.isLoading && !hasDashboardData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && !hasDashboardData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton(
                      onPressed: _fetchData,
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchData,
            child: ListView(
              padding: const EdgeInsets.all(defaultPadding),
              children: [
                _buildStatsGrid(context, stats),
                const SizedBox(height: 24),
                Text(
                  context.tr('recent_booking_requests'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (pendingRequests.isEmpty)
                  _EmptyDashboardCard(
                    message: context.tr('no_upcoming_bookings'),
                  )
                else
                  ...pendingRequests.map(
                    (booking) => _BookingRequestCard(
                      booking: booking,
                      onAccept: () => _updateBookingStatus(
                          booking, BookingStatus.confirmed),
                      onReject: () => _updateBookingStatus(
                          booking, BookingStatus.cancelled),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  context.tr('quick_actions'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ProviderDashboardStats stats) {
    final cards = [
      _StatItem(
        label: context.tr('total_bookings'),
        value: stats.totalBookings.toString(),
        icon: Icons.calendar_month,
        color: primaryColor,
      ),
      _StatItem(
        label: context.tr('revenue'),
        value: stats.totalRevenue.toStringAsFixed(0),
        icon: Icons.attach_money,
        color: const Color(0xFF2ED573),
      ),
      _StatItem(
        label: context.tr('status_pending'),
        value: stats.pendingBookings.toString(),
        icon: Icons.pending_actions,
        color: const Color(0xFFFFBE21),
      ),
      _StatItem(
        label: AppLocalizations.of(context).rating,
        value: stats.averageRating.toStringAsFixed(1),
        icon: Icons.star,
        color: const Color(0xFFFFBE21),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final stat = cards[index];
        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, providerBookingsScreenRoute);
          },
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
              color: stat.color.withOpacity(0.05),
              border: Border.all(color: stat.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(stat.icon, color: stat.color, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      stat.label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.calendar_today,
        label: context.tr('manage_availability'),
        color: primaryColor,
        onTap: () => Navigator.pushNamed(
          context,
          providerServiceManagementScreenRoute,
        ),
      ),
      _QuickAction(
        icon: Icons.room_service,
        label: context.tr('manage_services'),
        color: const Color(0xFF2ED573),
        onTap: () => Navigator.pushNamed(
          context,
          providerServiceManagementScreenRoute,
        ),
      ),
      _QuickAction(
        icon: Icons.attach_money,
        label: context.tr('set_pricing'),
        color: const Color(0xFFFFBE21),
        onTap: () => Navigator.pushNamed(
          context,
          providerServiceManagementScreenRoute,
        ),
      ),
      _QuickAction(
        icon: Icons.receipt_long,
        label: AppLocalizations.of(context).myBookings,
        color: const Color(0xFFEA5B5B),
        onTap: () => Navigator.pushNamed(context, providerBookingsScreenRoute),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions.map((action) {
        return GestureDetector(
          onTap: action.onTap,
          child: SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _BookingRequestCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingRequestCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final serviceTitle = booking.items.isNotEmpty
        ? booking.items.first.service?.title ?? context.tr('service')
        : context.tr('service');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.eventName ?? serviceTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFBE21).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.status.label(context),
                  style: const TextStyle(
                    color: Color(0xFFFFBE21),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            serviceTitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if ((booking.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.notes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.attach_money, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                formatPrice(booking.totalAmount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(context.tr('reject')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(context.tr('accept')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  final String message;

  const _EmptyDashboardCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        color: Theme.of(context).cardColor,
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
