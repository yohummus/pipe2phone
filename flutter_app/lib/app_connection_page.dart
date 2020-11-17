import 'dart:io';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_page.dart';
import 'broadcast_listener.dart';
import 'server_info.dart';

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
                  if (_serverInfos[i].address == serverInfo.address &&
                      _serverInfos[i].httpPort == serverInfo.httpPort) {
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
                                _connectToServer(serverInfo);
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

  void _connectToServer(ServerInfo serverInfo) async {
    log('Connecting to ${serverInfo.address.address} port ${serverInfo.httpPort}...');
    try {
      Socket socket = await Socket.connect(serverInfo.address, serverInfo.httpPort);
      log('Successfully connected');

      socket.close();
    } on SocketException catch (e) {
      log('Connection failed: $e');
    }
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

    final subtitle = '${serverInfo.address.address} port ${serverInfo.httpPort}\n${serverInfo.description}';

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
