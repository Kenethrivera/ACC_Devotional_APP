import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as color_picker;

class ReaderColorChoice {
  final Color? color;
  const ReaderColorChoice(this.color);
}

Future<ReaderColorChoice?> showReaderColorPicker(
  BuildContext context, {
  required String title,
  required Color initialColor,
  bool allowClear = false,
}) =>
    showDialog<ReaderColorChoice>(
      context: context,
      builder: (_) => _ReaderColorPickerDialog(
        title: title,
        initialColor: initialColor,
        allowClear: allowClear,
      ),
    );

class _ReaderColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initialColor;
  final bool allowClear;

  const _ReaderColorPickerDialog({
    required this.title,
    required this.initialColor,
    required this.allowClear,
  });

  @override
  State<_ReaderColorPickerDialog> createState() => _ReaderColorPickerDialogState();
}

class _ReaderColorPickerDialogState extends State<_ReaderColorPickerDialog> {
  late Color _selectedColor;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(
      text: color_picker.colorToHex(_selectedColor, enableAlpha: false),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 330,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Color'),
                  const Spacer(),
                  if (widget.allowClear)
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const ReaderColorChoice(null),
                      ),
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              color_picker.ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) =>
                    setState(() => _selectedColor = color),
                hexInputController: _hexController,
                enableAlpha: false,
                colorPickerWidth: 300,
                // The dialog stays narrow on desktop; the picker's automatic
                // landscape Row needs more than twice this width.
                portraitOnly: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _hexController,
                      decoration: const InputDecoration(
                        labelText: 'Hex',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      border: Border.all(color: Colors.black45),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ReaderColorChoice(_selectedColor),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
