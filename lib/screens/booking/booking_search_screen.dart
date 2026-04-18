import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/models/demo_booking_data.dart';
import 'package:shop/route/route_constants.dart' as routes;

class BookingSearchScreen extends StatefulWidget {
  const BookingSearchScreen({super.key});

  @override
  State<BookingSearchScreen> createState() => _BookingSearchScreenState();
}

class _BookingSearchScreenState extends State<BookingSearchScreen> {
  final _searchController = TextEditingController();
  List<ServiceModel> _results = [];
  bool _isSearching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _query = query;
      _isSearching = true;
    });

    // Simulate search with demo data
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final q = query.toLowerCase();
      setState(() {
        _results = allDemoServices
            .where((s) =>
                s.title.toLowerCase().contains(q) ||
                s.description?.toLowerCase().contains(q) == true ||
                s.tags.any((t) => t.toLowerCase().contains(q)) ||
                s.serviceTypeLabel.toLowerCase().contains(q))
            .toList();
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search halls, cars, photographers...',
            border: InputBorder.none,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.5),
                ),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: _performSearch,
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _results = [];
                });
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty) {
      return _buildSuggestions();
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64,
                color: Theme.of(context).disabledColor),
            const SizedBox(height: defaultPadding),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: defaultPadding / 2),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: defaultPadding),
      itemBuilder: (context, index) {
        final service = _results[index];
        return _SearchResultCard(
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
    );
  }

  Widget _buildSuggestions() {
    final categories = [
      _SuggestionCategory(
        icon: Icons.domain,
        label: 'Event Halls',
        type: ServiceType.hall,
      ),
      _SuggestionCategory(
        icon: Icons.directions_car,
        label: 'Cars & Limos',
        type: ServiceType.car,
      ),
      _SuggestionCategory(
        icon: Icons.camera_alt,
        label: 'Photographers',
        type: ServiceType.photographer,
      ),
      _SuggestionCategory(
        icon: Icons.music_note,
        label: 'Entertainers',
        type: ServiceType.entertainer,
      ),
    ];

    final popularSearches = [
      'Wedding hall',
      'Luxury limo',
      'DJ for wedding',
      'Photo booth',
      'Vintage car',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: defaultPadding),
          Wrap(
            spacing: defaultPadding,
            runSpacing: defaultPadding,
            children: categories.map((cat) {
              return ActionChip(
                avatar: Icon(cat.icon, size: 18),
                label: Text(cat.label),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    routes.serviceListingScreenRoute,
                    arguments: cat.type,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: defaultPadding * 2),
          Text('Popular Searches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: defaultPadding),
          Wrap(
            spacing: defaultPadding / 2,
            runSpacing: defaultPadding / 2,
            children: popularSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _SearchResultCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(defaultBorderRadious),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(defaultBorderRadious),
            child: Image.asset(
              'assets/icons/${service.serviceType.name}.svg',
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Theme.of(context).cardColor,
                child: Icon(service.serviceTypeIcon, size: 32),
              ),
            ),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  service.serviceTypeLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (service.provider?.rating != null) ...[
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${service.provider!.rating}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: defaultPadding / 2),
                    ],
                    Text(
                      '\$${service.basePrice.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _SuggestionCategory {
  final IconData icon;
  final String label;
  final ServiceType type;

  const _SuggestionCategory({
    required this.icon,
    required this.label,
    required this.type,
  });
}
