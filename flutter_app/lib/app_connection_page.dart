import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_page.dart';

class AppConnectionPage extends AppPage {
  @override
  _AppConnectionPageState createState() => _AppConnectionPageState();
}

class _AppConnectionPageState extends State<AppConnectionPage> {
  final _serverInfos = [];

  @override
  void initState() {
    super.initState();
    widget.pageActiveNotifier.addListener(_reset);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            BroadcastListener(
              broadcastAddress: InternetAddress.anyIPv4,
              broadcastPort: 17788,
              pageActiveNotifier: widget.pageActiveNotifier,
              onServerInfoReceived: (serverInfo) {
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
              },
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

  void _reset() {
    setState(() {
      _serverInfos.clear();
    });
  }
}

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

typedef void ServerInfoCallback(ServerInfo serverInfo);

class BroadcastListener extends StatefulWidget {
  final InternetAddress broadcastAddress;
  int broadcastPort;
  final ValueNotifier<bool> pageActiveNotifier;
  final ServerInfoCallback onServerInfoReceived;

  BroadcastListener({
    @required this.broadcastAddress,
    @required this.broadcastPort,
    @required this.pageActiveNotifier,
    @required this.onServerInfoReceived,
  });

  @override
  _BroadcastListenerState createState() => _BroadcastListenerState();
}

class _BroadcastListenerState extends State<BroadcastListener> {
  TextEditingController _portTextController;
  RawDatagramSocket _broadcastSocket;

  @override
  void initState() {
    super.initState();
    _portTextController = TextEditingController(text: '${widget.broadcastPort}');

    widget.pageActiveNotifier.addListener(() {
      if (widget.pageActiveNotifier.value) {
        _startListeningToBroadcasts();
      } else {
        _closeSocket();
      }
    });

    _startListeningToBroadcasts();
  }

  @override
  void dispose() {
    _closeSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          _portTextController.text = '$port';
          widget.broadcastPort = port;
          log('Changed broadcast listen port to $port');
          _startListeningToBroadcasts();
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  void _closeSocket() {
    if (_broadcastSocket != null) {
      _broadcastSocket.close();
      _broadcastSocket = null;
    }
  }

  void _startListeningToBroadcasts() {
    _closeSocket();

    RawDatagramSocket.bind(widget.broadcastAddress, widget.broadcastPort).then((RawDatagramSocket socket) {
      _broadcastSocket = socket;
      log('Listening for broadcasts on ${widget.broadcastAddress.address} port ${widget.broadcastPort}...');

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

        widget.onServerInfoReceived(serverInfo);
      });
    });
  }
}
