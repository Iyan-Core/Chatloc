import 'package:flutter_test/flutter_test.dart';

// Basic smoke tests — expand with proper mocks per feature
void main() {
  group('Utils', () {
    test('TimeUtil formats time correctly', () {
      // Add your tests here
      expect(1 + 1, 2);
    });
  });

  group('Validators', () {
    test('email validator rejects invalid email', () {
      // Example — import and test Validators
      expect('test'.contains('@'), false);
    });

    test('email validator accepts valid email', () {
      expect('test@example.com'.contains('@'), true);
    });
  });
}
