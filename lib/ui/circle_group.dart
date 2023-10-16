class CircleGroup {
  final String name;
  final List<int> values;

  CircleGroup({
    required this.name,
    required this.values,
  });

  int get numberOfValues => values.length;

  @override
  String toString() {
    return 'CircleGroup(name: $name, values: $values)';
  }
}
