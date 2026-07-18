import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// State management for case list and case data.
/// Implements offline-first: network → cache update; on failure → cached data.
class CaseProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final CacheService _cache = CacheService();

  List<CaseListItem> _cases = [];
  final Map<String, CaseScoreResponse> _scoreCache = {};
  bool _isLoading = false;
  String? _error;

  List<CaseListItem> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CaseScoreResponse? getCachedScore(String caseId) => _scoreCache[caseId];

  /// Fetch cases: try network, update cache. On failure, use cache.
  Future<void> fetchCases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cases = await _api.getCases();
      await _cache.cacheCases(_cases);
    } catch (e) {
      // Try cache fallback
      final cached = await _cache.getCachedCases();
      if (cached != null) {
        _cases = cached;
        _error = 'Offline — showing cached data';
      } else {
        _error = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Submit a case for scoring (SME flow).
  Future<CaseScoreResponse?> submitCase(
    List<Map<String, dynamic>> documents,
    String businessContext,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.scoreCase(documents, businessContext);
      _scoreCache[result.caseId] = result;
      await _cache.cacheCaseScore(result);

      // Add to local case list
      _cases.insert(
        0,
        CaseListItem(
          caseId: result.caseId,
          status: 'pending',
          score: result.score,
        ),
      );
      await _cache.cacheCases(_cases);

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update case status (officer swipe action).
  Future<bool> updateStatus(String caseId, String status) async {
    try {
      await _api.updateCaseStatus(caseId, status);

      // Update local state
      final idx = _cases.indexWhere((c) => c.caseId == caseId);
      if (idx >= 0) {
        _cases[idx] = CaseListItem(
          caseId: caseId,
          status: status,
          score: _cases[idx].score,
        );
        await _cache.cacheCases(_cases);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove a case from the local list (after swipe dismiss).
  void removeCaseLocally(String caseId) {
    _cases.removeWhere((c) => c.caseId == caseId);
    notifyListeners();
  }

  /// Store a full score response in the local cache.
  void cacheScoreResponse(CaseScoreResponse response) {
    _scoreCache[response.caseId] = response;
    _cache.cacheCaseScore(response);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
