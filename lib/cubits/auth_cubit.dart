import 'package:flutter_bloc/flutter_bloc.dart';

class AuthState {
  final bool isAuthenticated;
  final int? userId;
  final String? username;
  final String? role;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.userId,
    this.username,
    this.role,
    this.error,
  });
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState(isAuthenticated: false));

  void login(int userId, String username, String role) {
    emit(
      AuthState(
        isAuthenticated: true,
        userId: userId,
        username: username,
        role: role,
      ),
    );
  }

  void logout() {
    emit(AuthState(isAuthenticated: false));
  }
}
