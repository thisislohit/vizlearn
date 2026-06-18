typedef ArLoadProgressCallback = void Function(ArLoadProgress progress);

class ArLoadProgress {
  const ArLoadProgress({
    required this.percent,
    this.stage,
    this.completed,
    this.total,
  });

  final int percent;
  final String? stage;
  final int? completed;
  final int? total;
}
