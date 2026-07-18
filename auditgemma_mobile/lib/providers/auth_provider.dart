import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { sme, officer }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  UserRole? _currentRole;
  bool _isLoading = true;

  AuthProvider() {
    _initAuthListener();
  }

  User? get user => _user;
  UserRole? get currentRole => _currentRole;
  bool get isLoggedIn => _user != null && _currentRole != null;
  bool get isSme => _currentRole == UserRole.sme;
  bool get isOfficer => _currentRole == UserRole.officer;
  bool get isLoading => _isLoading;

  void _initAuthListener() async {
    final prefs = await SharedPreferences.getInstance();
    
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        // Restore role from local cache for hackathon simplicity
        final savedRole = prefs.getString('user_role');
        if (savedRole == 'officer') {
          _currentRole = UserRole.officer;
        } else {
          _currentRole = UserRole.sme;
        }
      } else {
        _currentRole = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password, UserRole role) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role == UserRole.officer ? 'officer' : 'sme');
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // state listener handles the rest
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await _auth.signOut();
  }
}
