import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/app_analytics_service.dart';

enum BookingDepositPaymentStatus {
  succeeded,
  cancelled,
  failed,
  unavailable,
}

class BookingDepositPaymentResult {
  const BookingDepositPaymentResult({
    required this.status,
    this.message,
    this.booking,
    this.payment,
  });

  final BookingDepositPaymentStatus status;
  final String? message;
  final BookingModel? booking;
  final PaymentModel? payment;

  bool get isSuccess => status == BookingDepositPaymentStatus.succeeded;
}

class StripePaymentService {
  StripePaymentService._();

  static final StripePaymentService instance = StripePaymentService._();

  static const String _publishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const String _merchantIdentifier =
      String.fromEnvironment('STRIPE_MERCHANT_IDENTIFIER');
  static const String _merchantName =
      String.fromEnvironment(
        'STRIPE_MERCHANT_NAME',
        defaultValue: 'Munasabati',
      );
  static const String _returnUrl = 'flutterstripe://redirect';

  final ApiServiceReal _api = ApiServiceReal();

  bool _didInitialize = false;

  bool get isConfigured =>
      !kIsWeb &&
      _publishableKey.isNotEmpty &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (_didInitialize || !isConfigured) {
      return;
    }

    Stripe.publishableKey = _publishableKey;
    Stripe.urlScheme = 'flutterstripe';
    if (_merchantIdentifier.isNotEmpty) {
      Stripe.merchantIdentifier = _merchantIdentifier;
    }
    await Stripe.instance.applySettings();
    _didInitialize = true;
  }

  Future<BookingDepositPaymentResult> payBookingDeposit({
    required BookingModel booking,
    String? customerName,
    String? customerEmail,
  }) async {
    if (booking.depositPaid) {
      return BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.succeeded,
        booking: booking,
      );
    }

    if (!isConfigured) {
      return const BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.unavailable,
      );
    }

    await initialize();

    final intentResponse = await _api.createPaymentIntent(
      amount: booking.depositAmount,
      currency: booking.currency,
      bookingId: booking.id,
    );

    if (!intentResponse.success || intentResponse.data == null) {
      return BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.failed,
        message: intentResponse.error ?? 'Unable to create a payment intent.',
      );
    }

    final paymentSheetData = intentResponse.data!;
    final clientSecret = paymentSheetData['clientSecret']?.toString();
    final paymentIntentId = paymentSheetData['paymentIntentId']?.toString();

    if (clientSecret == null ||
        clientSecret.isEmpty ||
        paymentIntentId == null ||
        paymentIntentId.isEmpty) {
      return const BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.failed,
        message: 'Stripe payment setup is incomplete.',
      );
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: _merchantName,
          paymentIntentClientSecret: clientSecret,
          returnURL: _returnUrl,
          billingDetails: BillingDetails(
            name: customerName,
            email: customerEmail,
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final confirmationResponse = await _api.confirmPayment(
        paymentIntentId: paymentIntentId,
        paymentMethod: 'card',
      );

      if (!confirmationResponse.success || confirmationResponse.data == null) {
        return BookingDepositPaymentResult(
          status: BookingDepositPaymentStatus.failed,
          message:
              confirmationResponse.error ?? 'Unable to confirm the payment.',
        );
      }

      final bookingResponse = await _api.getBookingById(booking.id);
      final updatedBooking = bookingResponse.success && bookingResponse.data != null
          ? bookingResponse.data!
          : booking.copyWith(depositPaid: true);

      await AppAnalyticsService.instance.logDepositPaid(
        bookingId: updatedBooking.id,
        amount: updatedBooking.depositAmount,
        currency: updatedBooking.currency,
      );

      return BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.succeeded,
        booking: updatedBooking,
        payment: confirmationResponse.data,
      );
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        return BookingDepositPaymentResult(
          status: BookingDepositPaymentStatus.cancelled,
          booking: booking,
          message: error.error.localizedMessage,
        );
      }

      return BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.failed,
        booking: booking,
        message: error.error.localizedMessage ?? error.error.message,
      );
    } catch (error) {
      return BookingDepositPaymentResult(
        status: BookingDepositPaymentStatus.failed,
        booking: booking,
        message: error.toString(),
      );
    }
  }
}
