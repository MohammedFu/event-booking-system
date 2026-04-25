import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/app_links_service.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:munasabati/services/stripe_payment_service.dart';
import 'package:provider/provider.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingModel _booking;
  bool _isPayingDeposit = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_booking.eventName ?? context.tr('booking_details')),
        actions: [
          IconButton(
            onPressed: () {
              AppLinksService.instance.shareBooking(
                context: context,
                bookingId: _booking.id,
              );
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
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
              context.tr('booked_services'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._booking.items.map((item) => _buildServiceItem(context, item)),
            const SizedBox(height: 24),
            _buildPaymentSummary(context),
            const SizedBox(height: 24),
            if (!_booking.depositPaid &&
                (_booking.status == BookingStatus.pending ||
                    _booking.status == BookingStatus.confirmed))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPayingDeposit ? null : _payDeposit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isPayingDeposit
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('pay_deposit_now')),
                ),
              ),
            if (!_booking.depositPaid &&
                (_booking.status == BookingStatus.pending ||
                    _booking.status == BookingStatus.confirmed))
              const SizedBox(height: 12),
            if (_booking.status == BookingStatus.pending ||
                _booking.status == BookingStatus.confirmed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(context.tr('cancel_booking')),
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
        color: _booking.statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: _booking.statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _booking.statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking.status.label(context),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _booking.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _booking.status.message(context),
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
          _infoRow(context, Icons.calendar_today, context.tr('event_date'),
              '${_booking.eventDate.day}/${_booking.eventDate.month}/${_booking.eventDate.year}'),
          const Divider(height: 20),
          _infoRow(
            context,
            Icons.category,
            context.l10n.eventType,
            localizedEventType(context, _booking.eventType),
          ),
          if (_booking.eventName != null) ...[
            const Divider(height: 20),
            _infoRow(context, Icons.label, context.l10n.eventName,
                _booking.eventName!),
          ],
          if (_booking.specialRequests != null &&
              _booking.specialRequests!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              context,
              Icons.note,
              context.l10n.specialRequests,
              _booking.specialRequests!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
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
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
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
                  item.service?.title ?? context.tr('service'),
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
    final deposit = _booking.depositAmount;
    final remaining = _booking.totalAmount - deposit;

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
            context.tr('payment_summary'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('total_amount'),
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(formatPrice(_booking.totalAmount),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('deposit_paid'),
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
              Text(context.tr('remaining'),
                  style: Theme.of(context).textTheme.bodySmall),
              Text('\$${remaining.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('deposit_status'),
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                _booking.depositPaid
                    ? context.tr('status_paid')
                    : context.tr('status_pending'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _booking.depositPaid
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

  Future<void> _payDeposit() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.pushNamed(context, authScreenRoute);
      return;
    }

    setState(() => _isPayingDeposit = true);

    final paymentResult = await StripePaymentService.instance.payBookingDeposit(
      booking: _booking,
      customerName: auth.user?.fullName,
      customerEmail: auth.user?.email,
    );

    if (!mounted) return;

    if (paymentResult.booking != null) {
      _booking = paymentResult.booking!;
      context.read<BookingProvider>().updateBookingLocally(_booking);
    } else {
      final refreshedBooking =
          await context.read<BookingProvider>().refreshBookingById(_booking.id);
      if (!mounted) return;
      if (refreshedBooking != null) {
        _booking = refreshedBooking;
      }
    }

    setState(() => _isPayingDeposit = false);

    final messenger = ScaffoldMessenger.of(context);
    switch (paymentResult.status) {
      case BookingDepositPaymentStatus.succeeded:
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.tr('deposit_paid_successfully')),
            backgroundColor: successColor,
          ),
        );
        break;
      case BookingDepositPaymentStatus.cancelled:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              paymentResult.message ?? context.tr('deposit_payment_cancelled'),
            ),
            backgroundColor: warningColor,
          ),
        );
        break;
      case BookingDepositPaymentStatus.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              paymentResult.message ?? context.tr('deposit_payment_failed'),
            ),
            backgroundColor: errorColor,
          ),
        );
        break;
      case BookingDepositPaymentStatus.unavailable:
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.tr('card_payment_unavailable')),
            backgroundColor: warningColor,
          ),
        );
        break;
    }
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

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('cancel_booking')),
        content: Text(context.tr('cancel_booking_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('keep_booking')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('booking_cancellation_requested')),
                ),
              );
            },
            child: Text(context.tr('cancel_booking'),
                style: const TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}
