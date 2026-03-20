import 'package:flutter/material.dart';
import 'login_page.dart';

/// Thin wrapper that opens [LoginPage] on the sign-up tab (page 1).
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) => const LoginPage(initialPage: 1);
}
