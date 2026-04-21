import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final ApiServiceReal _api = ApiServiceReal();
  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = true;

  final _hallThemes = [
    'حديث',
    'كلاسيكي',
    'ريفي',
    'حديقة',
    'شاطئ',
    'صناعي'
  ];
  final _carTypes = ['فاخر', 'كلاسيكي قديم', 'رياضي', 'دفع رباعي', 'ليموزين', 'عتيق'];
  final _photoStyles = [
    'تسجيلي',
    'تقليدي',
    'فني راقي',
    'تحريري',
    'داكن ومليء بالمشاعر',
    'فاتح وجيد التهوية'
  ];
  final _entertainerTypes = [
    'دي جي',
    'فرقة موسيقية حية',
    'مطرب',
    'راقص',
    'كوميدي',
    'ساحر'
  ];
  final _cities = [
    'صنعاء',
    'تعز',
    'الحديدة',
    'عدن',
    'إب',
    'عمران'
  ];
  final _budgetRanges = const [
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
        title: Text(AppLocalizations.of(context).myPreferences),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChipSection(
                    AppLocalizations.of(context).preferredHallThemes,
                    _hallThemes,
                    _preferences.preferredHallThemes,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: selected,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles:
                              _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes:
                              _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    AppLocalizations.of(context).preferredCarTypes,
                    _carTypes,
                    _preferences.preferredCarTypes,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: selected,
                          preferredPhotographerStyles:
                              _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes:
                              _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    AppLocalizations.of(context).photographyStyles,
                    _photoStyles,
                    _preferences.preferredPhotographerStyles,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles: selected,
                          preferredEntertainerTypes:
                              _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    AppLocalizations.of(context).entertainerTypes,
                    _entertainerTypes,
                    _preferences.preferredEntertainerTypes,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles:
                              _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes: selected,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: _preferences.preferredCities,
                        );
                      });
                    },
                  ),
                  _buildChipSection(
                    AppLocalizations.of(context).preferredCities,
                    _cities,
                    _preferences.preferredCities,
                    (selected) {
                      setState(() {
                        _preferences = UserPreferences(
                          preferredHallThemes: _preferences.preferredHallThemes,
                          preferredCarTypes: _preferences.preferredCarTypes,
                          preferredPhotographerStyles:
                              _preferences.preferredPhotographerStyles,
                          preferredEntertainerTypes:
                              _preferences.preferredEntertainerTypes,
                          budgetRange: _preferences.budgetRange,
                          preferredCities: selected,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: defaultPadding),
                  Text(AppLocalizations.of(context).budgetRange,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: defaultPadding / 2),
                  Wrap(
                    spacing: defaultPadding / 2,
                    runSpacing: defaultPadding / 2,
                    children: _budgetRanges.map((range) {
                      final isSelected =
                          _preferences.budgetRange.min == range.min &&
                              _preferences.budgetRange.max == range.max;
                      return ChoiceChip(
                        label: Text(range.max == double.infinity
                            ? 'ي.ر ${range.min.toStringAsFixed(0)}+'
                            : 'ي.ر ${range.min.toStringAsFixed(0)} - ي.ر ${range.max.toStringAsFixed(0)}'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _preferences = UserPreferences(
                              preferredHallThemes:
                                  _preferences.preferredHallThemes,
                              preferredCarTypes: _preferences.preferredCarTypes,
                              preferredPhotographerStyles:
                                  _preferences.preferredPhotographerStyles,
                              preferredEntertainerTypes:
                                  _preferences.preferredEntertainerTypes,
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
                          SnackBar(
                              content: Text(AppLocalizations.of(context)
                                  .preferencesSaved)),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context).savePreferences),
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
