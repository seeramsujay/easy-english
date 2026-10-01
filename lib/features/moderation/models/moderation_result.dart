enum ModerationRiskLevel {
  none,
  low,
  medium,
  high,
}

class ModerationResult {
  final bool isSafe;
  final ModerationRiskLevel riskLevel;
  final List<String> flaggedTerms;
  final String normalizedText;
  final String? feedbackReason;

  const ModerationResult({
    required this.isSafe,
    required this.riskLevel,
    this.flaggedTerms = const [],
    required this.normalizedText,
    this.feedbackReason,
  });

  static const safe = ModerationResult(
    isSafe: true,
    riskLevel: ModerationRiskLevel.none,
    flaggedTerms: [],
    normalizedText: '',
  );
}
