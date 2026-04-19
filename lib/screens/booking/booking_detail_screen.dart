import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/models/booking_models.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(booking.eventName ?? 'Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 24),
            _buildEventInfo(context),
            const SizedBox(height: 24),
            Text(
              'Booked Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...booking.items.map((item) => _buildServiceItem(context, item)),
            const SizedBox(height: 24),
            _buildPaymentSummary(context),
            const SizedBox(height: 24),
            if (booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel Booking'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: booking.statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: booking.statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: booking.statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.statusLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: booking.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _getStatusMessage(booking.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context) {
    return Container(
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
        children: [
          _infoRow(context, Icons.calendar_today, 'Event Date',
              '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}'),
          const Divider(height: 20),
          _infoRow(context, Icons.category, 'Event Type',
              booking.eventType.toUpperCase()),
          if (booking.eventName != null) ...[
            const Divider(height: 20),
            _infoRow(
                context, Icons.label, 'Event Name', booking.eventName!),
          ],
          if (booking.specialRequests != null &&
              booking.specialRequests!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(context, Icons.note, 'Special Requests',
                booking.specialRequests!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, BookingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getServiceIcon(item.service?.serviceType),
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.service?.title ?? 'Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.date.day}/${item.date.month}/${item.date.year}  '
                  '${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')} - '
                  '${item.endTime.hour.toString().padLeft(2, '0')}:${item.endTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (item.provider != null)
                  Text(
                    item.provider!.businessName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                  ),
              ],
            ),
          ),
          Text(
            '\$${item.subtotal.toInt()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final deposit = booking.depositAmount;
    final remaining = booking.totalAmount - deposit;

    return Container(
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
          Text(
            'Payment Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text('\$${booking.totalAmount.toInt()}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deposit Paid',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2ED573),
                      )),
              Text('\$${deposit.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2ED573),
                      )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Text('Remaining',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('\$${remaining.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deposit Status',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                booking.depositPaid ? 'Paid' : 'Pending',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: booking.depositPaid
                          ? const Color(0xFF2ED573)
                          : const Color(0xFFFFBE21),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
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

  String _getStatusMessage(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Waiting for provider confirmation';
      case BookingStatus.confirmed:
        return 'All providers confirmed your booking';
      case BookingStatus.inProgress:
        return 'Your event is in progress';
      case BookingStatus.completed:
        return 'Your event has been completed';
      case BookingStatus.cancelled:
        return 'This booking has been cancelled';
      case BookingStatus.refunded:
        return 'Refund has been processed';
      case BookingStatus.draft:
        return 'This booking is still a draft';
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
            'Are you sure you want to cancel this booking? Deposit refund policies apply.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancellation requested'),
                ),
              );
            },
            child: const Text('Cancel Booking',
                style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}
