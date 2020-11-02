import 'package:flutter/cupertino.dart';

import 'scripts_page.dart';
import 'connection_page.dart';
import 'terminal_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'pipe2phone',
      home: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(items: [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.play), label: 'Scripts'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.device_desktop), label: 'Terminal'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.link), label: 'Connection'),
          ]),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) {
                switch (index) {
                  case 0:
                    return ScriptsPage();
                  case 1:
                    return TerminalPage();
                  case 2:
                    return ConnectionPage();
                  default:
                    return null;
                }
              },
            );
          },
        ),
      ),
    );
  }
}
