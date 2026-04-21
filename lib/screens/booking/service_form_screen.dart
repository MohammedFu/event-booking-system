import 'dart:io';
import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/image_upload_service.dart';

class ServiceFormScreen extends StatefulWidget {
  final ServiceModel? service; // null for create, set for edit
  final ServiceType serviceType;

  const ServiceFormScreen({
    super.key,
    this.service,
    required this.serviceType,
  });

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiServiceReal();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _maxCapacityController;
  late final TextEditingController _minDurationController;
  late final TextEditingController _maxDurationController;

  // State
  bool _isLoading = false;
  bool _isAvailable = true;
  PricingModel _pricingModel = PricingModel.flat;
  final List<String> _tags = [];
  final List<String> _existingImageUrls = [];
  final List<File> _newImageFiles = [];
  final TextEditingController _tagController = TextEditingController();

  // Service type specific attributes
  ServiceAttributes _attributes = const ServiceAttributes();

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _titleController = TextEditingController(text: s?.title ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _basePriceController = TextEditingController(
      text: s?.basePrice.toString() ?? '',
    );
    _currencyController = TextEditingController(text: s?.currency ?? 'YER');
    _maxCapacityController = TextEditingController(
      text: s?.maxCapacity?.toString() ?? '',
    );
    _minDurationController = TextEditingController(
      text: s?.minDurationHours.toString() ?? '',
    );
    _maxDurationController = TextEditingController(
      text: s?.maxDurationHours?.toString() ?? '',
    );

    if (s != null) {
      _isAvailable = s.isAvailable;
      _pricingModel = s.pricingModel;
      _tags.addAll(s.tags);
      _existingImageUrls.addAll(s.images);
      _attributes = s.attributes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _currencyController.dispose();
    _maxCapacityController.dispose();
    _minDurationController.dispose();
    _maxDurationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await ImageUploadService.pickMultipleImages(
        maxImages: 10 - _totalImages);
    if (files.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(files);
      });
    }
  }

  Future<void> _takePhoto() async {
    final file = await ImageUploadService.pickImageFromCamera();
    if (file != null) {
      setState(() {
        _newImageFiles.add(file);
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  int get _totalImages => _existingImageUrls.length + _newImageFiles.length;

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pleaseAddImage)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload new images first
      List<String> allImageUrls = [..._existingImageUrls];
      if (_newImageFiles.isNotEmpty) {
        final uploadResult =
            await ImageUploadService.uploadImages(_newImageFiles);
        if (uploadResult.success && uploadResult.data != null) {
          allImageUrls.addAll(uploadResult.data!);
        } else {
          throw Exception(uploadResult.error ?? 'Failed to upload images');
        }
      }

      final basePrice = double.tryParse(_basePriceController.text) ?? 0;
      final maxCapacity = int.tryParse(_maxCapacityController.text);
      final minDuration = double.tryParse(_minDurationController.text);
      final maxDuration = double.tryParse(_maxDurationController.text);

      if (widget.service == null) {
        // Create new service
        final result = await _api.createService(
          title: _titleController.text.trim(),
          serviceType: widget.serviceType,
          basePrice: basePrice,
          description: _descriptionController.text.trim(),
          currency: _currencyController.text.trim(),
          pricingModel: _pricingModel,
          images: allImageUrls,
          tags: _tags,
          maxCapacity: maxCapacity,
          minDurationHours: minDuration,
          maxDurationHours: maxDuration,
          isAvailable: _isAvailable,
          attributes: _attributes,
        );

        if (result.success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).serviceCreated)),
            );
          }
        } else {
          throw Exception(result.error ?? 'Failed to create service');
        }
      } else {
        // Update existing service
        final result = await _api.updateService(
          serviceId: widget.service!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          basePrice: basePrice,
          currency: _currencyController.text.trim(),
          pricingModel: _pricingModel,
          images: allImageUrls,
          tags: _tags,
          maxCapacity: maxCapacity,
          minDurationHours: minDuration,
          maxDurationHours: maxDuration,
          isAvailable: _isAvailable,
          attributes: _attributes,
        );

        if (result.success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).serviceUpdated)),
            );
          }
        } else {
          throw Exception(result.error ?? 'Failed to update service');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .translate('error_with_message', params: {'message': '$e'}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.service != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editService : l10n.addService),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveService,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(defaultPadding),
          children: [
            // Image Section
            _buildImageSection(),
            const SizedBox(height: defaultPadding),

            // Basic Info
            Text(l10n.basicInfo,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultPadding / 2),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.serviceTitle,
                hintText: l10n.translate('service_title_hint'),
              ),
              validator: (v) =>
                  v?.isEmpty == true ? l10n.translate('title_required') : null,
            ),
            const SizedBox(height: defaultPadding / 2),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.description,
                hintText: l10n.translate('service_description_hint'),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: defaultPadding),

            // Pricing
            Text(l10n.pricing, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultPadding / 2),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _basePriceController,
                    decoration: InputDecoration(
                      labelText: l10n.basePrice,
                      prefixText: '${_currencyController.text} ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty == true ? l10n.translate('price_required') : null,
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration:
                        InputDecoration(labelText: l10n.translate('currency')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding / 2),
            DropdownButtonFormField<PricingModel>(
              value: _pricingModel,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.pricingModel),
              items: PricingModel.values.map((model) {
                return DropdownMenuItem(
                  value: model,
                  child: Text(model.label(context)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _pricingModel = v!),
            ),
            const SizedBox(height: defaultPadding),

            // Capacity & Duration
            Text(l10n.translate('details'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultPadding / 2),
            TextFormField(
              controller: _maxCapacityController,
              decoration: InputDecoration(
                labelText: l10n.maxCapacity,
                hintText: l10n.translate('max_capacity_hint'),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: defaultPadding / 2),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minDurationController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('min_duration_hours'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: defaultPadding / 2),
                Expanded(
                  child: TextFormField(
                    controller: _maxDurationController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('max_duration_hours'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding),

            // Tags
            Text(l10n.tags, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: defaultPadding / 2),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: l10n.addTag,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding / 2),
            Wrap(
              spacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: defaultPadding),

            // Availability Toggle
            SwitchListTile(
              title: Text(l10n.isAvailable),
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.images, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: defaultPadding / 2),
        Text(
          l10n.translate('images_count', params: {
            'count': _totalImages.toString(),
          }),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: defaultPadding / 2),

        // Image Grid
        if (_totalImages > 0)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _totalImages,
            itemBuilder: (context, index) {
              // Show existing images first
              if (index < _existingImageUrls.length) {
                return _buildImageTile(
                  imageUrl: _existingImageUrls[index],
                  onDelete: () => _removeExistingImage(index),
                );
              }
              // Then show new images
              final newIndex = index - _existingImageUrls.length;
              return _buildImageTile(
                file: _newImageFiles[newIndex],
                onDelete: () => _removeNewImage(newIndex),
              );
            },
          ),

        const SizedBox(height: defaultPadding / 2),

        // Add Image Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _totalImages < 10 ? _pickImages : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  maximumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.photo_library),
                label: Text(
                  l10n.gallery,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: defaultPadding / 2),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _totalImages < 10 ? _takePhoto : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  maximumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  l10n.camera,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageTile({
    String? imageUrl,
    File? file,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  )
                : file != null
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : const Icon(Icons.image),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
