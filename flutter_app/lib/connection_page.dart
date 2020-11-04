import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ServerInfo {
  InternetAddress address;
  String prefix;
  int protocolVersion;
  int port;
  String title;
  String description;

  ServerInfo(InternetAddress address, String broadcastMsg) {
    this.address = address;

    final List<dynamic> fields = jsonDecode(broadcastMsg);
    this.prefix = fields[0];
    this.protocolVersion = fields[1];
    this.port = fields[2];
    this.title = fields[3];
    this.description = fields[4];
  }
}

class ConnectionPage extends StatefulWidget {
  @override
  _ConnectionPageState createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final broadcastAddr = InternetAddress.anyIPv4;
  final broadcastPort = 17788;
  final serverInfos = [];

  @override
  void initState() {
    super.initState();

    RawDatagramSocket.bind(broadcastAddr, broadcastPort).then((RawDatagramSocket socket) {
      log('Listening for broadcasts on ${broadcastAddr.address} port $broadcastPort...');

      socket.listen((RawSocketEvent e) {
        // Receive the broadcast message
        Datagram datagram = socket.receive();
        if (datagram == null) return;

        String msg = new String.fromCharCodes(datagram.data);
        log('Received broadcast from ${datagram.address.address} port ${datagram.port}: $msg');

        // Parse the broadcast message
        ServerInfo serverInfo;
        try {
          serverInfo = ServerInfo(datagram.address, msg);
        } on Exception catch (e) {
          log('Failed to parse broadcast message: $e');
        }

        // Check if we already know the server
        var alreadyKnownIdx = null;
        for (var i = 0; i < serverInfos.length; ++i) {
          if (serverInfos[i].address == serverInfo.address && serverInfos[i].port == serverInfo.port) {
            alreadyKnownIdx = i;
            break;
          }
        }

        // Add or replace the server information
        setState(() {
          if (alreadyKnownIdx == null) {
            serverInfos.add(serverInfo);
          } else {
            serverInfos[alreadyKnownIdx] = serverInfo;
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: MediaQuery.of(context).padding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index % 2 == 0) {
                    final serverInfo = serverInfos[index ~/ 2];
                    return Material(
                      child: ListTile(
                        tileColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
                        onTap: () {
                          log('Selected');
                        },
                        title: Text(
                          serverInfo.title,
                          style: TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color),
                        ),
                        subtitle: Text(
                          '${serverInfo.address.address} port ${serverInfo.port}\n${serverInfo.description}',
                          style:
                              TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5)),
                        ),
                        trailing: Icon(
                          CupertinoIcons.minus_circle,
                          color: CupertinoTheme.of(context).textTheme.textStyle.color,
                        ),
                      ),
                    );
                  } else {
                    return Divider(
                      color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5),
                    );
                  }
                },
                childCount: math.max(0, serverInfos.length * 2 - 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
