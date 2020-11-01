import 'package:flutter/cupertino.dart';

import 'scripts_page.dart';
import 'settings_page.dart';
import 'terminal_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'pipe2phone',
      home: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(items: [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_plaintext), label: 'Scripts'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.device_desktop), label: 'Terminal'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.gear_alt_fill), label: 'Settings'),
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
                    return SettingsPage();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
