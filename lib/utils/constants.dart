    import 'dart:convert';
import 'dart:html' as html;
import '../models/whisperfire_models.dart';

class ApiService {
  // ✅ CORRECT Railway URL
  static const String baseUrl = 'https://suss-ai-backend-only-production-c323.up.railway.app';

  // 🚀 WHISPERFIRE API CALL - Matches backend exactly
  static Future<WhisperfireResponse> analyzeMessageWhisperfire({
    required String inputText,
    required String contentType,
    required String analysisGoal,
    required String tone,
    String? relationship,
    String? personName,
    String? stylePreference,
  }) async {
    print('🚀 ApiService: Making API call...');
    print('🚀 URL: $baseUrl/api/v1/analyze');
    print('🚀 Analysis goal: $analysisGoal');
    
    try {
      // Process input text
      dynamic inputData;
      if (analysisGoal == 'pattern_profiling') {
        inputData = inputText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      } else {
        inputData = inputText;
      }
      
      // Build request body - EXACTLY matches backend expectations
      final body = {
        'input_text': inputData,
        'content_type': contentType,
        'analysis_goal': analysisGoal,
        'tone': tone,
        'relationship': relationship ?? 'Partner',
      };
      
      // Add optional fields only if provided
      if (personName != null && personName.isNotEmpty) {
        body['person_name'] = personName;
      }
      if (stylePreference != null && stylePreference.isNotEmpty) {
        body['style_preference'] = stylePreference;
      }
      
      print('📤 Sending request body: ${jsonEncode(body)}');
      
      // Use dart:html for web compatibility
      final request = html.HttpRequest();
      request.open('POST', '$baseUrl/api/v1/analyze');
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Accept', 'application/json');
      
      // Send request
      request.send(jsonEncode(body));
      
      // Wait for response
      await request.onLoad.first;
      
      print('📥 Response Status: ${request.status}');
      print('📥 Response Body: ${request.responseText}');
      
      if (request.status == 200) {
        final jsonData = jsonDecode(request.responseText!);
        print('📊 Parsed JSON: $jsonData');
        
        // Extract data from the response
        final data = jsonData['data'];
        print('📊 Response data: $data');
        
        // Create WhisperfireResponse based on analysis goal
        WhisperfireResponse response;
        
        if (analysisGoal == 'instant_scan') {
          response = WhisperfireResponse(
            scanResult: WhisperfireScanResult.fromMap(data),
            viralPotential: data['confidence_metrics']?['viral_potential'] ?? 75,
            confidenceLevel: 85,
            empowermentScore: 90,
            safetyPriority: 'MODERATE',
            psychologicalAccuracy: 85,
          );
        } else if (analysisGoal == 'pattern_profiling') {
          response = WhisperfireResponse(
            patternResult: WhisperfirePatternResult.fromMap(data),
            viralPotential: data['confidence_metrics']?['viral_potential'] ?? 85,
            confidenceLevel: 90,
            empowermentScore: 95,
            safetyPriority: data['risk_assessment']?['intervention_urgency'] ?? 'MODERATE',
            psychologicalAccuracy: 90,
          );
        } else {
          // Fallback for other analysis goals
          response = WhisperfireResponse(
            viralPotential: 50,
            confidenceLevel: 70,
            empowermentScore: 60,
            safetyPriority: 'MODERATE',
            psychologicalAccuracy: 70,
          );
        }
        
        print('✅ Successfully created WhisperfireResponse');
        return response;
        
      } else {
        print('❌ HTTP Error ${request.status}');
        print('❌ Response body: ${request.responseText}');
        
        // Try to parse error message
        try {
          final errorData = jsonDecode(request.responseText!);
          throw Exception('API Error: ${errorData['error'] ?? 'Unknown error'}');
        } catch (e) {
          throw Exception('HTTP ${request.status}: ${request.responseText}');
        }
      }
      
    } catch (e) {
      print('❌ ApiService error: $e');
      print('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // 🧪 Simple health check method
  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing connection to: $baseUrl/api/v1/health');
      
      final request = html.HttpRequest();
      request.open('GET', '$baseUrl/api/v1/health');
      request.setRequestHeader('Accept', 'application/json');
      
      request.send();
      await request.onLoad.first;
      
      print('🔍 Health check status: ${request.status}');
      print('🔍 Health check response: ${request.responseText}');
      
      return request.status == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}
