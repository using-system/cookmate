import 'package:cookmate/features/chat/domain/title_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns first 6 words by default', () {
    expect(
      generateTitle('one two three four five six seven eight'),
      'one two three four five six',
    );
  });

  test('returns all words when fewer than maxWords', () {
    expect(generateTitle('hello world'), 'hello world');
  });

  test('returns null for empty string', () {
    expect(generateTitle(''), isNull);
  });

  test('returns null for whitespace-only string', () {
    expect(generateTitle('   '), isNull);
  });

  test('truncates to 50 characters with ellipsis', () {
    final long = 'abcdefghij ' * 6; // ~66 chars
    final result = generateTitle(long);
    expect(result!.length, lessThanOrEqualTo(50));
    expect(result, endsWith('...'));
  });

  test('does not truncate when exactly at maxLength', () {
    // 50 chars exactly
    final exact = 'a' * 50;
    expect(generateTitle(exact), exact);
  });

  test('trims leading and trailing whitespace', () {
    expect(generateTitle('  hello world  '), 'hello world');
  });

  test('collapses multiple spaces between words', () {
    expect(generateTitle('hello    world'), 'hello world');
  });

  test('respects custom maxWords', () {
    expect(
      generateTitle('one two three four five', maxWords: 3),
      'one two three',
    );
  });

  test('respects custom maxLength', () {
    final result = generateTitle('hello world foo bar', maxLength: 10);
    expect(result!.length, lessThanOrEqualTo(10));
    expect(result, endsWith('...'));
  });
}
