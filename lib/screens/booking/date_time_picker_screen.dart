import 'package:flutter/material.dart';
import 'package:munasabati/components/service_image.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class DateTimePickerScreen extends StatefulWidget {
  final ServiceModel service;

  const DateTimePickerScreen({super.key, required this.service});

  @override
  State<DateTimePickerScreen> createState() => _DateTimePickerScreenState();
}

class _DateTimePickerScreenState extends State<DateTimePickerScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  final _specialRequestsController = TextEditingController();
  late Future<List<TimeSlot>> _slotsFuture;

  ServiceModel get service => widget.service;

  @override
  void initState() {
    super.initState();
    _slotsFuture = _fetchSlots();
  }

  Future<List<TimeSlot>> _fetchSlots() async {
    final provider = context.read<BookingProvider>();
    return provider.fetchAvailableSlots(widget.service.id, _selectedDate);
  }

  void _refreshSlots() {
    setState(() {
      _selectedStartTime = null;
      _selectedEndTime = null;
      _slotsFuture = _fetchSlots();
    });
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectDateTime),
      ),
      body: FutureBuilder<List<TimeSlot>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildServiceSummary(context, service),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('select_date'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(context),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('available_time_slots'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (snapshot.hasError)
                        Text(
                          context.tr(
                            'error_with_message',
                            params: {'message': snapshot.error.toString()},
                          ),
                        )
                      else if (snapshot.hasData)
                        _buildTimeSlots(context, snapshot.data!)
                      else
                        Text(context.tr('no_slots_available')),
                      const SizedBox(height: 24),
                      Text(
                        context.tr('special_requests_optional'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _specialRequestsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: context.tr('special_requests_hint'),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(defaultBorderRadious),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(context, service),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceSummary(BuildContext context, ServiceModel service) {
    final imageUrl = service.images.isNotEmpty ? service.images.first : null;

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: ServiceImage(
                    imageUrl: imageUrl,
                    fallbackIcon: service.serviceTypeIcon,
                    borderRadius: BorderRadius.circular(8),
                    iconSize: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatPrice(service.basePrice)} ${service.pricingModel.suffix(context)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: ServiceImage(
                  imageUrl: imageUrl,
                  fallbackIcon: service.serviceTypeIcon,
                  borderRadius: BorderRadius.circular(8),
                  iconSize: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${formatPrice(service.basePrice)} ${service.pricingModel.suffix(context)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null) {
          return;
        }

        setState(() {
          _selectedDate = date;
        });
        _refreshSlots();
      },
      borderRadius: BorderRadius.circular(defaultBorderRadious),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots(BuildContext context, List<TimeSlot> slots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = _selectedStartTime != null &&
            _selectedStartTime!.hour == slot.startTime.hour &&
            _selectedStartTime!.minute == slot.startTime.minute;

        return GestureDetector(
          onTap: slot.isAvailable
              ? () {
                  final endMinutes = slot.startTime.hour * 60 +
                      slot.startTime.minute +
                      (service.minDurationHours * 60).round();

                  setState(() {
                    _selectedStartTime = slot.startTime;
                    _selectedEndTime = TimeOfDay(
                      hour: (endMinutes ~/ 60) % 24,
                      minute: endMinutes % 60,
                    );
                  });
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: !slot.isAvailable
                  ? Colors.grey.withOpacity(0.1)
                  : isSelected
                      ? primaryColor
                      : Theme.of(context).cardColor,
              border: Border.all(
                color: !slot.isAvailable
                    ? Colors.grey.withOpacity(0.3)
                    : isSelected
                        ? primaryColor
                        : Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              slot.timeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: !slot.isAvailable
                        ? Colors.grey
                        : isSelected
                            ? Colors.white
                            : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, ServiceModel service) {
    final provider = context.read<BookingProvider>();
    final canAdd = _selectedStartTime != null && _selectedEndTime != null;

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedStartTime != null && _selectedEndTime != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('estimated_total'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _calculatePrice(service),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final addMoreButton = OutlinedButton(
                  onPressed: canAdd
                      ? () {
                          _addToCartAndContinue(context, provider);
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(context.tr('add_and_browse_more')),
                );

                final checkoutButton = ElevatedButton(
                  onPressed: canAdd
                      ? () {
                          _addToCartAndCheckout(context, provider);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(context.tr('add_to_cart')),
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      addMoreButton,
                      const SizedBox(height: 12),
                      checkoutButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: addMoreButton),
                    const SizedBox(width: 12),
                    Expanded(child: checkoutButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _calculatePrice(ServiceModel service) {
    if (_selectedStartTime == null || _selectedEndTime == null) {
      return formatPrice(0);
    }

    final durationMinutes =
        (_selectedEndTime!.hour * 60 + _selectedEndTime!.minute) -
            (_selectedStartTime!.hour * 60 + _selectedStartTime!.minute);
    final durationHours = durationMinutes / 60.0;

    if (service.pricingModel == PricingModel.hourly) {
      return formatPrice(service.basePrice * durationHours);
    }

    return formatPrice(service.basePrice);
  }

  void _addToCartAndContinue(BuildContext context, BookingProvider provider) {
    final item = BookingCartItem(
      service: service,
      date: _selectedDate,
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      durationHours: _calculateDuration(),
      specialRequests: _specialRequestsController.text.isEmpty
          ? null
          : _specialRequestsController.text,
    );

    final conflicts = provider.getCartConflicts(item);
    if (conflicts.isNotEmpty) {
      _showConflictDialog(context, conflicts);
      return;
    }

    provider.addToCart(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'added_to_booking_cart',
            params: {'service': service.title},
          ),
        ),
        action: SnackBarAction(
          label: context.tr('undo'),
          onPressed: () => provider.removeFromCart(service.id),
        ),
      ),
    );
    Navigator.pop(context);
  }

  void _addToCartAndCheckout(BuildContext context, BookingProvider provider) {
    final item = BookingCartItem(
      service: service,
      date: _selectedDate,
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      durationHours: _calculateDuration(),
      specialRequests: _specialRequestsController.text.isEmpty
          ? null
          : _specialRequestsController.text,
    );

    final conflicts = provider.getCartConflicts(item);
    if (conflicts.isNotEmpty) {
      _showConflictDialog(context, conflicts);
      return;
    }

    provider.addToCart(item);
    Navigator.pushNamed(context, bookingCartScreenRoute);
  }

  double _calculateDuration() {
    if (_selectedStartTime == null || _selectedEndTime == null) {
      return 1;
    }

    final startMinutes =
        _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    return (endMinutes - startMinutes) / 60.0;
  }

  void _showConflictDialog(BuildContext context, List<String> conflicts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('time_conflict')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('time_conflicts_with')),
            const SizedBox(height: 8),
            ...conflicts.map(
              (conflict) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: warningColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(conflict)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }
}
