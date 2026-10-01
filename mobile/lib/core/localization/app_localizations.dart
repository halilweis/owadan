import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TurkmenMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const TurkmenMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'tk';
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      const DefaultMaterialLocalizations(),
    );
  }

  @override
  bool shouldReload(TurkmenMaterialLocalizationsDelegate old) {
    return false;
  }
}

class TurkmenCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const TurkmenCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'tk';
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(
      const DefaultCupertinoLocalizations(),
    );
  }

  @override
  bool shouldReload(TurkmenCupertinoLocalizationsDelegate old) {
    return false;
  }
}

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('tk'),
    Locale('ru'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static bool supports(String languageCode) =>
      const {'tk', 'ru', 'en'}.contains(languageCode);

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context.');
    return value!;
  }

  String get languageCode =>
      supports(locale.languageCode) ? locale.languageCode : 'en';

  String t(String key) =>
      _values[languageCode]?[key] ?? _values['en']?[key] ?? key;

  String replace(String key, Map<String, Object?> values) {
    var result = t(key);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return result;
  }

  String status(String value) => switch (value) {
    'PENDING' => t('statusPending'),
    'CONFIRMED' => t('statusConfirmed'),
    'DECLINED' => t('statusDeclined'),
    'CANCELLED_BY_CUSTOMER' => t('statusCancelledByYou'),
    'CANCELLED_BY_PROFESSIONAL' => t('statusCancelledByProfessional'),
    'COMPLETED' => t('statusCompleted'),
    'NO_SHOW' => t('statusNoShow'),
    _ => value,
  };

  String weekdayShort(int weekday) {
    const keys = [
      'monShort',
      'tueShort',
      'wedShort',
      'thuShort',
      'friShort',
      'satShort',
      'sunShort',
    ];
    return t(keys[weekday - 1]);
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'home': 'Home',
      'explore': 'Explore',
      'bookings': 'Bookings',
      'favorites': 'Favorites',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'findBeauty': 'Find your next beauty appointment',
      'discoverVerified':
          'Discover verified professionals and book the service that fits you.',
      'searchProfessionals': 'Search professionals',
      'categories': 'Categories',
      'seeAll': 'See all',
      'recommendedProfessionals': 'Recommended professionals',
      'noCategories': 'No categories available yet.',
      'noProfessionals': 'No professionals available yet.',
      'tryAgain': 'Try again',
      'beautyTagline': 'Beauty services, easier to discover and book.',
      'phoneNumber': 'Phone number',
      'useInternationalFormat': 'Use international format.',
      'continue': 'Continue',
      'verifyNumber': 'Verify your number',
      'sentCodeTo': 'We sent a code to {phone}.',
      'developmentCode': 'Development code: {code}',
      'verificationCode': 'Verification code',
      'enterVerificationCode': 'Enter the verification code.',
      'verifyAndContinue': 'Verify and continue',
      'upcoming': 'Upcoming',
      'history': 'History',
      'noUpcomingBookings': 'No upcoming bookings.',
      'noBookingHistory': 'No booking history.',
      'professional': 'Professional',
      'bookingDetails': 'Booking details',
      'cancelBookingQuestion': 'Cancel booking?',
      'cancelBookingMessage': 'This appointment will be cancelled and the time slot will become available again.',
      'keepBooking': 'Keep booking',
      'cancelBooking': 'Cancel booking',
      'bookingCancelled': 'Booking cancelled.',
      'priceOnRequest': 'Price on request',
      'statusPending': 'Pending confirmation',
      'statusConfirmed': 'Confirmed',
      'statusDeclined': 'Declined',
      'statusCancelledByYou': 'Cancelled by you',
      'statusCancelledByProfessional': 'Cancelled by professional',
      'statusCompleted': 'Completed',
      'statusNoShow': 'No show',
      'bookAppointment': 'Book appointment',
      'chooseService': 'Choose service',
      'chooseDate': 'Choose date',
      'chooseTime': 'Choose time',
      'noAvailableSlots': 'No available time slots for this date.',
      'noteOptional': 'Note (optional)',
      'noteHint': 'Anything the professional should know?',
      'confirmBooking': 'Confirm booking',
      'bookingRequested': 'Booking requested',
      'done': 'Done',
      'statusLabel': 'Status: {status}',
      'minutes': '{count} min',
      'noFavoritesYet': 'No favorites yet',
      'favoritesHint':
          'Tap the heart on a professional profile to save them here.',
      'removeFavorite': 'Remove favorite',
      'removedFromFavorites': '{name} removed from favorites.',
      'addFavorite': 'Add favorite',
      'professionalNotFound': 'Professional not found.',
      'about': 'About',
      'yearsExperience': '{count} years experience',
      'services': 'Services',
      'noActiveServices': 'No active services yet.',
      'reviews': 'Reviews',
      'noReviews': 'No reviews yet.',
      'newProfessional': 'New',
      'fromPrice': 'From {price} {currency}',
      'noProfessionalsFound': 'No professionals found.',
      'editProfile': 'Edit profile',
      'profileUpdated': 'Profile updated.',
      'account': 'Account',
      'displayName': 'Display name',
      'notSet': 'Not set',
      'language': 'Language',
      'accountType': 'Account type',
      'session': 'Session',
      'signOut': 'Sign out',
      'signOutAll': 'Sign out from all devices',
      'signOutAllQuestion': 'Sign out from all devices?',
      'signOutAllMessage':
          'This will revoke all active sessions for your Owadan account.',
      'cancel': 'Cancel',
      'accountUnavailable': 'Account information unavailable.',
      'administrator': 'Administrator',
      'customerProfessional': 'Customer + Professional',
      'customer': 'Customer',
      'preferredLanguage': 'Preferred language',
      'displayNameHint': 'How should we call you?',
      'saveChanges': 'Save changes',
      'monShort': 'Mon',
      'tueShort': 'Tue',
      'wedShort': 'Wed',
      'thuShort': 'Thu',
      'friShort': 'Fri',
      'satShort': 'Sat',
      'sunShort': 'Sun',
    },
    'ru': {
      'home': 'Главная',
      'explore': 'Поиск',
      'bookings': 'Записи',
      'favorites': 'Избранное',
      'profile': 'Профиль',
      'notifications': 'Уведомления',
      'findBeauty': 'Найдите следующую beauty-запись',
      'discoverVerified':
          'Находите проверенных специалистов и бронируйте подходящие услуги.',
      'searchProfessionals': 'Поиск специалистов',
      'categories': 'Категории',
      'seeAll': 'Все',
      'recommendedProfessionals': 'Рекомендуемые специалисты',
      'noCategories': 'Категории пока недоступны.',
      'noProfessionals': 'Специалисты пока недоступны.',
      'tryAgain': 'Повторить',
      'beautyTagline': 'Beauty-услуги — проще находить и бронировать.',
      'phoneNumber': 'Номер телефона',
      'useInternationalFormat': 'Используйте международный формат.',
      'continue': 'Продолжить',
      'verifyNumber': 'Подтвердите номер',
      'sentCodeTo': 'Мы отправили код на {phone}.',
      'developmentCode': 'Код разработки: {code}',
      'verificationCode': 'Код подтверждения',
      'enterVerificationCode': 'Введите код подтверждения.',
      'verifyAndContinue': 'Подтвердить и продолжить',
      'upcoming': 'Предстоящие',
      'history': 'История',
      'noUpcomingBookings': 'Нет предстоящих записей.',
      'noBookingHistory': 'История записей пуста.',
      'professional': 'Специалист',
      'bookingDetails': 'Детали записи',
      'cancelBookingQuestion': 'Отменить запись?',
      'cancelBookingMessage':
          'Запись будет отменена, и это время снова станет доступным.',
      'keepBooking': 'Оставить запись',
      'cancelBooking': 'Отменить запись',
      'bookingCancelled': 'Запись отменена.',
      'priceOnRequest': 'Цена по запросу',
      'statusPending': 'Ожидает подтверждения',
      'statusConfirmed': 'Подтверждено',
      'statusDeclined': 'Отклонено',
      'statusCancelledByYou': 'Отменено вами',
      'statusCancelledByProfessional': 'Отменено специалистом',
      'statusCompleted': 'Завершено',
      'statusNoShow': 'Неявка',
      'bookAppointment': 'Записаться',
      'chooseService': 'Выберите услугу',
      'chooseDate': 'Выберите дату',
      'chooseTime': 'Выберите время',
      'noAvailableSlots': 'На эту дату нет свободного времени.',
      'noteOptional': 'Примечание (необязательно)',
      'noteHint': 'Что специалисту стоит знать?',
      'confirmBooking': 'Подтвердить запись',
      'bookingRequested': 'Запрос на запись отправлен',
      'done': 'Готово',
      'statusLabel': 'Статус: {status}',
      'minutes': '{count} мин',
      'noFavoritesYet': 'Избранного пока нет',
      'favoritesHint':
          'Нажмите на сердце в профиле специалиста, чтобы сохранить его здесь.',
      'removeFavorite': 'Удалить из избранного',
      'removedFromFavorites': '{name} удалён из избранного.',
      'addFavorite': 'Добавить в избранное',
      'professionalNotFound': 'Специалист не найден.',
      'about': 'О специалисте',
      'yearsExperience': 'Опыт: {count} лет',
      'services': 'Услуги',
      'noActiveServices': 'Активных услуг пока нет.',
      'reviews': 'Отзывы',
      'noReviews': 'Отзывов пока нет.',
      'newProfessional': 'Новый',
      'fromPrice': 'От {price} {currency}',
      'noProfessionalsFound': 'Специалисты не найдены.',
      'editProfile': 'Редактировать профиль',
      'profileUpdated': 'Профиль обновлён.',
      'account': 'Аккаунт',
      'displayName': 'Имя',
      'notSet': 'Не указано',
      'language': 'Язык',
      'accountType': 'Тип аккаунта',
      'session': 'Сессия',
      'signOut': 'Выйти',
      'signOutAll': 'Выйти на всех устройствах',
      'signOutAllQuestion': 'Выйти на всех устройствах?',
      'signOutAllMessage':
          'Все активные сессии вашего аккаунта Owadan будут отозваны.',
      'cancel': 'Отмена',
      'accountUnavailable': 'Данные аккаунта недоступны.',
      'administrator': 'Администратор',
      'customerProfessional': 'Клиент + специалист',
      'customer': 'Клиент',
      'preferredLanguage': 'Предпочитаемый язык',
      'displayNameHint': 'Как к вам обращаться?',
      'saveChanges': 'Сохранить изменения',
      'monShort': 'Пн',
      'tueShort': 'Вт',
      'wedShort': 'Ср',
      'thuShort': 'Чт',
      'friShort': 'Пт',
      'satShort': 'Сб',
      'sunShort': 'Вс',
    },
    'tk': {
      'home': 'Baş sahypa',
      'explore': 'Gözleg',
      'bookings': 'Ýazgylar',
      'favorites': 'Halanlarym',
      'profile': 'Profil',
      'notifications': 'Bildirişler',
      'findBeauty': 'Indiki gözellik hyzmatyňyzy tapyň',
      'discoverVerified':
          'Tassyklanan hünärmenleri tapyň we size laýyk hyzmaty bron ediň.',
      'searchProfessionals': 'Hünärmenleri gözle',
      'categories': 'Kategoriýalar',
      'seeAll': 'Ählisi',
      'recommendedProfessionals': 'Maslahat berilýän hünärmenler',
      'noCategories': 'Häzirlikçe kategoriýa ýok.',
      'noProfessionals': 'Häzirlikçe hünärmen ýok.',
      'tryAgain': 'Gaýtadan synanş',
      'beautyTagline': 'Gözellik hyzmatlaryny tapmak we bron etmek has aňsat.',
      'phoneNumber': 'Telefon belgisi',
      'useInternationalFormat': 'Halkara formatyny ulanyň.',
      'continue': 'Dowam et',
      'verifyNumber': 'Belgini tassyklaň',
      'sentCodeTo': '{phone} belgisine kod iberdik.',
      'developmentCode': 'Öndüriji kody: {code}',
      'verificationCode': 'Tassyklama kody',
      'enterVerificationCode': 'Tassyklama koduny giriziň.',
      'verifyAndContinue': 'Tassykla we dowam et',
      'upcoming': 'Geljekki',
      'history': 'Taryh',
      'noUpcomingBookings': 'Geljekki ýazgy ýok.',
      'noBookingHistory': 'Ýazgy taryhy ýok.',
      'professional': 'Hünärmen',
      'bookingDetails': 'Ýazgynyň maglumatlary',
      'cancelBookingQuestion': 'Ýazgyny ýatyrmalymy?',
      'cancelBookingMessage':
          'Bu ýazgy ýatyrylar we şol wagt gaýtadan elýeterli bolar.',
      'keepBooking': 'Ýazgyny sakla',
      'cancelBooking': 'Ýazgyny ýatyr',
      'bookingCancelled': 'Ýazgy ýatyryldy.',
      'priceOnRequest': 'Bahasy sorag boýunça',
      'statusPending': 'Tassyklamaga garaşýar',
      'statusConfirmed': 'Tassyklanan',
      'statusDeclined': 'Ret edilen',
      'statusCancelledByYou': 'Siz tarapyndan ýatyrylan',
      'statusCancelledByProfessional': 'Hünärmen tarapyndan ýatyrylan',
      'statusCompleted': 'Tamamlanan',
      'statusNoShow': 'Gelmedi',
      'bookAppointment': 'Wagt belle',
      'chooseService': 'Hyzmat saýlaň',
      'chooseDate': 'Sene saýlaň',
      'chooseTime': 'Wagt saýlaň',
      'noAvailableSlots': 'Bu senede boş wagt ýok.',
      'noteOptional': 'Bellik (hökmany däl)',
      'noteHint': 'Hünärmen nämäni bilmeli?',
      'confirmBooking': 'Ýazgyny tassykla',
      'bookingRequested': 'Ýazgy haýyşy iberildi',
      'done': 'Taýýar',
      'statusLabel': 'Ýagdaýy: {status}',
      'minutes': '{count} min',
      'noFavoritesYet': 'Halanlaryňyz ýok',
      'favoritesHint':
          'Hünärmeniň profilindäki ýürek nyşanyna basyp, ony şu ýere goşuň.',
      'removeFavorite': 'Halanlardan aýyr',
      'removedFromFavorites': '{name} halanlardan aýryldy.',
      'addFavorite': 'Halanlara goş',
      'professionalNotFound': 'Hünärmen tapylmady.',
      'about': 'Hakynda',
      'yearsExperience': '{count} ýyl tejribe',
      'services': 'Hyzmatlar',
      'noActiveServices': 'Häzirlikçe işjeň hyzmat ýok.',
      'reviews': 'Teswirler',
      'noReviews': 'Häzirlikçe teswir ýok.',
      'newProfessional': 'Täze',
      'fromPrice': '{price} {currency}-dan',
      'noProfessionalsFound': 'Hünärmen tapylmady.',
      'editProfile': 'Profili üýtget',
      'profileUpdated': 'Profil täzelendi.',
      'account': 'Hasap',
      'displayName': 'Görkezilýän at',
      'notSet': 'Görkezilmedik',
      'language': 'Dil',
      'accountType': 'Hasap görnüşi',
      'session': 'Sessiýa',
      'signOut': 'Çyk',
      'signOutAll': 'Ähli enjamlardan çyk',
      'signOutAllQuestion': 'Ähli enjamlardan çykmalymy?',
      'signOutAllMessage':
          'Owadan hasabyňyzyň ähli işjeň sessiýalary ýatyrylar.',
      'cancel': 'Ýatyr',
      'accountUnavailable': 'Hasap maglumatlary elýeterli däl.',
      'administrator': 'Administrator',
      'customerProfessional': 'Müşderi + hünärmen',
      'customer': 'Müşderi',
      'preferredLanguage': 'Saýlanan dil',
      'displayNameHint': 'Size nähili ýüzleneli?',
      'saveChanges': 'Üýtgeşmeleri ýatda sakla',
      'monShort': 'Du',
      'tueShort': 'Si',
      'wedShort': 'Çar',
      'thuShort': 'Pen',
      'friShort': 'Ann',
      'satShort': 'Şen',
      'sunShort': 'Ýek',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supports(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
