import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/core/constants/app_constants.dart';
import 'package:smart_todo/core/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty input', () {
      expect(Validators.validateEmail(null), 'Email is required.');
      expect(Validators.validateEmail(''), 'Email is required.');
      expect(Validators.validateEmail('   '), 'Email is required.');
    });

    test('rejects malformed addresses', () {
      for (final input in [
        'invalid',
        'invalid@',
        '@domain.com',
        'no tld@domain',
        'two@@at.com',
      ]) {
        expect(
          Validators.validateEmail(input),
          'Enter a valid email address.',
          reason: 'expected "$input" to be rejected',
        );
      }
    });

    test('accepts ordinary addresses and ignores surrounding whitespace', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('  user.name+tag@sub.domain.org  '), isNull);
    });
  });

  group('validatePassword (sign-up)', () {
    test('rejects empty input', () {
      expect(Validators.validatePassword(null), 'Password is required.');
      expect(Validators.validatePassword(''), 'Password is required.');
    });

    test('enforces the minimum length', () {
      final short = 'a' * (AppConstants.minPasswordLength - 1);
      expect(
        Validators.validatePassword(short),
        'Password must be at least ${AppConstants.minPasswordLength} characters.',
      );
      expect(
        Validators.validatePassword('a' * AppConstants.minPasswordLength),
        isNull,
      );
    });

    test('enforces the maximum length', () {
      final long = 'a' * (AppConstants.maxPasswordLength + 1);
      expect(
        Validators.validatePassword(long),
        'Password must be at most ${AppConstants.maxPasswordLength} characters.',
      );
    });
  });

  group('validatePasswordPresence (sign-in)', () {
    test('only requires something to be typed', () {
      // Sign-in must not apply the sign-up strength rules, or an account whose
      // password predates a rule change would be locked out with an error the
      // user cannot act on.
      expect(Validators.validatePasswordPresence(null), 'Password is required.');
      expect(Validators.validatePasswordPresence(''), 'Password is required.');
      expect(Validators.validatePasswordPresence('abc'), isNull);
      expect(Validators.validatePasswordPresence('a'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('rejects an empty confirmation', () {
      expect(
        Validators.validateConfirmPassword(null, 'secret123'),
        'Please confirm your password.',
      );
    });

    test('rejects a mismatch', () {
      expect(
        Validators.validateConfirmPassword('different', 'secret123'),
        'Passwords do not match.',
      );
    });

    test('accepts a match', () {
      expect(Validators.validateConfirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('validateFullName', () {
    test('rejects empty input', () {
      expect(Validators.validateFullName(null), 'Full name is required.');
      expect(Validators.validateFullName('   '), 'Full name is required.');
    });

    test('rejects an over-long name', () {
      expect(
        Validators.validateFullName('a' * (AppConstants.maxNameLength + 1)),
        'Name must be at most ${AppConstants.maxNameLength} characters.',
      );
    });

    test('accepts an ordinary name', () {
      expect(Validators.validateFullName('Suresh Mahato'), isNull);
    });
  });

  group('validateTaskTitle', () {
    test('rejects empty input', () {
      expect(Validators.validateTaskTitle(null), 'Task title is required.');
      expect(Validators.validateTaskTitle(''), 'Task title is required.');
      expect(Validators.validateTaskTitle('   '), 'Task title is required.');
    });

    test('rejects an over-long title', () {
      expect(
        Validators.validateTaskTitle('a' * (AppConstants.maxTaskTitleLength + 1)),
        'Title must be at most ${AppConstants.maxTaskTitleLength} characters.',
      );
    });

    test('accepts a title at exactly the limit', () {
      expect(
        Validators.validateTaskTitle('a' * AppConstants.maxTaskTitleLength),
        isNull,
      );
    });
  });

  group('validateTaskDescription', () {
    test('an optional field may be empty', () {
      expect(Validators.validateTaskDescription(null), isNull);
      expect(Validators.validateTaskDescription(''), isNull);
    });

    test('rejects an over-long description', () {
      expect(
        Validators.validateTaskDescription(
          'a' * (AppConstants.maxTaskDescriptionLength + 1),
        ),
        'Description must be at most '
        '${AppConstants.maxTaskDescriptionLength} characters.',
      );
    });

    test('accepts a description at exactly the limit', () {
      expect(
        Validators.validateTaskDescription(
          'a' * AppConstants.maxTaskDescriptionLength,
        ),
        isNull,
      );
    });
  });
}
