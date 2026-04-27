// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aziza Food';

  @override
  String get navHome => 'Home';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navCart => 'Cart';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeGreeting => 'Good day';

  @override
  String get homePremiumBadge => 'Premium Member';

  @override
  String get homeBecomePremium => 'Become a Member';

  @override
  String get homeRecommended => 'Recommended';

  @override
  String get homeTopOfWeek => 'Top of the week';

  @override
  String get catalogAll => 'All';

  @override
  String get catalogSearchHint => 'Search by name';

  @override
  String get catalogEmpty => 'Nothing found';

  @override
  String get productAddToCart => 'Add to cart';

  @override
  String get productKbju => 'Per 100 g';

  @override
  String get productCalories => 'kcal';

  @override
  String get productProtein => 'Protein';

  @override
  String get productFat => 'Fat';

  @override
  String get productCarbs => 'Carbs';

  @override
  String get productIngredients => 'Ingredients';

  @override
  String get productCooking => 'How to cook';

  @override
  String productWeight(int weight) {
    return '$weight g';
  }

  @override
  String productPieces(int count) {
    return '$count pcs';
  }

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartGoShopping => 'Browse catalog';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartDelivery => 'Delivery';

  @override
  String get cartDiscount => 'Discount';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartPromoHint => 'Promo code';

  @override
  String get cartCheckout => 'Checkout';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutAddress => 'Delivery address';

  @override
  String get checkoutTime => 'Delivery time';

  @override
  String get checkoutTimeAsap => 'As soon as possible';

  @override
  String get checkoutTimeScheduled => 'Scheduled';

  @override
  String get checkoutPayment => 'Payment';

  @override
  String get checkoutPaymentCash => 'Cash';

  @override
  String get checkoutPaymentCard => 'Card online';

  @override
  String get checkoutPaymentKaspi => 'Kaspi';

  @override
  String get checkoutCommentHint => 'Note for the courier';

  @override
  String get checkoutPlaceOrder => 'Place order';

  @override
  String get checkoutAddNewAddress => 'Add address';

  @override
  String get orderSuccessTitle => 'Order placed';

  @override
  String get orderSuccessSubtitle => 'Our courier will reach out to confirm';

  @override
  String get orderSuccessCode => 'Order ID';

  @override
  String get orderSuccessHome => 'Home';

  @override
  String get orderSuccessTrack => 'Track';

  @override
  String get productSize => 'Size';

  @override
  String get promoApplied => 'Applied';

  @override
  String get promoRemove => 'Remove';

  @override
  String get promoApply => 'Apply';

  @override
  String get promoUnknown => 'Promo code not found';

  @override
  String get promoMinOrder => 'Order total below minimum';

  @override
  String get deliveryFree => 'Free';

  @override
  String fromPrice(String price) {
    return 'from $price';
  }

  @override
  String get inCart => 'Added to cart';

  @override
  String get goToCart => 'Open';

  @override
  String get subscriptionTitle => 'Premium Kitchen';

  @override
  String get subscriptionTagline => 'Become part of the club';

  @override
  String get subscriptionBenefit1 => 'Free delivery';

  @override
  String get subscriptionBenefit2 => '10% off all orders';

  @override
  String get subscriptionBenefit3 => 'A gift with every order';

  @override
  String get subscriptionMonthly => 'Monthly';

  @override
  String get subscriptionYearly => 'Yearly';

  @override
  String subscriptionSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String get subscriptionSubscribe => 'Subscribe';

  @override
  String get subscriptionPriceMonthly => '2 990 ₸/mo';

  @override
  String get subscriptionPriceYearly => '29 900 ₸/yr';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAddresses => 'Delivery addresses';

  @override
  String get profileOrders => 'My orders';

  @override
  String get profileSubscription => 'Subscription';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSupport => 'Support';

  @override
  String get profileLogout => 'Log out';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageEn => 'English';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNetwork => 'No connection';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboarding1Title => 'Your favorite dishes';

  @override
  String get onboarding1Body =>
      'Manty, pelmeni, samsa and sauces — family recipes';

  @override
  String get onboarding2Title => 'Pay your way';

  @override
  String get onboarding2Body => 'Card, Kaspi, Halyk or cash — whichever works';

  @override
  String get onboarding3Title => 'Premium club';

  @override
  String get onboarding3Body => 'Free delivery and a discount on every order';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginPhoneHint => '+7 (___) ___-__-__';

  @override
  String get loginGetCode => 'Send code';

  @override
  String get loginPolicy => 'By continuing you accept the terms of use';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSent(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get otpResend => 'Resend';

  @override
  String get otpVerify => 'Verify';

  @override
  String get loginButton => 'Sign in';

  @override
  String get profileLoginPrompt => 'Sign in to see orders and subscription';

  @override
  String get productRelated => 'You may also like';
}
