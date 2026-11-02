import 'package:flutter/material.dart';

/// The five destination bar from the approved mobile calendar reference.
class MemberBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onNotebook;
  final VoidCallback onAlerts;
  final VoidCallback onProfile;

  const MemberBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onHome,
    required this.onCalendar,
    required this.onNotebook,
    required this.onAlerts,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [onHome, onCalendar, onNotebook, onAlerts, onProfile];
    const labels = ['Home', 'Calendar', 'Notebook', 'Alerts', 'Profile'];
    const icons = [
      Icons.home_outlined,
      Icons.calendar_month_rounded,
      Icons.edit_note_outlined,
      Icons.notifications_none_rounded,
      Icons.person_outline_rounded,
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 90,
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 0, right: 0, top: 20, bottom: 0,
            child: CustomPaint(painter: _NavigationSurface(selectedIndex))),
          Row(children: [
            for (var index = 0; index < 5; index++)
              Expanded(child: Semantics(
                button: true,
                selected: index == selectedIndex,
                label: labels[index],
                child: Tooltip(
                  message: labels[index],
                  child: InkWell(
                    onTap: actions[index],
                    borderRadius: BorderRadius.circular(32),
                    child: Center(child: Transform.translate(
                      offset: Offset(0, index == selectedIndex ? -19 : 10),
                      child: Container(
                        width: index == selectedIndex ? 52 : 44,
                        height: index == selectedIndex ? 52 : 44,
                        decoration: BoxDecoration(
                          color: index == selectedIndex ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                          border: index == selectedIndex
                              ? Border.all(color: const Color(0xFFCBD1D6), width: 2)
                              : null,
                          boxShadow: index == selectedIndex ? const [
                            BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
                          ] : null,
                        ),
                        child: Icon(icons[index], size: 23,
                          color: index == selectedIndex
                            ? const Color(0xFF0D1F2D)
                            : const Color(0xFF9DAFBF)),
                      ),
                    )),
                  ),
                ),
              )),
          ]),
        ]),
      ),
    );
  }
}

class _NavigationSurface extends CustomPainter {
  final int selectedIndex;

  const _NavigationSurface(this.selectedIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width * (selectedIndex + .5) / 5;
    final base = Path()..addRRect(RRect.fromRectAndRadius(
      Offset.zero & size, const Radius.circular(32),
    ));
    final halfWidth = (size.width / 5 * .48).clamp(25.0, 39.0).toDouble();
    final notch = Path()
      ..moveTo(center - halfWidth, -2)
      ..lineTo(center - halfWidth, 0)
      ..cubicTo(center - halfWidth * .55, 0, center - halfWidth * .9, 38, center, 38)
      ..cubicTo(center + halfWidth * .9, 38, center + halfWidth * .55, 0, center + halfWidth, 0)
      ..lineTo(center + halfWidth, -2)
      ..close();
    final path = Path.combine(PathOperation.difference, base, notch);
    canvas.drawShadow(path, const Color(0x880D1F2D), 18, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFF0D1F2D));
  }

  @override
  bool shouldRepaint(covariant _NavigationSurface oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}
