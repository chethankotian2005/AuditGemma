/// Conversation model for Stage 4 Gemma Q&A.

class ConversationTurn {
  final String role; // 'officer' or 'gemma'
  final String content;

  ConversationTurn({required this.role, required this.content});

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    return ConversationTurn(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}
