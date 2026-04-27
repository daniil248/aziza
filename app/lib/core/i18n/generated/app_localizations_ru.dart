// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Aziza Food';

  @override
  String get navHome => 'Главная';

  @override
  String get navCatalog => 'Каталог';

  @override
  String get navCart => 'Корзина';

  @override
  String get navProfile => 'Профиль';

  @override
  String get homeGreeting => 'Добрый день';

  @override
  String get homePremiumBadge => 'Premium Member';

  @override
  String get homeBecomePremium => 'Стать участником';

  @override
  String get homeRecommended => 'Рекомендуем';

  @override
  String get homeTopOfWeek => 'Топ недели';

  @override
  String get catalogAll => 'Всё';

  @override
  String get catalogSearchHint => 'Поиск по названию';

  @override
  String get catalogEmpty => 'Ничего не найдено';

  @override
  String get productAddToCart => 'В корзину';

  @override
  String get productKbju => 'КБЖУ на 100 г';

  @override
  String get productCalories => 'ккал';

  @override
  String get productProtein => 'Белки';

  @override
  String get productFat => 'Жиры';

  @override
  String get productCarbs => 'Углеводы';

  @override
  String get productIngredients => 'Состав';

  @override
  String get productCooking => 'Способ приготовления';

  @override
  String productWeight(int weight) {
    return '$weight г';
  }

  @override
  String productPieces(int count) {
    return '$count шт';
  }

  @override
  String get cartTitle => 'Корзина';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get cartGoShopping => 'Перейти в каталог';

  @override
  String get cartSubtotal => 'Сумма заказа';

  @override
  String get cartDelivery => 'Доставка';

  @override
  String get cartDiscount => 'Скидка';

  @override
  String get cartTotal => 'Итого';

  @override
  String get cartPromoHint => 'Промокод';

  @override
  String get cartCheckout => 'Оформить заказ';

  @override
  String get checkoutTitle => 'Оформление';

  @override
  String get checkoutAddress => 'Адрес доставки';

  @override
  String get checkoutTime => 'Время доставки';

  @override
  String get checkoutTimeAsap => 'Как можно скорее';

  @override
  String get checkoutTimeScheduled => 'Ко времени';

  @override
  String get checkoutPayment => 'Оплата';

  @override
  String get checkoutPaymentCash => 'Наличными';

  @override
  String get checkoutPaymentCard => 'Картой онлайн';

  @override
  String get checkoutPaymentKaspi => 'Kaspi';

  @override
  String get checkoutCommentHint => 'Комментарий курьеру';

  @override
  String get checkoutPlaceOrder => 'Подтвердить заказ';

  @override
  String get checkoutAddNewAddress => 'Добавить адрес';

  @override
  String get orderSuccessTitle => 'Заказ принят';

  @override
  String get orderSuccessSubtitle => 'Курьер свяжется с вами для подтверждения';

  @override
  String get orderSuccessCode => 'Номер заказа';

  @override
  String get orderSuccessHome => 'На главную';

  @override
  String get orderSuccessTrack => 'Отследить';

  @override
  String get productSize => 'Размер';

  @override
  String get promoApplied => 'Применён';

  @override
  String get promoRemove => 'Убрать';

  @override
  String get promoApply => 'Применить';

  @override
  String get promoUnknown => 'Промокод не найден';

  @override
  String get promoMinOrder => 'Сумма заказа меньше минимальной';

  @override
  String get deliveryFree => 'Бесплатно';

  @override
  String fromPrice(String price) {
    return 'от $price';
  }

  @override
  String get inCart => 'В корзине';

  @override
  String get goToCart => 'Перейти';

  @override
  String get subscriptionTitle => 'Premium Kitchen';

  @override
  String get subscriptionTagline => 'Станьте частью клуба';

  @override
  String get subscriptionBenefit1 => 'Бесплатная доставка';

  @override
  String get subscriptionBenefit2 => 'Скидка 10% на все заказы';

  @override
  String get subscriptionBenefit3 => 'Подарок к каждому заказу';

  @override
  String get subscriptionMonthly => 'Месяц';

  @override
  String get subscriptionYearly => 'Год';

  @override
  String subscriptionSave(int percent) {
    return 'Экономия $percent%';
  }

  @override
  String get subscriptionSubscribe => 'Оформить подписку';

  @override
  String get subscriptionPriceMonthly => '2 990 ₸/мес';

  @override
  String get subscriptionPriceYearly => '29 900 ₸/год';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileAddresses => 'Адреса доставки';

  @override
  String get profileOrders => 'Мои заказы';

  @override
  String get profileSubscription => 'Подписка';

  @override
  String get profileLanguage => 'Язык';

  @override
  String get profileSupport => 'Поддержка';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageKk => 'Қазақша';

  @override
  String get languageEn => 'English';

  @override
  String get errorGeneric => 'Что-то пошло не так';

  @override
  String get errorNetwork => 'Нет соединения';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка...';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboarding1Title => 'Любимые блюда';

  @override
  String get onboarding1Body =>
      'Манты, пельмени, самса и соусы по семейным рецептам';

  @override
  String get onboarding2Title => 'Удобная оплата';

  @override
  String get onboarding2Body =>
      'Карта, Kaspi, Halyk или наличными — как удобно';

  @override
  String get onboarding3Title => 'Premium-клуб';

  @override
  String get onboarding3Body => 'Бесплатная доставка и скидки на каждый заказ';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginPhoneHint => '+7 (___) ___-__-__';

  @override
  String get loginGetCode => 'Получить код';

  @override
  String get loginPolicy =>
      'Продолжая, вы соглашаетесь с условиями использования';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSent(String phone) {
    return 'Код отправлен на $phone';
  }

  @override
  String get otpResend => 'Отправить ещё раз';

  @override
  String get otpVerify => 'Подтвердить';

  @override
  String get loginButton => 'Войти';

  @override
  String get profileLoginPrompt => 'Войдите, чтобы видеть заказы и подписку';

  @override
  String get productRelated => 'Похожие';
}
