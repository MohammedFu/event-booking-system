import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class BookingCartScreen extends StatelessWidget {
  const BookingCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).bookingCart),
        actions: [
          Consumer<BookingProvider>(
            builder: (context, provider, _) {
              if (provider.cartItems.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  _showClearCartDialog(context, provider);
                },
                child: Text(AppLocalizations.of(context).clear),
              );
            },
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).yourCartEmpty,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).browseServicesDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, bookingHomeScreenRoute);
                    },
                    child: Text(AppLocalizations.of(context).browseServices),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(defaultPadding),
                  itemCount: provider.cartItems.length,
                  itemBuilder: (context, index) {
                    return _CartItemCard(
                      item: provider.cartItems[index],
                      onRemove: () => provider
                          .removeFromCart(provider.cartItems[index].service.id),
                    );
                  },
                ),
              ),
              _buildBottomSection(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, BookingProvider provider) {
    final deposit = provider.cartTotal * 0.25;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).subtotal,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('\$${provider.cartTotal.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).depositPercent,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2ED573),
                        )),
                Text('\$${deposit.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2ED573),
                        )),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).total,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, bookingHomeScreenRoute);
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context).addMore),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                          context, bookingConfirmationScreenRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(AppLocalizations.of(context).proceedToBook),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, BookingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).clearCart),
        content: Text(AppLocalizations.of(context).clearCartConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              provider.clearCart();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).clear,
                style: const TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final BookingCartItem item;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final service = item.service;

    return Dismissible(
      key: Key(service.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: defaultPadding),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 70,
                child: service.images.isNotEmpty
                    ? Image.network(service.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: primaryColor.withOpacity(0.1),
                              child: Icon(service.serviceTypeIcon,
                                  color: primaryColor, size: 24),
                            ))
                    : Container(
                        color: primaryColor.withOpacity(0.1),
                        child: Icon(service.serviceTypeIcon,
                            color: primaryColor, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(service.serviceTypeIcon,
                          size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        service.serviceTypeLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${item.date.day}/${item.date.month}/${item.date.year}  ${item.timeLabel}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.subtotal.toInt()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.durationHours}h',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
