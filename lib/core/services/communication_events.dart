import 'dart:async';

class CommunicationEvents {
  CommunicationEvents._();

  static final StreamController<void>
      _newMessageController =
      StreamController<void>.broadcast();

  static Stream<void> get onNewMessage =>
      _newMessageController.stream;

  static void notifyNewMessage() {
    if (_newMessageController.isClosed) {
      return;
    }

    _newMessageController.add(null);
  }
}