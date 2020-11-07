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
  int broadcastPort;

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
              initialBroadcastPort: 17788,
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
                            return ServerListTile(serverInfo: serverInfo);
                          } else {
                            final color = CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5);
                            return Divider(color: color);
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
  final int initialBroadcastPort;
  final ValueNotifier<bool> pageActiveNotifier;
  final ServerInfoCallback onServerInfoReceived;

  BroadcastListener({
    @required this.broadcastAddress,
    @required this.initialBroadcastPort,
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
    _portTextController = TextEditingController(text: '${widget.initialBroadcastPort}');

    widget.pageActiveNotifier.addListener(() {
      if (widget.pageActiveNotifier.value) {
        _startListeningToBroadcasts(int.parse(_portTextController.text));
      } else {
        _closeSocket();
      }
    });

    _startListeningToBroadcasts(widget.initialBroadcastPort);
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
          // Parse & clamp broadcast port
          int port = int.parse(_portTextController.text);
          if (port < 1024) port = 1024;
          if (port > 65535) port = 65535;
          _portTextController.text = '$port';

          // Re-create the broadcast socket
          log('Changed broadcast listen port to $port');
          _closeSocket();
          _startListeningToBroadcasts(port);

          // Hide keyboard
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  void _closeSocket() {
    if (_broadcastSocket == null) return;

    _broadcastSocket.close();
    _broadcastSocket = null;
    log('Broadcast listener socket closed');
  }

  void _startListeningToBroadcasts(int port) {
    _closeSocket();

    RawDatagramSocket.bind(widget.broadcastAddress, port).then((RawDatagramSocket socket) {
      _broadcastSocket = socket;
      log('Listening for broadcasts on ${widget.broadcastAddress.address} port ${port}...');

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

        // Propagate the new server information
        widget.onServerInfoReceived(serverInfo);
      });
    });
  }
}

class ServerListTile extends StatefulWidget {
  final ServerInfo serverInfo;

  ServerListTile({
    @required this.serverInfo,
  });

  @override
  _ServerListTileState createState() => _ServerListTileState();
}

class _ServerListTileState extends State<ServerListTile> {
  @override
  Widget build(BuildContext context) {
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
    final inactiveTitleColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final activeTitleColor = CupertinoTheme.of(context).primaryColor;
    final descriptionColor = CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5);
    final removeIconColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    final serverInfo = widget.serverInfo;
    final subtitle = '${serverInfo.address.address} port ${serverInfo.port}\n${serverInfo.description}';

    return Material(
      child: ListTile(
        tileColor: backgroundColor,
        onTap: () {
          log('Selected');
        },
        title: Text(widget.serverInfo.title, style: TextStyle(color: activeTitleColor)),
        subtitle: Text(subtitle, style: TextStyle(color: descriptionColor)),
        trailing: CupertinoButton(
          child: Icon(CupertinoIcons.minus_circle, color: removeIconColor),
          padding: const EdgeInsets.only(left: 10),
          onPressed: () {
            log('Remove button pressed');
          },
        ),
      ),
    );
  }
}
