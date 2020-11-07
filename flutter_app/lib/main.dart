import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_page.dart';
import 'app_scripts_page.dart';
import 'app_connection_page.dart';
import 'app_terminal_page.dart';

void main() => runApp(MyApp());

class PageInfo {
  final IconData icon;
  final String title;
  final AppPage widget;

  PageInfo({this.icon, this.title, this.widget});
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  CupertinoTabController _tabController;
  int _activePageIndex = 2; // Also the default page at startup

  final List<PageInfo> _pages = [
    PageInfo(icon: CupertinoIcons.play, title: 'Scripts', widget: AppScriptsPage()),
    PageInfo(icon: CupertinoIcons.device_desktop, title: 'Terminal', widget: AppTerminalPage()),
    PageInfo(icon: CupertinoIcons.link, title: 'Connection', widget: AppConnectionPage()),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController(initialIndex: _activePageIndex);
    _tabController.addListener(_onNavigatedToDifferentPage);

    log('Initial navigation to ${_pages[_activePageIndex].title} page');
    _pages[_activePageIndex].widget.onNavigatedToPage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'pipe2phone',
      home: DefaultTextStyle(
        style: CupertinoTheme.of(context).textTheme.textStyle,
        child: CupertinoTabScaffold(
          controller: _tabController,
          tabBar: CupertinoTabBar(
            items: [for (var page in _pages) BottomNavigationBarItem(icon: Icon(page.icon), label: page.title)],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(builder: (context) {
              return _pages[index].widget;
            });
          },
        ),
      ),
    );
  }

  void _onNavigatedToDifferentPage() {
    log('Navigated from ${_pages[_activePageIndex].title} page to ${_pages[_tabController.index].title} page');
    _pages[_activePageIndex].widget.onNavigatedAwayFromPage();
    _activePageIndex = _tabController.index;
    _pages[_activePageIndex].widget.onNavigatedToPage();
  }
}
