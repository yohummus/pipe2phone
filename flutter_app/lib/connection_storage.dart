import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ConnectionInfo {
  String address;
  String hostname;
  int securePort;
  String title;
  String description;
  String user;
  String passwordHash;
  String certificate;

  ConnectionInfo();

  ConnectionInfo.fromJson(Map<String, dynamic> json)
      : address = json['address'],
        hostname = json['hostname'],
        securePort = json['securePort'],
        title = json['title'],
        description = json['description'],
        user = json['user'],
        passwordHash = json['passwordHash'],
        certificate = json['certificate'];

  Map<String, dynamic> toJson() => {
        'address': address,
        'hostname': hostname,
        'securePort': securePort,
        'title': title,
        'description': description,
        'user': user,
        'passwordHash': passwordHash,
        'certificate': certificate,
      };
}

class ConnectionStorage {
  Future<File> get _localFile async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/connections.json');
  }

  Future<List<ConnectionInfo>> read() async {
    try {
      final file = await _localFile;
      final jsonConnsList = jsonDecode(await file.readAsString());
      log('Read ${jsonConnsList.length} connections from file');
      final connections = jsonConnsList.map<ConnectionInfo>((jsonConn) => ConnectionInfo.fromJson(jsonConn)).toList();
      return connections;
    } catch (e) {
      log('ERROR: Failed to read connections from file: $e');
      return [];
    }
  }

  void write(List<ConnectionInfo> connections) async {
    final jsonConnsList = connections.map((conn) => conn.toJson()).toList();
    final file = await _localFile;
    await file.writeAsString(jsonEncode(jsonConnsList));
    log('Wrote ${connections.length} connections to file');
  }
}
