class ExpertConfig {
  const ExpertConfig({
    this.maxTokens = defaultMaxTokens,
    this.topK = defaultTopK,
    this.topP = defaultTopP,
    this.temperature = defaultTemperature,
  });

  static const int defaultMaxTokens = 8000;
  static const int defaultTopK = 40;
  static const double defaultTopP = 0.9;
  static const double defaultTemperature = 0.8;

  final int maxTokens;
  final int topK;
  final double topP;
  final double temperature;

  ExpertConfig copyWith({
    int? maxTokens,
    int? topK,
    double? topP,
    double? temperature,
  }) {
    return ExpertConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      temperature: temperature ?? this.temperature,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpertConfig &&
          other.maxTokens == maxTokens &&
          other.topK == topK &&
          other.topP == topP &&
          other.temperature == temperature;

  @override
  int get hashCode => Object.hash(maxTokens, topK, topP, temperature);
}
