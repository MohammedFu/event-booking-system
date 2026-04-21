import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class MostPopular extends StatefulWidget {
  const MostPopular({
    super.key,
  });

  @override
  State<MostPopular> createState() => _MostPopularState();
}

class _MostPopularState extends State<MostPopular> {
  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    await context.read<BookingProvider>().fetchServices();
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
            AppLocalizations.of(context).mostReviewed,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 114,
          child: Consumer<BookingProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              final services = provider.services.take(8).toList();
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
                  child: _CompactServiceCard(
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

class _CompactServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _CompactServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 240,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
              child: SizedBox(
                width: 100,
                height: 100,
                child: service.images.isNotEmpty
                    ? Image.network(
                        service.images.first,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: primaryColor.withOpacity(0.1),
                        child: Icon(
                          service.serviceTypeIcon,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    service.title,
                    maxLines: 2,
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
          ],
        ),
      ),
    );
  }
}
