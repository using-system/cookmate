class ExpertConfig {
  const ExpertConfig({
    this.maxTokens = defaultMaxTokens,
    this.topK = defaultTopK,
    this.topP = defaultTopP,
    this.temperature = defaultTemperature,
    this.tokenBuffer = defaultTokenBuffer,
  });

  static const int defaultMaxTokens = 8000;
  static const int defaultTopK = 40;
  static const double defaultTopP = 0.9;
  static const double defaultTemperature = 0.8;
  static const int defaultTokenBuffer = 2048;

  final int maxTokens;
  final int topK;
  final double topP;
  final double temperature;
  final int tokenBuffer;

  ExpertConfig copyWith({
    int? maxTokens,
    int? topK,
    double? topP,
    double? temperature,
    int? tokenBuffer,
  }) {
    return ExpertConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      temperature: temperature ?? this.temperature,
      tokenBuffer: tokenBuffer ?? this.tokenBuffer,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpertConfig &&
          other.maxTokens == maxTokens &&
          other.topK == topK &&
          other.topP == topP &&
          other.temperature == temperature &&
          other.tokenBuffer == tokenBuffer;

  @override
  int get hashCode => Object.hash(maxTokens, topK, topP, temperature, tokenBuffer);
}
