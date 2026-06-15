import 'package:flutter/material.dart';
import 'khade_repository.dart';

/// Wraps the app so screens can listen to [KhadeRepository].
class KhadeScope extends InheritedNotifier<KhadeRepository> {
  const KhadeScope({super.key, required KhadeRepository repo, required super.child})
      : super(notifier: repo);

  static KhadeRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<KhadeScope>();
    return scope!.notifier!;
  }
}
