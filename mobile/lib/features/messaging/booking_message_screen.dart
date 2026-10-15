import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'models/booking_message.dart';

class BookingMessageScreen extends StatefulWidget {
  const BookingMessageScreen({
    required this.bookingId,
    required this.title,
    required this.currentRole,
    required this.fetchMessages,
    required this.sendMessage,
    super.key,
  });

  final String bookingId;
  final String title;
  final String currentRole;
  final Future<List<BookingMessage>> Function(String bookingId) fetchMessages;
  final Future<BookingMessage> Function(String bookingId, String body)
  sendMessage;

  @override
  State<BookingMessageScreen> createState() => _BookingMessageScreenState();
}

class _BookingMessageScreenState extends State<BookingMessageScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<BookingMessage> _messages = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await widget.fetchMessages(widget.bookingId);

      if (!mounted) return;

      setState(() {
        _messages = messages;
      });

      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final message = await widget.sendMessage(widget.bookingId, text);

      if (!mounted) return;

      _controller.clear();

      setState(() {
        _messages = [..._messages, message];
      });

      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 52),
                          const SizedBox(height: 14),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: Text(
                              _text(
                                en: 'Try again',
                                ru: 'Повторить',
                                tk: 'Gaýtadan synanyş',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _text(
                          en: 'No messages yet. Send a message about this appointment.',
                          ru: 'Сообщений пока нет. Напишите по поводу этой записи.',
                          tk: 'Entäk habar ýok. Bu ýazgy barada habar iberiň.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final mine = message.senderRole == widget.currentRole;

                      return _MessageBubble(message: message, mine: mine);
                    },
                  ),
          ),
          if (_error != null && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: _text(
                          en: 'Message about this appointment',
                          ru: 'Сообщение по этой записи',
                          tk: 'Bu ýazgy barada habar',
                        ),
                        prefixIcon: const Icon(Icons.chat_bubble_outline),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: _text(en: 'Send', ru: 'Отправить', tk: 'Iber'),
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final BookingMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final local = message.createdAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(message.body),
            const SizedBox(height: 4),
            Text(time, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
