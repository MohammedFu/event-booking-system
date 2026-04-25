import 'package:flutter/material.dart';
import 'package:munasabati/components/service_image.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchBookmarks();
      }
    });
  }

  Future<void> _fetchBookmarks() async {
    await context.read<BookingProvider>().fetchBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.savedServices),
        ),
        body: _LoginRequiredState(
          title: 'Save services to revisit them later.',
          buttonLabel: l10n.login,
          onPressed: () => Navigator.pushNamed(context, routes.authScreenRoute),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedServices),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookmarkedServices = provider.bookmarkedServices;
          if (bookmarkedServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: defaultPadding),
                  Text(
                    l10n.noSavedServices,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    l10n.bookmarkServicesHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                onRemove: () => provider.toggleBookmark(
                  service.id,
                  service: service,
                ),
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

class _LoginRequiredState extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _LoginRequiredState({
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: defaultPadding),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
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
    final imageUrl = service.images.isNotEmpty ? service.images.first : null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 360;

              return isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: ServiceImage(
                                imageUrl: imageUrl,
                                fallbackIcon: service.serviceTypeIcon,
                                borderRadius: BorderRadius.circular(
                                  defaultBorderRadious,
                                ),
                                iconSize: 28,
                              ),
                            ),
                            const SizedBox(width: defaultPadding),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service.serviceType.label(context),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: onRemove,
                              icon: const Icon(
                                Icons.bookmark,
                                color: primaryColor,
                              ),
                              tooltip: context.tr('remove_bookmark'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            if (service.provider?.rating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${service.provider!.rating}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
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
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: ServiceImage(
                            imageUrl: imageUrl,
                            fallbackIcon: service.serviceTypeIcon,
                            borderRadius: BorderRadius.circular(
                              defaultBorderRadious,
                            ),
                            iconSize: 28,
                          ),
                        ),
                        const SizedBox(width: defaultPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.serviceType.label(context),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  if (service.provider?.rating != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${service.provider!.rating}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
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
                    );
            },
          ),
        ),
      ),
    );
  }
}
