import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class BestSellers extends StatefulWidget {
  const BestSellers({
    super.key,
  });

  @override
  State<BestSellers> createState() => _BestSellersState();
}

class _BestSellersState extends State<BestSellers> {
  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    await context.read<BookingProvider>().fetchServices(sortBy: 'reviews');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            AppLocalizations.of(context).translate('top_rated_services'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 220,
          child: Consumer<BookingProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final services = provider.services.take(6).toList();
              if (services.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('no_services_available'),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == services.length - 1 ? defaultPadding : 0,
                  ),
                  child: _ServiceCard(
                    service: services[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        routes.serviceDetailScreenRoute,
                        arguments: services[index],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(defaultBorderRadious),
                  color: service.images.isNotEmpty
                      ? null
                      : primaryColor.withOpacity(0.1),
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
                          color: primaryColor,
                          size: 40,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              formatPrice(service.basePrice),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
