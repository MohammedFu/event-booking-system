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
