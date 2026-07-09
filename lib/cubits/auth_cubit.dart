import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final int? userId;
  final String? username;
  final String? role;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.userId,
    this.username,
    this.role,
    this.accessToken,
    this.refreshToken,
    this.error,
  });
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState(isAuthenticated: false)) {
    ApiService.setAuthFailureHandler(_handleAuthExpired);
    ApiService.setTokenUpdateHandler(_handleTokensUpdated);
  }

  static const String _userIdKey = 'auth_user_id';
  static const String _usernameKey = 'auth_username';
  static const String _roleKey = 'auth_role';
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    final username = prefs.getString(_usernameKey);
    final role = prefs.getString(_roleKey);
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    final hasSession = userId != null &&
        username != null &&
        role != null &&
        accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;

    if (!hasSession) {
      await _clearStoredSession();
      emit(AuthState(isAuthenticated: false));
      return;
    }

    ApiService.setAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    emit(
      AuthState(
        isAuthenticated: true,
        userId: userId,
        username: username,
        role: role,
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Future<void> login(
    int userId,
    String username,
    String role, {
    String? accessToken,
    String? refreshToken,
  }) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      ApiService.setAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    final nextState = AuthState(
      isAuthenticated: true,
      userId: userId,
      username: username,
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    await _persistSession(nextState);

    emit(nextState);
  }

  Future<void> logout() async {
    await ApiService().logout();
    await _clearStoredSession();
    emit(AuthState(isAuthenticated: false));
  }

  Future<void> _handleAuthExpired() async {
    if (!state.isAuthenticated) {
      return;
    }

    await _clearStoredSession();
    emit(AuthState(isAuthenticated: false));
  }

  Future<void> _handleTokensUpdated(
    String accessToken,
    String? refreshToken,
  ) async {
    if (!state.isAuthenticated) {
      return;
    }

    final nextState = AuthState(
      isAuthenticated: true,
      userId: state.userId,
      username: state.username,
      role: state.role,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    await _persistSession(nextState);
    emit(nextState);
  }

  Future<void> _persistSession(AuthState authState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, authState.userId!);
    await prefs.setString(_usernameKey, authState.username!);
    await prefs.setString(_roleKey, authState.role!);

    if (authState.accessToken != null && authState.accessToken!.isNotEmpty) {
      await prefs.setString(_accessTokenKey, authState.accessToken!);
    }

    if (authState.refreshToken != null && authState.refreshToken!.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, authState.refreshToken!);
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    ApiService.clearAuthToken();
  }
}
