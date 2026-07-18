import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/case_model.dart';
import '../models/conversation_model.dart';

/// HTTP client wrapping all backend API endpoints.
///
/// Uses 10.0.2.2 for Android emulator → host loopback.
/// Configure [baseUrl] via environment or constructor for production.
class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api/v1')});

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      // Ignore if FirebaseAuth is not initialized
    }
    return headers;
  }

  // ── POST /extract ─────────────────────────────────────────────
  /// Upload a document image for Stage 1 Gemma extraction.
  Future<ExtractionResponse> extractDocument(XFile file) async {
    final uri = Uri.parse('$baseUrl/extract');
    final request = http.MultipartRequest('POST', uri);
    
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: file.name),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _checkResponse(response);
    return ExtractionResponse.fromJson(jsonDecode(response.body));
  }

  // ── POST /score ───────────────────────────────────────────────
  /// Submit documents + business context + PAN for Stage 2+3 scoring.
  Future<CaseScoreResponse> scoreCase(
    List<Map<String, dynamic>> documents,
    String businessContext, {
    String panNumber = "",
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/score'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'documents': documents,
        'business_context': businessContext,
        'pan_number': panNumber,
      }),
    );
    _checkResponse(response);
    return CaseScoreResponse.fromJson(jsonDecode(response.body));
  }

  // ── POST /converse ────────────────────────────────────────────
  /// Stage 4: ask the conversational audit agent a question.
  Future<String> converse(
    String caseId,
    String question,
    List<ConversationTurn> history,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/converse'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'case_id': caseId,
        'question': question,
        'conversation_history': history.map((t) => t.toJson()).toList(),
      }),
    );
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return data['answer'] as String;
  }

  // ── GET /cases ────────────────────────────────────────────────
  /// Fetch all cases for the officer queue.
  Future<List<CaseListItem>> getCases() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cases'),
      headers: await _getHeaders(),
    );
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => CaseListItem.fromJson(e)).toList();
  }

  // ── GET /case/{id} ────────────────────────────────────────────
  Future<CaseDetail> getCase(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/case/${Uri.encodeComponent(id)}'),
      headers: await _getHeaders(),
    );
    _checkResponse(response);
    return CaseDetail.fromJson(jsonDecode(response.body));
  }

  // ── PATCH /case/{id}/status?status=... ────────────────────────
  Future<void> updateCaseStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/case/${Uri.encodeComponent(id)}/status?status=${Uri.encodeComponent(status)}',
      ),
      headers: await _getHeaders(),
    );
    _checkResponse(response);
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String detail = response.reasonPhrase ?? 'Unknown error';
      try {
        final body = jsonDecode(response.body);
        detail = body['detail']?.toString() ?? detail;
      } catch (_) {}
      throw ApiException(response.statusCode, detail);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String detail;

  ApiException(this.statusCode, this.detail);

  @override
  String toString() => 'ApiException($statusCode): $detail';
}
