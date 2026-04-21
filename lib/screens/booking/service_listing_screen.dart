import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class ServiceListingScreen extends StatefulWidget {
  final ServiceType? serviceType;

  const ServiceListingScreen({super.key, this.serviceType});

  @override
  State<ServiceListingScreen> createState() => _ServiceListingScreenState();
}

class _ServiceListingScreenState extends State<ServiceListingScreen> {
  ServiceType? _selectedType;
  String _sortBy = 'rating';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.serviceType;
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    await context.read<BookingProvider>().fetchServices(
          type: _selectedType,
          searchQuery:
              _searchController.text.isEmpty ? null : _searchController.text,
          sortBy: _sortBy,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTypeLabel(_selectedType) ?? l10n.allServices),
      ),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(context.maybeTr(provider.error!),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchServices,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                final services = provider.services;

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.noServicesFound,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(defaultPadding),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return _ServiceListCard(
                      service: services[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          serviceDetailScreenRoute,
                          arguments: services[index],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _fetchServices(),
            decoration: InputDecoration(
              hintText: l10n.searchServices,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadious),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.light
                  ? lightGreyColor
                  : darkGreyColor,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () async {
                        _searchController.clear();
                        await _fetchServices();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.all,
                  selected: _selectedType == null,
                  onSelected: () async {
                    setState(() => _selectedType = null);
                    await _fetchServices();
                  },
                ),
                _FilterChip(
                  label: l10n.halls,
                  selected: _selectedType == ServiceType.hall,
                  onSelected: () async {
                    setState(() => _selectedType = ServiceType.hall);
                    await _fetchServices();
                  },
                ),
                _FilterChip(
                  label: l10n.cars,
                  selected: _selectedType == ServiceType.car,
                  onSelected: () async {
                    setState(() => _selectedType = ServiceType.car);
                    await _fetchServices();
                  },
                ),
                _FilterChip(
                  label: l10n.photographers,
                  selected: _selectedType == ServiceType.photographer,
                  onSelected: () async {
                    setState(() => _selectedType = ServiceType.photographer);
                    await _fetchServices();
                  },
                ),
                _FilterChip(
                  label: l10n.entertainers,
                  selected: _selectedType == ServiceType.entertainer,
                  onSelected: () async {
                    setState(() => _selectedType = ServiceType.entertainer);
                    await _fetchServices();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                        value: 'rating', child: Text(l10n.topRated)),
                    DropdownMenuItem(
                        value: 'price_low', child: Text(l10n.priceLow)),
                    DropdownMenuItem(
                        value: 'price_high', child: Text(l10n.priceHigh)),
                    DropdownMenuItem(
                        value: 'reviews', child: Text(l10n.mostReviewed)),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _sortBy = val);
                      await _fetchServices();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getTypeLabel(ServiceType? type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case ServiceType.hall:
        return l10n.eventHalls;
      case ServiceType.car:
        return l10n.weddingCars;
      case ServiceType.photographer:
        return l10n.photographers;
      case ServiceType.entertainer:
        return l10n.entertainers;
      case null:
        return null;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: primaryColor.withOpacity(0.2),
      ),
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceListCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
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
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(defaultBorderRadious)),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: service.images.isNotEmpty
                      ? Image.network(
                          service.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: primaryColor.withOpacity(0.1),
                            child: Icon(service.serviceTypeIcon,
                                color: primaryColor, size: 32),
                          ),
                        )
                      : Container(
                          color: primaryColor.withOpacity(0.1),
                          child: Icon(service.serviceTypeIcon,
                              color: primaryColor, size: 32),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
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
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                size: 14, color: primaryColor),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (service.provider != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          service.provider!.businessName,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.color
                                        ?.withOpacity(0.6),
                                  ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Color(0xFFFFBE21)),
                          Text(
                            '${service.provider?.rating ?? 0} (${service.provider?.reviewCount ?? 0})',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const Spacer(),
                          Text(
                            formatPrice(service.basePrice),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (service.pricingModel == PricingModel.hourly)
                            Text(
                              l10n.perHour,
                              style: Theme.of(context).textTheme.labelSmall,
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
      ),
    );
  }
}
