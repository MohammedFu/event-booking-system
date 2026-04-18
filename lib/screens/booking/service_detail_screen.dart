import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/booking_provider.dart';
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
                  final isBookmarked =
                      provider.isBookmarked(service.id);
                  return IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    onPressed: () =>
                        provider.toggleBookmark(service.id),
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
                          service.serviceTypeLabel,
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
                                'Verified',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: const Color(0xFF2ED573)),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          ' (${service.provider!.reviewCount} reviews)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description ?? 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildAttributesSection(context, service),
                  const SizedBox(height: 20),
                  if (service.provider != null)
                    _buildProviderCard(context, service.provider!),
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
                'Price',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: primaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${service.basePrice.toInt()}',
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
                _pricingModelLabel(service.pricingModel),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Min ${service.minDurationHours}h'
                '${service.maxDurationHours != null ? ' - Max ${service.maxDurationHours}h' : ''}',
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
                  'Capacity',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.maxCapacity} guests',
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
          items.add(_attrItem(Icons.people, 'Capacity: ${attrs.capacity}'));
        if (attrs.theme != null)
          items.add(_attrItem(Icons.palette, 'Theme: ${attrs.theme}'));
        if (attrs.hasStage == true)
          items.add(_attrItem(Icons.theater_comedy, 'Stage Available'));
        if (attrs.hasParking == true)
          items.add(_attrItem(Icons.local_parking, 'Parking'));
        if (attrs.hasKitchen == true)
          items.add(_attrItem(Icons.kitchen, 'Kitchen'));
        for (final a in attrs.amenities)
          items.add(_attrItem(Icons.check_circle, a, small: true));
      case ServiceType.car:
        if (attrs.make != null && attrs.model != null)
          items.add(_attrItem(Icons.directions_car, '${attrs.make} ${attrs.model}'));
        if (attrs.year != null)
          items.add(_attrItem(Icons.calendar_today, '${attrs.year}'));
        if (attrs.color != null)
          items.add(_attrItem(Icons.color_lens, attrs.color!));
        if (attrs.maxPassengers != null)
          items.add(_attrItem(Icons.airline_seat_recline_normal, '${attrs.maxPassengers} passengers'));
        for (final f in attrs.features)
          items.add(_attrItem(Icons.check_circle, f, small: true));
      case ServiceType.photographer:
        for (final s in attrs.specialties)
          items.add(_attrItem(Icons.camera, s, small: true));
        if (attrs.editingIncluded == true)
          items.add(_attrItem(Icons.edit, 'Editing Included'));
        for (final e in attrs.equipment)
          items.add(_attrItem(Icons.settings, e, small: true));
      case ServiceType.entertainer:
        if (attrs.performerType != null)
          items.add(_attrItem(Icons.person, attrs.performerType!));
        if (attrs.groupSize != null)
          items.add(_attrItem(Icons.group, '${attrs.groupSize} performers'));
        for (final g in attrs.genres)
          items.add(_attrItem(Icons.music_note, g, small: true));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features & Details',
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
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2)),
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
          'Service Provider',
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
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                            'Verified',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: const Color(0xFF2ED573)),
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
                  '\$${service.basePrice.toInt()}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _pricingModelLabel(service.pricingModel),
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
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pricingModelLabel(PricingModel model) {
    switch (model) {
      case PricingModel.flat:
        return 'Flat rate';
      case PricingModel.hourly:
        return 'Per hour';
      case PricingModel.perEvent:
        return 'Per event';
      case PricingModel.tiered:
        return 'Tiered pricing';
    }
  }
}
