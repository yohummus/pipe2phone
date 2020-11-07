import 'package:flutter/cupertino.dart';

import 'app_page.dart';

class AppTerminalPage extends AppPage {
  @override
  _AppTerminalPageState createState() => _AppTerminalPageState();
}

class _AppTerminalPageState extends State<AppTerminalPage> {
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
