import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    await auth.syncCurrentUser(silent: true);
    if (!mounted) return;

    await bookingProvider.fetchProviderBookings();
  }

  Future<void> _updateStatus(
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

    await _fetchBookings();
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
          title: Text(AppLocalizations.of(context).myBookings),
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
        title: Text(AppLocalizations.of(context).myBookings),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('upcoming')),
            Tab(text: context.tr('completed')),
            Tab(text: context.tr('cancelled')),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          final upcoming = provider.providerBookings
              .where((booking) =>
                  booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.confirmed ||
                  booking.status == BookingStatus.inProgress)
              .toList();
          final completed = provider.providerBookings
              .where((booking) => booking.status == BookingStatus.completed)
              .toList();
          final cancelled = provider.providerBookings
              .where((booking) =>
                  booking.status == BookingStatus.cancelled ||
                  booking.status == BookingStatus.refunded)
              .toList();

          if (provider.isLoading && provider.providerBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _fetchBookings,
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProviderBookingList(
                  bookings: upcoming,
                  emptyMessage: context.tr('no_upcoming_bookings'),
                  onAccept: (booking) =>
                      _updateStatus(booking, BookingStatus.confirmed),
                  onReject: (booking) =>
                      _updateStatus(booking, BookingStatus.cancelled),
                ),
                _ProviderBookingList(
                  bookings: completed,
                  emptyMessage: context.tr('no_completed_bookings'),
                ),
                _ProviderBookingList(
                  bookings: cancelled,
                  emptyMessage: context.tr('no_cancelled_bookings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProviderBookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyMessage;
  final ValueChanged<BookingModel>? onAccept;
  final ValueChanged<BookingModel>? onReject;

  const _ProviderBookingList({
    required this.bookings,
    required this.emptyMessage,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy,
                      size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _ProviderBookingCard(
          booking: bookings[index],
          onAccept: onAccept,
          onReject: onReject,
        );
      },
    );
  }
}

class _ProviderBookingCard extends StatelessWidget {
  final BookingModel booking;
  final ValueChanged<BookingModel>? onAccept;
  final ValueChanged<BookingModel>? onReject;

  const _ProviderBookingCard({
    required this.booking,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final item = booking.items.isNotEmpty ? booking.items.first : null;
    final serviceTitle = item?.service?.title ?? context.tr('service');
    final isPending = booking.status == BookingStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.label(context),
                  style: TextStyle(
                    color: booking.statusColor,
                    fontSize: 12,
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
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.attach_money, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                formatPrice(booking.totalAmount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (isPending && onAccept != null && onReject != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onReject!(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: errorColor,
                    ),
                    child: Text(context.tr('reject')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAccept!(booking),
                    child: Text(context.tr('accept')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
