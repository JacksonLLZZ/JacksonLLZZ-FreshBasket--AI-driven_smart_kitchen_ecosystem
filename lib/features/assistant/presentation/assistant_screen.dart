import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../data/chat_message.dart';
import '../domain/assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final AssistantService _assistantService = AssistantService();
  bool _isLoading = false;
  bool _isStreaming = false;
  StreamSubscription<String>? _streamSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your kitchen AI assistant. I can help you with recipe suggestions, ingredient analysis, meal planning, and food management. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    // Scroll to bottom after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Cancel any existing subscription
    await _cancelStreamSubscription();

    setState(() {
      // Add user message
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _textController.clear();
      _isLoading = true;
      _isStreaming = true;
      // Add empty AI response placeholder
      _messages.add(
        ChatMessage(text: '', isUser: false, timestamp: DateTime.now()),
      );
    });

    // Scroll to show new message
    _scrollToBottom();

    try {
      final responseStream = _assistantService.getResponseStream(text);
      _streamSubscription = responseStream.listen(
        (chunk) {
          setState(() {
            // Update the last message (which should be the AI response)
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages.last = ChatMessage(
                text: _messages.last.text + chunk,
                isUser: false,
                timestamp: _messages.last.timestamp,
              );
            }
          });
          _scrollToBottom();
        },
        onError: (error) {
          _handleStreamError(error);
        },
        onDone: () {
          setState(() {
            _isLoading = false;
            _isStreaming = false;
          });
          _scrollToBottom();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _handleStreamError(e);
    }
  }

  Future<void> _cancelStreamSubscription() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  void _handleStreamError(dynamic error) {
    setState(() {
      _isLoading = false;
      _isStreaming = false;

      // Update the last message (which should be the AI response placeholder)
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.last = ChatMessage(
          text: _getUserFriendlyErrorMessage(error),
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        // Add error message if no AI placeholder exists
        _messages.add(
          ChatMessage(
            text: _getUserFriendlyErrorMessage(error),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "AI Assistant",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, theme);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Ask me about recipes, ingredients...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? theme.colorScheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 13),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString();
    final lowerErrorStr = errorStr.toLowerCase();

    if (lowerErrorStr.contains('api key not configured') ||
        lowerErrorStr.contains('gemini api key not configured')) {
      return "Please configure the Gemini API key in Account Settings.\n\n Steps：\n1. Go to account setting page\n2. Locate Advanced Options\n3. Click Gemini API Configuration\n4. Enter your API key and save";
    } else if (lowerErrorStr.contains('invalid api key') ||
        lowerErrorStr.contains('api_key_invalid')) {
      return "Invalid API key. Please check:：\n1. Whether the key was copied correctly\n2. Whether the key is enabled\n3. Whether the key has sufficient quota\n\nYou can update the API key in Profile settings.";
    } else if (lowerErrorStr.contains('network error') ||
        lowerErrorStr.contains('network')) {
      return "Network connection failed. Please check:\n1. Internet Connection\n2. Firewall settings\n3. Proxy configuration\n\nPlease try again later.";
    } else if (lowerErrorStr.contains('api quota exceeded') ||
        lowerErrorStr.contains('quota')) {
      return "API quota has been exceeded. Please:\n1. Check Usage\n2. reset quota\n3. Update API plan";
    } else if (lowerErrorStr.contains('timeout') ||
        lowerErrorStr.contains('timed out')) {
      return "Request timed out\n1. Check network connection\n2. Check API service availability \n3. Try again later";
    } else {
      // 提取主要错误信息，避免显示过多技术细节
      final parts = errorStr.split(':');
      final lastPart = parts.isNotEmpty ? parts.last.trim() : errorStr;
      return "The AI service is temporarily unavailable.$lastPart\n\nPlease try again later or check your network connection.";
    }
  }
}
