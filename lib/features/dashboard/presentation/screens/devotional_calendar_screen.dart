import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/calm_brand_background.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../devotional/domain/models/assigned_devotional.dart';
import '../../../devotional/domain/models/devotional_completion.dart';
import '../../../devotional/domain/models/devotional_participation.dart';
import '../../../devotional/domain/repositories/devotional_repository.dart';
import '../../../devotional/presentation/screens/daily_devotional_reader_screen.dart';
import '../widgets/dashboard_date_utils.dart';
import '../widgets/member_dashboard_header.dart';
import '../widgets/member_bottom_navigation.dart';

/// Month navigation uses the existing member-scoped repository. A day without a
/// published assignment stays neutral, whether it is a weekday or weekend.
class DevotionalCalendarScreen extends StatefulWidget {
  final AuthUser user;
  final DevotionalRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback onNotifications;
  final VoidCallback onAccount;

  const DevotionalCalendarScreen({
    super.key,
    required this.user,
    required this.repository,
    required this.onSignOut,
    required this.onNotifications,
    required this.onAccount,
  });

  @override
  State<DevotionalCalendarScreen> createState() => _DevotionalCalendarScreenState();
}

class _DevotionalCalendarScreenState extends State<DevotionalCalendarScreen> {
  static const _ink = Color(0xFF102130);
  static const _blue = Color(0xFF004482);
  static const _green = Color(0xFF2E704C);
  static const _read = Color(0xFFD9E9FF);
  static const _reflected = Color(0xFFAAF0C5);
  static const _canvas = Color(0xFFF8F9FF);

  late DateTime _month;
  late DateTime _selected;
  DateTime? _today;
  List<AssignedDevotional> _assignments = const [];
  List<DevotionalReadingState> _reading = const [];
  List<DevotionalCompletion> _completions = const [];
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    final now = manilaNow();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = await widget.repository.getManilaToday();
      if (_today == null) {
        _month = DateTime(today.year, today.month);
        _selected = DateTime(today.year, today.month, today.day);
      }
      final start = DateTime(_month.year, _month.month);
      final end = DateTime(_month.year, _month.month + 1, 0);
      final assignments = await widget.repository.listAvailableAssignments(
        fromManilaDate: start,
        throughManilaDate: end,
      );
      final reading = await widget.repository.listMyReadingStates(
        fromManilaDate: start,
        throughManilaDate: end,
      );
      final completions = await widget.repository.listMyCompletions(
        fromManilaDate: start,
        throughManilaDate: end,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _today = today;
        _assignments = assignments;
        _reading = reading;
        _completions = completions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = 'Your calendar could not be loaded. Please try again.';
        _loading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    setState(() {
      _month = next;
      _selected = DateTime(next.year, next.month, 1);
    });
    _load();
  }

  AssignedDevotional? _assignmentFor(DateTime day) {
    for (final item in _assignments) {
      if (isSameCalendarDay(item.assignment.scheduledDate, day)) return item;
    }
    return null;
  }

  DevotionalReadingState? _readingFor(DateTime day) {
    for (final item in _reading) {
      if (isSameCalendarDay(item.scheduledDate, day)) return item;
    }
    return null;
  }

  bool _completedFor(DateTime day) => _completions.any(
    (item) => isSameCalendarDay(item.scheduledDate, day),
  );

  bool _readFor(DateTime day) => _readingFor(day) != null || _completedFor(day);

  bool _reflectedFor(DateTime day) =>
      _readingFor(day)?.level == DevotionalParticipationLevel.reflected;

  Future<void> _openSelected() async {
    if (_assignmentFor(_selected) == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DailyDevotionalReaderScreen(
        repository: widget.repository,
        requestedManilaDate: _selected,
      ),
    ));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 620;
    final web = width >= 900;
    return Scaffold(
      backgroundColor: _canvas,
      body: Stack(children: [
        if (web) const Positioned.fill(child: CalmBrandBackground(showCrossHero: false)),
        SafeArea(
          child: Column(children: [
            MemberDashboardHeader(
              email: widget.user.email,
              compact: mobile,
              webLayout: web,
              calendarSelected: true,
              onHome: () => Navigator.of(context).pop(),
              onCalendar: () {},
              onNotebook: () => _unavailable('Notebook'),
              onProgress: () => _unavailable('Progress'),
              onNotifications: widget.onNotifications,
              onAccount: widget.onAccount,
              onSignOut: widget.onSignOut,
            ),
            Expanded(child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(children: [
                if (mobile) _mobileHero(),
                Center(child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(mobile ? 22 : 48, mobile ? 0 : 30, mobile ? 22 : 48, 80),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _intro(mobile),
                      SizedBox(height: mobile ? 20 : 32),
                      _metrics(mobile),
                      SizedBox(height: mobile ? 20 : 30),
                      if (_loading) const Center(child: Padding(
                        padding: EdgeInsets.all(32), child: CircularProgressIndicator(),
                      )) else if (_error != null) _errorView() else if (web)
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(flex: 65, child: _calendar(false)),
                          const SizedBox(width: 30),
                          Expanded(flex: 35, child: Column(children: [
                            _selectedCard(false),
                            const SizedBox(height: 16),
                            _principle(false),
                          ])),
                        ])
                      else Column(children: [
                        _calendar(mobile),
                        const SizedBox(height: 20),
                        _selectedCard(mobile),
                        const SizedBox(height: 20),
                        _principle(mobile),
                      ]),
                    ]),
                  ),
                )),
                if (web) _footer(),
              ]),
            )),
          ]),
        ),
      ]),
      bottomNavigationBar: mobile ? MemberBottomNavigation(
        selectedIndex: 1,
        onHome: () => Navigator.of(context).pop(),
        onCalendar: () {},
        onNotebook: () => _unavailable('Notebook'),
        onAlerts: widget.onNotifications,
        onProfile: widget.onAccount,
      ) : null,
    );
  }

  void _unavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature will be available soon.'),
    ));
  }

  Widget _mobileHero() => SizedBox(
    height: 126,
    width: double.infinity,
    child: LayoutBuilder(builder: (context, constraints) {
      // The supplied hero.jpg differs from the ocean banner in screen.png.
      // Crop only the banner from the approved screenshot at its source size.
      final scale = (constraints.maxWidth / 461).clamp(126 / 120, 10.0).toDouble();
      final imageWidth = 461 * scale;
      return Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(
          top: -64 * scale,
          left: (constraints.maxWidth - imageWidth) / 2,
          width: imageWidth,
          child: Image.asset('asset/illustrations/calendar_ocean_banner.png'),
        ),
      ]);
    }),
  );

  Widget _intro(bool mobile) {
    final monthLabel = '${longMonthNames[_month.month - 1]} ${_month.year}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (mobile) ...[
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8, runSpacing: 8, children: [
          _pill(Icons.circle, '$monthLabel  •  4+ Days Target', const Color(0xFFEEF4FF)),
          Text('Week ${((_selected.day - 1) ~/ 7) + 1} of 5',
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
        ]),
        const SizedBox(height: 12),
      ],
      if (mobile)
        Text("Your Journey in God's Word", style: GoogleFonts.lora(
          fontSize: 25, fontWeight: FontWeight.w700, color: _blue,
        ))
      else Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Text("Your Journey in God's Word", style: GoogleFonts.lora(
          fontSize: 46, color: _ink, fontWeight: FontWeight.w500,
        ))),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _pill(Icons.calendar_month_outlined, '$monthLabel Journey', const Color(0xFFEEF4FF)),
          const SizedBox(height: 7),
          _pill(Icons.circle, 'Pacing: 4+ Days Target', Colors.white),
        ]),
      ]),
      const SizedBox(height: 8),
      Text("Look back on the days you've spent reading, reflecting, and growing in faith through HIS Words.",
        style: mobile
          ? const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF566070))
          : GoogleFonts.lora(fontSize: 17, color: const Color(0xFF566070))),
    ]);
  }

  Widget _pill(IconData icon, String label, Color fill) => Container(
    constraints: BoxConstraints(maxWidth:
      (MediaQuery.sizeOf(context).width - 44).clamp(120.0, 260.0).toDouble()),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: _blue),
      const SizedBox(width: 5),
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600))),
    ]),
  );

  Widget _metrics(bool mobile) {
    final read = _assignments.where((item) => _readFor(item.assignment.scheduledDate)).length;
    final reflected = _assignments.where((item) => _reflectedFor(item.assignment.scheduledDate)).length;
    final published = _assignments.where((item) => _today == null ||
      !item.assignment.scheduledDate.isAfter(_today!)).length;
    final percent = published == 0 ? 0 : ((read / published) * 100).round();
    final streak = _monthStreak();
    final cards = [
      _metric('DAYS READ', '$read', 'sessions', Icons.menu_book_outlined, _blue),
      _metric('REFLECTED', '$reflected', 'journaled', Icons.edit_note_rounded, _green),
      _metric('THIS MONTH', '$read of $published', '($percent%)', Icons.auto_stories_outlined, _ink),
      _metric('CURRENT STREAK', '$streak', 'days', Icons.local_fire_department_outlined, const Color(0xFF9C4D23)),
    ];
    if (MediaQuery.sizeOf(context).width < 900) return Column(children: [
      Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: cards[3]), const SizedBox(width: 12), Expanded(child: cards[2])]),
    ]);
    return Row(children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(width: 16),
        Expanded(child: cards[i]),
      ],
    ]);
  }

  int _monthStreak() {
    if (_today == null) return 0;
    var count = 0;
    final ordered = _assignments.where((a) => !a.assignment.scheduledDate.isAfter(_today!)).toList()
      ..sort((a, b) => b.assignment.scheduledDate.compareTo(a.assignment.scheduledDate));
    for (final item in ordered) {
      if (!_readFor(item.assignment.scheduledDate)) break;
      count++;
    }
    return count;
  }

  Widget _metric(String label, String number, String suffix, IconData icon, Color color) => Container(
    constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).width < 900 ? 96 : 132),
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 900 ? 14 : 19),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFF0F1F5))),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700, color: color,
      ))), if (MediaQuery.sizeOf(context).width >= 900) Icon(icon, color: color, size: 18)]),
      const SizedBox(height: 9),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text(number, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lora(fontSize: 25, color: color, fontWeight: FontWeight.w700))),
        const SizedBox(width: 5),
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(suffix,
          style: const TextStyle(fontSize: 10, color: Color(0xFF566070)))),
      ]),
      if (MediaQuery.sizeOf(context).width >= 900) ...[
        const SizedBox(height: 7),
        const Text('Faithful moments in the Word', maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Color(0xFF566070))),
      ],
    ]),
  );

  Widget _calendar(bool mobile) {
    final first = DateTime(_month.year, _month.month);
    final offset = first.weekday % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((offset + days) / 7).ceil();
    return _surface(Padding(
      padding: EdgeInsets.all(mobile ? 16 : 32),
      child: Column(children: [
        Row(children: [
          IconButton(tooltip: 'Previous month', onPressed: () => _changeMonth(-1),
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left_rounded)),
          if (mobile) const Icon(Icons.calendar_month_outlined, color: _blue, size: 18),
          if (mobile) const SizedBox(width: 6),
          Expanded(child: Text('${longMonthNames[_month.month - 1]} ${_month.year}',
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lora(fontSize: mobile ? 19 : 24, color: _blue, fontWeight: FontWeight.w600))),
          IconButton(tooltip: 'Next month', onPressed: () => _changeMonth(1),
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        const SizedBox(height: 16),
        Row(children: [for (final name in const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'])
          Expanded(child: Center(child: Text(name, style: const TextStyle(
            fontSize: 10, letterSpacing: .5, fontWeight: FontWeight.w700,
            color: Color(0xFF606674),
          ))))]),
        const SizedBox(height: 12),
        for (var row = 0; row < rows; row++) ...[
          Row(children: [for (var col = 0; col < 7; col++)
            Expanded(child: Padding(
              padding: EdgeInsets.all(mobile ? 2 : 5),
              child: _dayCell(DateTime(_month.year, _month.month, row * 7 + col - offset + 1), mobile),
            ))]),
          if (row < rows - 1) SizedBox(height: mobile ? 1 : 4),
        ],
        const SizedBox(height: 20),
        Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
          _legend(_green, 'Reflected'), _legend(_blue, 'Read'),
          _legend(const Color(0xFF184F35), 'Today (${shortMonthNames[(_today ?? manilaNow()).month - 1]} ${(_today ?? manilaNow()).day})'),
        ]),
      ]),
    ));
  }

  Widget _dayCell(DateTime date, bool mobile) {
    final inMonth = date.month == _month.month;
    final assignment = inMonth ? _assignmentFor(date) : null;
    final isToday = _today != null && isSameCalendarDay(date, _today!);
    final isSelected = isSameCalendarDay(date, _selected);
    final reflected = assignment != null && _reflectedFor(date);
    final read = assignment != null && _readFor(date);
    final color = reflected ? _reflected : read ? _read : const Color(0xFFEEF3FF);
    return AspectRatio(aspectRatio: mobile ? 1 : 1.05, child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: inMonth ? () => setState(() => _selected = date) : null,
        borderRadius: BorderRadius.circular(mobile ? 50 : 16),
        child: Container(
          decoration: BoxDecoration(
            color: !inMonth ? Colors.transparent : isToday && mobile ? const Color(0xFF246B49) : color,
            borderRadius: BorderRadius.circular(mobile ? 50 : 16),
            border: isSelected && !mobile ? Border.all(color: _green) : null,
            boxShadow: isSelected && !mobile ? const [BoxShadow(color: Color(0x22000000), blurRadius: 6)] : null,
          ),
          child: Stack(alignment: Alignment.center, children: [
            Align(alignment: assignment != null && (read || reflected) && !mobile
                ? const Alignment(0, -0.35) : Alignment.center,
              child: Text('${date.day}', style: TextStyle(
                color: !inMonth ? const Color(0xFFD4D9E2) : isToday && mobile ? Colors.white
                  : reflected ? _green : read ? _blue : const Color(0xFF4B5360),
                fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: mobile ? 13 : 14,
              ))),
            if (assignment != null && (read || reflected))
              Positioned(bottom: mobile ? 2 : 4, child: mobile
                ? Container(width: 4, height: 4, decoration: BoxDecoration(
                    color: isToday ? Colors.white : reflected ? _green : _blue,
                    shape: BoxShape.circle,
                  ))
                : Icon(reflected ? Icons.edit_note_rounded : Icons.menu_book_outlined,
                    size: 14, color: reflected ? _green : _blue)),
          ]),
        ),
      ),
    ));
  }

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5360))),
  ]);

  Widget _selectedCard(bool mobile) {
    final assignment = _assignmentFor(_selected);
    final isToday = _today != null && isSameCalendarDay(_selected, _today!);
    final read = _readFor(_selected);
    final reflected = _reflectedFor(_selected);
    return _surface(Padding(
      padding: EdgeInsets.all(mobile ? 23 : 31),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(fullManilaDate(_selected), style: TextStyle(
            fontSize: mobile ? 13 : 14, color: mobile ? const Color(0xFF4B5360) : _blue,
            fontWeight: FontWeight.w700,
          ))),
          if (isToday) _badge('TODAY', const Color(0xFFD9E9FF), _blue),
        ]),
        const SizedBox(height: 16),
        const Text('ADELINA CHRISTIAN CHURCH · DAILY BREAD', style: TextStyle(
          fontSize: 10, letterSpacing: .4, fontWeight: FontWeight.w700, color: Color(0xFF596272))),
        const SizedBox(height: 7),
        Text(assignment?.content.title ?? 'No devotional assigned', style: GoogleFonts.lora(
          fontSize: mobile ? 25 : 29, fontWeight: FontWeight.w600, color: _ink,
        )),
        const SizedBox(height: 9),
        if (assignment != null) Row(children: [
          const Icon(Icons.menu_book_outlined, color: _blue, size: 16),
          const SizedBox(width: 5),
          Expanded(child: Text(assignment.content.scriptureReference,
            style: const TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700))),
        ]),
        if (assignment != null) ...[
          const SizedBox(height: 18),
          Wrap(spacing: 7, children: [
            if (read) _badge('✓ Read', _read, _blue),
            if (reflected) _badge('✓ Reflected', _reflected, _green),
          ]),
          const SizedBox(height: 19),
          Container(width: double.infinity, padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(mobile ? 0 : 32)),
            child: Text(_excerpt(assignment.content.body), maxLines: 5, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lora(fontSize: mobile ? 15 : 16, height: 1.7,
                fontStyle: FontStyle.italic, color: _ink))),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: _openSelected,
            child: const Row(children: [
              Expanded(child: Text('Open Devotional & Reflection', textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ]),
            style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15)),
          )),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _secondaryAction(Icons.menu_book_outlined, 'Passage', _openSelected)),
            const SizedBox(width: 5),
            Expanded(child: _secondaryAction(Icons.edit_outlined, 'Edit Reflection', _openSelected)),
          ]),
        ] else ...[
          const SizedBox(height: 12),
          const Text('This date has no published assignment.',
            style: TextStyle(fontSize: 12, color: Color(0xFF596272))),
        ],
        const SizedBox(height: 18),
        const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF667180)),
          SizedBox(width: 5),
          Flexible(child: Text('All reflections remain strictly private to you.',
            style: TextStyle(fontSize: 10, color: Color(0xFF667180)))),
        ])),
      ]),
    ));
  }

  String _excerpt(String body) {
    final clean = body.replaceAll(RegExp(r'[#*_\n\r]+'), ' ').trim();
    return clean.isEmpty ? 'Open the devotional to spend time in the Word.' : '“$clean”';
  }

  Widget _badge(String label, Color fill, Color ink) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, color: ink, fontWeight: FontWeight.w700)),
  );

  Widget _secondaryAction(IconData icon, String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 16),
      const SizedBox(width: 4),
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
    style: TextButton.styleFrom(backgroundColor: const Color(0xFFE5EFFF), foregroundColor: _blue,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6)),
  );

  Widget _principle(bool mobile) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: mobile ? const Color(0xFFDAF4E6) : Colors.white,
      borderRadius: BorderRadius.circular(mobile ? 32 : 18)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 40, height: 40, decoration: const BoxDecoration(
        color: _reflected, shape: BoxShape.circle),
        child: const Icon(Icons.spa_outlined, color: _green, size: 21)),
      const SizedBox(width: 11),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('The Power of 4+ Principle', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Engaging scripture 4 or more times a week fundamentally reshapes your spiritual habits, grounding your days in clarity, peace, and sacred resilience.',
          style: TextStyle(fontSize: 12, height: 1.6, color: Color(0xFF52616A))),
      ])),
    ]),
  );

  Widget _surface(Widget child) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFF0F1F5))), child: child,
  );

  Widget _errorView() => _surface(Padding(
    padding: const EdgeInsets.all(30), child: Column(children: [
      Text(_error!, style: const TextStyle(color: _ink)),
      const SizedBox(height: 10), TextButton(onPressed: _load, child: const Text('Retry')),
    ]),
  ));

  Widget _footer() => Container(
    color: const Color(0xFFEAF1FE), padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 27),
    child: const Row(children: [
      Expanded(child: Text('Adelina Christian Church · Power of 4+ Devotions',
        style: TextStyle(fontSize: 11, color: Color(0xFF596272)))),
      Text('© 2026 Adelina Christian Church. Built for contemplative sanctuary reading.',
        style: TextStyle(fontSize: 11, color: Color(0xFF596272))),
    ]),
  );

}
