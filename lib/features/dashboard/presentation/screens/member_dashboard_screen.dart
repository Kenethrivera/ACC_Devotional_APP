import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../auth/domain/models/auth_user.dart';

class MemberDashboardScreen extends StatelessWidget {
  final AuthUser user;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenDevotional;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenHistory;

  const MemberDashboardScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    this.onOpenDevotional,
    this.onOpenNotifications,
    this.onOpenHistory,
  });

  static const _wideBreakpoint = 900.0;
  static const _compactBreakpoint = 620.0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          const Positioned.fill(child: _SanctuaryBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < _compactBreakpoint;
                final wide = constraints.maxWidth >= _wideBreakpoint;
                final horizontalPadding = compact ? 18.0 : 32.0;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              compact ? 12 : 20,
                              horizontalPadding,
                              42,
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 520),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0, end: 1),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 12 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DashboardHeader(
                                    email: user.email,
                                    compact: compact,
                                    onNotifications: onOpenNotifications,
                                    onAccount: () =>
                                        _showAccountPanel(context),
                                  ),
                                  SizedBox(height: compact ? 30 : 46),
                                  _WelcomeBlock(
                                    email: user.email,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 24 : 30),
                                  if (wide)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: _TodayDevotionalCard(
                                            onOpen: onOpenDevotional,
                                          ),
                                        ),
                                        const SizedBox(width: 22),
                                        const Expanded(
                                          flex: 4,
                                          child: _ProgressSummary(),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _TodayDevotionalCard(
                                      onOpen: onOpenDevotional,
                                    ),
                                    const SizedBox(height: 18),
                                    const _ProgressSummary(),
                                  ],
                                  SizedBox(height: compact ? 26 : 34),
                                  const _SectionHeading(
                                    eyebrow: 'YOUR RHYTHM',
                                    title: 'This week',
                                    description:
                                        'Monday through Friday devotional progress',
                                  ),
                                  const SizedBox(height: 16),
                                  const _WeeklyProgressCard(),
                                  SizedBox(height: compact ? 26 : 34),
                                  const _SectionHeading(
                                    eyebrow: 'STAY CONNECTED',
                                    title: 'Your spaces',
                                    description:
                                        'Return to the parts of your journey that matter',
                                  ),
                                  const SizedBox(height: 16),
                                  _QuickAccessGrid(
                                    compact: compact,
                                    onNotifications: onOpenNotifications,
                                    onHistory: onOpenHistory,
                                    onAccount: () =>
                                        _showAccountPanel(context),
                                    onUnavailable: (feature) =>
                                        _showUnavailable(context, feature),
                                  ),
                                  const SizedBox(height: 34),
                                  const _DashboardFooter(),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  void _showUnavailable(BuildContext context, String feature) {
    AppFeedback.show(
      context,
      message: '$feature will be available when its service is connected.',
      type: AppMessageType.info,
    );
  }

  Future<void> _showAccountPanel(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33091C35),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const _RoundIcon(
                        icon: Icons.person_outline_rounded,
                        size: 46,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your account',
                              style: GoogleFonts.lora(
                                color: AppColors.navy,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? 'Authenticated member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF5D6D7E),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close account panel',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _UnavailableNotice(
                    title: 'Account settings are not connected yet',
                    message:
                        'Profile and preference controls will appear here '
                        'when account settings are implemented.',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await onSignOut();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String? email;
  final bool compact;
  final VoidCallback? onNotifications;
  final VoidCallback onAccount;

  const _DashboardHeader({
    required this.email,
    required this.compact,
    required this.onNotifications,
    required this.onAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x29173B70),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            color: AppColors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POWER OF 4+',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.7,
                ),
              ),
              if (!compact)
                const Text(
                  'The Fresh Page',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: onNotifications == null
              ? 'Notification inbox unavailable'
              : 'Open notification inbox',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.navy,
        ),
        const SizedBox(width: 2),
        Semantics(
          button: true,
          label: 'Open account options for ${email ?? 'member'}',
          child: InkWell(
            onTap: onAccount,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: _RoundIcon(
                icon: Icons.person_outline_rounded,
                size: compact ? 38 : 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeBlock extends StatelessWidget {
  final String? email;
  final bool compact;

  const _WelcomeBlock({required this.email, required this.compact});

  String get _accountName {
    final address = email?.trim();
    if (address == null || address.isEmpty || !address.contains('@')) {
      return 'friend';
    }

    final localPart = address.split('@').first;
    final firstPart = localPart.split(RegExp(r'[._-]')).first.trim();
    if (firstPart.isEmpty) return 'friend';
    return '${firstPart[0].toUpperCase()}${firstPart.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greetingForManila(),
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome, $_accountName',
          style: GoogleFonts.lora(
            color: AppColors.navy,
            fontSize: compact ? 34 : 46,
            height: 1.08,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Make space for the Word, one fresh page at a time.',
          style: TextStyle(
            color: const Color(0xFF5D6D7E),
            fontSize: compact ? 14 : 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TodayDevotionalCard extends StatelessWidget {
  final VoidCallback? onOpen;

  const _TodayDevotionalCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final today = _manilaNow();
    final weekday = _weekdayNames[today.weekday - 1];
    final isScheduledDay = today.weekday <= DateTime.friday;

    return Container(
      height: 330,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173B70), Color(0xFF235794)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30173B70),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -35,
            top: -45,
            child: _DecorativeHalo(size: 160),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
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
                      "TODAY'S DEVOTIONAL",
                      style: TextStyle(
                        color: Color(0xFFEAF3FC),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.25,
                      ),
                    ),
                  ),
                  Text(
                    '$weekday  |  ${_monthNames[today.month - 1]} ${today.day}',
                    style: const TextStyle(
                      color: Color(0xFFD4E3F5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                isScheduledDay
                    ? Icons.menu_book_rounded
                    : Icons.wb_sunny_outlined,
                color: AppColors.gold,
                size: 34,
              ),
              const SizedBox(height: 17),
              Text(
                isScheduledDay
                    ? 'Assignment unavailable'
                    : 'A weekend pause',
                style: GoogleFonts.lora(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isScheduledDay
                    ? 'Today\'s devotional section will appear here once the '
                          'devotional service is connected.'
                    : 'The shared devotional rhythm runs Monday through Friday. '
                          'Your next assignment will appear when available.',
                style: const TextStyle(
                  color: Color(0xFFDCE7F3),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onOpen,
                icon: Icon(
                  onOpen == null
                      ? Icons.lock_outline_rounded
                      : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(
                  onOpen == null ? 'Reading unavailable' : 'Open devotional',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor: const Color(0x26FFFFFF),
                  disabledForegroundColor: const Color(0xFFCAD9EA),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary();

  @override
  Widget build(BuildContext context) {
    return _SanctuaryCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RoundIcon(
                icon: Icons.insights_outlined,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Progress at a glance',
                  style: GoogleFonts.lora(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _MetricRow(
            icon: Icons.donut_large_rounded,
            title: 'Overall progress',
            status: 'Awaiting tracking',
          ),
          const Divider(height: 25, color: AppColors.border),
          const _MetricRow(
            icon: Icons.local_fire_department_outlined,
            title: 'Current streak',
            status: 'Not available yet',
          ),
          const Divider(height: 25, color: AppColors.border),
          const _MetricRow(
            icon: Icons.replay_rounded,
            title: 'Catch-up devotions',
            status: 'Awaiting tracking',
          ),
          const SizedBox(height: 18),
          const _UnavailableNotice(
            title: 'Progress tracking is not connected',
            message:
                'Your real completion activity will replace these placeholders '
                'when the tracking service is implemented.',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;

  const _MetricRow({
    required this.icon,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 21),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'N/A',
          semanticsLabel: 'No data available',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard();

  @override
  Widget build(BuildContext context) {
    final currentWeekday = _manilaNow().weekday;

    return _SanctuaryCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 650;
          final itemWidth = narrow
              ? (constraints.maxWidth - 10) / 2
              : (constraints.maxWidth - 40) / 5;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(5, (index) {
              final weekday = index + 1;
              return SizedBox(
                width: itemWidth,
                child: _WeekdayTile(
                  day: _shortWeekdayNames[index],
                  isToday: weekday == currentWeekday,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _WeekdayTile extends StatelessWidget {
  final String day;
  final bool isToday;

  const _WeekdayTile({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isToday ? AppColors.iceBlue : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? const Color(0xFFB8D3F1) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                day,
                style: TextStyle(
                  color: isToday ? AppColors.blue : AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (isToday)
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const Spacer(),
          const Text(
            'N/A',
            semanticsLabel: 'Progress unavailable',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Awaiting data',
            style: TextStyle(color: Color(0xFF718096), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final bool compact;
  final VoidCallback? onNotifications;
  final VoidCallback? onHistory;
  final VoidCallback onAccount;
  final ValueChanged<String> onUnavailable;

  const _QuickAccessGrid({
    required this.compact,
    required this.onNotifications,
    required this.onHistory,
    required this.onAccount,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        subtitle: onNotifications == null
            ? 'Inbox not connected'
            : 'Open your inbox',
        onTap: onNotifications ?? () => onUnavailable('Notification inbox'),
        unavailable: onNotifications == null,
      ),
      _QuickAccessItem(
        icon: Icons.history_rounded,
        title: 'Devotional history',
        subtitle: onHistory == null
            ? 'History not connected'
            : 'Review past readings',
        onTap: onHistory ?? () => onUnavailable('Devotional history'),
        unavailable: onHistory == null,
      ),
      _QuickAccessItem(
        icon: Icons.manage_accounts_outlined,
        title: 'Account',
        subtitle: 'View account and log out',
        onTap: onAccount,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact ? 1 : 3;
        const gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map((item) => SizedBox(width: width, child: item))
              .toList(),
        );
      },
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool unavailable;

  const _QuickAccessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.unavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unavailable ? '$title, currently unavailable' : title,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            minHeight: 118,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _RoundIcon(icon: icon, size: 44),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  unavailable
                      ? Icons.lock_outline_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: unavailable
                      ? const Color(0xFF9AA7B4)
                      : AppColors.blue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 18,
      runSpacing: 7,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.lora(
                color: AppColors.navy,
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            description,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SanctuaryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SanctuaryCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFAFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11173B70),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _RoundIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.iceBlue,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: AppColors.blue, size: size * 0.48),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  final String title;
  final String message;

  const _UnavailableNotice({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE9DFC9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF9A7437),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF6C727A),
                    fontSize: 10,
                    height: 1.4,
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

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(width: 42, height: 1, color: AppColors.gold),
          const SizedBox(height: 12),
          const Text(
            'ADELINA CHRISTIAN CHURCH',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF718096),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _SanctuaryBackground extends StatelessWidget {
  const _SanctuaryBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F7FA), AppColors.ivory, Color(0xFFF8F6F0)],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(right: -100, top: -90, child: _DecorativeHalo(size: 280)),
          Positioned(left: -120, top: 430, child: _DecorativeHalo(size: 240)),
        ],
      ),
    );
  }
}

class _DecorativeHalo extends StatelessWidget {
  final double size;

  const _DecorativeHalo({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x12C8A66B), width: 24),
        ),
      ),
    );
  }
}

DateTime _manilaNow() {
  return DateTime.now().toUtc().add(const Duration(hours: 8));
}

String _greetingForManila() {
  final hour = _manilaNow().hour;
  if (hour < 12) return 'GOOD MORNING';
  if (hour < 18) return 'GOOD AFTERNOON';
  return 'GOOD EVENING';
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _shortWeekdayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI'];

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
