import 'package:flutter/foundation.dart';

/// Evento compartido para que un interceptor pueda expulsar la sesión actual.
class AuthSessionEvents extends ChangeNotifier {
  String? _message;

  String? get message => _message;

  void invalidate({String? message}) {
    _message = message;
    notifyListeners();
  }

  void clearMessage() => _message = null;
}
