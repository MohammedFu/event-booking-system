import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/models/demo_booking_data.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class BookingHomeScreen extends StatelessWidget {
  const BookingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    defaultPadding, defaultPadding, defaultPadding, 8),
                child: Text(
                  AppLocalizations.of(context).bookPerfectEvent,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding, vertical: 8),
                child: Text(
                  AppLocalizations.of(context).everythingOnePlace,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildServiceCategories(context)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    defaultPadding, 24, defaultPadding, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).popularServices,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, routes.serviceListingScreenRoute);
                      },
                      child: Text(AppLocalizations.of(context).seeAll),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: defaultPadding,
                  crossAxisSpacing: defaultPadding,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final service = allDemoServices[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          routes.serviceDetailScreenRoute,
                          arguments: service,
                        );
                      },
                    );
                  },
                  childCount: 4,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    defaultPadding, 24, defaultPadding, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).featuredHalls,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          routes.serviceListingScreenRoute,
                          arguments: ServiceType.hall,
                        );
                      },
                      child: Text(AppLocalizations.of(context).seeAll),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: defaultPadding),
                  itemCount: demoHalls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: defaultPadding),
                      child: _HorizontalServiceCard(
                        service: demoHalls[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            routes.serviceDetailScreenRoute,
                            arguments: demoHalls[index],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: defaultPadding * 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          defaultPadding, defaultPadding, defaultPadding, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).helloUser('علي'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).planDreamEvent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, routes.bookingBookmarksScreenRoute);
            },
            icon: const Icon(Icons.bookmark_outline),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                  context, routes.bookingNotificationsScreenRoute);
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          Consumer<BookingProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(
                          context, routes.bookingCartScreenRoute);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                  if (provider.cartItemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${provider.cartItemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: TextField(
        readOnly: true,
        onTap: () {
          Navigator.pushNamed(context, routes.bookingSearchScreenRoute);
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchHallsCars,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadious),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.light
              ? lightGreyColor
              : darkGreyColor,
        ),
      ),
    );
  }

  Widget _buildServiceCategories(BuildContext context) {
    final categories = [
      _CategoryItem(
        icon: Icons.domain,
        label: AppLocalizations.of(context).halls,
        color: const Color(0xFF7B61FF),
        type: ServiceType.hall,
      ),
      _CategoryItem(
        icon: Icons.directions_car,
        label: AppLocalizations.of(context).cars,
        color: const Color(0xFF2ED573),
        type: ServiceType.car,
      ),
      _CategoryItem(
        icon: Icons.camera_alt,
        label: AppLocalizations.of(context).photos,
        color: const Color(0xFFFFBE21),
        type: ServiceType.photographer,
      ),
      _CategoryItem(
        icon: Icons.music_note,
        label: AppLocalizations.of(context).entertainment,
        color: const Color(0xFFEA5B5B),
        type: ServiceType.entertainer,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                routes.serviceListingScreenRoute,
                arguments: cat.type,
              );
            },
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(defaultPadding, 16, defaultPadding, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionChip(
              icon: Icons.receipt_long,
              label: AppLocalizations.of(context).myBookings,
              onTap: () =>
                  Navigator.pushNamed(context, routes.myBookingsScreenRoute),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionChip(
              icon: Icons.tune,
              label: AppLocalizations.of(context).preferences,
              onTap: () => Navigator.pushNamed(
                  context, routes.userPreferencesScreenRoute),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionChip(
              icon: Icons.business_center,
              label: AppLocalizations.of(context).dashboard,
              onTap: () => Navigator.pushNamed(
                  context, routes.providerDashboardScreenRoute),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  final ServiceType type;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.type,
  });
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(defaultBorderRadious)),
                  color: service.images.isNotEmpty
                      ? null
                      : service.serviceTypeIcon.toString().contains('domain')
                          ? primaryColor.withOpacity(0.1)
                          : service.serviceType == ServiceType.car
                              ? const Color(0xFF2ED573).withOpacity(0.1)
                              : service.serviceType == ServiceType.photographer
                                  ? const Color(0xFFFFBE21).withOpacity(0.1)
                                  : const Color(0xFFEA5B5B).withOpacity(0.1),
                  image: service.images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(service.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: service.images.isEmpty
                    ? Center(
                        child: Icon(
                          service.serviceTypeIcon,
                          size: 40,
                          color: service.serviceType == ServiceType.hall
                              ? primaryColor
                              : service.serviceType == ServiceType.car
                                  ? const Color(0xFF2ED573)
                                  : service.serviceType ==
                                          ServiceType.photographer
                                      ? const Color(0xFFFFBE21)
                                      : const Color(0xFFEA5B5B),
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    if (service.provider != null)
                      Text(
                        service.provider!.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        if (service.provider != null) ...[
                          const Icon(Icons.star,
                              size: 14, color: Color(0xFFFFBE21)),
                          Text(
                            '${service.provider!.rating}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Spacer(),
                        Text(
                          '\$${service.basePrice.toInt()}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _HorizontalServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 280,
        child: Container(
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(defaultBorderRadious)),
                    image: service.images.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(service.images.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: service.images.isEmpty
                        ? primaryColor.withOpacity(0.1)
                        : null,
                  ),
                  child: service.images.isEmpty
                      ? Center(
                          child: Icon(service.serviceTypeIcon,
                              size: 40, color: primaryColor),
                        )
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Row(
                      children: [
                        if (service.provider != null) ...[
                          const Icon(Icons.star,
                              size: 12, color: Color(0xFFFFBE21)),
                          Text('${service.provider!.rating}',
                              style: Theme.of(context).textTheme.labelSmall),
                        ],
                        const Spacer(),
                        Text(
                          '\$${service.basePrice.toInt()}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
