import 'dart:async';

import 'package:flutter/cupertino.dart';

class Event {
  final String name;
  final Map data;
  Event(this.name, this.data);
}

class EventCenter {
  //生成单利
  static final EventCenter _instance = EventCenter._internal();
  EventCenter._internal();
  factory EventCenter() => _instance;
  static EventCenter get instance => _instance;

  Map listeners = {};
  StreamController streamController = StreamController.broadcast();
  void init() {
    streamController.stream.where((event) => event is Event).cast<Event>().listen((event) {
      if (listeners[event.name] != null) {
        for (var listener in listeners[event.name]) {
          try {
            listener.call(event);
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      }
    });
  }

  //添加监听者
  dynamic addListener(String name, Function(Event) callback) {
    if (listeners[name] == null) {
      listeners[name] = [];
    }
    listeners[name]!.add(callback);

    return callback;
  }

  //移除监听者
  void removeListener(String name, Function(Event) callback) {
    if (listeners[name] != null) {
      listeners[name]!.remove(callback);
    }
  }

  //发送事件
  void sendEvent(String name, Map? data) {
    streamController.add(Event(name, data ?? {}));
  }

  //销毁
  void dispose() {
    streamController.close();
  }
}
