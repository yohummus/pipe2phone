import 'package:flutter/cupertino.dart';

class TerminalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: CupertinoColors.black,
          child: Text(
            'Terminal output\nThis could\nbe some long text...',
            style: TextStyle(
              color: CupertinoColors.white,
              fontFamily: "RobotoMono",
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
