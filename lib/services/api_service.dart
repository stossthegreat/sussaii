import 'dart:convert';
import 'dart:html' as html;
import '../models/analysis_result.dart';
import '../models/whisperfire_models.dart';

class ApiService {
  // 🚀 RAILWAY BACKEND URL
  static const String baseUrl = 'https://suss-ai-backend-only-production-c323.up.railway.app/api/v1';
  // static const String baseUrl = 'http://127.0.0.1:3000/api/v1'; // For local development

  // Force DeepSeek everywhere (backend will fall back if unavailable)
  static const String _preferredModel = 'deepseek-v3';

  // 🧠 LEGACY SYSTEM (for backward compatibility)
  static Future<AnalysisResult> analyzeMessage({
    required String inputText,
    required String contentType,
    required String analysisGoal,
    required String tone,
    bool comebackEnabled = true,
    String? relationship,
  }) async {
    print('🚀 ApiService: Making LEGACY API call...');
    print('🚀 ApiService: URL: $baseUrl/analyze');
    print('🚀 ApiService: Analysis goal: $analysisGoal');

    try {
      // For pattern analysis, split + enforce 2–10 messages
      dynamic inputData;
      if (analysisGoal == 'pattern_analysis') {
        final lines = inputText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        if (lines.length < 2) {
          throw Exception('Pattern analysis requires at least 2 messages.');
        }
        final trimmed = lines.take(10).toList();
        inputData = trimmed;
      } else {
        inputData = inputText.trim();
      }

      final body = <String, dynamic>{
        'input_text': inputData,
        'content_type': contentType,
        'analysis_goal': analysisGoal,
        'tone': tone,
        'comeback_enabled': comebackEnabled,
        if (relationship != null && relationship.isNotEmpty) 'relationship': relationship,
        // 🔥 Force DeepSeek on backend
        'preferred_model': _preferredModel,
      };

      print('📤 ApiService: Sending LEGACY request: ${jsonEncode(body)}');

      final request = html.HttpRequest();
      request.open('POST', '$baseUrl/analyze');
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Accept', 'application/json');
      request.send(jsonEncode(body));
      await request.onLoad.first;

      print('📥 ApiService: Received LEGACY response: ${request.responseText}');
      print('📊 ApiService: Status code: ${request.status}');

      if (request.status == 200) {
        final jsonData = jsonDecode(request.responseText!);
        final data = jsonData['data'];
        final mappedData = _mapLegacyResponseToFlutterModel(data, analysisGoal);
        return AnalysisResult.fromMap(mappedData);
      } else {
        final errorData = jsonDecode(request.responseText!);
        throw Exception('API Error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ ApiService: LEGACY API call failed: $e');
      rethrow;
    }
  }

  // 🚀 WHISPERFIRE SYSTEM (new system)
  static Future<WhisperfireResponse> analyzeMessageWhisperfire({
    required String inputText,
    required String contentType,
    required String analysisGoal,
    required String tone,
    String? relationship,
    String? personName,
    String? stylePreference,
  }) async {
    print('🚀 ApiService: Making WHISPERFIRE API call...');
    print('🚀 ApiService: URL: $baseUrl/analyze');
    print('🚀 ApiService: Analysis goal: $analysisGoal');

    try {
      // Pattern profiling: enforce 2–10 messages
      dynamic inputData;
      if (analysisGoal == 'pattern_profiling') {
        final lines = inputText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        if (lines.length < 2) {
          throw Exception('Pattern profiling requires 2–10 messages.');
        }
        inputData = lines.take(10).toList();
      } else {
        inputData = inputText.trim();
      }

      final body = <String, dynamic>{
        'input_text': inputData,
        'content_type': contentType,
        'analysis_goal': analysisGoal,
        'tone': tone,
        if (relationship != null && relationship.isNotEmpty) 'relationship': relationship,
        if (personName != null && personName.isNotEmpty) 'person_name': personName,
        // If you still send stylePreference from older UI, we pass it through; backend can ignore.
        if (stylePreference != null && stylePreference.isNotEmpty) 'style_preference': stylePreference,
        // 🔥 Force DeepSeek on backend
        'preferred_model': _preferredModel,
      };

      print('📤 ApiService: Sending WHISPERFIRE request: ${jsonEncode(body)}');

      final request = html.HttpRequest();
      request.open('POST', '$baseUrl/analyze');
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Accept', 'application/json');
      request.send(jsonEncode(body));
      await request.onLoad.first;

      print('📥 ApiService: Received WHISPERFIRE response: ${request.responseText}');
      print('📊 ApiService: Status code: ${request.status}');

      if (request.status == 200) {
        final jsonData = jsonDecode(request.responseText!);
        final data = jsonData['data'];
        final whisperfireData = _mapWhisperfireResponse(data, analysisGoal);
        return whisperfireData;
      } else {
        final errorData = jsonDecode(request.responseText!);
        throw Exception('API Error: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ ApiService: WHISPERFIRE API call failed: $e');
      rethrow;
    }
  }

  // 🧠 LEGACY RESPONSE MAPPING
  static Map<String, dynamic> _mapLegacyResponseToFlutterModel(Map<String, dynamic> data, String analysisGoal) {
    if (analysisGoal == 'pattern_analysis') {
      return {
        'headline': data['suss_verdict'] ?? 'Pattern Analysis Complete',
        'motive': data['pattern_detected'] ?? 'Unknown pattern',
        'redFlag': _calculatePatternRiskScore(data),
        'redFlagTier': _getRedFlagTier(_calculatePatternRiskScore(data)),
        'feeling': data['emotional_effect'] ?? 'Neutral',
        'subtext': data['pattern_summary'] ?? 'No pattern detected',
        'comeback': data['comeback'] ?? '',
        'pattern': data['archetype'] ?? 'Unknown',
        'lieDetector': {
          'verdict': data['suss_verdict'] ?? 'Pattern analysis complete',
          'isHonest': _calculatePatternRiskScore(data) < 50,
          'cues': [data['pattern_summary'] ?? 'No cues detected'],
          'gutCheck': data['suss_verdict'] ?? 'Pattern analysis complete',
        }
      };
    } else {
      return {
        'headline': data['suss_verdict'] ?? 'Analysis Complete',
        'motive': data['behavior_pattern'] ?? 'Unknown pattern',
        'redFlag': data['lie_risk_score'] ?? 0,
        'redFlagTier': _getRedFlagTier(data['lie_risk_score'] ?? 0),
        'feeling': _getFeelingFromScore(data['lie_risk_score'] ?? 0),
        'subtext': data['subtext_summary'] ?? 'No subtext detected',
        'comeback': data['comeback'] ?? '',
        'pattern': data['behavior_pattern'] ?? 'Unknown',
        'lieDetector': {
          'verdict': data['suss_verdict'] ?? 'Analysis complete',
          'isHonest': (data['lie_risk_score'] ?? 0) < 50,
          'cues': List<String>.from(data['evidence'] ?? []),
          'gutCheck': data['suss_verdict'] ?? 'Analysis complete',
        }
      };
    }
  }

  // 🚀 WHISPERFIRE RESPONSE MAPPING
  static WhisperfireResponse _mapWhisperfireResponse(Map<String, dynamic> data, String analysisGoal) {
    switch (analysisGoal) {
      case 'instant_scan':
        final scanResult = WhisperfireScanResult.fromMap(data);
        return WhisperfireResponse(
          scanResult: scanResult,
          viralPotential: scanResult.confidenceMetrics.viralPotential,
          confidenceLevel: scanResult.confidenceMetrics.viralPotential,
          empowermentScore: 85,
          safetyPriority: _getSafetyPriorityFromScan(scanResult),
          psychologicalAccuracy: scanResult.confidenceMetrics.viralPotential,
        );

      case 'comeback_generation':
        final comebackResult = WhisperfireComebackResult.fromMap(data);
        return WhisperfireResponse(
          comebackResult: comebackResult,
          viralPotential: comebackResult.viralMetrics.viralFactor,
          confidenceLevel: comebackResult.viralMetrics.powerLevel,
          empowermentScore: comebackResult.viralMetrics.powerLevel,
          safetyPriority: comebackResult.safetyCheck.riskLevel,
          psychologicalAccuracy: 80,
        );

      case 'pattern_profiling':
        final patternResult = WhisperfirePatternResult.fromMap(data);
        return WhisperfireResponse(
          patternResult: patternResult,
          viralPotential: patternResult.confidenceMetrics.viralPotential,
          confidenceLevel: patternResult.confidenceMetrics.viralPotential,
          empowermentScore: 90,
          safetyPriority: patternResult.riskAssessment.interventionUrgency,
          psychologicalAccuracy: patternResult.confidenceMetrics.viralPotential,
        );

      default:
        return WhisperfireResponse();
    }
  }

  // 🛡️ SAFETY PRIORITY CALCULATION
  static String _getSafetyPriorityFromScan(WhisperfireScanResult scanResult) {
    final redFlagIntensity = scanResult.psychologicalScan.redFlagIntensity;
    final relationshipToxicity = scanResult.psychologicalScan.relationshipToxicity;

    if (redFlagIntensity >= 80 || relationshipToxicity >= 80) return 'CRITICAL';
    if (redFlagIntensity >= 60 || relationshipToxicity >= 60) return 'HIGH';
    if (redFlagIntensity >= 40 || relationshipToxicity >= 40) return 'MODERATE';
    return 'LOW';
  }

  // Helper method to calculate risk score for pattern analysis
  static int _calculatePatternRiskScore(Map<String, dynamic> data) {
    final pattern = data['pattern_detected']?.toString().toLowerCase() ?? '';
    final archetype = data['archetype']?.toString().toLowerCase() ?? '';

    if (pattern.contains('manipulation') || archetype.contains('manipulator')) return 85;
    if (pattern.contains('evasion') || archetype.contains('evasive')) return 75;
    if (pattern.contains('mixed') || pattern.contains('confusion')) return 65;
    if (pattern.contains('distance') || pattern.contains('avoidance')) return 55;
    return 45; // Default moderate risk
  }

  static String _getRedFlagTier(int score) {
    if (score >= 80) return 'Critical';
    if (score >= 60) return 'High';
    if (score >= 40) return 'Medium';
    if (score >= 20) return 'Low';
    return 'Safe';
  }

  static String _getFeelingFromScore(int score) {
    if (score >= 80) return 'Extremely suspicious';
    if (score >= 60) return 'Very suspicious';
    if (score >= 40) return 'Somewhat suspicious';
    if (score >= 20) return 'Slightly suspicious';
    return 'Neutral';
  }
}
