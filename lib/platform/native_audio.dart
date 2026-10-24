import 'package:flutter/services.dart';

abstract class AudioGateway {
  Stream<dynamic> get events;
  Future<dynamic> invoke(String method, [dynamic arguments]);
}

class NativeAudio implements AudioGateway {
  static const _method = MethodChannel('aura/native');
  static const _events = EventChannel('aura/events');
  @override
  Stream<dynamic> get events => _events.receiveBroadcastStream();
  @override
  Future<dynamic> invoke(String method, [dynamic arguments]) =>
      _method.invokeMethod<dynamic>(method, arguments);
}
