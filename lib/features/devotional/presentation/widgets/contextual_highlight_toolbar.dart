import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/text_highlight.dart';
import '../reader_design_tokens.dart';
import 'reader_color_picker_dialog.dart';
import 'toolbar_browser_cursor_stub.dart'
    if (dart.library.html) 'toolbar_browser_cursor_web.dart'
    as browser_cursor;

class ContextualHighlightToolbar extends StatefulWidget {
  final ValueChanged<HighlightColor> onColor;
  final VoidCallback onMoreColors;
  final VoidCallback onRemove;
  final VoidCallback onCite;

  const ContextualHighlightToolbar({
    super.key,
    required this.onColor,
    required this.onMoreColors,
    required this.onRemove,
    required this.onCite,
  });

  @override
  State<ContextualHighlightToolbar> createState() =>
      _ContextualHighlightToolbarState();
}

class _ContextualHighlightToolbarState
    extends State<ContextualHighlightToolbar> {
  // Keep the browser cursor bridge alongside the Flutter MouseRegions. On web,
  // selectable text can leave an I-beam on the DOM element beneath this overlay.
  bool _overSurface = false;
  bool _overControl = false;

  void _surfaceEnter(PointerEvent event) {
    _overSurface = true;
    _surfaceHover(event);
  }

  void _surfaceHover(PointerEvent event) {
    browser_cursor.setToolbarBrowserCursor(
      _overControl ? 'pointer' : 'default',
      event.position.dx,
      event.position.dy,
    );
  }

  void _controlEnter(PointerEvent event) {
    _overControl = true;
    browser_cursor.setToolbarBrowserCursor(
      'pointer',
      event.position.dx,
      event.position.dy,
    );
  }

  void _controlExit(PointerEvent event) {
    _overControl = false;
    if (_overSurface) {
      _surfaceHover(event);
    } else {
      browser_cursor.clearToolbarBrowserCursor();
    }
  }

  void _surfaceExit(PointerEvent event) {
    _overSurface = false;
    _overControl = false;
    browser_cursor.clearToolbarBrowserCursor();
  }

  @override
  void dispose() {
    browser_cursor.clearToolbarBrowserCursor();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile =
        MediaQuery.sizeOf(context).width < ReaderDesign.mobileBreakpoint;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      opaque: true,
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: _surfaceEnter,
      onHover: _surfaceHover,
      onExit: _surfaceExit,
      child: Material(
        color: mobile ? ReaderDesign.inverseSurface : ReaderDesign.surface,
        elevation: mobile ? 10 : 7,
        shadowColor: const Color(0x55233242),
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final color in HighlightColor.values)
                  _ColorAction(
                    color: color,
                    onPressed: () => widget.onColor(color),
                    onEnter: _controlEnter,
                    onHover: _controlEnter,
                    onExit: _controlExit,
                  ),
                _ToolbarAction(
                  label: 'Custom highlight color',
                  icon: Icons.expand_more_rounded,
                  mobile: mobile,
                  onPressed: widget.onMoreColors,
                  onEnter: _controlEnter,
                  onHover: _controlEnter,
                  onExit: _controlExit,
                ),
                _ToolbarAction(
                  label: 'Remove highlight',
                  icon: Icons.format_color_reset_rounded,
                  mobile: mobile,
                  onPressed: widget.onRemove,
                  onEnter: _controlEnter,
                  onHover: _controlEnter,
                  onExit: _controlExit,
                ),
                _ToolbarAction(
                  label: 'Cite to reflection',
                  icon: Icons.edit_note_rounded,
                  mobile: mobile,
                  prominent: true,
                  onPressed: widget.onCite,
                  onEnter: _controlEnter,
                  onHover: _controlEnter,
                  onExit: _controlExit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorAction extends StatelessWidget {
  final HighlightColor color;
  final VoidCallback onPressed;
  final void Function(PointerEvent) onEnter;
  final void Function(PointerEvent) onHover;
  final void Function(PointerEvent) onExit;

  const _ColorAction({
    required this.color,
    required this.onPressed,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${color.label} highlight',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: true,
        hitTestBehavior: HitTestBehavior.opaque,
        onEnter: onEnter,
        onHover: onHover,
        onExit: onExit,
        child: IconButton(
          mouseCursor: SystemMouseCursors.click,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          padding: const EdgeInsets.all(8),
          onPressed: onPressed,
          icon: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: highlightColorValue(color),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool mobile;
  final bool prominent;
  final void Function(PointerEvent) onEnter;
  final void Function(PointerEvent) onHover;
  final void Function(PointerEvent) onExit;

  const _ToolbarAction({
    required this.label,
    required this.icon,
    required this.mobile,
    this.prominent = false,
    required this.onPressed,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: true,
        hitTestBehavior: HitTestBehavior.opaque,
        onEnter: onEnter,
        onHover: onHover,
        onExit: onExit,
        child: prominent
            ? TextButton.icon(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: ReaderDesign.brand,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ).copyWith(
                  mouseCursor: const WidgetStatePropertyAll(
                    SystemMouseCursors.click,
                  ),
                ),
                icon: Icon(icon, size: 15),
                label: Text(
                  'Cite to Reflection',
                  style: ReaderDesign.ui(
                    mobile: mobile,
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : IconButton(
                mouseCursor: SystemMouseCursors.click,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 38,
                ),
                padding: const EdgeInsets.all(7),
                color: mobile
                    ? ReaderDesign.inverseOnSurface
                    : ReaderDesign.muted,
                onPressed: onPressed,
                icon: Icon(icon, size: 17),
              ),
      ),
    );
  }
}

Color highlightColorValue(HighlightColor color) {
  final value = int.parse(color.hex.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}

Future<HighlightColor?> showCustomHighlightColorPicker(
  BuildContext context,
) async {
  final choice = await showReaderColorPicker(
    context,
    title: 'Custom highlight color',
    initialColor: highlightColorValue(HighlightColor.yellow),
  );
  final color = choice?.color;
  if (color == null) return null;
  final hex = '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
      .toUpperCase();
  return HighlightColor.fromHex(hex);
}
