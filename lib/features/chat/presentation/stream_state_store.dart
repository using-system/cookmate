import 'package:flutter/foundation.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';

class StreamStateStore {
  final Map<String, ValueNotifier<StreamState>> _notifiers = {};

  ValueNotifier<StreamState> of(String streamId) =>
      _notifiers.putIfAbsent(
          streamId, () => ValueNotifier(const StreamStateLoading()));

  void set(String streamId, StreamState state) {
    of(streamId).value = state;
  }

  StreamState? get(String streamId) => _notifiers[streamId]?.value;

  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
  }
}
