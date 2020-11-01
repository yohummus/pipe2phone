import 'package:flutter/cupertino.dart';

class TerminalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Connected to 192.168.1.100'),
      ),
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Text(
          'Terminal output\nThis could\nbe some long text...',
          style: TextStyle(
            color: CupertinoColors.white,
            fontFamily: "RobotoMono",
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
