import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/services/api_service.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final ApiService _api = ApiService();
  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = true;

  final _hallThemes = ['Modern', 'Classic', 'Rustic', 'Garden', 'Beach', 'Industrial'];
  final _carTypes = ['Luxury', 'Vintage', 'Sports', 'SUV', 'Limo', 'Classic'];
  final _photoStyles = ['Documentary', 'Traditional', 'Fine Art', 'Editorial', 'Dark & Moody', 'Light & Airy'];
  final _entertainerTypes = ['DJ', 'Live Band', 'Singer', 'Dancer', 'Comedian', 'Magician'];
  final _cities = ['New York', 'Los Angeles', 'Chicago', 'Miami', 'Las Vegas', 'San Francisco'];
  final _budgetRanges = [
    BudgetRange(min: 0, max: 5000),
    BudgetRange(min: 5000, max: 15000),
    BudgetRange(min: 15000, max: 30000),
    BudgetRange(min: 30000, max: 50000),
    BudgetRange(min: 50000, max: double.infinity),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final response = await _api.getUserPreferences();
    if (response.success && response.data != null) {
      setState(() {
        _preferences = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preferences'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChipSection(
                    'Preferred Hall Themes',
                    _hallThemes,
                    _preferences.preferredHallThemes,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: selected,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles: _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes: _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    'Preferred Car Types',
                    _carTypes,
                    _preferences.preferredCarTypes,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: selected,
                          preferredPhotographerStyles: _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes: _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    'Photography Styles',
                    _photoStyles,
                    _preferences.preferredPhotographerStyles,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles: selected,
                          preferredEntertainerTypes: _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    'Entertainer Types',
                    _entertainerTypes,
                    _preferences.preferredEntertainerTypes,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles: _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes: selected,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    'Preferred Cities',
                    _cities,
                    _preferences.preferredCities,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles: _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes: _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: selected,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: defaultPadding),
                  Text('Budget Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: defaultPadding / 2),
                  Wrap(
                    spacing: defaultPadding / 2,
                    runSpacing: defaultPadding / 2,
                    children: _budgetRanges.map((range) {
                      final isSelected = _preferences.budgetRange.min == range.min &&
                          _preferences.budgetRange.max == range.max;
                      return ChoiceChip(
                        label: Text(range.max == double.infinity
                            ? '\$${range.min.toStringAsFixed(0)}+'
                            : '\$${range.min.toStringAsFixed(0)} - \$${range.max.toStringAsFixed(0)}'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _preferences = UserPreferences(
                              preferredHallThemes: _preferences.preferredHallThemes,
                              preferredCarTypes: _preferences.preferredCarTypes,
                              preferredPhotographerStyles: _preferences.preferredPhotographerStyles,
                              preferredEntertainerTypes: _preferences.preferredEntertainerTypes,
                              budgetRange: range,
                              preferredCities: _preferences.preferredCities,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: defaultPadding * 3),
                  ElevatedButton(
                    onPressed: () async {
                      await _api.updateUserPreferences(_preferences);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preferences saved')),
                        );
                      }
                    },
                    child: const Text('Save Preferences'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChipSection(
    String title,
    List<String> options,
    List<String> selected,
    ValueChanged<List<String>> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: defaultPadding / 2),
        Wrap(
          spacing: defaultPadding / 2,
          runSpacing: defaultPadding / 2,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (val) {
                final newSelected = List<String>.from(selected);
                if (val) {
                  newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: defaultPadding),
      ],
    );
  }
}
