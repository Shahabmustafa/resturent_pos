import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resturent_application/core/service/caller_id_watcher.dart';
import 'package:resturent_application/feature/restaurant/setup/pos_setup.dart';

/// The one keyboard shortcut in the POS: Ctrl + D opens the cash drawer.
final kDrawerKey = LogicalKeyboardKey.keyD;

final drawerMessengerKey = GlobalKey<ScaffoldMessengerState>();

// ESC p 0 25 250: pulse drawer pin 2, the standard ESC/POS "open drawer" command.
const _kickBytes = [0x1B, 0x70, 0x00, 0x19, 0xFA];

// Sends the raw bytes to a Windows printer through the spooler (RAW datatype).
const _winScript = r'''
param([string]$Printer, [string]$File)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class RawPrint {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
  public class DOCINFO { [MarshalAs(UnmanagedType.LPStr)] public string Name; [MarshalAs(UnmanagedType.LPStr)] public string Output; [MarshalAs(UnmanagedType.LPStr)] public string Type; }
  [DllImport("winspool.drv", CharSet=CharSet.Ansi, SetLastError=true)] public static extern bool OpenPrinter(string n, out IntPtr h, IntPtr d);
  [DllImport("winspool.drv", SetLastError=true)] public static extern bool ClosePrinter(IntPtr h);
  [DllImport("winspool.drv", CharSet=CharSet.Ansi, SetLastError=true)] public static extern bool StartDocPrinter(IntPtr h, int l, [In] DOCINFO d);
  [DllImport("winspool.drv", SetLastError=true)] public static extern bool EndDocPrinter(IntPtr h);
  [DllImport("winspool.drv", SetLastError=true)] public static extern bool StartPagePrinter(IntPtr h);
  [DllImport("winspool.drv", SetLastError=true)] public static extern bool EndPagePrinter(IntPtr h);
  [DllImport("winspool.drv", SetLastError=true)] public static extern bool WritePrinter(IntPtr h, byte[] b, int c, out int w);
  public static bool Send(string printer, byte[] bytes) {
    IntPtr h; if (!OpenPrinter(printer, out h, IntPtr.Zero)) return false;
    var di = new DOCINFO { Name = "Cash drawer", Type = "RAW" };
    bool ok = StartDocPrinter(h, 1, di);
    if (ok) { StartPagePrinter(h); int w; ok = WritePrinter(h, bytes, bytes.Length, out w); EndPagePrinter(h); EndDocPrinter(h); }
    ClosePrinter(h); return ok;
  }
}
"@
$bytes = [System.IO.File]::ReadAllBytes($File)
if (-not [RawPrint]::Send($Printer, $bytes)) { exit 1 }
''';

/// Opens the cash drawer by sending the ESC/POS kick to the printer chosen
/// in POS Setup > Print. Returns an error message, or null on success.
Future<String?> openCashDrawer(String printerName) async {
  if (kIsWeb) return 'The cash drawer works only in the desktop app.';
  if (printerName.isEmpty) {
    return 'Tick the drawer\'s receipt printer in Setup > Print first.';
  }
  final dir = await Directory.systemTemp.createTemp('drawer');
  try {
    final data = File('${dir.path}/kick.bin');
    await data.writeAsBytes(_kickBytes);
    ProcessResult r;
    if (Platform.isWindows) {
      final script = File('${dir.path}/kick.ps1');
      await script.writeAsString(_winScript);
      r = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script.path,
        '-Printer',
        printerName,
        '-File',
        data.path,
      ]);
    } else {
      r = await Process.run('lp', ['-d', printerName, '-o', 'raw', data.path]);
    }
    return r.exitCode == 0 ? null : 'Could not open the cash drawer.';
  } catch (_) {
    return 'Could not open the cash drawer.';
  } finally {
    await dir.delete(recursive: true).catchError((_) => dir);
  }
}

/// Listens for the drawer key anywhere in the POS, whichever field has focus.
class DrawerKeyListener extends ConsumerStatefulWidget {
  final Widget child;
  const DrawerKeyListener({super.key, required this.child});

  @override
  ConsumerState<DrawerKeyListener> createState() => _DrawerKeyListenerState();
}

class _DrawerKeyListenerState extends ConsumerState<DrawerKeyListener> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    CallerIdWatcher.instance.start();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != kDrawerKey) return false;
    if (!HardwareKeyboard.instance.isControlPressed) return false;
    _open();
    return true;
  }

  Future<void> _open() async {
    final err = await openCashDrawer(ref.read(posSetupProvider).printerName);
    drawerMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(err ?? 'Cash drawer opened')),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
