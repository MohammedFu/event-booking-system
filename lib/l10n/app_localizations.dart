import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/locales/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  String translate(String key, {Map<String, String>? params}) {
    String value = _localizedStrings[key] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }

  String get welcomeBack => translate('welcome_back');
  String get loginDesc => translate('login_desc');
  String get letsGetStarted => translate('lets_get_started');
  String get signUpDesc => translate('sign_up_desc');
  String get appTitle => translate('app_title');
  String get book => translate('book');
  String get discover => translate('discover');
  String get bookmark => translate('bookmark');
  String get cart => translate('cart');
  String get profile => translate('profile');
  String get wallet => translate('wallet');
  String get walletHistory => translate('wallet_history');
  String get yourCurrentBalance => translate('your_current_balance');
  String get chargeBalance => translate('charge_balance');
  String get returnLabel => translate('return');
  String get purchase => translate('purchase');
  String get notifications => translate('notifications');
  String get findSomething => translate('find_something');
  String get account => translate('account');
  String get orders => translate('orders');
  String get returns => translate('returns');
  String get wishlist => translate('wishlist');
  String get addresses => translate('addresses');
  String get payment => translate('payment');
  String get personalization => translate('personalization');
  String get notification => translate('notification');
  String get off => translate('off');
  String get preferences => translate('preferences');
  String get settings => translate('settings');
  String get language => translate('language');
  String get location => translate('location');
  String get helpSupport => translate('help_support');
  String get getHelp => translate('get_help');
  String get faq => translate('faq');
  String get logOut => translate('log_out');
  String get cookiePreferences => translate('cookie_preferences');
  String get reset => translate('reset');
  String get analytics => translate('analytics');
  String get analyticsDesc => translate('analytics_desc');
  String get personalizationCookie => translate('personalization_cookie');
  String get personalizationDesc => translate('personalization_desc');
  String get marketing => translate('marketing');
  String get marketingDesc => translate('marketing_desc');
  String get socialMediaCookies => translate('social_media_cookies');
  String get socialMediaDesc => translate('social_media_desc');
  String get addToCart => translate('add_to_cart');
  String get totalPrice => translate('total_price');
  String get sizeGuide => translate('size_guide');
  String get checkStores => translate('check_stores');
  String get storePickupAvailability => translate('store_pickup_availability');
  String get storePickupDesc => translate('store_pickup_desc');
  String get productDetails => translate('product_details');
  String get shippingInformation => translate('shipping_information');
  String get reviews => translate('reviews');
  String reviewsCount(String count) =>
      translate('reviews_count', params: {'count': count});
  String basedOnReviews(String count) =>
      translate('based_on_reviews', params: {'count': count});
  String get order => translate('order');
  String get addedToCart => translate('added_to_cart');
  String get addedToCartDesc => translate('added_to_cart_desc');
  String get continueShopping => translate('continue_shopping');
  String get checkout => translate('checkout');
  String get continueLabel => translate('continue');
  String get doYouHaveAccount => translate('do_you_have_account');
  String get logIn => translate('log_in');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get signUp => translate('sign_up');
  String get confirmBooking => translate('confirm_booking');
  String get noItemsInCart => translate('no_items_in_cart');
  String get bookingConfirmed => translate('booking_confirmed');
  String get bookingSuccessDesc => translate('booking_success_desc');
  String get myBookings => translate('my_bookings');
  String get bookNow => translate('book_now');
  String get selectDateTime => translate('select_date_time');
  String get selectServices => translate('select_services');
  String get eventType => translate('event_type');
  String get specialRequests => translate('special_requests');
  String get subtotal => translate('subtotal');
  String get deposit => translate('deposit');
  String get total => translate('total');
  String get confirm => translate('confirm');
  String get addService => translate('add_service');
  String get searchServices => translate('search_services');
  String get filter => translate('filter');
  String get sortBy => translate('sort_by');
  String get priceRange => translate('price_range');
  String get rating => translate('rating');
  String get available => translate('available');
  String get unavailable => translate('unavailable');
  String get description => translate('description');
  String get provider => translate('provider');
  String get duration => translate('duration');
  String get hours => translate('hours');
  String get perHour => translate('per_hour');
  String get bookThisService => translate('book_this_service');
  String get viewDetails => translate('view_details');
  String get back => translate('back');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get done => translate('done');
  String get next => translate('next');
  String get skip => translate('skip');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get noResults => translate('no_results');
  String get search => translate('search');
  String get apply => translate('apply');
  String get clear => translate('clear');
  String get close => translate('close');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');
  String get selectLanguage => translate('select_language');
  String get english => translate('english');
  String get arabic => translate('arabic');

  // Auth screens
  String get login => translate('login');
  String get signUpTab => translate('sign_up_tab');
  String get emailAddress => translate('email_address');
  String get password => translate('password');
  String get createAccount => translate('create_account');
  String get resetPassword => translate('reset_password');
  String get continueWithGoogle => translate('continue_with_google');
  String get continueWithApple => translate('continue_with_apple');
  String get or => translate('or');
  String get fullName => translate('full_name');
  String get phoneNumberOptional => translate('phone_number');

  String get rememberMe => translate('remember_me');
  String get loginFailed => translate('login_failed');
  String get registrationFailed => translate('registration_failed');
  String get errorServerConnection => translate('error_server_connection');
  String get errorWrongCredentials => translate('error_wrong_credentials');
  String get errorNetwork => translate('error_network');
  String get errorEmailExists => translate('error_email_exists');
  String get errorValidation => translate('error_validation');

  String get iAgreeWithThe => translate('i_agree_with_the');
  String get termsOfService => translate('terms_of_service');
  String get privacyPolicy => translate('privacy_policy');

  String get eventBookerAppName => translate('eventbooker_app_name');
  String get eventBookerTagline => translate('eventbooker_tagline');
  String get forgotPasswordQuestion => translate('forgot_password_question');
  String get send => translate('send');
  String get resetLinkSent => translate('reset_link_sent');
  String get resetPasswordInstructions =>
      translate('reset_password_instructions');
  String get pleaseEnterYourEmail => translate('please_enter_your_email');
  String get pleaseEnterValidEmail => translate('please_enter_valid_email');
  String get pleaseEnterYourPassword => translate('please_enter_your_password');
  String get passwordMinChars => translate('password_min_chars');
  String get pleaseEnterYourName => translate('please_enter_your_name');

  String get eventDetails => translate('event_details');
  String get eventName => translate('event_name');
  String get eventNameExample => translate('event_name_example');
  String get bookingSummary => translate('booking_summary');
  String get depositDueNow => translate('deposit_due_now');
  String get paymentMethod => translate('payment_method');
  String get creditDebitCard => translate('credit_debit_card');
  String get cardBrands => translate('card_brands');
  String get bankTransfer => translate('bank_transfer');
  String get directBankTransfer => translate('direct_bank_transfer');
  String get walletLabel => translate('wallet');
  String get payFromWalletBalance => translate('pay_from_wallet_balance');
  String confirmAndPayDeposit(String amount) =>
      translate('confirm_and_pay_deposit', params: {'amount': amount});

  String get pricingRules => translate('pricing_rules');
  String pricingRulesForService(String service) =>
      translate('pricing_rules_for_service', params: {'service': service});
  String get addPricingRule => translate('add_pricing_rule');
  String increasesPriceByPercent(String percent) =>
      translate('increases_price_by_percent', params: {'percent': percent});
  String decreasesPriceByPercent(String percent) =>
      translate('decreases_price_by_percent', params: {'percent': percent});
  String get noChange => translate('no_change');
  String fixedAdjustmentValue(String value) =>
      translate('fixed_adjustment_value', params: {'value': value});
  String get fixedAdjustmentPlaceholder =>
      translate('fixed_adjustment_placeholder');
  String dateRangeShort(String start, String end) =>
      translate('date_range_short', params: {'start': start, 'end': end});
  String minDaysAdvance(String days) =>
      translate('min_days_advance', params: {'days': days});

  // Home / Search
  String get searchHallsCars => translate('search_halls_cars');
  String get categories => translate('categories');
  String get popularSearches => translate('popular_searches');
  String get eventHalls => translate('event_halls');
  String get carsLimos => translate('cars_limos');
  String get photographers => translate('photographers');
  String get entertainers => translate('entertainers');

  // Reviews
  String get writeAReview => translate('write_a_review');
  String get shareYourExperience => translate('share_your_experience');
  String get submit => translate('submit');
  String get savedServices => translate('saved_services');
  String get noSavedServices => translate('no_saved_services');
  String get bookmarkServicesHint => translate('bookmark_services_hint');

  // Provider / Services
  String get myServices => translate('my_services');
  String get availability => translate('availability');
  String get pricing => translate('pricing');
  String get saveChanges => translate('save_changes');
  String get addRule => translate('add_rule');
  String get ruleType => translate('rule_type');
  String get priceMultiplier => translate('price_multiplier');
  String get fixedAdjustment => translate('fixed_adjustment');
  String get noPricingRules => translate('no_pricing_rules');
  String get addRulesHint => translate('add_rules_hint');

  // Preferences
  String get myPreferences => translate('my_preferences');
  String get preferredHallThemes => translate('preferred_hall_themes');
  String get preferredCarTypes => translate('preferred_car_types');
  String get photographyStyles => translate('photography_styles');
  String get entertainerTypes => translate('entertainer_types');
  String get preferredCities => translate('preferred_cities');
  String get budgetRange => translate('budget_range');
  String get savePreferences => translate('save_preferences');

  // Notifications
  String get markAllRead => translate('mark_all_read');
  String get noNotifications => translate('no_notifications');
  String get bookingConfirmedNotif => translate('booking_confirmed_notif');
  String get paymentReceived => translate('payment_received');
  String get upcomingEvent => translate('upcoming_event');
  String get leaveReview => translate('leave_review');
  String get specialOffer => translate('special_offer');

  // Booking Home
  String helloUser(String name) =>
      translate('hello_user', params: {'name': name});
  String get planDreamEvent => translate('plan_dream_event');
  String get bookPerfectEvent => translate('book_perfect_event');
  String get everythingOnePlace => translate('everything_one_place');
  String get popularServices => translate('popular_services');
  String get seeAll => translate('see_all');
  String get featuredHalls => translate('featured_halls');
  String get halls => translate('halls');
  String get cars => translate('cars');
  String get photos => translate('photos');
  String get entertainment => translate('entertainment');
  String get dashboard => translate('dashboard');

  // Booking Cart
  String get bookingCart => translate('booking_cart');
  String get yourCartEmpty => translate('your_cart_empty');
  String get browseServicesDesc => translate('browse_services_desc');
  String get browseServices => translate('browse_services');
  String get addMore => translate('add_more');
  String get proceedToBook => translate('proceed_to_book');
  String get clearCart => translate('clear_cart');
  String get clearCartConfirm => translate('clear_cart_confirm');
  String get depositPercent => translate('deposit_percent');
  String get preferencesSaved => translate('preferences_saved');

  // Service Detail
  String get verified => translate('verified');
  String get about => translate('about');
  String get noDescription => translate('no_description');
  String get price => translate('price');
  String get capacity => translate('capacity');
  String get guests => translate('guests');
  String get featuresDetails => translate('features_details');
  String get serviceProvider => translate('service_provider');
  String get cancellationPolicy => translate('cancellation_policy');
  String get flatRate => translate('flat_rate');
  String get perEvent => translate('per_event');
  String get tieredPricing => translate('tiered_pricing');
  String get stageAvailable => translate('stage_available');
  String get parking => translate('parking');
  String get kitchen => translate('kitchen');
  String get editingIncluded => translate('editing_included');
  String get passengers => translate('passengers');
  String get performers => translate('performers');

  // Service Listing
  String get allServices => translate('all_services');
  String get noServicesFound => translate('no_services_found');
  String get all => translate('all');
  String get topRated => translate('top_rated');
  String get priceLow => translate('price_low');
  String get priceHigh => translate('price_high');
  String get mostReviewed => translate('most_reviewed');
  String get weddingCars => translate('wedding_cars');

  // Provider Service Management
  String get serviceCreationForm => translate('service_creation_form');
  String get noServicesYet => translate('no_services_yet');
  String get tapToAddFirstService => translate('tap_to_add_first_service');

  // Onboarding
  String get onboardingTitle1 => translate('onboarding_title_1');
  String get onboardingDesc1 => translate('onboarding_desc_1');
  String get onboardingTitle2 => translate('onboarding_title_2');
  String get onboardingDesc2 => translate('onboarding_desc_2');
  String get onboardingTitle3 => translate('onboarding_title_3');
  String get onboardingDesc3 => translate('onboarding_desc_3');
  String get onboardingTitle4 => translate('onboarding_title_4');
  String get onboardingDesc4 => translate('onboarding_desc_4');
  String get onboardingTitle5 => translate('onboarding_title_5');
  String get onboardingDesc5 => translate('onboarding_desc_5');

  // Service Form
  String get serviceTitle => translate('service_title');
  String get basicInfo => translate('basic_info');
  String get basePrice => translate('base_price');
  String get pricingModel => translate('pricing_model');
  String get images => translate('images');
  String get gallery => translate('gallery');
  String get camera => translate('camera');
  String get tags => translate('tags');
  String get addTag => translate('add_tag');
  String get isAvailable => translate('is_available');
  String get editService => translate('edit_service');
  String get serviceUpdated => translate('service_updated');
  String get serviceCreated => translate('service_created');
  String get pleaseAddImage => translate('please_add_image');
  String get maxCapacity => translate('max_capacity');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, {Map<String, String>? params}) =>
      l10n.translate(key, params: params);

  String maybeTr(String value, {Map<String, String>? params}) {
    final translated = l10n.translate(value, params: params);
    return translated == value ? value : translated;
  }
}
