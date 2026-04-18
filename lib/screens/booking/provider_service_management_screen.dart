import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/models/demo_booking_data.dart';
import 'package:shop/route/route_constants.dart' as routes;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Halls'),
            Tab(text: 'Cars'),
            Tab(text: 'Photos'),
            Tab(text: 'Entertainers'),
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
    final typeIndex = _tabController.index;
    final serviceType = ServiceType.values[typeIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${serviceType.name.toUpperCase()} Service'),
        content: const Text(
            'Service creation form will be available after backend integration.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_business,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: defaultPadding),
            Text('No services yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultPadding / 2),
            Text('Tap + to add your first service',
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
                  Text('/hr',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (service.pricingRules.isNotEmpty) ...[
              const SizedBox(height: defaultPadding / 2),
              Wrap(
                spacing: 4,
                children: service.pricingRules.map((rule) => Chip(
                  avatar: Icon(rule.ruleTypeIcon, size: 14),
                  label: Text(rule.ruleTypeLabel,
                      style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                )).toList(),
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
                  label: const Text('Availability'),
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
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: const Text('Pricing'),
                ),
                const SizedBox(width: defaultPadding / 2),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
