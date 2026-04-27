// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppL10nKk extends AppL10n {
  AppL10nKk([String locale = 'kk']) : super(locale);

  @override
  String get appName => 'Aziza Food';

  @override
  String get navHome => 'Басты';

  @override
  String get navCatalog => 'Каталог';

  @override
  String get navCart => 'Себет';

  @override
  String get navProfile => 'Профиль';

  @override
  String get homeGreeting => 'Қайырлы күн';

  @override
  String get homePremiumBadge => 'Premium мүше';

  @override
  String get homeBecomePremium => 'Мүше болу';

  @override
  String get homeRecommended => 'Ұсынылады';

  @override
  String get homeTopOfWeek => 'Апта таңдауы';

  @override
  String get catalogAll => 'Барлығы';

  @override
  String get catalogSearchHint => 'Атауы бойынша іздеу';

  @override
  String get catalogEmpty => 'Ештеңе табылмады';

  @override
  String get productAddToCart => 'Себетке';

  @override
  String get productKbju => '100 г үшін КБЖА';

  @override
  String get productCalories => 'ккал';

  @override
  String get productProtein => 'Ақуыз';

  @override
  String get productFat => 'Май';

  @override
  String get productCarbs => 'Көмірсу';

  @override
  String get productIngredients => 'Құрамы';

  @override
  String get productCooking => 'Дайындау тәсілі';

  @override
  String productWeight(int weight) {
    return '$weight г';
  }

  @override
  String productPieces(int count) {
    return '$count дана';
  }

  @override
  String get cartTitle => 'Себет';

  @override
  String get cartEmpty => 'Себет бос';

  @override
  String get cartGoShopping => 'Каталогқа өту';

  @override
  String get cartSubtotal => 'Тапсырыс сомасы';

  @override
  String get cartDelivery => 'Жеткізу';

  @override
  String get cartDiscount => 'Жеңілдік';

  @override
  String get cartTotal => 'Жалпы';

  @override
  String get cartPromoHint => 'Промокод';

  @override
  String get cartCheckout => 'Тапсырыс беру';

  @override
  String get checkoutTitle => 'Тапсырыс ресімдеу';

  @override
  String get checkoutAddress => 'Жеткізу мекенжайы';

  @override
  String get checkoutTime => 'Жеткізу уақыты';

  @override
  String get checkoutTimeAsap => 'Мүмкіндігінше тез';

  @override
  String get checkoutTimeScheduled => 'Уақытқа';

  @override
  String get checkoutPayment => 'Төлем';

  @override
  String get checkoutPaymentCash => 'Қолма-қол';

  @override
  String get checkoutPaymentCard => 'Онлайн картамен';

  @override
  String get checkoutPaymentKaspi => 'Kaspi';

  @override
  String get checkoutCommentHint => 'Курьерге пікір';

  @override
  String get checkoutPlaceOrder => 'Тапсырысты растау';

  @override
  String get checkoutAddNewAddress => 'Мекенжай қосу';

  @override
  String get orderSuccessTitle => 'Тапсырыс қабылданды';

  @override
  String get orderSuccessSubtitle => 'Курьер растау үшін хабарласады';

  @override
  String get orderSuccessCode => 'Тапсырыс нөмірі';

  @override
  String get orderSuccessHome => 'Басты бетке';

  @override
  String get orderSuccessTrack => 'Бақылау';

  @override
  String get productSize => 'Көлемі';

  @override
  String get promoApplied => 'Қолданылды';

  @override
  String get promoRemove => 'Алып тастау';

  @override
  String get promoApply => 'Қолдану';

  @override
  String get promoUnknown => 'Промокод табылмады';

  @override
  String get promoMinOrder => 'Тапсырыс сомасы ең аз сомадан кем';

  @override
  String get deliveryFree => 'Тегін';

  @override
  String fromPrice(String price) {
    return '$price бастап';
  }

  @override
  String get inCart => 'Себетте';

  @override
  String get goToCart => 'Өту';

  @override
  String get subscriptionTitle => 'Premium Kitchen';

  @override
  String get subscriptionTagline => 'Клубтың мүшесі болыңыз';

  @override
  String get subscriptionBenefit1 => 'Тегін жеткізу';

  @override
  String get subscriptionBenefit2 => 'Барлық тапсырыстарға 10% жеңілдік';

  @override
  String get subscriptionBenefit3 => 'Әр тапсырысқа сыйлық';

  @override
  String get subscriptionMonthly => 'Ай';

  @override
  String get subscriptionYearly => 'Жыл';

  @override
  String subscriptionSave(int percent) {
    return '$percent% үнемдеу';
  }

  @override
  String get subscriptionSubscribe => 'Жазылу';

  @override
  String get subscriptionPriceMonthly => '2 990 ₸/айына';

  @override
  String get subscriptionPriceYearly => '29 900 ₸/жылына';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileAddresses => 'Жеткізу мекенжайлары';

  @override
  String get profileOrders => 'Менің тапсырыстарым';

  @override
  String get profileSubscription => 'Жазылым';

  @override
  String get profileLanguage => 'Тіл';

  @override
  String get profileSupport => 'Қолдау';

  @override
  String get profileLogout => 'Шығу';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageEn => 'English';

  @override
  String get errorGeneric => 'Бірдеңе дұрыс болмады';

  @override
  String get errorNetwork => 'Байланыс жоқ';

  @override
  String get retry => 'Қайталау';

  @override
  String get loading => 'Жүктелуде...';

  @override
  String get onboardingSkip => 'Өткізіп жіберу';

  @override
  String get onboardingNext => 'Әрі қарай';

  @override
  String get onboardingStart => 'Бастау';

  @override
  String get onboarding1Title => 'Сүйікті тағамдар';

  @override
  String get onboarding1Body =>
      'Манты, пельмендер, самса және тұздықтар отбасы рецептері бойынша';

  @override
  String get onboarding2Title => 'Ыңғайлы төлем';

  @override
  String get onboarding2Body => 'Карта, Kaspi, Halyk немесе қолма-қол';

  @override
  String get onboarding3Title => 'Premium-клуб';

  @override
  String get onboarding3Body => 'Тегін жеткізу және әр тапсырысқа жеңілдіктер';

  @override
  String get loginTitle => 'Кіру';

  @override
  String get loginPhoneHint => '+7 (___) ___-__-__';

  @override
  String get loginGetCode => 'Код алу';

  @override
  String get loginPolicy =>
      'Жалғастыра отырып, пайдалану шарттарымен келісесіз';

  @override
  String get otpTitle => 'Кодты енгізіңіз';

  @override
  String otpSent(String phone) {
    return 'Код $phone нөміріне жіберілді';
  }

  @override
  String get otpResend => 'Қайта жіберу';

  @override
  String get otpVerify => 'Растау';

  @override
  String get loginButton => 'Кіру';

  @override
  String get profileLoginPrompt =>
      'Тапсырыстар мен жазылымды көру үшін кіріңіз';

  @override
  String get productRelated => 'Ұқсас';
}
