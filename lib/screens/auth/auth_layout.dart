import 'package:ehr/app/auth_services.dart';
import 'package:ehr/screens/auth/login_page.dart';
import 'package:ehr/screens/home/dashboard.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});
  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            Widget widget;
            if (snapshot.connectionState == ConnectionState.waiting) {
              widget = const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              widget = Dashboard();
            } else {
              widget = LoginPage();
            }
            return widget;
          },
        );
      },
    );
  }
}
