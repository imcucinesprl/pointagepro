import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';

class MessageInput extends StatefulWidget {
  final Future<bool> Function(String message) onSend;
  final VoidCallback? onAttachmentPressed;
  final bool isSending;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onAttachmentPressed,
    this.isSending = false,
  });

  @override
  State<MessageInput> createState() =>
      _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller =
      TextEditingController();

  final FocusNode _focusNode = FocusNode();

  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;

    if (hasText == _hasText) {
      return;
    }

    setState(() {
      _hasText = hasText;
    });
  }

  Future<void> _send() async {
    final message = _controller.text.trim();

    if (message.isEmpty || widget.isSending) {
      return;
    }

    final sent = await widget.onSend(message);

    if (!mounted || !sent) {
      return;
    }

    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final background =
        CupertinoColors.systemBackground
            .resolveFrom(context);

    final borderColor =
        CupertinoColors.separator
            .resolveFrom(context)
            .withOpacity(0.45);

    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8 + MediaQuery.viewInsetsOf(context).bottom * 0,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(6),
            minSize: 38,
            onPressed: widget.isSending
                ? null
                : widget.onAttachmentPressed,
            child: const Icon(
              CupertinoIcons.add_circled_solid,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 42,
                maxHeight: 130,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(21),
              ),
              child: CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction:
                    TextInputAction.newline,
                keyboardType:
                    TextInputType.multiline,
                placeholder: 'Écrire un message…',
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                decoration: null,
                enabled: !widget.isSending,
              ),
            ),
          ),
          const SizedBox(width: 7),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 42,
            onPressed:
                !_hasText || widget.isSending
                    ? null
                    : _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _hasText
                    ? AppColors.primary
                    : CupertinoColors.systemGrey4
                        .resolveFrom(context),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: widget.isSending
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : const Icon(
                      CupertinoIcons.arrow_up,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}