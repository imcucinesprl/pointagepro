import 'package:flutter/cupertino.dart';

class ChatDaySeparator extends StatelessWidget {
  final DateTime? date;

  const ChatDaySeparator({
    super.key,
    required this.date,
  });

  String _label() {
    if (date == null) {
      return '';
    }

    final localDate = date!.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Aujourd’hui';
    }

    if (difference == 1) {
      return 'Hier';
    }

    const weekdays = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];

    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    final weekday = weekdays[localDate.weekday - 1];
    final month = months[localDate.month - 1];

    if (localDate.year == now.year) {
      return '$weekday ${localDate.day} $month';
    }

    return '$weekday ${localDate.day} '
        '$month ${localDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();

    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5
                .resolveFrom(context)
                .withOpacity(0.85),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel
                  .resolveFrom(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}