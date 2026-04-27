import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'Aziza Food'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get navCatalog;

  /// No description provided for @navCart.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get navCart;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get homeGreeting;

  /// No description provided for @homePremiumBadge.
  ///
  /// In ru, this message translates to:
  /// **'Premium Member'**
  String get homePremiumBadge;

  /// No description provided for @homeBecomePremium.
  ///
  /// In ru, this message translates to:
  /// **'Стать участником'**
  String get homeBecomePremium;

  /// No description provided for @homeRecommended.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуем'**
  String get homeRecommended;

  /// No description provided for @homeTopOfWeek.
  ///
  /// In ru, this message translates to:
  /// **'Топ недели'**
  String get homeTopOfWeek;

  /// No description provided for @catalogAll.
  ///
  /// In ru, this message translates to:
  /// **'Всё'**
  String get catalogAll;

  /// No description provided for @catalogSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию'**
  String get catalogSearchHint;

  /// No description provided for @catalogEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get catalogEmpty;

  /// No description provided for @productAddToCart.
  ///
  /// In ru, this message translates to:
  /// **'В корзину'**
  String get productAddToCart;

  /// No description provided for @productKbju.
  ///
  /// In ru, this message translates to:
  /// **'КБЖУ на 100 г'**
  String get productKbju;

  /// No description provided for @productCalories.
  ///
  /// In ru, this message translates to:
  /// **'ккал'**
  String get productCalories;

  /// No description provided for @productProtein.
  ///
  /// In ru, this message translates to:
  /// **'Белки'**
  String get productProtein;

  /// No description provided for @productFat.
  ///
  /// In ru, this message translates to:
  /// **'Жиры'**
  String get productFat;

  /// No description provided for @productCarbs.
  ///
  /// In ru, this message translates to:
  /// **'Углеводы'**
  String get productCarbs;

  /// No description provided for @productIngredients.
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get productIngredients;

  /// No description provided for @productCooking.
  ///
  /// In ru, this message translates to:
  /// **'Способ приготовления'**
  String get productCooking;

  /// No description provided for @productWeight.
  ///
  /// In ru, this message translates to:
  /// **'{weight} г'**
  String productWeight(int weight);

  /// No description provided for @productPieces.
  ///
  /// In ru, this message translates to:
  /// **'{count} шт'**
  String productPieces(int count);

  /// No description provided for @cartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Корзина пуста'**
  String get cartEmpty;

  /// No description provided for @cartGoShopping.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в каталог'**
  String get cartGoShopping;

  /// No description provided for @cartSubtotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа'**
  String get cartSubtotal;

  /// No description provided for @cartDelivery.
  ///
  /// In ru, this message translates to:
  /// **'Доставка'**
  String get cartDelivery;

  /// No description provided for @cartDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка'**
  String get cartDiscount;

  /// No description provided for @cartTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get cartTotal;

  /// No description provided for @cartPromoHint.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get cartPromoHint;

  /// No description provided for @cartCheckout.
  ///
  /// In ru, this message translates to:
  /// **'Оформить заказ'**
  String get cartCheckout;

  /// No description provided for @checkoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get checkoutTitle;

  /// No description provided for @checkoutAddress.
  ///
  /// In ru, this message translates to:
  /// **'Адрес доставки'**
  String get checkoutAddress;

  /// No description provided for @checkoutTime.
  ///
  /// In ru, this message translates to:
  /// **'Время доставки'**
  String get checkoutTime;

  /// No description provided for @checkoutTimeAsap.
  ///
  /// In ru, this message translates to:
  /// **'Как можно скорее'**
  String get checkoutTimeAsap;

  /// No description provided for @checkoutTimeScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Ко времени'**
  String get checkoutTimeScheduled;

  /// No description provided for @checkoutPayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get checkoutPayment;

  /// No description provided for @checkoutPaymentCash.
  ///
  /// In ru, this message translates to:
  /// **'Наличными'**
  String get checkoutPaymentCash;

  /// No description provided for @checkoutPaymentCard.
  ///
  /// In ru, this message translates to:
  /// **'Картой онлайн'**
  String get checkoutPaymentCard;

  /// No description provided for @checkoutPaymentKaspi.
  ///
  /// In ru, this message translates to:
  /// **'Kaspi'**
  String get checkoutPaymentKaspi;

  /// No description provided for @checkoutCommentHint.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий курьеру'**
  String get checkoutCommentHint;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить заказ'**
  String get checkoutPlaceOrder;

  /// No description provided for @checkoutAddNewAddress.
  ///
  /// In ru, this message translates to:
  /// **'Добавить адрес'**
  String get checkoutAddNewAddress;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ принят'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Курьер свяжется с вами для подтверждения'**
  String get orderSuccessSubtitle;

  /// No description provided for @orderSuccessCode.
  ///
  /// In ru, this message translates to:
  /// **'Номер заказа'**
  String get orderSuccessCode;

  /// No description provided for @orderSuccessHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get orderSuccessHome;

  /// No description provided for @orderSuccessTrack.
  ///
  /// In ru, this message translates to:
  /// **'Отследить'**
  String get orderSuccessTrack;

  /// No description provided for @productSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер'**
  String get productSize;

  /// No description provided for @promoApplied.
  ///
  /// In ru, this message translates to:
  /// **'Применён'**
  String get promoApplied;

  /// No description provided for @promoRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get promoRemove;

  /// No description provided for @promoApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get promoApply;

  /// No description provided for @promoUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Промокод не найден'**
  String get promoUnknown;

  /// No description provided for @promoMinOrder.
  ///
  /// In ru, this message translates to:
  /// **'Сумма заказа меньше минимальной'**
  String get promoMinOrder;

  /// No description provided for @deliveryFree.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно'**
  String get deliveryFree;

  /// No description provided for @fromPrice.
  ///
  /// In ru, this message translates to:
  /// **'от {price}'**
  String fromPrice(String price);

  /// No description provided for @inCart.
  ///
  /// In ru, this message translates to:
  /// **'В корзине'**
  String get inCart;

  /// No description provided for @goToCart.
  ///
  /// In ru, this message translates to:
  /// **'Перейти'**
  String get goToCart;

  /// No description provided for @subscriptionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Premium Kitchen'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionTagline.
  ///
  /// In ru, this message translates to:
  /// **'Станьте частью клуба'**
  String get subscriptionTagline;

  /// No description provided for @subscriptionBenefit1.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатная доставка'**
  String get subscriptionBenefit1;

  /// No description provided for @subscriptionBenefit2.
  ///
  /// In ru, this message translates to:
  /// **'Скидка 10% на все заказы'**
  String get subscriptionBenefit2;

  /// No description provided for @subscriptionBenefit3.
  ///
  /// In ru, this message translates to:
  /// **'Подарок к каждому заказу'**
  String get subscriptionBenefit3;

  /// No description provided for @subscriptionMonthly.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get subscriptionMonthly;

  /// No description provided for @subscriptionYearly.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get subscriptionYearly;

  /// No description provided for @subscriptionSave.
  ///
  /// In ru, this message translates to:
  /// **'Экономия {percent}%'**
  String subscriptionSave(int percent);

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In ru, this message translates to:
  /// **'Оформить подписку'**
  String get subscriptionSubscribe;

  /// No description provided for @subscriptionPriceMonthly.
  ///
  /// In ru, this message translates to:
  /// **'2 990 ₸/мес'**
  String get subscriptionPriceMonthly;

  /// No description provided for @subscriptionPriceYearly.
  ///
  /// In ru, this message translates to:
  /// **'29 900 ₸/год'**
  String get subscriptionPriceYearly;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileAddresses.
  ///
  /// In ru, this message translates to:
  /// **'Адреса доставки'**
  String get profileAddresses;

  /// No description provided for @profileOrders.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get profileOrders;

  /// No description provided for @profileSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get profileSubscription;

  /// No description provided for @profileLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get profileLanguage;

  /// No description provided for @profileSupport.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get profileSupport;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @languageRu.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @languageKk.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get languageKk;

  /// No description provided for @languageEn.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @errorGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения'**
  String get errorNetwork;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get loading;

  /// No description provided for @onboardingSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In ru, this message translates to:
  /// **'Любимые блюда'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In ru, this message translates to:
  /// **'Манты, пельмени, самса и соусы по семейным рецептам'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In ru, this message translates to:
  /// **'Удобная оплата'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In ru, this message translates to:
  /// **'Карта, Kaspi, Halyk или наличными — как удобно'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In ru, this message translates to:
  /// **'Premium-клуб'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатная доставка и скидки на каждый заказ'**
  String get onboarding3Body;

  /// No description provided for @loginTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get loginTitle;

  /// No description provided for @loginPhoneHint.
  ///
  /// In ru, this message translates to:
  /// **'+7 (___) ___-__-__'**
  String get loginPhoneHint;

  /// No description provided for @loginGetCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get loginGetCode;

  /// No description provided for @loginPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Продолжая, вы соглашаетесь с условиями использования'**
  String get loginPolicy;

  /// No description provided for @otpTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get otpTitle;

  /// No description provided for @otpSent.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен на {phone}'**
  String otpSent(String phone);

  /// No description provided for @otpResend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить ещё раз'**
  String get otpResend;

  /// No description provided for @otpVerify.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get otpVerify;

  /// No description provided for @loginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get loginButton;

  /// No description provided for @profileLoginPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы видеть заказы и подписку'**
  String get profileLoginPrompt;

  /// No description provided for @productRelated.
  ///
  /// In ru, this message translates to:
  /// **'Похожие'**
  String get productRelated;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'kk':
      return AppL10nKk();
    case 'ru':
      return AppL10nRu();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
