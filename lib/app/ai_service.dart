// lib/services/huggingface_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ehr/constants/app_config.dart';

class AiService {
  // New router endpoint for chat completions
  static const String _baseUrl = 'https://router.huggingface.co/v1';
  
  // Medical-focused models available via Inference Providers
  static const Map<String, String> _medicalModels = {
    // For medical text understanding and analysis
    'biomedical': 'microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract',
    
    // For general medical Q&A (using OpenAI-compatible models)
    'medical_qa': 'deepseek-ai/DeepSeek-R1',  // Good for reasoning
    
    // Alternative medical models
    'clinical': 'emilyalsentzer/Bio_ClinicalBERT',
  };

  Future<Map<String, dynamic>> queryMedicalModel({
    required String prompt,
    String modelType = 'medical_qa',
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    try {
      if (AppConfig.huggingFaceApiKey.isEmpty) {
        throw Exception('Hugging Face API key not configured');
      }

      // Get the actual model ID
      final modelId = _medicalModels[modelType] ?? _medicalModels['medical_qa']!;
      
      // Use the router endpoint for chat completions
      final url = Uri.parse('$_baseUrl/chat/completions');

      final headers = {
        'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
        'Content-Type': 'application/json',
      };

      // OpenAI-compatible request format
      final body = jsonEncode({
        'model': '$modelId:fastest',  // Use fastest available provider
        'messages': [
          {
            'role': 'system',
            'content': 'You are a medical AI assistant. Provide accurate, evidence-based medical information. Include disclaimers about consulting healthcare professionals.'
          },
          {
            'role': 'user',
            'content': prompt
          }
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
        'top_p': 0.95,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return _parseChatResponse(response.body);
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Service Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseChatResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      
      final choices = data['choices'] as List;
      if (choices.isEmpty) {
        return {
          'text': 'No response generated',
          'model': 'unknown',
          'confidence': 0.0,
        };
      }
      
      final message = choices[0]['message'];
      final content = message['content'] ?? 'No content';
      
      // Add medical disclaimer if not present
      String finalContent = content;
      if (!content.toLowerCase().contains('consult') && 
          !content.toLowerCase().contains('disclaimer') &&
          !content.toLowerCase().contains('professional')) {
        finalContent += '\n\n*Note: This information is for educational purposes only. Please consult with a healthcare professional for medical advice.*';
      }
      
      return {
        'text': finalContent,
        'model': data['model'] ?? 'medical_ai',
        'confidence': 0.85,  // Default confidence for chat models
      };
    } catch (e) {
      print('Parse Error: $e');
      return {
        'text': 'Error parsing response: $e',
        'model': 'error',
        'confidence': 0.0,
      };
    }
  }

  // Alternative: For non-chat models (like PubMedBERT), use different endpoint
  Future<Map<String, dynamic>> queryBiomedicalModel({
    required String prompt,
    String model = 'microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract',
  }) async {
    try {
      final url = Uri.parse('https://api-inference.huggingface.co/models/$model');
      
      final headers = {
        'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
        'Content-Type': 'application/json',
      };
      
      final body = jsonEncode({
        'inputs': prompt,
      });
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        return {
          'text': 'Biomedical analysis complete. For detailed interpretation, please consult the full response.',
          'model': model,
          'confidence': 0.9,
          'raw_data': jsonDecode(response.body),
        };
      } else {
        // Fallback to chat API if traditional API fails
        return await queryMedicalModel(prompt: prompt, modelType: 'medical_qa');
      }
    } catch (e) {
      // Fallback to chat API
      return await queryMedicalModel(prompt: prompt, modelType: 'medical_qa');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableMedicalModels() async {
    try {
      // Try to get models from the new router API
      final url = Uri.parse('$_baseUrl/models');
      final headers = {
        'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['data'] as List)
            .where((model) => 
                model['id'].toString().contains('medical') ||
                model['id'].toString().contains('bio') ||
                model['id'].toString().contains('clinical'))
            .map((model) => {
              'id': model['id'],
              'name': model['id'].toString().split('/').last,
            })
            .toList();
        
        return models;
      }
      
      // Return default medical models if API call fails
      return [
        {'id': 'deepseek-ai/DeepSeek-R1', 'name': 'DeepSeek-R1 (Medical Reasoning)'},
        {'id': 'microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract', 'name': 'PubMed BERT'},
        {'id': 'emilyalsentzer/Bio_ClinicalBERT', 'name': 'Clinical BERT'},
      ];
    } catch (e) {
      return [
        {'id': 'deepseek-ai/DeepSeek-R1', 'name': 'DeepSeek-R1'},
        {'id': 'microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract', 'name': 'PubMed BERT'},
      ];
    }
  }
}