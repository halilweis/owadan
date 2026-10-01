import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import 'models/app_notification.dart';
import 'notification_repository.dart';
import 'notification_text.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    required this.repository,
    required this.onOpenBookings,
    required this.onUnreadCountChanged,
    super.key,
  });

  final NotificationRepository repository;
  final VoidCallback onOpenBookings;
  final ValueChanged<int> onUnreadCountChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  bool _markingAll = false;
  String? _error;
  List<AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifications = await widget.repository.fetchNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
      });

      widget.onUnreadCountChanged(
        notifications.where((notification) => !notification.read).length,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read) {
      _openNotification(notification);
      return;
    }

    try {
      await widget.repository.markRead(notification.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map(
              (item) =>
                  item.id == notification.id ? item.copyWith(read: true) : item,
            )
            .toList();
      });

      widget.onUnreadCountChanged(
        _notifications.where((item) => !item.read).length,
      );

      _openNotification(notification.copyWith(read: true));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll ||
        _notifications.every((notification) => notification.read)) {
      return;
    }

    setState(() {
      _markingAll = true;
    });

    try {
      await widget.repository.markAllRead();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map((notification) => notification.copyWith(read: true))
            .toList();
      });

      widget.onUnreadCountChanged(0);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _markingAll = false;
        });
      }
    }
  }

  void _openNotification(AppNotification notification) {
    if (notification.bookingId == null) {
      return;
    }

    Navigator.of(context).pop();
    widget.onOpenBookings();
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;

    final markAllLabel = switch (language) {
      'tk' => 'Ählisini okalan et',
      'ru' => 'Прочитать все',
      _ => 'Mark all read',
    };

    final emptyLabel = switch (language) {
      'tk' => 'Häzirlikçe bildiriş ýok.',
      'ru' => 'Уведомлений пока нет.',
      _ => 'No notifications yet.',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.t('notifications')),
        actions: [
          if (_notifications.any((notification) => !notification.read))
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: Text(markAllLabel),
            ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(emptyLabel)),
    );
  }

  Widget _buildBody(String emptyLabel) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: Text(context.l10n.t('tryAgain')),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 160),
          const Icon(Icons.notifications_none, size: 60),
          const SizedBox(height: 16),
          Text(
            emptyLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = _notifications[index];

        return _NotificationTile(
          notification: notification,
          onTap: () => _markRead(notification),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = NotificationText.message(context, notification);

    return Card(
      color: notification.read ? null : scheme.primaryContainer.withAlpha(80),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Icon(_icon(notification.type))),
        title: Text(
          NotificationText.title(context, notification),
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.w600 : FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null && message.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message),
            ],
            const SizedBox(height: 6),
            Text(
              _dateTime(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.read
            ? const Icon(Icons.chevron_right)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  IconData _icon(String type) {
    return switch (type) {
      'BOOKING_CONFIRMED' => Icons.event_available,
      'BOOKING_DECLINED' => Icons.event_busy,
      'BOOKING_CANCELLED' => Icons.event_busy,
      'BOOKING_COMPLETED' => Icons.task_alt,
      'BOOKING_NO_SHOW' => Icons.person_off_outlined,
      'NEW_BOOKING' => Icons.event_note,
      'REVIEW_RECEIVED' => Icons.star_outline,
      _ => Icons.notifications_outlined,
    };
  }

  String _dateTime(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}
