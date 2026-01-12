import 'package:ehr/app/ai_service.dart';
import 'package:ehr/model/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:ehr/constants/app_colors.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ehr/services/voice_service.dart';
import 'package:ehr/services/file_upload_service.dart';
import 'package:ehr/services/chat_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final AiService _aiService = AiService(); // Changed from HuggingFaceService
  final VoiceService _voiceService = VoiceService();
  final FileUploadService _fileService = FileUploadService();
  final ChatStorageService _chatStorage = ChatStorageService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  String _selectedModel = 'pubmedbert';
  MedicalFile? _attachedFile;
  
  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _checkPermissions();
    _initializeVoiceService();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.microphone,
      Permission.storage,
      Permission.camera,
      Permission.photos,
    ].request();
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await _chatStorage.getMessages(limit: 50);
      
      if (messages.isEmpty) {
        // Add welcome message
        final welcomeMessage = ChatMessage(
          text: "Hello! I'm your AI medical assistant. I can help with:\n• Medical condition analysis\n• Drug interaction checks\n• Clinical decision support\n• Medical literature queries\n• Treatment recommendations\n\nPlease note: I provide general medical information and should not replace professional medical advice.",
          isUser: false,
          timestamp: DateTime.now(),
          modelUsed: 'welcome',
          confidence: 1.0,
        );
        
        setState(() {
          _messages.add(welcomeMessage);
        });
        await _chatStorage.insertMessage(welcomeMessage);
      } else {
        setState(() {
          _messages = messages;
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _attachedFile == null) return;

    String fullMessage = message;
    if (_attachedFile != null) {
      final fileText = await _fileService.extractTextFromFile(_attachedFile!);
      fullMessage = '$message\n\n[Attached file: ${_attachedFile!.name}]\n$fileText';
    }

    final userMessage = ChatMessage(
      text: fullMessage,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentPath: _attachedFile?.path,
      attachmentType: _attachedFile?.type,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _attachedFile = null;
    });

    await _chatStorage.insertMessage(userMessage);
    _messageController.clear();
    _focusNode.unfocus();
    
    _scrollToBottom();

    try {
      final aiResponse = await _aiService.queryMedicalModel(
        prompt: fullMessage,
        modelType: _selectedModel,
      );

      final aiMessage = ChatMessage(
        text: aiResponse['text'] ?? 'No response received',
        isUser: false,
        timestamp: DateTime.now(),
        modelUsed: aiResponse['model'],
        confidence: aiResponse['confidence'],
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      await _chatStorage.insertMessage(aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        modelUsed: 'error',
        confidence: 0.0,
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });

      await _chatStorage.insertMessage(errorMessage);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleVoiceRecording() async {
    if (_isRecording) {
      await _voiceService.stopListening();
      setState(() => _isRecording = false);
    } else {
      setState(() => _isRecording = true);
      
      final result = await _voiceService.startListening(
        onResult: (text) {
          if (text.isNotEmpty && mounted) {
            setState(() {
              _messageController.text = text;
            });
          }
        },
        onListeningStarted: () {
          if (mounted) {
            setState(() => _isRecording = true);
          }
        },
        onListeningStopped: () {
          if (mounted) {
            setState(() => _isRecording = false);
          }
        },
      );
      
      if (result != null && result.isNotEmpty && mounted) {
        _messageController.text = result;
      }
    }
  }

  Future<void> _attachFile() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
                  title: const Text('Upload Document'),
                  onTap: () => Navigator.pop(context, 'document'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    MedicalFile? file;
    switch (action) {
      case 'gallery':
        file = await _fileService.pickImage();
        break;
      case 'camera':
        file = await _fileService.takePhoto();
        break;
      case 'document':
        file = await _fileService.pickDocument();
        break;
    }

    if (file != null && mounted) {
      setState(() {
        _attachedFile = file;
      });
    }
  }

  void _showModelSelector() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Medical AI Model',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Using Hugging Face Inference Providers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildModelOptions(setState),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Confirm Selection'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

List<Widget> _buildModelOptions(StateSetter setState) {
  final models = [
    {
      'id': 'medical_qa', 
      'name': 'Medical Q&A Model', 
      'desc': 'Best for patient questions and medical explanations',
      'provider': 'DeepSeek-R1 via Router'
    },
    {
      'id': 'biomedical', 
      'name': 'Biomedical Analysis', 
      'desc': 'PubMed literature and research analysis',
      'provider': 'PubMed BERT'
    },
    {
      'id': 'clinical', 
      'name': 'Clinical Text', 
      'desc': 'Clinical note analysis and terminology',
      'provider': 'Clinical BERT'
    },
  ];

  return models.map((model) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedModel == model['id'] ? AppColors.primaryDark : Colors.grey.shade200,
          width: _selectedModel == model['id'] ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _selectedModel == model['id'] 
                ? AppColors.primaryDark.withOpacity(0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.psychology,
            color: _selectedModel == model['id'] 
                ? AppColors.primaryDark 
                : Colors.grey,
          ),
        ),
        title: Text(
          model['name']!,
          style: TextStyle(
            fontWeight: _selectedModel == model['id'] 
                ? FontWeight.bold 
                : FontWeight.normal,
            color: const Color(0xFF2D3142),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model['desc']!),
            const SizedBox(height: 4),
            Text(
              'Provider: ${model['provider']}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: _selectedModel == model['id']
            ? const Icon(Icons.check_circle, color: AppColors.primaryDark)
            : null,
        onTap: () => setState(() => _selectedModel = model['id']!),
      ),
    );
  }).toList();
}
  void _showChatHistory() async {
    final count = await _chatStorage.getMessageCount();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chat History ($count messages)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear History'),
                          content: const Text('Are you sure you want to delete all chat history?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _chatStorage.clearChatHistory();
                                setState(() => _messages = []);
                                Navigator.pop(context);
                                Navigator.pop(context);
                                await _loadChatHistory();
                              },
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ListTile(
                      leading: Icon(
                        message.isUser ? Icons.person : Icons.psychology,
                        color: message.isUser ? AppColors.primaryDark : const Color(0xFF4ECDC4),
                      ),
                      title: Text(
                        message.text.length > 50
                            ? '${message.text.substring(0, 50)}...'
                            : message.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatTime(message.timestamp)} • ${message.modelUsed ?? 'AI'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: message.attachmentPath != null
                          ? const Icon(Icons.attach_file, size: 16)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 1,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical AI Assistant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            Text(
              'Model: ${_selectedModel.toUpperCase()}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF2D3142)),
            onPressed: _showChatHistory,
          ),
          IconButton(
            icon: const Icon(Icons.model_training, color: Color(0xFF2D3142)),
            onPressed: _showModelSelector,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF2D3142)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Medical AI Assistant'),
                  content: const Text(
                    'This assistant uses advanced medical AI models to provide general medical information.\n\nFeatures:\n• Real medical model integration\n• Voice input capability\n• File upload support\n• Chat history storage\n• Multiple AI models\n\nNote: Always verify with licensed healthcare providers.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Model Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isLoading 
                      ? 'Processing with $_selectedModel...' 
                      : '$_selectedModel Active • Secure • Medical',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),

          // Attached File Preview
          if (_attachedFile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  top: BorderSide(color: Colors.blue.shade100),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(_attachedFile!.type),
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedFile!.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(_attachedFile!.size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() => _attachedFile = null);
                    },
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice Input
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop_circle : Icons.mic,
                    color: _isRecording ? Colors.red : AppColors.primaryDark,
                  ),
                  onPressed: _toggleVoiceRecording,
                ),
                
                // File Attachment
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.primaryDark),
                  onPressed: _attachFile,
                ),
                
                // Text Input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Type your medical question...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            maxLines: 3,
                            minLines: 1,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Send Button
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: message.isUser
                  ? AppColors.primaryDark.withOpacity(0.1)
                  : const Color(0xFF4ECDC4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              message.isUser ? Icons.person : Icons.psychology,
              color: message.isUser ? AppColors.primaryDark : const Color(0xFF4ECDC4),
              size: 16,
            ),
          ),
          
          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      message.isUser ? 'You' : 'Medical AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: message.isUser ? AppColors.primaryDark : const Color(0xFF4ECDC4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${_formatTime(message.timestamp)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    if (message.modelUsed != null && !message.isUser)
                      Text(
                        ' • ${message.modelUsed}',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF4ECDC4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 2),
                
                // Message Bubble
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppColors.primaryDark.withOpacity(0.1)
                        : const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                            height: 1.4,
                          ),
                          strong: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                            fontWeight: FontWeight.bold,
                          ),
                          listBullet: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                      
                      // Attachment preview
                      if (message.attachmentPath != null)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(message.attachmentType ?? ''),
                                color: Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Attached file',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: Color(0xFF4ECDC4),
              size: 16,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypingDot(),
                      const SizedBox(width: 4),
                      _buildTypingDot(),
                      const SizedBox(width: 4),
                      _buildTypingDot(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF4ECDC4),
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else if (mimeType.startsWith('text/')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }
}