import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ServerStatus {
  neverConnected,
  previouslyConnected,
  connecting,
  connected,
}

class ServerInfo {
  InternetAddress address;
  String prefix;
  int protocolVersion;
  String title;
  String description;
  int httpPort;
  int securePort;
  ServerStatus status = ServerStatus.neverConnected;

  static ServerInfo fromBroadcastMsg(InternetAddress address, String broadcastMsg) {
    var info = ServerInfo();
    info.address = address;

    final List<dynamic> fields = jsonDecode(broadcastMsg);
    info.prefix = fields[0];
    info.protocolVersion = fields[1];
    info.title = fields[2];
    info.description = fields[3];
    info.httpPort = fields[4];
    info.securePort = fields[5];

    return info;
  }

  @protected
  ServerInfo();
}
