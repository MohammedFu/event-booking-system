import 'package:flutter/widgets.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';

extension ServiceTypeLocalizationX on ServiceType {
  String get l10nKey {
    switch (this) {
      case ServiceType.hall:
        return 'service_type_event_hall';
      case ServiceType.car:
        return 'service_type_car';
      case ServiceType.photographer:
        return 'service_type_photographer';
      case ServiceType.entertainer:
        return 'service_type_entertainer';
    }
  }

  String label(BuildContext context) => context.tr(l10nKey);
}

extension BookingStatusLocalizationX on BookingStatus {
  String get l10nKey {
    switch (this) {
      case BookingStatus.draft:
        return 'status_draft';
      case BookingStatus.pending:
        return 'status_pending';
      case BookingStatus.confirmed:
        return 'status_confirmed';
      case BookingStatus.inProgress:
        return 'status_in_progress';
      case BookingStatus.completed:
        return 'status_completed';
      case BookingStatus.cancelled:
        return 'status_cancelled';
      case BookingStatus.refunded:
        return 'status_refunded';
    }
  }

  String get messageKey {
    switch (this) {
      case BookingStatus.draft:
        return 'booking_status_message_draft';
      case BookingStatus.pending:
        return 'booking_status_message_pending';
      case BookingStatus.confirmed:
        return 'booking_status_message_confirmed';
      case BookingStatus.inProgress:
        return 'booking_status_message_in_progress';
      case BookingStatus.completed:
        return 'booking_status_message_completed';
      case BookingStatus.cancelled:
        return 'booking_status_message_cancelled';
      case BookingStatus.refunded:
        return 'booking_status_message_refunded';
    }
  }

  String label(BuildContext context) => context.tr(l10nKey);

  String message(BuildContext context) => context.tr(messageKey);
}

extension PricingRuleTypeLocalizationX on PricingRuleType {
  String get l10nKey {
    switch (this) {
      case PricingRuleType.seasonal:
        return 'pricing_rule_type_seasonal';
      case PricingRuleType.weekend:
        return 'pricing_rule_type_weekend';
      case PricingRuleType.peak:
        return 'pricing_rule_type_peak';
      case PricingRuleType.earlyBird:
        return 'pricing_rule_type_early_bird';
      case PricingRuleType.lastMinute:
        return 'pricing_rule_type_last_minute';
      case PricingRuleType.bulkDiscount:
        return 'pricing_rule_type_bulk_discount';
    }
  }

  String label(BuildContext context) => context.tr(l10nKey);
}

extension PricingModelLocalizationX on PricingModel {
  String label(BuildContext context) {
    switch (this) {
      case PricingModel.flat:
        return context.l10n.flatRate;
      case PricingModel.hourly:
        return context.tr('per_hour_label');
      case PricingModel.perEvent:
        return context.l10n.perEvent;
      case PricingModel.tiered:
        return context.l10n.tieredPricing;
    }
  }

  String suffix(BuildContext context) {
    switch (this) {
      case PricingModel.flat:
      case PricingModel.tiered:
        return '';
      case PricingModel.hourly:
        return context.l10n.perHour;
      case PricingModel.perEvent:
        return context.tr('per_event_short');
    }
  }
}

extension AvailabilityTemplateLocalizationX on AvailabilityTemplateModel {
  String get dayL10nKey {
    switch (dayOfWeek) {
      case 0:
        return 'weekday_sunday';
      case 1:
        return 'weekday_monday';
      case 2:
        return 'weekday_tuesday';
      case 3:
        return 'weekday_wednesday';
      case 4:
        return 'weekday_thursday';
      case 5:
        return 'weekday_friday';
      default:
        return 'weekday_saturday';
    }
  }

  String localizedDay(BuildContext context) => context.tr(dayL10nKey);

  String localizedShortDay(BuildContext context) {
    final day = localizedDay(context);
    return day.length <= 2 ? day : day.substring(0, 2);
  }
}

String localizedEventType(BuildContext context, String eventType) {
  switch (eventType.toLowerCase()) {
    case 'wedding':
      return context.tr('wedding');
    case 'engagement':
      return context.tr('engagement');
    case 'birthday':
      return context.tr('birthday');
    case 'corporate':
      return context.tr('corporate');
    default:
      return context.tr('other');
  }
}
