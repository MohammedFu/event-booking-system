import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/booking_cache_service.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:provider/provider.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final ApiServiceReal _api = ApiServiceReal();
  final BookingCacheService _cache = BookingCacheService();
  UserPreferences _preferences = const UserPreferences();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _hallThemes = ['حديث', 'كلاسيكي', 'ريفي', 'حديقة', 'شاطئ', 'صناعي'];
  final _carTypes = [
    'فاخر',
    'كلاسيكي قديم',
    'رياضي',
    'دفع رباعي',
    'ليموزين',
    'عتيق'
  ];
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
  final _cities = ['صنعاء', 'تعز', 'الحديدة', 'عدن', 'إب', 'عمران'];
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
    if (context.read<AuthProvider>().isAuthenticated) {
      _loadPreferences();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadPreferences() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final response = await _api.getUserPreferences();
    if (response.success && response.data != null) {
      await _cache.cachePreferences(userId, response.data!);
      setState(() {
        _preferences = response.data!;
        _error = null;
        _isLoading = false;
      });
    } else {
      final cachedPreferences = await _cache.getPreferences(userId);
      setState(() {
        _preferences = cachedPreferences ?? const UserPreferences();
        _error = cachedPreferences == null
            ? response.error ?? 'Failed to load preferences.'
            : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).myPreferences),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune,
                    size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: defaultPadding),
                Text(
                  'Sign in to save and sync your preferences.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, authScreenRoute),
                  child: Text(AppLocalizations.of(context).login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).myPreferences),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: defaultPadding),
                        ElevatedButton(
                          onPressed: _loadPreferences,
                          child: Text(AppLocalizations.of(context).retry),
                        ),
                      ],
                    ),
                  ),
                )
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
                              preferredHallThemes:
                                  _preferences.preferredHallThemes,
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
                              preferredHallThemes:
                                  _preferences.preferredHallThemes,
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
                              preferredHallThemes:
                                  _preferences.preferredHallThemes,
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
                              preferredHallThemes:
                                  _preferences.preferredHallThemes,
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                  preferredCarTypes:
                                      _preferences.preferredCarTypes,
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
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final userId =
                                    context.read<AuthProvider>().user?.id;
                                final bookingProvider =
                                    context.read<BookingProvider>();
                                final messenger = ScaffoldMessenger.of(context);
                                final preferencesSavedText =
                                    AppLocalizations.of(context)
                                        .preferencesSaved;
                                const offlineSavedText =
                                    'Preferences saved on this device. They will sync when the connection is back.';
                                if (userId == null) return;

                                setState(() => _isSaving = true);
                                final response = await _api
                                    .updateUserPreferences(_preferences);
                                if (!mounted) return;

                                final syncedPreferences =
                                    response.success && response.data != null
                                        ? response.data!
                                        : _preferences;

                                await _cache.cachePreferences(
                                  userId,
                                  syncedPreferences,
                                );

                                if (!mounted) return;

                                bookingProvider.updatePreferences(
                                  syncedPreferences,
                                );

                                setState(() {
                                  _preferences = syncedPreferences;
                                  _isSaving = false;
                                });

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.success
                                          ? preferencesSavedText
                                          : offlineSavedText,
                                    ),
                                  ),
                                );
                              },
                        child:
                            Text(AppLocalizations.of(context).savePreferences),
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
