import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import 'dashboard_date_utils.dart';

class WeeklyRhythmPanel extends StatelessWidget {
  final bool compact;

  const WeeklyRhythmPanel({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xE8FFFFFF),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F102F4E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Weekly Rhythm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lora(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Today highlighted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              'Weekly Rhythm',
              style: GoogleFonts.lora(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'A quiet seven-day rhythm with today clearly marked.',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
          SizedBox(height: compact ? 6 : 10),
          DevotionalWeekStrip(compact: compact),
        ],
      ),
    );
  }
}

class DevotionalWeekStrip extends StatelessWidget {
  final bool compact;

  const DevotionalWeekStrip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final today = manilaNow();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final sunday = dateOnly.subtract(Duration(days: today.weekday % 7));

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 4.0 : 5.0;
        final boundedWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 324.0;
        final rawChipWidth = (boundedWidth - spacing * 6) / 7;
        final chipWidth = compact
            ? rawChipWidth.clamp(32.0, 46.0).toDouble()
            : rawChipWidth.clamp(38.0, 54.0).toDouble();

        return SizedBox(
          height: compact ? 52 : 72,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(13, (index) {
                if (index.isOdd) return SizedBox(width: spacing);

                final dayIndex = index ~/ 2;
                final date = sunday.add(Duration(days: dayIndex));
                return _WeekDayChip(
                  width: chipWidth,
                  date: date,
                  isToday: isSameCalendarDay(date, today),
                  compact: compact,
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  final double width;
  final DateTime date;
  final bool isToday;
  final bool compact;

  const _WeekDayChip({
    required this.width,
    required this.date,
    required this.isToday,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isToday
          ? 'Today, ${fullManilaDate(date)}'
          : '${fullManilaDate(date)}, devotional calendar date',
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.navy
              : const Color(0xDFFFFFFF),
          borderRadius: BorderRadius.circular(compact ? 14 : 17),
          border: Border.all(
            color: isToday
                ? AppColors.navy
                : AppColors.border,
          ),
          boxShadow: isToday
              ? const [
                  BoxShadow(
                    color: Color(0x33102F4E),
                    blurRadius: 13,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shortWeekdayNames[date.weekday - 1],
              style: TextStyle(
                color: isToday ? AppColors.white : AppColors.mutedText,
                fontSize: compact ? 7.5 : 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 3 : 5),
            Text(
              '${date.day}',
              style: TextStyle(
                color: isToday ? AppColors.white : AppColors.navy,
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
