import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/cart_cubit.dart';
import '/screen/login_screen.dart';
import '/screen/pos_screen.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => CartCubit()),
      ],
      child: const PosApp(),
    ),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokladna',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.isAuthenticated) {
            return const PosScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
