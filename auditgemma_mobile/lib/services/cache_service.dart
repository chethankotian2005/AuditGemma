import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/case_model.dart';

/// Offline-first cache layer using SharedPreferences.
///
/// Serializes case list and full case data to JSON strings.
/// On network success, updates cache. On network failure, returns cached data.
class CacheService {
  static const _casesKey = 'auditgemma_cases';
  static const _caseDataPrefix = 'auditgemma_case_';
  static const _caseScorePrefix = 'auditgemma_score_';

  // ── Case List ─────────────────────────────────────────────────
  Future<void> cacheCases(List<CaseListItem> cases) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cases.map((c) => c.toJson()).toList();
    await prefs.setString(_casesKey, jsonEncode(jsonList));
  }

  Future<List<CaseListItem>?> getCachedCases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_casesKey);
    if (raw == null) return null;
    try {
      final List<dynamic> data = jsonDecode(raw);
      return data.map((e) => CaseListItem.fromJson(e)).toList();
    } catch (_) {
      return null;
    }
  }

  // ── Case Detail ───────────────────────────────────────────────
  Future<void> cacheCaseDetail(CaseDetail detail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_caseDataPrefix${detail.caseId}',
      jsonEncode(detail.toJson()),
    );
  }

  Future<CaseDetail?> getCachedCaseDetail(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_caseDataPrefix$caseId');
    if (raw == null) return null;
    try {
      return CaseDetail.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ── Full Score Response (for officer detail view) ─────────────
  Future<void> cacheCaseScore(CaseScoreResponse score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_caseScorePrefix${score.caseId}',
      jsonEncode(score.toJson()),
    );
  }

  Future<CaseScoreResponse?> getCachedCaseScore(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_caseScorePrefix$caseId');
    if (raw == null) return null;
    try {
      return CaseScoreResponse.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (k) =>
              k.startsWith('auditgemma_'),
        );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
