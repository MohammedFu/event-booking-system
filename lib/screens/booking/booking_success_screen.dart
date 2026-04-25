import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';

class BookingSuccessScreen extends StatelessWidget {
  final BookingModel? booking;

  const BookingSuccessScreen({
    super.key,
    this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingStatus = booking?.status ?? BookingStatus.pending;
    final statusLabel = bookingStatus.label(context);
    final title = bookingStatus == BookingStatus.pending
        ? context.tr('booking_request_sent_title')
        : context.tr('booking_confirmed_exclamation');
    final message = bookingStatus == BookingStatus.pending
        ? context.tr('booking_request_sent_message')
        : context.tr('booking_success_message_full');
    final bookingReference = booking != null
        ? '#${booking!.id.split('-').first.toUpperCase()}'
        : '#BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final depositLabel = booking?.depositPaid == true
        ? context.tr('deposit_paid')
        : l10n.depositDueNow;
    final depositValue = booking != null
        ? formatPrice(booking!.depositAmount)
        : context.tr('deposit_confirmed_percent');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ED573).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Color(0xFF2ED573),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(defaultBorderRadious),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('booking_id'),
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          bookingReference,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('status'),
                            style: Theme.of(context).textTheme.bodySmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBE21).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: Color(0xFFFFBE21),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(depositLabel,
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          depositValue,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF2ED573),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, myBookingsScreenRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(context.tr('view_my_bookings')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      bookingHomeScreenRoute,
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(context.tr('back_to_home')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
