import 'circle_group.dart';

class CircleConfig {
  final List<CircleGroup> groups;

  CircleConfig({
    required this.groups,
  });

  @override
  String toString() {
    return 'CircleConfig(groups: $groups)';
  }
}
