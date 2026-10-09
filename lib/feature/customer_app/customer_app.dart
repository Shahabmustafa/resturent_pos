import 'package:flutter/material.dart';
import 'presentation/screen/customer_shell.dart';
import 'presentation/theme/customer_theme.dart';

/// Customer-facing website (Pak Afghan & Woking Shawarma) — served on web.
class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pak Afghan & Woking Shawarma',
      debugShowCheckedModeBanner: false,
      theme: buildCustomerTheme(),
      themeAnimationDuration: Duration.zero,
      // The website is fully static: every motion effect (reveal, parallax, tilt,
      // float, tab fade) checks this flag and renders at rest.
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
      home: const CustomerShell(),
    );
  }
}
