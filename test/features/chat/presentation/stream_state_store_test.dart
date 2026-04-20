import 'package:cookmate/features/chat/presentation/stream_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';

void main() {
  late StreamStateStore store;

  setUp(() {
    store = StreamStateStore();
  });

  tearDown(() {
    store.dispose();
  });

  test('get returns null for unknown streamId', () {
    expect(store.get('unknown'), isNull);
  });

  test('set and get return the stored state', () {
    store.set('s1', const StreamStateLoading());
    expect(store.get('s1'), isA<StreamStateLoading>());
  });

  test('of returns a ValueNotifier defaulting to StreamStateLoading', () {
    final notifier = store.of('s1');
    expect(notifier.value, isA<StreamStateLoading>());
  });

  test('set updates the ValueNotifier from of()', () {
    final notifier = store.of('s1');
    store.set('s1', const StreamStateCompleted('hello'));
    expect(notifier.value, isA<StreamStateCompleted>());
  });

  test('each streamId gets its own independent notifier', () {
    store.set('s1', const StreamStateCompleted('a'));
    store.set('s2', const StreamStateLoading());

    expect(store.get('s1'), isA<StreamStateCompleted>());
    expect(store.get('s2'), isA<StreamStateLoading>());
  });

  test('updating one stream does not notify listeners of another', () {
    final notifier1 = store.of('s1');
    final notifier2 = store.of('s2');

    var notifier1Count = 0;
    var notifier2Count = 0;
    notifier1.addListener(() => notifier1Count++);
    notifier2.addListener(() => notifier2Count++);

    store.set('s1', const StreamStateCompleted('done'));

    expect(notifier1Count, 1);
    expect(notifier2Count, 0);
  });

  test('dispose clears all notifiers', () {
    store.of('s1');
    store.of('s2');
    store.dispose();

    // After dispose, of() creates fresh notifiers.
    final notifier = store.of('s1');
    expect(notifier.value, isA<StreamStateLoading>());
  });
}
