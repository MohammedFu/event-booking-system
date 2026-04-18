import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/services/api_service.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;

  const ProviderAvailabilityScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
  });

  @override
  State<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState
    extends State<ProviderAvailabilityScreen> {
  final ApiService _api = ApiService();
  List<AvailabilityTemplateModel> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final response = await _api.getAvailabilityTemplates(widget.serviceId);
    if (response.success && response.data != null) {
      setState(() {
        _templates = response.data!;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(defaultPadding),
              itemCount: _templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: defaultPadding / 2),
              itemBuilder: (context, index) {
                final template = _templates[index];
                return _AvailabilityCard(
                  template: template,
                  onToggle: () {
                    setState(() {
                      _templates[index] = AvailabilityTemplateModel(
                        id: template.id,
                        serviceId: template.serviceId,
                        dayOfWeek: template.dayOfWeek,
                        startTime: template.startTime,
                        endTime: template.endTime,
                        isAvailable: !template.isAvailable,
                      );
                    });
                  },
                  onEdit: () => _editTemplate(context, template, index),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: ElevatedButton(
            onPressed: () => _saveChanges(),
            child: const Text('Save Changes'),
          ),
        ),
      ),
    );
  }

  void _editTemplate(
      BuildContext context, AvailabilityTemplateModel template, int index) {
    TimeOfDay startTime = template.startTime;
    TimeOfDay endTime = template.endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            defaultPadding,
            defaultPadding,
            defaultPadding,
            MediaQuery.of(context).viewInsets.bottom + defaultPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template.dayLabel,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: defaultPadding),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(
                  '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    setSheetState(() => startTime = picked);
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(
                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (picked != null) {
                    setSheetState(() => endTime = picked);
                  }
                },
              ),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _templates[index] = AvailabilityTemplateModel(
                      id: template.id,
                      serviceId: template.serviceId,
                      dayOfWeek: template.dayOfWeek,
                      startTime: startTime,
                      endTime: endTime,
                      isAvailable: template.isAvailable,
                    );
                  });
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    for (final template in _templates) {
      await _api.updateAvailabilityTemplate(template);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability updated successfully')),
      );
    }
  }
}

class _AvailabilityCard extends StatelessWidget {
  final AvailabilityTemplateModel template;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _AvailabilityCard({
    required this.template,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isUnavailable = !template.isAvailable;
    return Card(
      color: isUnavailable ? Theme.of(context).cardColor.withOpacity(0.5) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: template.isAvailable
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Text(
            template.dayLabel.substring(0, 2),
            style: TextStyle(
              color: template.isAvailable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(template.dayLabel),
        subtitle: Text(
          isUnavailable ? 'Unavailable' : template.timeLabel,
          style: TextStyle(
            color: isUnavailable ? Colors.red : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: template.isAvailable,
              onChanged: (_) => onToggle(),
              activeColor: Colors.green,
            ),
            if (template.isAvailable)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }
}
