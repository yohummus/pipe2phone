import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'server_info.dart';

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
          log('ERROR: Failed to parse broadcast message: $e');
        }

        // Propagate the new server information
        widget.onServerInfoReceived(serverInfo);
      });
    });
  }
}
