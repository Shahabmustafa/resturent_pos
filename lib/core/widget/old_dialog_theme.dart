import 'package:flutter/material.dart';

/// Classic (Material 2 era) dialog look: nearly square corners, flat white
/// surface and a strong drop shadow. Shared by every app theme.
const DialogThemeData kOldStyleDialogTheme = DialogThemeData(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  shadowColor: Colors.black,
  elevation: 24,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
  ),
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  ),
  contentTextStyle: TextStyle(fontSize: 16, color: Colors.black54, height: 1.4),
);
