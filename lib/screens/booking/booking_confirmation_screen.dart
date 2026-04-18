import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/booking_provider.dart';
import 'package:provider/provider.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String _eventType = 'wedding';
  String _paymentMethod = 'card';
  final _eventNameController = TextEditingController();

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).confirmBooking),
      ),
      body: provider.cartItems.isEmpty
          ? Center(child: Text(AppLocalizations.of(context).noItemsInCart))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEventDetails(context),
                        const SizedBox(height: 24),
                        _buildBookingSummary(context, provider),
                        const SizedBox(height: 24),
                        _buildPaymentSection(context),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                _buildConfirmButton(context, provider),
              ],
            ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _eventNameController,
          decoration: InputDecoration(
            labelText: 'Event Name',
            hintText: 'e.g., Sarah & James Wedding',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
          ),
          onChanged: (val) => _eventNameController.text = val,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _eventType,
          decoration: InputDecoration(
            labelText: 'Event Type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'wedding', child: Text('Wedding')),
            DropdownMenuItem(value: 'engagement', child: Text('Engagement')),
            DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
            DropdownMenuItem(value: 'corporate', child: Text('Corporate')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _eventType = val);
          },
        ),
      ],
    );
  }

  Widget _buildBookingSummary(BuildContext context, BookingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...provider.cartItems.map((item) => Container(
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
                    child: Icon(item.service.serviceTypeIcon,
                        color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.service.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${item.date.day}/${item.date.month}/${item.date.year}  ${item.timeLabel}',
                          style: Theme.of(context).textTheme.labelSmall,
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
            )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            Text('\$${provider.cartTotal.toInt()}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Deposit due now (25%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2ED573),
                    )),
            Text('\$${(provider.cartTotal * 0.25).toInt()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF2ED573),
                      fontWeight: FontWeight.bold,
                    )),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _PaymentOption(
          icon: Icons.credit_card,
          label: 'Credit/Debit Card',
          subtitle: 'Visa, Mastercard, Amex',
          selected: _paymentMethod == 'card',
          onTap: () => setState(() => _paymentMethod = 'card'),
        ),
        _PaymentOption(
          icon: Icons.account_balance,
          label: 'Bank Transfer',
          subtitle: 'Direct bank transfer',
          selected: _paymentMethod == 'bank_transfer',
          onTap: () => setState(() => _paymentMethod = 'bank_transfer'),
        ),
        _PaymentOption(
          icon: Icons.account_balance_wallet,
          label: 'Wallet',
          subtitle: 'Pay from wallet balance',
          selected: _paymentMethod == 'wallet',
          onTap: () => setState(() => _paymentMethod = 'wallet'),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context, BookingProvider provider) {
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
        child: provider.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            : ElevatedButton(
                onPressed: () async {
                  provider.setEventType(_eventType);
                  await provider.createBooking();
                  if (context.mounted) {
                    Navigator.pushNamed(
                        context, bookingConfirmationScreenRoute);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                    'Confirm & Pay \$${(provider.cartTotal * 0.25).toInt()} Deposit'),
              ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          border: Border.all(
            color: selected
                ? primaryColor
                : Theme.of(context).dividerColor.withOpacity(0.3),
          ),
          color: selected ? primaryColor.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? primaryColor : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: label,
              groupValue: selected ? label : '',
              onChanged: (_) => onTap(),
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
