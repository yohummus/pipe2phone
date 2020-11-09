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
  final List<ServerInfo> _serverInfos = [];
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
                            return ServerListTile(
                              serverInfo: serverInfo,
                              onTileTap: () {
                                log('List tile tapped');
                              },
                              onRemoveBtnTap: () {
                                log('Remove button tapped');
                              },
                              onDisconnectBtnTap: () {
                                log('Disconnect button tapped');
                              },
                            );
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

enum ServerStatus {
  neverConnected,
  previouslyConnected,
  connecting,
  failedToConnect,
  connected,
}

class ServerInfo {
  InternetAddress address;
  String prefix;
  int protocolVersion;
  int port;
  String title;
  String description;
  ServerStatus status = ServerStatus.neverConnected;

  static ServerInfo fromBroadcastMsg(InternetAddress address, String broadcastMsg) {
    var info = ServerInfo();
    info.address = address;

    final List<dynamic> fields = jsonDecode(broadcastMsg);
    info.prefix = fields[0];
    info.protocolVersion = fields[1];
    info.port = fields[2];
    info.title = fields[3];
    info.description = fields[4];

    return info;
  }

  @protected
  ServerInfo();
}

typedef void ServerInfoCallback(ServerInfo serverInfo);

class BroadcastListener extends StatefulWidget {
  final InternetAddress broadcastAddress;
  final int initialBroadcastPort;
  final ValueNotifier<bool> pageActiveNotifier;
  final ServerInfoCallback onServerInfoReceived;

  BroadcastListener({
    Key key,
    @required this.broadcastAddress,
    @required this.initialBroadcastPort,
    @required this.pageActiveNotifier,
    @required this.onServerInfoReceived,
  }) : super(key: key);

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
          serverInfo = ServerInfo.fromBroadcastMsg(datagram.address, msg);
        } on Exception catch (e) {
          log('Failed to parse broadcast message: $e');
        }

        // Propagate the new server information
        widget.onServerInfoReceived(serverInfo);
      });
    });
  }
}

class ServerListTile extends StatelessWidget {
  final ServerInfo serverInfo;
  final VoidCallback onTileTap;
  final VoidCallback onRemoveBtnTap;
  final VoidCallback onDisconnectBtnTap;

  ServerListTile({
    Key key,
    @required this.serverInfo,
    @required this.onTileTap,
    @required this.onRemoveBtnTap,
    @required this.onDisconnectBtnTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final textStyle = theme.textTheme.textStyle;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final titleColor = serverInfo.status == ServerStatus.connected ? theme.primaryColor : textStyle.color;
    final descriptionColor = textStyle.color.withOpacity(0.5);

    final subtitle = '${serverInfo.address.address} port ${serverInfo.port}\n${serverInfo.description}';

    return Material(
      color: backgroundColor,
      child: InkWell(
        splashColor: textStyle.color.withOpacity(0.3),
        onTap: onTileTap,
        child: Container(
          padding: EdgeInsets.all(6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _makeLeadingWidget(context),
              Padding(padding: EdgeInsets.only(left: 6.0)),
              Column(
                children: [
                  Text(serverInfo.title, style: TextStyle(color: titleColor)),
                  Text(subtitle, style: TextStyle(color: descriptionColor)),
                ],
              ),
              Spacer(),
              _makeTrailingWidget(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _makeLeadingWidget(BuildContext context) {
    switch (serverInfo.status) {
      case ServerStatus.connecting:
        return CupertinoActivityIndicator();

      case ServerStatus.connected:
        return Icon(CupertinoIcons.checkmark_alt, color: CupertinoTheme.of(context).primaryColor);

      default:
        return SizedBox();
    }
  }

  Widget _makeTrailingWidget(BuildContext context) {
    switch (serverInfo.status) {
      case ServerStatus.previouslyConnected:
        return CupertinoButton(
          child: Icon(CupertinoIcons.trash, color: CupertinoTheme.of(context).textTheme.textStyle.color),
          padding: const EdgeInsets.only(left: 10),
          onPressed: onRemoveBtnTap,
        );

      case ServerStatus.connected:
        return CupertinoButton(
          child: Icon(CupertinoIcons.xmark_circle, color: CupertinoTheme.of(context).textTheme.textStyle.color),
          padding: const EdgeInsets.only(left: 10),
          onPressed: onDisconnectBtnTap,
        );

      default:
        return SizedBox();
    }
  }
}
