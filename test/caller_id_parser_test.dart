import 'package:flutter_test/flutter_test.dart';
import 'package:resturent_application/core/service/caller_id_watcher.dart';

void main() {
  test('records the number once per ringing call', () {
    const log = '''
2026-11-03 12:26:17,128 [1] INFO ETM.CallerID - Device Message Type - [9]
2026-11-03 12:26:17,130 [1] INFO ETM.CallerID - Caller ID - [07710538128,,]
2026-11-03 12:26:31,334 [1] INFO ETM.CallerID - Device Message Type - [8]
2026-11-03 12:26:31,334 [1] INFO ETM.CallerID - Caller ID - [07710538128,,]
2026-11-03 12:26:37,530 [1] INFO ETM.CallerID - Device Message Type - [10]
2026-11-03 12:26:37,530 [1] INFO ETM.CallerID - Dial Digit - [#]
2026-11-03 12:26:32,915 [1] INFO ETM.CallerID - Device Message Type - [187]
2026-11-03 12:26:32,917 [1] INFO ETM.CallerID - BACK TALK - [1S]
''';
    final parser = CallerIdLogParser();
    final found = log.split('\n').map(parser.feed).whereType<String>().toList();
    expect(found, ['07710538128']);
  });
}
