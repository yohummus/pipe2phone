import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ConnectionInfo {
  final String address;
  final int securePort;
  final String title;
  final String description;
  final String passwordHash;
  final String certificate;

  ConnectionInfo(this.address, this.securePort, this.title, this.description, this.passwordHash, this.certificate);

  ConnectionInfo.fromJson(Map<String, dynamic> json)
      : address = json['address'],
        securePort = json['securePort'],
        title = json['title'],
        description = json['description'],
        passwordHash = json['passwordHash'],
        certificate = json['certificate'];

  Map<String, dynamic> toJson() => {
        'address': address,
        'securePort': securePort,
        'title': title,
        'description': description,
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
