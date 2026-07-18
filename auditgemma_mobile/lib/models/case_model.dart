/// Data models matching the backend Pydantic schemas (fixed contract).

class CaseListItem {
  final String caseId;
  final String status;
  final int score;

  CaseListItem({
    required this.caseId,
    required this.status,
    required this.score,
  });

  factory CaseListItem.fromJson(Map<String, dynamic> json) {
    return CaseListItem(
      caseId: json['case_id'] as String,
      status: json['status'] as String,
      score: json['score'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'case_id': caseId,
        'status': status,
        'score': score,
      };
}

class CaseDetail {
  final String caseId;
  final String status;
  final int? score;
  final String updatedAt;
  final String confidence;
  final List<String> flaggedReasons;
  final String recommendedAction;
  final String reasoningNarrative;
  final Map<String, dynamic> signals;
  final String? rejectionReason;

  CaseDetail({
    required this.caseId,
    required this.status,
    this.score,
    required this.updatedAt,
    required this.confidence,
    required this.flaggedReasons,
    required this.recommendedAction,
    required this.reasoningNarrative,
    required this.signals,
    this.rejectionReason,
  });

  factory CaseDetail.fromJson(Map<String, dynamic> json) {
    return CaseDetail(
      caseId: json['case_id'] as String,
      status: json['status'] as String,
      score: json['score'] as int?,
      updatedAt: json['updated_at'] as String? ?? '',
      confidence: json['confidence'] as String? ?? 'low',
      flaggedReasons: List<String>.from(json['flagged_reasons'] ?? []),
      recommendedAction: json['recommended_action'] as String? ?? 'human_review',
      reasoningNarrative: json['reasoning_narrative'] as String? ?? '',
      signals: Map<String, dynamic>.from(json['signals'] ?? {}),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'case_id': caseId,
        'status': status,
        'score': score,
        'updated_at': updatedAt,
        'confidence': confidence,
        'flagged_reasons': flaggedReasons,
        'recommended_action': recommendedAction,
        'reasoning_narrative': reasoningNarrative,
        'signals': signals,
        'rejection_reason': rejectionReason,
      };
}

class CaseScoreResponse {
  final String caseId;
  final int score;
  final String confidence;
  final List<String> flaggedReasons;
  final String recommendedAction;
  final String reasoningNarrative;
  final Map<String, dynamic> signals;

  CaseScoreResponse({
    required this.caseId,
    required this.score,
    required this.confidence,
    required this.flaggedReasons,
    required this.recommendedAction,
    required this.reasoningNarrative,
    required this.signals,
  });

  factory CaseScoreResponse.fromJson(Map<String, dynamic> json) {
    return CaseScoreResponse(
      caseId: json['case_id'] as String,
      score: json['score'] as int,
      confidence: json['confidence'] as String,
      flaggedReasons: List<String>.from(json['flagged_reasons'] ?? []),
      recommendedAction: json['recommended_action'] as String,
      reasoningNarrative: json['reasoning_narrative'] as String,
      signals: Map<String, dynamic>.from(json['signals'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'case_id': caseId,
        'score': score,
        'confidence': confidence,
        'flagged_reasons': flaggedReasons,
        'recommended_action': recommendedAction,
        'reasoning_narrative': reasoningNarrative,
        'signals': signals,
      };
}

class ExtractionResponse {
  final String documentType;
  final Map<String, dynamic> extractedEntities;
  final List<double> amounts;
  final List<Map<String, dynamic>> transactions;
  final List<String> dates;
  final List<String> inconsistencyFlags;
  final String extractionConfidence;

  ExtractionResponse({
    required this.documentType,
    required this.extractedEntities,
    required this.amounts,
    required this.transactions,
    required this.dates,
    required this.inconsistencyFlags,
    required this.extractionConfidence,
  });

  factory ExtractionResponse.fromJson(Map<String, dynamic> json) {
    return ExtractionResponse(
      documentType: json['document_type'] as String? ?? 'unknown',
      extractedEntities:
          Map<String, dynamic>.from(json['extracted_entities'] ?? {}),
      amounts: (json['amounts'] as List?)
              ?.where((e) => e != null)
              .map((e) => (e as num).toDouble())
              .toList() ??
          [],
      transactions: (json['transactions'] as List?)
              ?.where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      dates: (json['dates'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          [],
      inconsistencyFlags: (json['inconsistency_flags'] as List?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          [],
      extractionConfidence:
          json['extraction_confidence'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'document_type': documentType,
        'extracted_entities': extractedEntities,
        'amounts': amounts,
        'transactions': transactions,
        'dates': dates,
        'inconsistency_flags': inconsistencyFlags,
        'extraction_confidence': extractionConfidence,
      };
}
