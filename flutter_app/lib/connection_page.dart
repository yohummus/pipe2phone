import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _broadcastAddr = InternetAddress.anyIPv4;
  int _broadcastPort = 17788;
  RawDatagramSocket _broadcastSocket;
  final _serverInfos = [];
  TextEditingController _portTextController;

  void _startListeningToBroadcasts() {
    if (_broadcastSocket != null) {
      _broadcastSocket.close();
    }

    if (_broadcastPort == null || _broadcastPort < 1 || _broadcastPort > 65535) {
      log('Invalid broadcast port: $_broadcastPort');
      return;
    }

    RawDatagramSocket.bind(_broadcastAddr, _broadcastPort).then((RawDatagramSocket socket) {
      _broadcastSocket = socket;
      log('Listening for broadcasts on ${_broadcastAddr.address} port $_broadcastPort...');

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
        var alreadyKnownIdx;
        for (var i = 0; i < _serverInfos.length; ++i) {
          if (_serverInfos[i].address == serverInfo.address && _serverInfos[i].port == serverInfo.port) {
            alreadyKnownIdx = i;
            break;
          }
        }

        // Add or replace the server information
        setState(() {
          if (alreadyKnownIdx == null) {
            _serverInfos.add(serverInfo);
          } else {
            _serverInfos[alreadyKnownIdx] = serverInfo;
          }
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _portTextController = TextEditingController(text: '$_broadcastPort');
    _startListeningToBroadcasts();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoTextField(
                prefix: Row(
                  children: [
                    SizedBox(width: 10),
                    CupertinoActivityIndicator(radius: 9.0),
                    SizedBox(width: 10),
                    Text('Listing on port'),
                  ],
                ),
                controller: _portTextController,
                keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                clearButtonMode: OverlayVisibilityMode.editing,
                maxLength: 5,
                maxLengthEnforced: true,
                maxLines: 1,
                onEditingComplete: () {
                  int port = int.parse(_portTextController.text);
                  if (port < 1024) port = 1024;
                  if (port > 65535) port = 65535;
                  log('Changed listen port to $port');
                  _broadcastPort = port;
                  _portTextController.text = '$port';
                  _startListeningToBroadcasts();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: MediaQuery.of(context).removePadding(removeTop: true).padding,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index % 2 == 0) {
                            final serverInfo = _serverInfos[index ~/ 2];
                            return Material(
                              child: ListTile(
                                tileColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
                                onTap: () {
                                  log('Selected');
                                },
                                leading: Icon(
                                  CupertinoIcons.check_mark,
                                  color: CupertinoTheme.of(context).primaryColor,
                                ),
                                title: Align(
                                  alignment: Alignment(-3, 0),
                                  child: Text(
                                    serverInfo.title,
                                    style: TextStyle(color: CupertinoTheme.of(context).primaryColor),
                                  ),
                                ),
                                subtitle: Align(
                                  alignment: Alignment(-2, 0),
                                  child: Text(
                                    '${serverInfo.address.address} port ${serverInfo.port}\n${serverInfo.description}',
                                    style: TextStyle(
                                        color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5)),
                                  ),
                                ),
                                trailing: CupertinoButton(
                                  child: Icon(
                                    CupertinoIcons.minus_circle,
                                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                                  ),
                                  padding: const EdgeInsets.only(left: 10),
                                  onPressed: () {
                                    log('Remove button pressed');
                                  },
                                ),
                              ),
                            );
                          } else {
                            return Divider(
                              color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5),
                            );
                          }
                        },
                        childCount: math.max(0, _serverInfos.length * 2 - 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
