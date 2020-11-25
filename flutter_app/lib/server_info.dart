import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pipe2phone/connection_storage.dart';

const PROTOCOL_VERSION = 1;

class ServerInfo extends ConnectionInfo {
  String certificateHash;
  int httpPort = -1;
  bool previouslyConnected = false;
  bool broadcastReceived = false;
  bool connecting = false;
  bool connected = false;

  static ServerInfo fromConnectionInfo(ConnectionInfo conn) {
    var info = ServerInfo();
    info.address = conn.address;
    info.hostname = conn.hostname;
    info.securePort = conn.securePort;
    info.title = conn.title;
    info.description = conn.description;
    info.user = conn.user;
    info.passwordHash = conn.passwordHash;
    info.certificate = conn.certificate;
    info.previouslyConnected = true;
    return info;
  }

  static ServerInfo fromBroadcastMsg(InternetAddress address, String broadcastMsg) {
    final List<dynamic> fields = jsonDecode(broadcastMsg);

    if (fields[0] != 'pipe2phone') {
      throw Exception('First array element is not "pipe2phone" in: $broadcastMsg');
    }

    if (fields[1] != PROTOCOL_VERSION) {
      throw Exception('Incompatible server version in: $broadcastMsg');
    }

    var info = ServerInfo();
    info.address = address.address;
    info.title = fields[2];
    info.description = fields[3];
    info.user = fields[4];
    info.hostname = fields[5];
    info.httpPort = fields[6];
    info.securePort = fields[7];
    info.certificateHash = fields[8];
    info.broadcastReceived = true;
    return info;
  }
}
