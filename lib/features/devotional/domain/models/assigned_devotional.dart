import 'devotional_assignment.dart';
import 'devotional_version.dart';

class AssignedDevotional {
  final DevotionalAssignment assignment;
  final DevotionalVersion content;

  const AssignedDevotional({
    required this.assignment,
    required this.content,
  });
}
