import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../models/employee_week_summary.dart';
import '../../core/services/employee_week_summary_service.dart';

class EmployeeWeekSummaryScreen extends StatefulWidget {
  final int userId;
  final int companyId;

  const EmployeeWeekSummaryScreen({
    super.key,
    required this.userId,
    required this.companyId,
  });

  @override
  State<EmployeeWeekSummaryScreen> createState() =>
      _EmployeeWeekSummaryScreenState();
}

class _EmployeeWeekSummaryScreenState extends State<EmployeeWeekSummaryScreen> {
  late Future<List<EmployeeWeekDaySummary>> _future;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _getMonday(DateTime.now());
    _load();
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _load() {
    _future = EmployeeWeekSummaryService.fetchWeekSummary(
      userId: widget.userId,
      companyId: widget.companyId,
      weekStart: _formatDateForApi(_weekStart),
    );
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _load();
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _load();
    });
  }

  String _formatSeconds(int seconds) {
    final negative = seconds < 0;
    final abs = seconds.abs();
    final hours = abs ~/ 3600;
    final minutes = (abs % 3600) ~/ 60;

    if (hours == 0 && minutes == 0) return '0 min';

    final sign = negative ? '-' : '+';
    return '$sign${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    return _formatSeconds(seconds).replaceFirst('+', '');
  }

  String _shortTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '--';
    if (dateTime.length >= 16) return dateTime.substring(11, 16);
    return dateTime;
  }

  Color _differenceColor(int seconds) {
    if (seconds > 0) return AppColors.success;
    if (seconds < 0) return AppColors.danger;
    return AppColors.subtitle;
  }

  String _formatDisplayDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday).inDays;
    final week = (diff ~/ 7) + 1;
    return week.toString();
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Résumé semaine'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _WeekSelector(
              weekStart: _weekStart,
              weekEnd: weekEnd,
              weekNumber: _weekNumber(_weekStart),
              onPrevious: _previousWeek,
              onNext: _nextWeek,
              formatDate: _formatDisplayDate,
            ),
            Expanded(
              child: FutureBuilder<List<EmployeeWeekDaySummary>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    );
                  }

                  final days = snapshot.data ?? [];

                  if (days.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun planning trouvé pour cette semaine',
                        style: TextStyle(color: AppColors.subtitle),
                      ),
                    );
                  }

                  final totalPlanned =
                      days.fold<int>(0, (sum, d) => sum + d.plannedSeconds);
                  final totalWorked =
                      days.fold<int>(0, (sum, d) => sum + d.workedSeconds);
                  final totalDifference = totalWorked - totalPlanned;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    children: [
                      _TotalGradientCard(
                        planned: _formatDuration(totalPlanned),
                        worked: _formatDuration(totalWorked),
                        difference: _formatSeconds(totalDifference),
                        differenceColor: _differenceColor(totalDifference),
                      ),
                      const SizedBox(height: 18),
                      ...days.map(
                        (day) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DayCard(
                            day: day,
                            shortTime: _shortTime,
                            formatSeconds: _formatSeconds,
                            formatDuration: _formatDuration,
                            differenceColor: _differenceColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final String weekNumber;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String Function(DateTime) formatDate;

  const _WeekSelector({
    required this.weekStart,
    required this.weekEnd,
    required this.weekNumber,
    required this.onPrevious,
    required this.onNext,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: CupertinoIcons.chevron_left,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.calendar,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatDate(weekStart)} - ${formatDate(weekEnd)}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Semaine $weekNumber',
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: CupertinoIcons.chevron_right,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(0.16),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}

class _TotalGradientCard extends StatelessWidget {
  final String planned;
  final String worked;
  final String difference;
  final Color differenceColor;

  const _TotalGradientCard({
    required this.planned,
    required this.worked,
    required this.difference,
    required this.differenceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF7C4DFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Total semaine',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.clock,
                  color: CupertinoColors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _TotalItem(
                  label: 'Prévu',
                  value: planned,
                ),
              ),
              _VerticalWhiteDivider(),
              Expanded(
                child: _TotalItem(
                  label: 'Réel',
                  value: worked,
                ),
              ),
              _VerticalWhiteDivider(),
              Expanded(
                child: _TotalItem(
                  label: 'Diff.',
                  value: difference,
                  valueColor: differenceColor == AppColors.danger
                      ? const Color(0xFFFFC1CC)
                      : const Color(0xFFC8FFD8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.82),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor ?? CupertinoColors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _VerticalWhiteDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: CupertinoColors.white.withOpacity(0.22),
    );
  }
}

class _DayCard extends StatelessWidget {
  final EmployeeWeekDaySummary day;
  final String Function(String?) shortTime;
  final String Function(int) formatSeconds;
  final String Function(int) formatDuration;
  final Color Function(int) differenceColor;

  const _DayCard({
    required this.day,
    required this.shortTime,
    required this.formatSeconds,
    required this.formatDuration,
    required this.differenceColor,
  });

  bool get isOffDay {
    final status = day.status.toLowerCase();
    return status == 'repos' ||
        status == 'conge' ||
        status == 'congé' ||
        status == 'holiday';
  }

  Color get accentColor {
    final status = day.status.toLowerCase();

    if (status == 'conge' || status == 'congé') {
      return const Color(0xFF2F80ED);
    }

    if (status == 'repos') {
      return const Color(0xFF7E57C2);
    }

    if (day.differenceSeconds < 0) {
      return AppColors.danger;
    }

    if (day.differenceSeconds > 0) {
      return AppColors.success;
    }

    return AppColors.success;
  }

  IconData get statusIcon {
    final status = day.status.toLowerCase();

    if (status == 'conge' || status == 'congé') {
      return CupertinoIcons.briefcase_fill;
    }

    if (status == 'repos') {
      return CupertinoIcons.bed_double_fill;
    }

    if (day.differenceSeconds < 0) {
      return CupertinoIcons.exclamationmark_circle_fill;
    }

    return CupertinoIcons.check_mark_circled_solid;
  }

  @override
  Widget build(BuildContext context) {
    final planned = isOffDay
        ? _statusLabel(day.status)
        : '${day.plannedStart ?? '--'} - ${day.plannedEnd ?? '--'}';

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _shortDay(day.dayOfWeek),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dayNumber(day.date),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _monthShort(day.date),
                  style: TextStyle(
                    color: accentColor.withOpacity(0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(statusIcon, color: accentColor, size: 24),
              ],
            ),
          ),
          Expanded(
            child: isOffDay
                ? _OffDayContent(
                    status: _statusLabel(day.status),
                    accentColor: accentColor,
                    icon: statusIcon,
                  )
                : _WorkDayContent(
                    day: day,
                    accentColor: accentColor,
                    shortTime: shortTime,
                    formatSeconds: formatSeconds,
                    formatDuration: formatDuration,
                    differenceColor: differenceColor,
                    planned: planned,
                  ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'conge' || s == 'congé') return 'Congé';
    if (s == 'repos') return 'Repos';
    return status;
  }

  String _shortDay(String value) {
    final v = value.toUpperCase();
    if (v.length <= 3) return v;
    return '${v.substring(0, 3)}.';
  }

  String _dayNumber(String date) {
    if (date.length >= 10) return date.substring(8, 10);
    return '--';
  }

  String _monthShort(String date) {
    if (date.length < 7) return '';
    final month = int.tryParse(date.substring(5, 7)) ?? 0;
    const months = [
      '',
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sep',
      'oct',
      'nov',
      'déc',
    ];
    if (month < 1 || month > 12) return '';
    return months[month];
  }
}

class _WorkDayContent extends StatelessWidget {
  final EmployeeWeekDaySummary day;
  final Color accentColor;
  final String Function(String?) shortTime;
  final String Function(int) formatSeconds;
  final String Function(int) formatDuration;
  final Color Function(int) differenceColor;
  final String planned;

  const _WorkDayContent({
    required this.day,
    required this.accentColor,
    required this.shortTime,
    required this.formatSeconds,
    required this.formatDuration,
    required this.differenceColor,
    required this.planned,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Prévu',
                  value: planned,
                  icon: CupertinoIcons.clock,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Pointage',
                  value: '${shortTime(day.clockIn)} - ${shortTime(day.clockOut)}',
                  icon: CupertinoIcons.time,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Presté',
                  value: formatDuration(day.workedSeconds),
                  icon: CupertinoIcons.stopwatch,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Pause',
                  value: formatDuration(day.pauseSeconds),
                  icon: CupertinoIcons.pause_circle_fill,
                  color: const Color(0xFFFF8A00),
                ),
              ),
              Expanded(
                child: _DiffPill(
                  value: formatSeconds(day.differenceSeconds),
                  color: differenceColor(day.differenceSeconds),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OffDayContent extends StatelessWidget {
  final String status;
  final Color accentColor;
  final IconData icon;

  const _OffDayContent({
    required this.status,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                color: accentColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(icon, color: accentColor, size: 34),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.subtitle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Icon(icon, color: color, size: 17),
      ],
    );
  }
}

class _DiffPill extends StatelessWidget {
  final String value;
  final Color color;

  const _DiffPill({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Diff.',
            style: TextStyle(
              color: AppColors.subtitle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}