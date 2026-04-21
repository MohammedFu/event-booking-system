import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart' as routes;
import 'package:munasabati/screens/booking/service_form_screen.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class ProviderServiceManagementScreen extends StatefulWidget {
  const ProviderServiceManagementScreen({super.key});

  @override
  State<ProviderServiceManagementScreen> createState() =>
      _ProviderServiceManagementScreenState();
}

class _ProviderServiceManagementScreenState
    extends State<ProviderServiceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    await auth.syncCurrentUser(silent: true);
    if (!mounted) return;

    await bookingProvider.fetchProviderServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final isProvider = auth.user?.role == UserRole.provider;

    if (!isProvider) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.myServices),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Text(
              context.tr('provider_access_only'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myServices),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.halls),
            Tab(text: l10n.cars),
            Tab(text: l10n.photos),
            Tab(text: l10n.entertainers),
          ],
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final services = provider.providerServices;
          return TabBarView(
            controller: _tabController,
            children: [
              _ServiceListTab(
                services: services
                    .where((s) => s.serviceType == ServiceType.hall)
                    .toList(),
              ),
              _ServiceListTab(
                services: services
                    .where((s) => s.serviceType == ServiceType.car)
                    .toList(),
              ),
              _ServiceListTab(
                services: services
                    .where((s) => s.serviceType == ServiceType.photographer)
                    .toList(),
              ),
              _ServiceListTab(
                services: services
                    .where((s) => s.serviceType == ServiceType.entertainer)
                    .toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) async {
    final typeIndex = _tabController.index;
    final serviceType = ServiceType.values[typeIndex];

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceFormScreen(
          serviceType: serviceType,
        ),
      ),
    );

    if (result == true) {
      _fetchServices();
    }
  }
}

class _ServiceListTab extends StatelessWidget {
  final List<ServiceModel> services;

  const _ServiceListTab({required this.services});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_business,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: defaultPadding),
            Text(l10n.noServicesYet,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultPadding / 2),
            Text(l10n.tapToAddFirstService,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(defaultPadding),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: defaultPadding / 2),
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceManagementCard(service: service);
      },
    );
  }
}

class _ServiceManagementCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceManagementCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: service.isAvailable,
                  onChanged: (value) async {
                    final provider = context.read<BookingProvider>();
                    final success =
                        await provider.updateProviderServiceAvailability(
                      serviceId: service.id,
                      isAvailable: value,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? context.tr('availability_updated_successfully')
                              : provider.error ??
                                  context.tr('error_fetch_services'),
                        ),
                      ),
                    );
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: defaultPadding / 2),
            Row(
              children: [
                Icon(service.serviceTypeIcon, size: 16),
                const SizedBox(width: 4),
                Text(service.serviceType.label(context),
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  formatPrice(service.basePrice),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: primaryColor),
                ),
                if (service.pricingModel == PricingModel.hourly)
                  Text(l10n.perHour,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (service.pricingRules.isNotEmpty) ...[
              const SizedBox(height: defaultPadding / 2),
              Wrap(
                spacing: 4,
                children: service.pricingRules
                    .map((rule) => Chip(
                          avatar: Icon(rule.ruleTypeIcon, size: 14),
                          label: Text(rule.ruleType.label(context),
                              style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],
            const Divider(height: defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      routes.providerAvailabilityScreenRoute,
                      arguments: service,
                    );
                  },
                  icon: const Icon(Icons.schedule, size: 16),
                  label: Text(l10n.availability),
                ),
                const SizedBox(width: defaultPadding / 2),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      routes.providerPricingRulesScreenRoute,
                      arguments: service,
                    );
                  },
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: Text(l10n.pricing),
                ),
                const SizedBox(width: defaultPadding / 2),
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceFormScreen(
                          service: service,
                          serviceType: service.serviceType,
                        ),
                      ),
                    );
                    if (result == true) {
                      // Refresh parent to show updated data
                      if (context.mounted) {
                        final parent = context.findAncestorStateOfType<
                            _ProviderServiceManagementScreenState>();
                        parent?._fetchServices();
                      }
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: l10n.edit,
                ),
                IconButton(
                  onPressed: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.delete),
                        content: Text(service.title),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete != true || !context.mounted) return;

                    final provider = context.read<BookingProvider>();
                    final success =
                        await provider.deleteProviderService(service.id);
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? context.tr('service_deleted')
                              : provider.error ??
                                  context.tr('error_fetch_services'),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
