class ApiErrorMessages {
  ApiErrorMessages._();

  static String _languageCode = 'en';

  static String get languageCode => _languageCode;

  static void setLanguage(String languageCode) {
    _languageCode = switch (languageCode) {
      'tk' => 'tk',
      'ru' => 'ru',
      _ => 'en',
    };
  }

  static String translate(
    String code, {
    String? fallback,
  }) {
    final normalizedCode = code.trim().toUpperCase();

    final translated = _messages[_languageCode]?[normalizedCode];
    if (translated != null) {
      return translated;
    }

    final english = _messages['en']?[normalizedCode];
    if (english != null) {
      return english;
    }

    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback;
    }

    return _messages[_languageCode]?['API_ERROR'] ??
        'Unable to complete the request.';
  }

  static const Map<String, Map<String, String>> _messages = {
    'en': {
      'API_ERROR': 'Unable to complete the request.',
      'UNAUTHENTICATED': 'Your session has expired. Please sign in again.',
      'FORBIDDEN': 'You do not have permission to perform this action.',
      'NOT_FOUND': 'The requested item could not be found.',
      'VALIDATION_ERROR': 'Please check the information and try again.',
      'OTP_INVALID': 'The verification code is invalid or has expired.',
      'USER_DISABLED': 'This account is disabled.',
      'REFRESH_TOKEN_INVALID': 'Your session has expired. Please sign in again.',
      'PROFESSIONAL_UNAVAILABLE':
          'This professional is currently unavailable.',
      'OUTSIDE_WORKING_HOURS':
          'The selected time is outside the professional’s working hours.',
      'TIME_BLOCKED': 'The selected time is unavailable.',
      'TIME_NOT_AVAILABLE':
          'That time is no longer available. Please choose another time.',
      'INVALID_BOOKING_STATE':
          'This booking cannot be changed in its current state.',
      'BOOKING_NOT_COMPLETED':
          'Only completed bookings can be reviewed.',
      'REVIEW_ALREADY_EXISTS':
          'You have already reviewed this booking.',
      'INVALID_AUTH_RESPONSE':
          'Authentication could not be completed. Please try again.',
    },
    'ru': {
      'API_ERROR': 'Не удалось выполнить запрос.',
      'UNAUTHENTICATED':
          'Срок действия сеанса истёк. Пожалуйста, войдите снова.',
      'FORBIDDEN': 'У вас нет разрешения на выполнение этого действия.',
      'NOT_FOUND': 'Запрошенные данные не найдены.',
      'VALIDATION_ERROR':
          'Проверьте введённые данные и попробуйте ещё раз.',
      'OTP_INVALID': 'Код подтверждения неверен или срок его действия истёк.',
      'USER_DISABLED': 'Этот аккаунт отключён.',
      'REFRESH_TOKEN_INVALID':
          'Срок действия сеанса истёк. Пожалуйста, войдите снова.',
      'PROFESSIONAL_UNAVAILABLE':
          'Этот специалист сейчас недоступен.',
      'OUTSIDE_WORKING_HOURS':
          'Выбранное время находится вне рабочего времени специалиста.',
      'TIME_BLOCKED': 'Выбранное время недоступно.',
      'TIME_NOT_AVAILABLE':
          'Это время больше недоступно. Выберите другое время.',
      'INVALID_BOOKING_STATE':
          'Эту запись нельзя изменить в её текущем состоянии.',
      'BOOKING_NOT_COMPLETED':
          'Оставить отзыв можно только после завершённой записи.',
      'REVIEW_ALREADY_EXISTS':
          'Вы уже оставили отзыв по этой записи.',
      'INVALID_AUTH_RESPONSE':
          'Не удалось завершить авторизацию. Попробуйте ещё раз.',
    },
    'tk': {
      'API_ERROR': 'Talaby ýerine ýetirip bolmady.',
      'UNAUTHENTICATED':
          'Sessiýanyň möhleti gutardy. Täzeden ulgama giriň.',
      'FORBIDDEN': 'Bu hereketi ýerine ýetirmäge rugsadyňyz ýok.',
      'NOT_FOUND': 'Talap edilen maglumat tapylmady.',
      'VALIDATION_ERROR':
          'Maglumatlary barlap, gaýtadan synanyşyň.',
      'OTP_INVALID':
          'Tassyklama kody nädogry ýa-da möhleti gutaran.',
      'USER_DISABLED': 'Bu hasap öçürilen.',
      'REFRESH_TOKEN_INVALID':
          'Sessiýanyň möhleti gutardy. Täzeden ulgama giriň.',
      'PROFESSIONAL_UNAVAILABLE':
          'Bu hünärmen häzirki wagtda elýeterli däl.',
      'OUTSIDE_WORKING_HOURS':
          'Saýlanan wagt hünärmeniň iş wagtynyň daşynda.',
      'TIME_BLOCKED': 'Saýlanan wagt elýeterli däl.',
      'TIME_NOT_AVAILABLE':
          'Bu wagt indi elýeterli däl. Başga wagt saýlaň.',
      'INVALID_BOOKING_STATE':
          'Bu ýazgyny häzirki ýagdaýynda üýtgedip bolmaýar.',
      'BOOKING_NOT_COMPLETED':
          'Diňe tamamlanan ýazgylar üçin teswir galdyryp bolýar.',
      'REVIEW_ALREADY_EXISTS':
          'Bu ýazgy üçin eýýäm teswir galdyrdyňyz.',
      'INVALID_AUTH_RESPONSE':
          'Ulgama giriş tamamlanmady. Gaýtadan synanyşyň.',
    },
  };
}
