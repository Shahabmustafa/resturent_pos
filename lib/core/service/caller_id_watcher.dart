import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:resturent_application/feature/restaurant/calls/call_provider.dart';

/// Reads incoming call numbers from the log written by the "Caller ID Tool"
/// that ships with the caller-ID box, and records each one with [logCall].
///
/// The tool writes %APPDATA%\ETM.CallerID\CallerIDRollingLog.log. A ringing
/// call looks like this:
///
///   Device Message Type - [9]
///   Caller ID - [07969918854,,]
///
/// The same number is written again when the call is answered (message type
/// [8]), so only the line that follows message type [9] is used.
class CallerIdLogParser {
  static final _typeRe = RegExp(r'Device Message Type - \[(\d+)\]');
  static final _numberRe = RegExp(r'Caller ID - \[([^,\]]*)');

  int? _lastType;

  /// Feeds one log line. Returns a phone number when the line is the
  /// caller-ID line of a ringing call, otherwise null.
  String? feed(String line) {
    final type = _typeRe.firstMatch(line);
    if (type != null) {
      _lastType = int.tryParse(type.group(1)!);
      return null;
    }
    final number = _numberRe.firstMatch(line);
    if (number == null || _lastType != 9) return null;
    _lastType = null;
    final phone = number.group(1)!.trim();
    return phone.isEmpty ? null : phone;
  }
}

class CallerIdWatcher {
  CallerIdWatcher._();
  static final CallerIdWatcher instance = CallerIdWatcher._();

  final _parser = CallerIdLogParser();
  Timer? _timer;
  File? _file;
  int _pos = 0;
  String _partial = '';
  bool _busy = false;

  static String? get _logPath {
    final appData = Platform.environment['APPDATA'];
    if (appData == null) return null;
    return '$appData\\ETM.CallerID\\CallerIDRollingLog.log';
  }

  /// Starts watching. Does nothing off Windows or when the tool is not installed.
  void start() {
    if (_timer != null || kIsWeb || !Platform.isWindows) return;
    final path = _logPath;
    if (path == null) return;
    _file = File(path);
    // Begin at the end of the file so old calls are not replayed.
    _pos = _file!.existsSync() ? _file!.lengthSync() : 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_busy) return;
    _busy = true;
    try {
      final file = _file!;
      if (!await file.exists()) return;
      final length = await file.length();
      // The tool starts a new file when the log is full.
      if (length < _pos) {
        _pos = 0;
        _partial = '';
      }
      if (length == _pos) return;

      final raf = await file.open();
      List<int> bytes;
      try {
        await raf.setPosition(_pos);
        bytes = await raf.read(length - _pos);
      } finally {
        await raf.close();
      }
      _pos = length;

      final text = _partial + latin1.decode(bytes);
      final lines = text.split('\n');
      _partial = lines.removeLast();
      for (final line in lines) {
        final phone = _parser.feed(line);
        if (phone != null) {
          try {
            await logCall(phone);
          } catch (e) {
            debugPrint('Could not record call $phone: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Caller ID watcher: $e');
    } finally {
      _busy = false;
    }
  }
}
