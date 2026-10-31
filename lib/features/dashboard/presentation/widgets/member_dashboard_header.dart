import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/acc_brand_mark.dart';
import 'dashboard_common.dart';

class MemberDashboardHeader extends StatelessWidget {
  final String? email;
  final bool compact;
  final bool webLayout;
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onProgress;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;
  final Future<void> Function() onSignOut;

  const MemberDashboardHeader({
    super.key,
    required this.email,
    required this.compact,
    required this.webLayout,
    required this.onHome,
    required this.onCalendar,
    required this.onProgress,
    required this.onNotifications,
    required this.onAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (!webLayout) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 32,
              compact ? 12 : 16,
              compact ? 18 : 32,
              compact ? 8 : 12,
            ),
            child: _mobileHeader(context),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: const BoxDecoration(
        color: Color(0xF7FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10102F4E),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final compactNavigation =
              constraints.maxWidth < 1080 || textScale > 1.15;
          final horizontalPadding = constraints.maxWidth >= 1600 ? 32.0 : 24.0;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: _desktopHeader(
              context,
              compactNavigation: compactNavigation,
            ),
          );
        },
      ),
    );
  }

  Widget _mobileHeader(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: 'Account',
          child: InkWell(
            onTap: onAccount,
            borderRadius: BorderRadius.circular(15),
            child: const AccBrandMark(height: 54, maxWidth: 54),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADELINA CHRISTIAN CHURCH',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Power of 4+  |  The Fresh Page',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xDFFFFFFF),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.navy,
            iconSize: 21,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _desktopHeader(
    BuildContext context, {
    required bool compactNavigation,
  }) {
    return Row(
      children: [
        const AccBrandMark(height: 44, maxWidth: 44),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADELINA CHRISTIAN CHURCH',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Power of 4+  |  The Fresh Page',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
            ],
          ),
        ),
        _DesktopNavigation(
          compact: compactNavigation,
          onHome: onHome,
          onCalendar: onCalendar,
          onProgress: onProgress,
        ),
        const SizedBox(width: 10),
        Container(width: 1, height: 28, color: AppColors.border),
        const SizedBox(width: 10),
        _NotificationMenu(onOpen: onNotifications),
        const SizedBox(width: 6),
        _ProfileMenu(email: email, onSignOut: onSignOut),
      ],
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  final bool compact;
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onProgress;

  const _DesktopNavigation({
    required this.compact,
    required this.onHome,
    required this.onCalendar,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DesktopNavItem(
          label: 'Home',
          icon: Icons.home_rounded,
          selected: true,
          compact: compact,
          onTap: onHome,
        ),
        const SizedBox(width: 4),
        _DesktopNavItem(
          label: 'Calendar',
          icon: Icons.calendar_month_outlined,
          available: false,
          compact: compact,
          onTap: onCalendar,
        ),
        const SizedBox(width: 4),
        _DesktopNavItem(
          label: 'Progress',
          icon: Icons.insights_outlined,
          available: false,
          compact: compact,
          onTap: onProgress,
        ),
      ],
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool available;
  final bool compact;

  const _DesktopNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.compact,
    this.selected = false,
    this.available = true,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.primary
        : available
        ? AppColors.navy
        : AppColors.mutedText;
    final tooltip = available ? label : '$label — unavailable';

    return Semantics(
      button: true,
      selected: selected,
      enabled: true,
      label: label,
      hint: available ? null : 'Not available yet',
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 19, color: foreground),
                    if (compact && !available) ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 11,
                        color: foreground,
                      ),
                    ],
                    if (!compact) ...[
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: foreground,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationMenu extends StatelessWidget {
  final VoidCallback onOpen;

  const _NotificationMenu({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-250, 8),
      style: _menuStyle(),
      menuChildren: [
        SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.lora(
                        color: AppColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const DashboardUnavailableNotice(
                  title: 'Your inbox is not connected yet',
                  message:
                      'Church updates and devotional reminders will appear here.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onOpen,
                    child: const Text('Notification details'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return _HeaderButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onPressed: () => controller.isOpen
              ? controller.close()
              : controller.open(),
        );
      },
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final String? email;
  final Future<void> Function() onSignOut;

  const _ProfileMenu({required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-245, 8),
      style: _menuStyle(),
      menuChildren: [
        SizedBox(
          width: 310,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                const DashboardRoundIcon(
                  icon: Icons.person_outline_rounded,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member account',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email ?? 'Authenticated member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        const MenuItemButton(
          leadingIcon: Icon(Icons.settings_outlined),
          onPressed: null,
          child: Text('Account settings unavailable'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout_rounded),
          onPressed: onSignOut,
          child: const Text('Log out'),
        ),
      ],
      builder: (context, controller, child) {
        return _HeaderButton(
          tooltip: 'Account',
          icon: Icons.person_outline_rounded,
          onPressed: () => controller.isOpen
              ? controller.close()
              : controller.open(),
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppColors.navy, size: 21),
          ),
        ),
      ),
    );
  }
}

MenuStyle _menuStyle() {
  return MenuStyle(
    backgroundColor: const WidgetStatePropertyAll(AppColors.white),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(12),
    shadowColor: const WidgetStatePropertyAll(Color(0x33102F4E)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
  );
}
