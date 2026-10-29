import 'package:flutter/material.dart';
import 'package:resturent_application/core/constants/app_info.dart';
import 'package:window_manager/window_manager.dart';

const kSplashWindowSize = Size(560, 300);
const _mainWindowSize = Size(1280, 720);

/// Opens the POS as a small borderless window centred on the desktop,
/// so the splash card floats over the user's wallpaper.
Future<void> showSplashWindow() async {
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    title: kAppName,
    size: kSplashWindowSize,
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setResizable(false);
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Turns the splash window into the normal, full-size POS window.
/// Resized in place without hiding, so the app always keeps a visible window.
Future<void> showMainWindow() async {
  await windowManager.setTitleBarStyle(
    TitleBarStyle.normal,
    windowButtonVisibility: true,
  );
  await windowManager.setResizable(true);
  await windowManager.setSize(_mainWindowSize);
  await windowManager.center();
  await windowManager.maximize();
  await windowManager.focus();
}

Future<void> minimizeApp() => windowManager.minimize();

/// Closes the POS window, which quits the app on Windows and macOS.
Future<void> closeApp() => windowManager.close();
