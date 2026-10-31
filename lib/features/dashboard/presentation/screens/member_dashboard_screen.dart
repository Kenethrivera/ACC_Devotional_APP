import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/widgets/calm_brand_background.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../devotional/domain/repositories/devotional_repository.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/dashboard_common.dart';
import '../widgets/dashboard_date_utils.dart';
import '../widgets/devotional_calendar.dart';
import '../widgets/member_dashboard_header.dart';

class MemberDashboardScreen extends StatefulWidget {
  final AuthUser user;
  final Future<void> Function() onSignOut;
  final Future<void> Function()? onOpenDevotional;
  final VoidCallback? onOpenNotifications;
  final DevotionalRepository devotionalRepository;

  const MemberDashboardScreen({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.devotionalRepository,
    this.onOpenDevotional,
    this.onOpenNotifications,
  });

  @override
  State<MemberDashboardScreen> createState() =>
      _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  static const _webBreakpoint = 900.0;
  static const _mobileBreakpoint = 620.0;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < _mobileBreakpoint;
        final web = constraints.maxWidth >= _webBreakpoint;

        return Scaffold(
          backgroundColor: AppColors.ivory,
          body: Stack(
            children: [
              Positioned.fill(
                child: CalmBrandBackground(
                  showCrossHero: true,
                  compact: !web,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    MemberDashboardHeader(
                      email: widget.user.email,
                      compact: mobile,
                      webLayout: web,
                      onHome: _scrollHome,
                      onCalendar: () => _showUnavailable('Calendar'),
                      onProgress: () => _showUnavailable('Progress tracking'),
                      onNotifications: _openNotifications,
                      onAccount: _showAccountPanel,
                      onSignOut: widget.onSignOut,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: web ? 6 : 0),
                        child: ClipRect(
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1180),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        mobile ? 16 : 32,
                                        mobile
                                            ? 20
                                            : web
                                            ? 22
                                            : 38,
                                        mobile ? 16 : 32,
                                        mobile ? 28 : 44,
                                      ),
                                      child: web
                                          ? _DesktopDashboard(
                                              repository: widget.devotionalRepository,
                                              onOpenDevotional:
                                                  widget.onOpenDevotional,
                                              onCalendar: () =>
                                                  _showUnavailable('Calendar'),
                                              onProgress: () =>
                                                  _showUnavailable(
                                                'Progress tracking',
                                              ),
                                              onHistory: () =>
                                                  _showUnavailable(
                                                'Devotional history',
                                              ),
                                            )
                                          : _MobileDashboard(
                                              repository: widget.devotionalRepository,
                                              onOpenDevotional:
                                                  widget.onOpenDevotional,
                                              onCalendar: () =>
                                                  _showUnavailable('Calendar'),
                                              onProgress: () =>
                                                  _showUnavailable(
                                                'Progress tracking',
                                              ),
                                              onHistory: () =>
                                                  _showUnavailable(
                                                'Devotional history',
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: mobile
              ? _MobileBottomNavigation(
                  onHome: _scrollHome,
                  onCalendar: () => _showUnavailable('Calendar'),
                  onNotifications: _openNotifications,
                  onAccount: _showAccountPanel,
                )
              : null,
        );
      },
    );
  }

  void _openNotifications() {
    final callback = widget.onOpenNotifications;
    if (callback != null) {
      callback();
      return;
    }

    AppFeedback.show(
      context,
      message:
          'Notification inbox will be available when its service is connected.',
      type: AppMessageType.info,
    );
  }

  void _showUnavailable(String feature) {
    AppFeedback.show(
      context,
      message: '$feature will be available when its service is connected.',
      type: AppMessageType.info,
    );
  }

  void _scrollHome() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _scrollController.animateTo(
      0,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showAccountPanel() async {
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
                    color: Color(0x33102F4E),
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
                      const DashboardRoundIcon(
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
                              widget.user.email ?? 'Authenticated member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedText,
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
                  const SizedBox(height: 20),
                  const DashboardUnavailableNotice(
                    title: 'Account settings are not connected yet',
                    message:
                        'Profile and preference controls will appear here when '
                        'account settings are implemented.',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await widget.onSignOut();
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

class _MobileDashboard extends StatelessWidget {
  final DevotionalRepository repository;
  final Future<void> Function()? onOpenDevotional;
  final VoidCallback onCalendar;
  final VoidCallback onProgress;
  final VoidCallback onHistory;

  const _MobileDashboard({
    required this.repository,
    required this.onOpenDevotional,
    required this.onCalendar,
    required this.onProgress,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MobileWelcome(),
        const SizedBox(height: 20),
        TodayDevotionalCard(
          compact: true,
          repository: repository,
          onOpen: onOpenDevotional,
        ),
        const SizedBox(height: 14),
        const WeeklyRhythmPanel(),
        const SizedBox(height: 26),
        const DashboardSectionTitle(
          eyebrow: 'THIS WEEK',
          title: 'Your Progress',
          description: 'Honest placeholders until tracking is connected.',
        ),
        const SizedBox(height: 15),
        const ProgressMosaic(compact: true),
        const SizedBox(height: 26),
        const DashboardSectionTitle(
          eyebrow: 'DEVOTIONAL LIFE',
          title: 'Your Journey',
          description: 'A quiet rhythm for daily growth.',
        ),
        const SizedBox(height: 15),
        JourneyMosaic(
          compact: true,
          onCalendar: onCalendar,
          onProgress: onProgress,
          onHistory: onHistory,
        ),
        const SizedBox(height: 28),
        const _DashboardFooter(),
      ],
    );
  }
}

class _MobileWelcome extends StatelessWidget {
  const _MobileWelcome();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manilaGreeting(),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Welcome back',
          style: GoogleFonts.lora(
            color: AppColors.navy,
            fontSize: 30,
            height: 1.08,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Ready for today\'s devotion? Make space for the Word, '
          'one fresh page at a time.',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xDFFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                fullManilaDate(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopDashboard extends StatelessWidget {
  final DevotionalRepository repository;
  final Future<void> Function()? onOpenDevotional;
  final VoidCallback onCalendar;
  final VoidCallback onProgress;
  final VoidCallback onHistory;

  const _DesktopDashboard({
    required this.repository,
    required this.onOpenDevotional,
    required this.onCalendar,
    required this.onProgress,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DesktopWelcome(),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: TodayDevotionalCard(
                compact: false,
                repository: repository,
                onOpen: onOpenDevotional,
              ),
            ),
            const SizedBox(width: 22),
            const Expanded(
              flex: 5,
              child: Column(
                children: [
                  ProgressMosaic(compact: false),
                  SizedBox(height: 10),
                  WeeklyRhythmPanel(compact: true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const DashboardSectionTitle(
          eyebrow: 'DEVOTIONAL LIFE',
          title: 'Your Journey',
          description: 'Calendar, progress, and history destinations.',
        ),
        const SizedBox(height: 15),
        JourneyMosaic(
          compact: false,
          onCalendar: onCalendar,
          onProgress: onProgress,
          onHistory: onHistory,
        ),
        const SizedBox(height: 36),
        const _DashboardFooter(),
      ],
    );
  }
}

class _DesktopWelcome extends StatelessWidget {
  const _DesktopWelcome();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manilaGreeting(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Welcome back',
                style: GoogleFonts.lora(
                  color: AppColors.navy,
                  fontSize: 44,
                  height: 1.08,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Ready for today\'s devotion? Make space for the Word, '
                'one fresh page at a time.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xDFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 17,
              ),
              const SizedBox(width: 10),
              Text(
                fullManilaDate(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;

  const _MobileBottomNavigation({
    required this.onHome,
    required this.onCalendar,
    required this.onNotifications,
    required this.onAccount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(12, 7, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF244863)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D102F4E),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavAction(
                label: 'Home',
                icon: Icons.home_rounded,
                selected: true,
                onTap: onHome,
              ),
            ),
            Expanded(
              child: _NavAction(
                label: 'Calendar',
                icon: Icons.calendar_month_outlined,
                onTap: onCalendar,
              ),
            ),
            Expanded(
              child: _NavAction(
                label: 'Inbox',
                icon: Icons.notifications_none_rounded,
                onTap: onNotifications,
              ),
            ),
            Expanded(
              child: _NavAction(
                label: 'Account',
                icon: Icons.person_outline_rounded,
                onTap: onAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const _NavAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: selected
                    ? AppColors.navy
                    : const Color(0xFFD6E1E8),
                size: 22,
              ),
            ),
          ),
        ),
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
              color: AppColors.mutedText,
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
