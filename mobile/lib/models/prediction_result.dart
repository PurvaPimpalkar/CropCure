import 'package:flutter/material.dart';



class PredictionResult {
  final int classId;
  final String label;
  final String crop;
  final String disease;
  final bool healthy;
  final double confidence;
  final List<Top3Prediction> top3;
  final bool isMock;
  final TreatmentInfo? treatment;
  /// True when the image passed all crop validation checks.
  /// False when validation failed (non-crop image detected).
  final bool isCrop;

  const PredictionResult({
    required this.classId,
    required this.label,
    required this.crop,
    required this.disease,
    required this.healthy,
    required this.confidence,
    required this.top3,
    required this.isMock,
    this.treatment,
    this.isCrop = true,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      classId:    json['class_id']   as int,
      label:      json['label']      as String,
      crop:       json['crop']       as String,
      disease:    json['disease']    as String,
      healthy:    json['healthy']    as bool,
      confidence: (json['confidence'] as num).toDouble(),
      isMock:     json['mock']       as bool? ?? false,
      top3: (json['top3'] as List<dynamic>)
          .map((e) => Top3Prediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      treatment: json['treatment'] != null
          ? TreatmentInfo.fromJson(json['treatment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Top3Prediction {
  final int classId;
  final String crop;
  final String disease;
  final double confidence;

  const Top3Prediction({
    required this.classId,
    required this.crop,
    required this.disease,
    required this.confidence,
  });

  factory Top3Prediction.fromJson(Map<String, dynamic> json) {
    return Top3Prediction(
      classId:    json['class_id']    as int,
      crop:       json['crop']        as String,
      disease:    json['disease']     as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class TreatmentInfo {
  final String description;
  final String severity;
  final List<MedicineInfo> medicines;
  final String dosage;
  final String applicationMethod;
  final List<String> precautions;
  final String culturalPractices;
  // ── New detailed fields ──────────────────────────────────────────
  final String immediateAction;
  final String chemicalTreatment;
  final String organicAlternative;
  final String farmerTips;

  const TreatmentInfo({
    required this.description,
    required this.severity,
    required this.medicines,
    required this.dosage,
    required this.applicationMethod,
    required this.precautions,
    required this.culturalPractices,
    this.immediateAction    = '',
    this.chemicalTreatment  = '',
    this.organicAlternative = '',
    this.farmerTips         = '',
  });

  factory TreatmentInfo.fromJson(Map<String, dynamic> json) {
    return TreatmentInfo(
      description:        json['description']        as String? ?? '',
      severity:           json['severity']            as String? ?? 'Unknown',
      dosage:             json['dosage']              as String? ?? '',
      applicationMethod:  json['application_method']  as String? ?? '',
      culturalPractices:  json['cultural_practices']  as String? ?? '',
      immediateAction:    json['immediate_action']    as String? ?? '',
      chemicalTreatment:  json['chemical_treatment']  as String? ?? '',
      organicAlternative: json['organic_alternative'] as String? ?? '',
      farmerTips:         json['farmer_tips']         as String? ?? '',
      medicines: (json['medicines'] as List<dynamic>? ?? [])
          .map((e) => MedicineInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      precautions: (json['precautions'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':         return const Color(0xFFD32F2F);
      case 'high':             return const Color(0xFFE64A19);
      case 'moderate to high': return const Color(0xFFF57C00);
      case 'moderate':         return const Color(0xFFF9A825);
      case 'none':             return const Color(0xFF2E7D32);
      default:                 return const Color(0xFF757575);
    }
  }
}

class MedicineInfo {
  final String name;
  final String type;

  const MedicineInfo({required this.name, required this.type});

  factory MedicineInfo.fromJson(Map<String, dynamic> json) {
    return MedicineInfo(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}

class DiseaseListItem {
  final int classId;
  final String label;
  final String crop;
  final String disease;
  final bool healthy;
  final String severity;
  final String description;

  const DiseaseListItem({
    required this.classId,
    required this.label,
    required this.crop,
    required this.disease,
    required this.healthy,
    required this.severity,
    required this.description,
  });

  factory DiseaseListItem.fromJson(Map<String, dynamic> json) {
    return DiseaseListItem(
      classId:     json['class_id']    as int,
      label:       json['label']       as String,
      crop:        json['crop']        as String,
      disease:     json['disease']     as String,
      healthy:     json['healthy']     as bool,
      severity:    json['severity']    as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
    );
  }
}
