part of '../../../click_connect_ai_crm_ui.dart';

extension NavX on BuildContext {
  Future<T?> open<T>(Widget page) {
    return Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  }
}


