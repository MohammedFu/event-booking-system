import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class BookingHomeScreen extends StatefulWidget {
  const BookingHomeScreen({super.key});

  @override
  State<BookingHomeScreen> createState() => _BookingHomeScreenState();
}

class _BookingHomeScreenState extends State<BookingHomeScreen> {
  int _currentOfferIndex = 0;

  // List of offer images
  final List<String> _offerImages = [
    'assets/services-images/1.jpg',
    'assets/services-images/2.jpg',
    'assets/services-images/3.jpg',
    'assets/services-images/4.jpg',
    'assets/services-images/5.jpg',
    'assets/services-images/6.jpg',
    'assets/services-images/7.jpg',
    'assets/services-images/8.jpg',
    'assets/services-images/9.jpg',
  ];
  List<String> _shuffledImages = [];

  // Offers data for titles and descriptions
  final List<Map<String, dynamic>> _offers = [
    {
      'titleKey': 'offer_summer_special_title',
      'descriptionKey': 'offer_summer_special_description',
    },
    {
      'titleKey': 'offer_wedding_package_title',
      'descriptionKey': 'offer_wedding_package_description',
    },
    {
      'titleKey': 'offer_early_bird_title',
      'descriptionKey': 'offer_early_bird_description',
    },
    {
      'titleKey': 'offer_vip_entertainment_title',
      'descriptionKey': 'offer_vip_entertainment_description',
    },
  ];

  @override
  void initState() {
    super.initState();
    _shuffledImages = List.from(_offerImages)..shuffle();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    await context.read<BookingProvider>().fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(child: _buildOffersCarousel(context)),
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
              sliver: Consumer<BookingProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final services = provider.services.take(4).toList();
                  if (services.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }
                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: defaultPadding,
                      crossAxisSpacing: defaultPadding,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = services[index];
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
                      childCount: services.length,
                    ),
                  );
                },
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
                child: Consumer<BookingProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final halls = provider.services
                        .where((s) => s.serviceType == ServiceType.hall)
                        .take(5)
                        .toList();
                    if (halls.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding),
                      itemCount: halls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: defaultPadding),
                          child: _HorizontalServiceCard(
                            service: halls[index],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                routes.serviceDetailScreenRoute,
                                arguments: halls[index],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                  height: defaultPadding * 6), // Extra padding for bottom nav
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
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final userName =
                        auth.user?.fullName ?? context.tr('guest_user_name');
                    return Text(
                      AppLocalizations.of(context).helloUser(userName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    );
                  },
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

  Widget _buildOffersCarousel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() => _currentOfferIndex = index);
              },
            ),
            items: _shuffledImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imagePath = entry.value;
              final offer = _offers[index % _offers.length];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(defaultBorderRadious),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr(offer['titleKey'] as String),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr(offer['descriptionKey'] as String),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _shuffledImages.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentOfferIndex == entry.key
                      ? const Color.fromARGB(255, 255, 210, 97)
                      : Colors.grey.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
        ],
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    routes.serviceListingScreenRoute,
                    arguments: cat.type,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(defaultBorderRadious),
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
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isProvider = auth.user?.role == UserRole.provider;

        return Padding(
          padding:
              const EdgeInsets.fromLTRB(defaultPadding, 16, defaultPadding, 8),
          child: Row(
            children: [
              Expanded(
                child: _QuickActionChip(
                  icon: Icons.receipt_long,
                  label: AppLocalizations.of(context).myBookings,
                  onTap: () => Navigator.pushNamed(
                      context, routes.myBookingsScreenRoute),
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
              if (isProvider) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionChip(
                    icon: Icons.business_center,
                    label: AppLocalizations.of(context).dashboard,
                    onTap: () => Navigator.pushNamed(
                        context, routes.providerEntryPointScreenRoute),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(defaultBorderRadious)),
                child: service.images.isNotEmpty
                    ? Image.network(
                        service.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: service.serviceTypeIcon
                                  .toString()
                                  .contains('domain')
                              ? primaryColor.withOpacity(0.1)
                              : service.serviceType == ServiceType.car
                                  ? const Color(0xFF2ED573).withOpacity(0.1)
                                  : service.serviceType ==
                                          ServiceType.photographer
                                      ? const Color(0xFFFFBE21).withOpacity(0.1)
                                      : const Color(0xFFEA5B5B)
                                          .withOpacity(0.1),
                          child: Center(
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
                          ),
                        ),
                      )
                    : Container(
                        color: service.serviceTypeIcon
                                .toString()
                                .contains('domain')
                            ? primaryColor.withOpacity(0.1)
                            : service.serviceType == ServiceType.car
                                ? const Color(0xFF2ED573).withOpacity(0.1)
                                : service.serviceType ==
                                        ServiceType.photographer
                                    ? const Color(0xFFFFBE21).withOpacity(0.1)
                                    : const Color(0xFFEA5B5B).withOpacity(0.1),
                        child: Center(
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
                        ),
                      ),
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
                          formatPrice(service.basePrice),
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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(defaultBorderRadious)),
                  child: service.images.isNotEmpty
                      ? Image.network(
                          service.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: primaryColor.withOpacity(0.1),
                            child: Center(
                              child: Icon(service.serviceTypeIcon,
                                  size: 40, color: primaryColor),
                            ),
                          ),
                        )
                      : Container(
                          color: primaryColor.withOpacity(0.1),
                          child: Center(
                            child: Icon(service.serviceTypeIcon,
                                size: 40, color: primaryColor),
                          ),
                        ),
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
                          formatPrice(service.basePrice),
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
