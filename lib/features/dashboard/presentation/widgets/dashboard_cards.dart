import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../devotional/domain/models/assigned_devotional.dart';
import '../../../devotional/domain/models/devotional_participation.dart';
import '../../../devotional/domain/repositories/devotional_repository.dart';
import 'dashboard_date_utils.dart';

class TodayDevotionalCard extends StatefulWidget {
  final bool compact;
  final Future<void> Function()? onOpen;
  final DevotionalRepository repository;

  const TodayDevotionalCard({
    super.key,
    required this.compact,
    required this.onOpen,
    required this.repository,
  });

  @override
  State<TodayDevotionalCard> createState() => _TodayDevotionalCardState();
}

class _TodayDevotionalCardState extends State<TodayDevotionalCard> {
  AssignedDevotional? _assignment;
  DevotionalReadingState? _participation;
  DateTime? _scheduledDate;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final today = await widget.repository.getManilaToday();
      final assignment = await widget.repository.getAssignmentForDate(
        manilaDate: today,
      );
      DevotionalReadingState? participation;
      if (assignment != null) {
        try {
          participation = await widget.repository.getReadingState(
            scheduledDate: assignment.assignment.scheduledDate,
          );
        } catch (_) {
          // Module 2C may not be migrated yet. Assignment display remains valid.
        }
      }
      if (!mounted) return;
      setState(() {
        _scheduledDate = assignment?.assignment.scheduledDate ?? today;
        _assignment = assignment;
        _participation = participation;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assignment = null;
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final today = manilaNow();
    final assignment = _assignment;
    final participation = _participation;
    final engagementLabel = switch (participation?.level) {
      DevotionalParticipationLevel.reflected => 'Reflected · Continue your time in the Word.',
      DevotionalParticipationLevel.read => 'Read · Reflection remains optional.',
      _ => 'Open to read; reflection is optional.',
    };
    final title = _loading
        ? 'Preparing today\'s devotion'
        : assignment?.content.title ?? 'Assignment unavailable';
    final subtitle = _loading
        ? 'Checking the official Manila-date assignment...'
        : _failed
            ? 'The assignment could not be loaded. Try again.'
            : assignment == null
                ? 'There is no published devotional assignment for today.'
                : '${assignment.content.scriptureReference} - $engagementLabel';
    final openAction = assignment == null ? null : widget.onOpen;
    final textWidth = compact
        ? (MediaQuery.sizeOf(context).width * 0.48)
              .clamp(80.0, 168.0)
              .toDouble()
        : 320.0;

    return Container(
      height: compact ? 210 : 360,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFF277CC4)],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(compact ? 25 : 30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x381162B1),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: compact ? 18 : 38,
            top: compact ? 58 : 96,
            child: _DevotionalIcon(compact: compact),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x24FFFFFF),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text(
                        "TODAY'S DEVOTION",
                        style: TextStyle(
                          color: Color(0xFFF2F7FC),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      shortManilaDate(_scheduledDate ?? today),
                      style: const TextStyle(
                        color: Color(0xFFDDEBFA),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: textWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          color: AppColors.white,
                          fontSize: compact ? 22 : 34,
                          height: 1.08,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: compact ? 5 : 10),
                      Text(
                        subtitle,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFE0ECF8),
                          fontSize: compact ? 10.5 : 13,
                          height: compact ? 1.3 : 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 7 : 20),
                FilledButton.icon(
                  onPressed: _failed
                      ? _load
                      : openAction == null
                          ? null
                          : () async {
                              await openAction();
                              if (mounted) await _load();
                            },
                  icon: Icon(
                    _failed
                        ? Icons.refresh_rounded
                        : openAction == null
                            ? Icons.menu_book_outlined
                            : Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                  label: Text(
                    _loading
                        ? 'Loading assignment'
                        : _failed
                            ? 'Retry'
                            : openAction == null
                                ? 'Reading unavailable'
                                : 'Open devotion',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: const Color(0x2EFFFFFF),
                    disabledForegroundColor: const Color(0xFFD5E5F4),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 11 : 17,
                      vertical: compact ? 7 : 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DevotionalIcon extends StatelessWidget {
  final bool compact;

  const _DevotionalIcon({required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 66.0 : 112.0;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0x38FFFFFF), Color(0x12FFFFFF)],
            ),
            border: Border.all(color: const Color(0x35FFFFFF)),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: AppColors.white,
            size: size * 0.46,
          ),
        ),
      ),
    );
  }
}

class JourneyMosaic extends StatelessWidget {
  final bool compact;
  final VoidCallback onCalendar;
  final VoidCallback onProgress;
  final VoidCallback onHistory;

  const JourneyMosaic({
    super.key,
    this.compact = true,
    required this.onCalendar,
    required this.onProgress,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final today = manilaNow();

    if (!compact) {
      return SizedBox(
        height: 144,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _JourneyCard(
                background: AppColors.goldSoft,
                foreground: AppColors.navy,
                onTap: onCalendar,
                child: _DesktopJourneyContent(
                  eyebrow: 'THIS MONTH',
                  title: 'Calendar',
                  status:
                      '${longMonthNames[today.month - 1]} ${today.year} · Coming soon',
                  icon: Icons.calendar_month_outlined,
                  foreground: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _JourneyCard(
                background: AppColors.skySoft,
                foreground: AppColors.primaryDark,
                onTap: onProgress,
                child: const _DesktopJourneyContent(
                  eyebrow: 'OVERVIEW',
                  title: 'Progress',
                  status: 'Awaiting tracking service',
                  icon: Icons.insights_outlined,
                  foreground: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _JourneyCard(
                background: AppColors.lavender,
                foreground: AppColors.lavenderInk,
                onTap: onHistory,
                child: const _DesktopJourneyContent(
                  eyebrow: 'PAST READINGS',
                  title: 'History',
                  status: 'Not connected yet',
                  icon: Icons.history_rounded,
                  foreground: AppColors.lavenderInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 264,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _JourneyCard(
              background: AppColors.goldSoft,
              foreground: AppColors.navy,
              onTap: onCalendar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _JourneyPill(label: 'THIS MONTH'),
                  const SizedBox(height: 20),
                  Text(
                    'Calendar',
                    style: GoogleFonts.lora(
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${longMonthNames[today.month - 1]} ${today.year}',
                    style: const TextStyle(
                      color: Color(0xB3102F4E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Text(
                          'Calendar page coming soon',
                          style: TextStyle(
                            color: Color(0xB3102F4E),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0x55FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.navy,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _JourneyCard(
                    background: AppColors.skySoft,
                    foreground: AppColors.navy,
                    onTap: onProgress,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            _JourneyPill(label: 'OVERVIEW'),
                            Spacer(),
                            Icon(
                              Icons.insights_outlined,
                              color: AppColors.primaryDark,
                              size: 21,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Progress',
                          style: GoogleFonts.lora(
                            color: AppColors.navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Awaiting tracking',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: _JourneyCard(
                    background: AppColors.lavender,
                    foreground: AppColors.lavenderInk,
                    onTap: onHistory,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: AppColors.lavenderInk,
                          size: 23,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History',
                                style: GoogleFonts.lora(
                                  color: AppColors.lavenderInk,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Not connected',
                                style: TextStyle(
                                  color: AppColors.lavenderInk,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopJourneyContent extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String status;
  final IconData icon;
  final Color foreground;

  const _DesktopJourneyContent({
    required this.eyebrow,
    required this.title,
    required this.status,
    required this.icon,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _JourneyPill(label: eyebrow),
            const Spacer(),
            Icon(icon, color: foreground, size: 23),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: GoogleFonts.lora(
            color: foreground,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground.withAlpha(185),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final Widget child;

  const _JourneyCard({
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: foreground.withAlpha(24)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _JourneyPill extends StatelessWidget {
  final String label;

  const _JourneyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x55FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class ProgressMosaic extends StatelessWidget {
  final bool compact;

  const ProgressMosaic({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          const _ProgressCard(
            title: 'Overall progress',
            status: 'Awaiting tracking',
            icon: Icons.donut_large_rounded,
            background: AppColors.sage,
            foreground: AppColors.sageInk,
            expanded: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _ProgressCard(
                  title: 'Current streak',
                  status: 'Not available',
                  icon: Icons.local_fire_department_outlined,
                  background: AppColors.lavender,
                  foreground: AppColors.lavenderInk,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ProgressCard(
                  title: 'Catch-up',
                  status: 'Awaiting tracking',
                  icon: Icons.replay_rounded,
                  background: AppColors.peach,
                  foreground: AppColors.peachInk,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: const [
        _ProgressCard(
          title: 'Overall progress',
          status: 'Awaiting tracking',
          icon: Icons.donut_large_rounded,
          background: AppColors.sage,
          foreground: AppColors.sageInk,
          expanded: true,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProgressCard(
                title: 'Current streak',
                status: 'Not available',
                icon: Icons.local_fire_department_outlined,
                background: AppColors.lavender,
                foreground: AppColors.lavenderInk,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _ProgressCard(
                title: 'Catch-up',
                status: 'Awaiting tracking',
                icon: Icons.replay_rounded,
                background: AppColors.peach,
                foreground: AppColors.peachInk,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool expanded;

  const _ProgressCard({
    required this.title,
    required this.status,
    required this.icon,
    required this.background,
    required this.foreground,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: expanded ? 116 : 126,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(17),
      child: expanded
          ? Row(
              children: [
                _metricIcon(),
                const SizedBox(width: 13),
                Expanded(child: _metricText()),
                Text(
                  '—',
                  semanticsLabel: 'No progress data available',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metricIcon(),
                const Spacer(),
                _metricText(),
              ],
            ),
    );
  }

  Widget _metricIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: foreground, size: 20),
    );
  }

  Widget _metricText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: foreground.withAlpha(190), fontSize: 10),
        ),
      ],
    );
  }
}
