import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:provider/provider.dart';

class BookingBookmarksScreen extends StatefulWidget {
  const BookingBookmarksScreen({super.key});

  @override
  State<BookingBookmarksScreen> createState() => _BookingBookmarksScreenState();
}

class _BookingBookmarksScreenState extends State<BookingBookmarksScreen> {
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedServices),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookmarkedServices = provider.services
              .where((s) => provider.isBookmarked(s.id))
              .toList();

          if (bookmarkedServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border,
                      size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: defaultPadding),
                  Text(l10n.noSavedServices,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: defaultPadding / 2),
                  Text(l10n.bookmarkServicesHint,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: bookmarkedServices.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: defaultPadding / 2),
            itemBuilder: (context, index) {
              final service = bookmarkedServices[index];
              return _BookmarkCard(
                service: service,
                onRemove: () => provider.toggleBookmark(service.id),
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
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkCard({
    required this.service,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(defaultBorderRadious),
                ),
                child: Icon(service.serviceTypeIcon,
                    color: primaryColor, size: 28),
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
                    Text(service.serviceType.label(context),
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (service.provider?.rating != null) ...[
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${service.provider!.rating}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const Spacer(),
                        Text(
                          formatPrice(service.basePrice),
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
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.bookmark, color: primaryColor),
                tooltip: context.tr('remove_bookmark'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
