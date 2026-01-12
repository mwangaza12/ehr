
// lib/constants/app_config.dart
class AppConfig {
  // Your Hugging Face API key
  static const String huggingFaceApiKey = 'hf_AXuzQuDZmmDWqHuAisdKzENzpcKDHnFFi';
  
  // Default model type for medical queries
  static const String defaultMedicalModel = 'medical_qa';
  
  // Features
  static const bool enableVoiceInput = true;
  static const bool enableFileUpload = true;
  static const int maxChatHistory = 100;
  
  // API Configuration
  static const String huggingFaceApiBase = 'https://router.huggingface.co/v1';
}