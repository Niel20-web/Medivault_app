import 'dart:convert';

import 'package:flutter/material.dart';

import '../screens/welcome_screen.dart';
import '../utils/auth_storage.dart';

/// Central place for session state: restoring a saved login on launch,
/// checking whether the stored token has expired, and ending the session.
class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  /// Shared navigator key so the session can be ended from anywhere
  /// (for example from a service that receives a 401 response).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final AuthStorage _authStorage = AuthStorage();

  bool _isHandlingExpiry = false;

  /// True when a token is stored and has not passed its `exp` time.
  Future<bool> hasValidSession() async {
    try {
      final token = await _authStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      if (_isExpired(token)) {
        await _authStorage.deleteAccessToken();
        return false;
      }

      return true;
    } catch (_) {
      // Secure storage can fail to read (for example after a reinstall or
      // a restored backup). Treat that as "not logged in" instead of
      // leaving the app stuck on the loading screen.
      try {
        await _authStorage.deleteAccessToken();
      } catch (_) {}
      return false;
    }
  }

  /// Called when the backend rejects the token. Clears it and sends the
  /// user back to the welcome/login flow, showing a short message.
  ///
  /// [usedToken] is the token the failed request was sent with. If the
  /// stored token is no longer that one (the user already logged out or
  /// logged in again), the late 401 is ignored.
  Future<void> handleSessionExpired({String? usedToken}) async {
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    try {
      final storedToken = await _authStorage.getAccessToken();

      if (usedToken != null && storedToken != usedToken) {
        return;
      }

      await _authStorage.deleteAccessToken();

      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );

      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
          ),
        );
      }
    } finally {
      _isHandlingExpiry = false;
    }
  }

  /// Reads the `exp` claim from a JWT without verifying the signature
  /// (the server does that). If the token can't be parsed or has no
  /// `exp`, it is treated as still valid and the server stays the judge.
  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload);

      final exp = claims is Map ? claims['exp'] : null;
      if (exp is! num) return false;

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      // Small buffer so we don't start a request with a token that is
      // about to expire.
      return DateTime.now()
          .toUtc()
          .isAfter(expiresAt.subtract(const Duration(seconds: 30)));
    } catch (_) {
      return false;
    }
  }
}
