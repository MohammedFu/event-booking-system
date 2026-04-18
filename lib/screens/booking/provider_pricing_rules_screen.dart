import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/services/api_service.dart';

class ProviderPricingRulesScreen extends StatefulWidget {
  final ServiceModel service;

  const ProviderPricingRulesScreen({super.key, required this.service});

  @override
  State<ProviderPricingRulesScreen> createState() =>
      _ProviderPricingRulesScreenState();
}

class _ProviderPricingRulesScreenState
    extends State<ProviderPricingRulesScreen> {
  final ApiService _api = ApiService();
  List<PricingRuleModel> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    final response = await _api.getPricingRules(widget.service.id);
    if (response.success && response.data != null) {
      setState(() {
        _rules = response.data!;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.service.title} - Pricing Rules'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer,
                          size: 64, color: Theme.of(context).disabledColor),
                      const SizedBox(height: defaultPadding),
                      Text('No pricing rules',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: defaultPadding / 2),
                      Text('Add rules for dynamic pricing',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(defaultPadding),
                  itemCount: _rules.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: defaultPadding / 2),
                  itemBuilder: (context, index) =>
                      _PricingRuleCard(rule: _rules[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRuleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    PricingRuleType selectedType = PricingRuleType.weekend;
    double multiplier = 1.0;
    double fixedAdjustment = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Pricing Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<PricingRuleType>(
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Rule Type'),
                  items: PricingRuleType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(_ruleTypeIcon(t), size: 18),
                                const SizedBox(width: 8),
                                Text(t.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: defaultPadding),
                Text('Price Multiplier',
                    style: Theme.of(context).textTheme.bodySmall),
                Slider(
                  value: multiplier,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  label: '${multiplier.toStringAsFixed(2)}x',
                  onChanged: (val) =>
                      setDialogState(() => multiplier = val),
                ),
                Text(
                  multiplier > 1
                      ? 'Increases price by ${((multiplier - 1) * 100).toStringAsFixed(0)}%'
                      : multiplier < 1
                          ? 'Decreases price by ${((1 - multiplier) * 100).toStringAsFixed(0)}%'
                          : 'No change',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: multiplier > 1 ? Colors.red : Colors.green,
                      ),
                ),
                const SizedBox(height: defaultPadding),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fixed Adjustment (\$)',
                    hintText: '0.00',
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      setDialogState(() => fixedAdjustment = parsed);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final rule = PricingRuleModel(
                  id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
                  serviceId: widget.service.id,
                  ruleType: selectedType,
                  multiplier: multiplier,
                  fixedAdjustment: fixedAdjustment,
                );
                await _api.createPricingRule(rule);
                setState(() => _rules.add(rule));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add Rule'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _ruleTypeIcon(PricingRuleType type) {
    switch (type) {
      case PricingRuleType.seasonal:
        return Icons.wb_sunny;
      case PricingRuleType.weekend:
        return Icons.weekend;
      case PricingRuleType.peak:
        return Icons.trending_up;
      case PricingRuleType.earlyBird:
        return Icons.alarm;
      case PricingRuleType.lastMinute:
        return Icons.schedule;
      case PricingRuleType.bulkDiscount:
        return Icons.local_offer;
    }
  }
}

class _PricingRuleCard extends StatelessWidget {
  final PricingRuleModel rule;

  const _PricingRuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final isDiscount = rule.multiplier < 1;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isDiscount ? Colors.green : Colors.orange).withOpacity(0.1),
          child: Icon(rule.ruleTypeIcon,
              color: isDiscount ? Colors.green : Colors.orange, size: 20),
        ),
        title: Row(
          children: [
            Text(rule.ruleTypeLabel),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isDiscount ? Colors.green : Colors.orange)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${rule.multiplier.toStringAsFixed(2)}x',
                style: TextStyle(
                  fontSize: 11,
                  color: isDiscount ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rule.fixedAdjustment != 0)
              Text('Fixed: ${rule.fixedAdjustment > 0 ? '+' : ''}\$${rule.fixedAdjustment.toStringAsFixed(2)}'),
            if (rule.startDate != null && rule.endDate != null)
              Text('${rule.startDate!.month}/${rule.startDate!.day} - ${rule.endDate!.month}/${rule.endDate!.day}'),
            if (rule.minAdvanceDays != null)
              Text('Min ${rule.minAdvanceDays} days advance'),
          ],
        ),
        trailing: Switch(
          value: rule.isActive,
          onChanged: (val) {},
          activeColor: Colors.green,
        ),
      ),
    );
  }
}
