import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final provider = context.read<BookingProvider>();

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(context, service, provider),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              Consumer<BookingProvider>(
                builder: (context, provider, _) {
                  final isBookmarked = provider.isBookmarked(service.id);
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () => provider.toggleBookmark(service.id),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: service.images.isNotEmpty
                  ? PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      itemCount: service.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          service.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: primaryColor.withOpacity(0.1),
                            child: Icon(service.serviceTypeIcon,
                                size: 64, color: primaryColor),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(service.serviceTypeIcon,
                          size: 64, color: primaryColor),
                    ),
            ),
          ),
          if (service.images.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    service.images.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.serviceType.label(context),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: primaryColor),
                        ),
                      ),
                      if (service.provider?.isVerified == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ED573).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  size: 12, color: Color(0xFF2ED573)),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).verified,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: const Color(0xFF2ED573)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (service.provider != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 18, color: Color(0xFFFFBE21)),
                        const SizedBox(width: 4),
                        Text(
                          '${service.provider!.rating}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          ' (${context.tr('reviews_count_compact', params: {
                                'count':
                                    service.provider!.reviewCount.toString(),
                              })})',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.6),
                                  ),
                        ),
                        const Spacer(),
                        if (service.provider!.city != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              Text(
                                service.provider!.city!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  _buildPricingCard(context, service),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context).about,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description ??
                        AppLocalizations.of(context).noDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildAttributesSection(context, service),
                  const SizedBox(height: 20),
                  if (service.provider != null)
                    _buildProviderCard(context, service.provider!),
                  const SizedBox(height: 20),
                  _buildReviewsLink(context, service),
                  const SizedBox(height: 20),
                  _buildCancellationPolicy(context, service),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).price,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                formatPrice(service.basePrice),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.pricingModel.label(context),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                service.maxDurationHours == null
                    ? context.tr('min_duration_value', params: {
                        'value': service.minDurationHours.toString(),
                      })
                    : context.tr('duration_range_value', params: {
                        'min': service.minDurationHours.toString(),
                        'max': service.maxDurationHours.toString(),
                      }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          if (service.maxCapacity != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppLocalizations.of(context).capacity,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.maxCapacity} ${AppLocalizations.of(context).guests}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(BuildContext context, ServiceModel service) {
    final attrs = service.attributes;
    List<Widget> items = [];

    switch (service.serviceType) {
      case ServiceType.hall:
        if (attrs.capacity != null)
          items.add(_attrItem(
            Icons.people,
            context.tr('capacity_value', params: {
              'value': attrs.capacity.toString(),
            }),
          ));
        if (attrs.theme != null)
          items.add(_attrItem(
            Icons.palette,
            context.tr('theme_value', params: {'value': attrs.theme!}),
          ));
        if (attrs.hasStage == true)
          items.add(
              _attrItem(Icons.theater_comedy, context.l10n.stageAvailable));
        if (attrs.hasParking == true)
          items.add(_attrItem(Icons.local_parking, context.l10n.parking));
        if (attrs.hasKitchen == true)
          items.add(_attrItem(Icons.kitchen, context.l10n.kitchen));
        for (final a in attrs.amenities)
          items.add(_attrItem(Icons.check_circle, a, small: true));
      case ServiceType.car:
        if (attrs.make != null && attrs.model != null)
          items.add(
              _attrItem(Icons.directions_car, '${attrs.make} ${attrs.model}'));
        if (attrs.year != null)
          items.add(_attrItem(Icons.calendar_today, '${attrs.year}'));
        if (attrs.color != null)
          items.add(_attrItem(Icons.color_lens, attrs.color!));
        if (attrs.maxPassengers != null)
          items.add(_attrItem(
            Icons.airline_seat_recline_normal,
            context.tr('passengers_value', params: {
              'value': attrs.maxPassengers.toString(),
            }),
          ));
        for (final f in attrs.features)
          items.add(_attrItem(Icons.check_circle, f, small: true));
      case ServiceType.photographer:
        for (final s in attrs.specialties)
          items.add(_attrItem(Icons.camera, s, small: true));
        if (attrs.editingIncluded == true)
          items.add(_attrItem(Icons.edit, context.l10n.editingIncluded));
        for (final e in attrs.equipment)
          items.add(_attrItem(Icons.settings, e, small: true));
      case ServiceType.entertainer:
        if (attrs.performerType != null)
          items.add(_attrItem(Icons.person, attrs.performerType!));
        if (attrs.groupSize != null)
          items.add(_attrItem(
            Icons.group,
            context.tr('performers_value', params: {
              'value': attrs.groupSize.toString(),
            }),
          ));
        for (final g in attrs.genres)
          items.add(_attrItem(Icons.music_note, g, small: true));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).featuresDetails,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items,
        ),
      ],
    );
  }

  Widget _attrItem(IconData icon, String label, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12, vertical: small ? 4 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 14 : 18, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: small ? FontWeight.normal : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, ProviderModel provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).serviceProvider,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  provider.businessName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.businessName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFFFBE21)),
                        Text(
                          '${provider.rating} (${provider.reviewCount})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (provider.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified,
                              size: 14, color: Color(0xFF2ED573)),
                          Text(
                            AppLocalizations.of(context).verified,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: const Color(0xFF2ED573)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsLink(BuildContext context, ServiceModel service) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          bookingReviewsScreenRoute,
          arguments: {
            'serviceId': service.id,
            'serviceTitle': service.title,
          },
        );
      },
      borderRadius: BorderRadius.circular(defaultBorderRadious),
      child: Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(defaultBorderRadious),
          color: Theme.of(context).cardColor,
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.rate_review, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).reviews,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  if (service.provider != null)
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${service.provider!.rating} (${context.tr('reviews_count_compact', params: {
                                'count':
                                    service.provider!.reviewCount.toString(),
                              })})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationPolicy(BuildContext context, ServiceModel service) {
    final policy = service.cancellationPolicy;
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        color: Theme.of(context).cardColor,
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).cancellationPolicy,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _policyRow(
              Icons.check_circle_outline,
              Colors.green,
              context.tr('free_cancellation_before', params: {
                'hours': policy.freeCancellationHours.toString(),
              })),
          const SizedBox(height: 4),
          _policyRow(
              Icons.info_outline,
              Colors.orange,
              context.tr('refund_after_that', params: {
                'percent': policy.partialRefundPercentage.toInt().toString(),
              })),
          const SizedBox(height: 4),
          _policyRow(
            policy.depositRefundable
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            policy.depositRefundable ? Colors.green : Colors.red,
            policy.depositRefundable
                ? context.tr('deposit_is_refundable')
                : context.tr('deposit_not_refundable'),
          ),
        ],
      ),
    );
  }

  Widget _policyRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, ServiceModel service, BookingProvider provider) {
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
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPrice(service.basePrice),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  service.pricingModel.label(context),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    dateTimePickerScreenRoute,
                    arguments: service,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(AppLocalizations.of(context).bookNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
