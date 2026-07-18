import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';

/// State management for the Gemma Q&A conversation.
class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<ConversationTurn> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ConversationTurn> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Send a question to the conversational audit agent.
  Future<void> sendQuestion(String caseId, String question) async {
    // Add officer message immediately
    _messages.add(ConversationTurn(role: 'officer', content: question));
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final answer = await _api.converse(
        caseId,
        question,
        // Send history without the just-added officer turn
        _messages.sublist(0, _messages.length - 1),
      );
      _messages.add(ConversationTurn(role: 'gemma', content: answer));
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
