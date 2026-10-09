import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'data/rider_datasource.dart';
import 'presentation/screen/rider_shell.dart';
import 'presentation/screen/rider_login_screen.dart';

final riderDsProvider = Provider<RiderDatasource>((_) => RiderDatasource(Supabase.instance.client));

/// Phone app for delivery riders: sign in, see assigned deliveries, update them.
class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Rider', debugShowCheckedModeBanner: false, theme: _theme, home: const _AuthGate());
  }
}

OutlineInputBorder _inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: color, width: width),
);

/// One look for every rider screen: inputs, buttons, dialogs, sheets and the bottom bar.
final _theme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: kBg,
  colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary, surface: kCard),
  fontFamily: 'Roboto',
  splashFactory: InkSparkle.splashFactory,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: kPrimary,
    selectionColor: kPrimary.withValues(alpha: 0.2),
    selectionHandleColor: kPrimary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kLight,
    hintStyle: const TextStyle(color: kMuted, fontSize: 15),
    border: _inputBorder(kBorder),
    enabledBorder: _inputBorder(kBorder),
    focusedBorder: _inputBorder(kPrimary, 1.5),
    errorBorder: _inputBorder(kRed),
    focusedErrorBorder: _inputBorder(kRed, 1.5),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kPrimary,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: kCard,
    surfaceTintColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kText),
    contentTextStyle: const TextStyle(fontSize: 14.5, color: kSub, height: 1.5),
  ),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: kCard, surfaceTintColor: kCard),
  navigationBarTheme: NavigationBarThemeData(
    height: 68,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
        color: states.contains(WidgetState.selected) ? kPrimary : kSub,
      ),
    ),
  ),
);

/// Shows login or home depending on the Supabase session (it persists across restarts).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) => auth.currentSession == null ? const RiderLoginScreen() : const RiderShell(),
    );
  }
}
