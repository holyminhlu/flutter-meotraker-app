import 'package:flutter/material.dart';
import 'package:meo_traker/data/models/user.dart';
import 'package:meo_traker/data/services/auth_service.dart';
import 'package:meo_traker/features/admin/admin_shell.dart';
import 'package:meo_traker/features/auth/login_page.dart';
import 'package:meo_traker/features/onboarding/onboarding_flow.dart';
import 'package:meo_traker/features/shell/main_shell.dart';

Widget destinationForUser(User? user) {
  if (user == null) return const LoginPage();
  if (user.isAdmin) return const AdminShell();
  if (user.needsOnboarding) {
    return OnboardingFlow(initialStep: user.onboardingStep);
  }
  return const MainShell();
}

void goAfterAuth(BuildContext context) {
  final user = AuthService.instance.currentUser;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => destinationForUser(user)),
    (_) => false,
  );
}
