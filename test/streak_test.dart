import 'package:flutter_test/flutter_test.dart';
import 'package:wgnmobile/data/user_state.dart';

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  final today = DateTime.now();

  group('streak', () {
    test('empty history is 0', () {
      expect(const UserState().streak, 0);
    });

    test('today only is 1', () {
      final s = UserState(readDates: {_key(today)});
      expect(s.streak, 1);
      expect(s.readToday, true);
    });

    test('consecutive days ending today count', () {
      final s = UserState(readDates: {
        for (var i = 0; i < 5; i++)
          _key(today.subtract(Duration(days: i))),
      });
      expect(s.streak, 5);
    });

    test('streak alive if yesterday read but not today yet', () {
      final s = UserState(readDates: {
        for (var i = 1; i <= 3; i++)
          _key(today.subtract(Duration(days: i))),
      });
      expect(s.streak, 3);
      expect(s.readToday, false);
    });

    test('gap breaks the streak', () {
      final s = UserState(readDates: {
        _key(today),
        _key(today.subtract(const Duration(days: 1))),
        // gap on day 2
        _key(today.subtract(const Duration(days: 3))),
        _key(today.subtract(const Duration(days: 4))),
      });
      expect(s.streak, 2);
    });

    test('old-only history is 0', () {
      final s = UserState(readDates: {
        _key(today.subtract(const Duration(days: 10))),
      });
      expect(s.streak, 0);
    });
  });
}
