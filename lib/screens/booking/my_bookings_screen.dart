import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BookingProvider>().loadDemoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          final upcoming = provider.bookings
              .where((b) =>
                  b.status == BookingStatus.pending ||
                  b.status == BookingStatus.confirmed ||
                  b.status == BookingStatus.inProgress)
              .toList();
          final completed = provider.bookings
              .where((b) => b.status == BookingStatus.completed)
              .toList();
          final cancelled = provider.bookings
              .where((b) =>
                  b.status == BookingStatus.cancelled ||
                  b.status == BookingStatus.refunded)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(
                  bookings: upcoming, emptyMessage: 'No upcoming bookings'),
              _BookingList(
                  bookings: completed, emptyMessage: 'No completed bookings'),
              _BookingList(
                  bookings: cancelled, emptyMessage: 'No cancelled bookings'),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyMessage;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy,
                size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(booking: bookings[index]);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: defaultPadding),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        child: InkWell(
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          onTap: () {
            Navigator.pushNamed(
              context,
              bookingDetailScreenRoute,
              arguments: booking,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.eventName ?? 'Event',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.statusLabel,
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
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      booking.eventType.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...booking.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getServiceIcon(item.service?.serviceType),
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.service?.title ?? 'Service',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toInt()}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    )),
                if (booking.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${booking.items.length - 3} more services',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: primaryColor,
                          ),
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${booking.items.length} services booked',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Total: \$${booking.totalAmount.toInt()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(ServiceType? type) {
    switch (type) {
      case ServiceType.hall:
        return Icons.domain;
      case ServiceType.car:
        return Icons.directions_car;
      case ServiceType.photographer:
        return Icons.camera_alt;
      case ServiceType.entertainer:
        return Icons.music_note;
      case null:
        return Icons.miscellaneous_services;
    }
  }
}
