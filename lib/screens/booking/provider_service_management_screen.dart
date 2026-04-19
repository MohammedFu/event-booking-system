import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/models/demo_booking_data.dart';
import 'package:munasabati/route/route_constants.dart' as routes;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _ServiceListTab(services: demoHalls),
          _ServiceListTab(services: demoCars),
          _ServiceListTab(services: demoPhotographers),
          _ServiceListTab(services: demoEntertainers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeIndex = _tabController.index;
    final serviceType = ServiceType.values[typeIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.addService} ${serviceType.name.toUpperCase()}'),
        content: Text(l10n.serviceCreationForm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
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
                  onChanged: (val) {},
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: defaultPadding / 2),
            Row(
              children: [
                Icon(service.serviceTypeIcon, size: 16),
                const SizedBox(width: 4),
                Text(service.serviceTypeLabel,
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  '\$${service.basePrice.toStringAsFixed(0)}',
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
                          label: Text(rule.ruleTypeLabel,
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
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: l10n.edit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
