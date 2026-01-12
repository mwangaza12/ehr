// lib/services/file_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

class MedicalFile {
  final String path;
  final String name;
  final int size;
  final String type;
  final DateTime uploadedAt;

  MedicalFile({
    required this.path,
    required this.name,
    required this.size,
    required this.type,
    required this.uploadedAt,
  });
}

class FileUploadService {
  final ImagePicker _imagePicker = ImagePicker();
  
  Future<MedicalFile?> pickImage() async {
    final permission = await Permission.photos.request();
    if (!permission.isGranted) return null;
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      
      if (image != null) {
        return await _saveFile(File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }
  
  Future<MedicalFile?> pickDocument() async {
    final permission = await Permission.storage.request();
    if (!permission.isGranted) return null;
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final tempFile = File(file.path!);
        return await _saveFile(tempFile);
      }
    } catch (e) {
      print('Error picking document: $e');
    }
    return null;
  }
  
  Future<MedicalFile?> takePhoto() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) return null;
    
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
      );
      
      if (photo != null) {
        return await _saveFile(File(photo.path));
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
    return null;
  }
  
  Future<MedicalFile> _saveFile(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final medicalDir = Directory(p.join(appDir.path, 'medical_files'));
    
    if (!await medicalDir.exists()) {
      await medicalDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(file.path);
    final newFileName = 'medical_file_$timestamp$extension';
    final newPath = p.join(medicalDir.path, newFileName);
    
    await file.copy(newPath);
    
    final newFile = File(newPath);
    final mimeType = lookupMimeType(newPath) ?? 'application/octet-stream';
    
    return MedicalFile(
      path: newPath,
      name: newFileName,
      size: await newFile.length(),
      type: mimeType,
      uploadedAt: DateTime.now(),
    );
  }
  
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
  
  Future<List<MedicalFile>> getUploadedFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    final medicalDir = Directory(p.join(appDir.path, 'medical_files'));
    
    if (!await medicalDir.exists()) {
      return [];
    }
    
    final files = await medicalDir.list().toList();
    final List<MedicalFile> medicalFiles = [];
    
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        
        medicalFiles.add(MedicalFile(
          path: file.path,
          name: p.basename(file.path),
          size: stat.size,
          type: mimeType,
          uploadedAt: stat.modified,
        ));
      }
    }
    
    medicalFiles.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return medicalFiles;
  }
  
  Future<String> extractTextFromFile(MedicalFile file) async {
    // For now, return placeholder text
    // In production, integrate with OCR libraries like:
    // - firebase_ml_vision for image text recognition
    // - pdf_text for PDF extraction
    // - tesseract_ocr for more advanced OCR
    
    if (file.type.startsWith('image/')) {
      return '[Image file: ${file.name}]\nMedical image uploaded for reference.';
    } else if (file.type == 'application/pdf') {
      return '[PDF document: ${file.name}]\nMedical document uploaded for analysis.';
    } else if (file.type == 'text/plain') {
      final content = await File(file.path).readAsString();
      return content;
    } else {
      return '[File: ${file.name}]\nMedical file uploaded for reference.';
    }
  }
}