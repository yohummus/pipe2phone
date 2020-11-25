import 'dart:io';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pipe2phone/connection_storage.dart';

import 'app_page.dart';
import 'broadcast_listener.dart';
import 'server_info.dart';

class AppConnectionPage extends AppPage {
  @override
  _AppConnectionPageState createState() => _AppConnectionPageState();
}

class _AppConnectionPageState extends State<AppConnectionPage> {
  List<ServerInfo> _serverInfos = [];
  int broadcastPort;

  @override
  void initState() {
    super.initState();
    widget.pageActiveNotifier.addListener(_onPageActiveChanged);
    _onPageActiveChanged();
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
              onServerInfoReceived: _onBroadcastReceived,
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
                              onTileTap: () => _onTileTapped(serverInfo),
                              onRemoveBtnTap: () => _onRemoveIconTapped(serverInfo),
                              onDisconnectBtnTap: () => _onDisconnectIconTapped(serverInfo),
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

  void _onPageActiveChanged() async {
    // We are only interested when the page becomes active
    if (!widget.pageActiveNotifier.value) return;

    // Load the connections from disk
    var serverInfos = await _readConnectionsFromFile();

    // Update the widget state
    setState(() {
      _serverInfos = serverInfos;
    });
  }

  void _onBroadcastReceived(ServerInfo serverInfo) {
    // Check if we already know the server
    var alreadyKnownIdx;
    for (int idx = 0; idx < _serverInfos.length; ++idx) {
      final a = _serverInfos[idx];
      final b = serverInfo;
      if (a.title == b.title && a.hostname == b.hostname && a.user == b.user) {
        alreadyKnownIdx = idx;
        break;
      }
    }

    // Update the UI
    setState(() {
      // If we don't know the server already then add it to the list
      if (alreadyKnownIdx == null) {
        _serverInfos.add(serverInfo);
      }
      // Otherwise mark it as seen
      else {
        _serverInfos[alreadyKnownIdx].broadcastReceived = true;
      }
    });
  }

  void _onTileTapped(ServerInfo serverInfo) {
    log('Tile tapped');
  }

  void _onDisconnectIconTapped(ServerInfo serverInfo) {
    log('Disconnect tapped');
  }

  void _onRemoveIconTapped(ServerInfo serverInfo) {
    log('Remove tapped');
  }

  void _connectToServer(ServerInfo serverInfo) async {
    log('Connecting to ${serverInfo.address} port ${serverInfo.httpPort}...');
    try {
      Socket socket = await Socket.connect(serverInfo.address, serverInfo.httpPort);
      log('Successfully connected');
      _saveConnectionsToFile(_serverInfos);

      socket.close();
    } on SocketException catch (e) {
      log('Connection failed: $e');
    }
  }

  void _saveConnectionsToFile(List<ServerInfo> serverInfos) async {
    ConnectionStorage().write(serverInfos);
  }

  Future<List<ServerInfo>> _readConnectionsFromFile() async {
    final connections = await ConnectionStorage().read();
    final serverInfos = connections.map<ServerInfo>((conn) => ServerInfo.fromConnectionInfo(conn)).toList();
    return serverInfos;
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

    // Colors for the title, subtitle and description
    var titleColor = textStyle.color.withOpacity(0.4);
    var subtitleColor = textStyle.color.withOpacity(0.4);
    var descriptionColor = textStyle.color.withOpacity(0.4);

    if (serverInfo.broadcastReceived) {
      titleColor = textStyle.color;
      subtitleColor = textStyle.color.withOpacity(0.5);
      descriptionColor = textStyle.color.withOpacity(0.5);
    }

    if (serverInfo.connecting) {
      titleColor = textStyle.color;
      subtitleColor = textStyle.color.withOpacity(0.5);
      descriptionColor = textStyle.color.withOpacity(0.5);
    }

    if (serverInfo.connected) {
      titleColor = theme.primaryColor;
      subtitleColor = textStyle.color.withOpacity(0.5);
      descriptionColor = textStyle.color.withOpacity(0.5);
    }

    // Create the subtitle
    var subtitle = 'from ${serverInfo.user} @ ${serverInfo.hostname}';
    if (serverInfo.broadcastReceived || serverInfo.connected) {
      subtitle = 'Seen $subtitle';
    } else {
      subtitle = 'Previously seen $subtitle';
    }

    // Create the widget
    return Material(
      color: theme.scaffoldBackgroundColor,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serverInfo.title, style: TextStyle(color: titleColor, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
                  Container(height: 2),
                  Text(serverInfo.description, style: TextStyle(color: descriptionColor)),
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
    if (serverInfo.connected) {
      return Icon(CupertinoIcons.checkmark_alt, color: CupertinoTheme.of(context).primaryColor);
    } else if (serverInfo.connecting) {
      return CupertinoActivityIndicator();
    } else {
      return SizedBox();
    }
  }

  Widget _makeTrailingWidget(BuildContext context) {
    if (serverInfo.connected) {
      return CupertinoButton(
        child: Icon(CupertinoIcons.xmark_circle, color: CupertinoTheme.of(context).textTheme.textStyle.color),
        padding: const EdgeInsets.only(left: 10),
        onPressed: onDisconnectBtnTap,
      );
    } else if (serverInfo.previouslyConnected) {
      return CupertinoButton(
        child: Icon(CupertinoIcons.trash, color: CupertinoTheme.of(context).textTheme.textStyle.color),
        padding: const EdgeInsets.only(left: 10),
        onPressed: onRemoveBtnTap,
      );
    } else {
      return SizedBox();
    }
  }
}
