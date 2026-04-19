import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/models/demo_booking_data.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:provider/provider.dart';

class BookingBookmarksScreen extends StatelessWidget {
  const BookingBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Services'),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          final bookmarkedServices = allDemoServices
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
                  Text('No saved services',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: defaultPadding / 2),
                  Text('Bookmark services you like to find them easily',
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
                    Text(service.serviceTypeLabel,
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
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.bookmark, color: primaryColor),
                tooltip: 'Remove bookmark',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
