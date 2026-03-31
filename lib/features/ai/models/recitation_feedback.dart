enum RecitationTokenStatus { correct, missing, mismatch, uncertain }

class RecitationTokenFeedback {
  final String expected;
  final String heard;
  final RecitationTokenStatus status;

  const RecitationTokenFeedback({
    required this.expected,
    required this.heard,
    required this.status,
  });
}

class RecitationFeedbackResult {
  final List<RecitationTokenFeedback> tokens;
  final double score;

  const RecitationFeedbackResult({required this.tokens, required this.score});
}
