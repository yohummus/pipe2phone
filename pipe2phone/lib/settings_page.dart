import 'package:flutter/cupertino.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Connected to 192.168.1.100'),
      ),
      backgroundColor: CupertinoColors.systemBackground,
      child: Center(child: Text('Settings')),
    );
  }
}
