import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final int? userId;
  final String? username;
  final String? role;
  final String? accessToken;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.userId,
    this.username,
    this.role,
    this.accessToken,
    this.error,
  });
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState(isAuthenticated: false));

  void login(int userId, String username, String role, {String? accessToken}) {
    if (accessToken != null && accessToken.isNotEmpty) {
      ApiService.setAuthToken(accessToken);
    }

    emit(
      AuthState(
        isAuthenticated: true,
        userId: userId,
        username: username,
        role: role,
        accessToken: accessToken,
      ),
    );
  }

  void logout() {
    ApiService.clearAuthToken();
    emit(AuthState(isAuthenticated: false));
  }
}
