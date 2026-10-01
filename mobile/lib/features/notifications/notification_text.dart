import 'package:flutter/material.dart';

import 'models/app_notification.dart';

class NotificationText {
  NotificationText._();

  static String title(BuildContext context, AppNotification notification) {
    final language = Localizations.localeOf(context).languageCode;

    return switch (notification.type) {
      'BOOKING_CONFIRMED' => _pick(
        language,
        tk: 'Ýazgy tassyklandy',
        ru: 'Запись подтверждена',
        en: 'Booking confirmed',
      ),
      'BOOKING_DECLINED' => _pick(
        language,
        tk: 'Ýazgy ret edildi',
        ru: 'Запись отклонена',
        en: 'Booking declined',
      ),
      'BOOKING_CANCELLED' => _pick(
        language,
        tk: 'Ýazgy ýatyryldy',
        ru: 'Запись отменена',
        en: 'Booking cancelled',
      ),
      'BOOKING_COMPLETED' => _pick(
        language,
        tk: 'Ýazgy tamamlandy',
        ru: 'Запись завершена',
        en: 'Booking completed',
      ),
      'BOOKING_NO_SHOW' => _pick(
        language,
        tk: 'Gelmändigiňiz bellendi',
        ru: 'Отмечена неявка',
        en: 'Booking marked as no-show',
      ),
      'NEW_BOOKING' => _pick(
        language,
        tk: 'Täze ýazgy haýyşy',
        ru: 'Новый запрос на запись',
        en: 'New booking request',
      ),
      'REVIEW_RECEIVED' => _pick(
        language,
        tk: 'Täze teswir geldi',
        ru: 'Получен новый отзыв',
        en: 'New review received',
      ),
      _ => notification.title,
    };
  }

  static String? message(BuildContext context, AppNotification notification) {
    final language = Localizations.localeOf(context).languageCode;

    return switch (notification.type) {
      'BOOKING_CONFIRMED' => _pick(
        language,
        tk: 'Ýazgyňyz hünärmen tarapyndan tassyklandy.',
        ru: 'Ваша запись подтверждена специалистом.',
        en: 'Your booking has been confirmed by the professional.',
      ),
      'BOOKING_DECLINED' => _pick(
        language,
        tk: 'Ýazgy haýyşyňyz hünärmen tarapyndan ret edildi.',
        ru: 'Ваш запрос на запись отклонён специалистом.',
        en: 'Your booking request was declined by the professional.',
      ),
      'BOOKING_CANCELLED' => _pick(
        language,
        tk: 'Ýazgyňyz ýatyryldy.',
        ru: 'Ваша запись была отменена.',
        en: 'Your booking was cancelled.',
      ),
      'BOOKING_COMPLETED' => _pick(
        language,
        tk: 'Hyzmat tamamlandy. Indi teswir galdyryp bilersiňiz.',
        ru: 'Услуга завершена. Теперь вы можете оставить отзыв.',
        en: 'Your appointment is complete. You can now leave a review.',
      ),
      'BOOKING_NO_SHOW' => _pick(
        language,
        tk: 'Bu ýazgy boýunça gelmändigiňiz bellendi.',
        ru: 'По этой записи отмечена неявка.',
        en: 'This booking was marked as a no-show.',
      ),
      'NEW_BOOKING' => _pick(
        language,
        tk: 'Täze ýazgy haýyşy aldyňyz.',
        ru: 'Вы получили новый запрос на запись.',
        en: 'You received a new booking request.',
      ),
      'REVIEW_RECEIVED' => _pick(
        language,
        tk: 'Täze teswir aldyňyz.',
        ru: 'Вы получили новый отзыв.',
        en: 'You received a new review.',
      ),
      _ => notification.message,
    };
  }

  static String _pick(
    String language, {
    required String tk,
    required String ru,
    required String en,
  }) {
    return switch (language) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }
}
