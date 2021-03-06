import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_page.dart';

class AppScriptsPage extends AppPage {
  @override
  _AppScriptsPageState createState() => _AppScriptsPageState();
}

class _AppScriptsPageState extends State<AppScriptsPage> {
  @override
  Widget build(BuildContext context) {
    final scripts = [
      {
        'title': 'Say hello world',
        'description': 'Example script to just say "Hello World!"',
        'icon': CupertinoIcons.bubble_left,
      },
      {
        'title': 'Show the CPU load',
        'description': 'Shows the CPU load in regular intervals',
        'icon': CupertinoIcons.speedometer,
      },
      {
        'title': 'Cleanup & re-run',
        'description': 'Clean up temporary files and run the program again to create some more files',
        'icon': CupertinoIcons.alarm_fill,
      },
    ];

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Navigator(onGenerateRoute: (settings) {
        return _PageRoute<void>(
          title: 'Scripts',
          builder: (context) => CupertinoPageScaffold(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: MediaQuery.of(context).padding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final scriptInfo = scripts[index ~/ 2];
                        if (index % 2 == 0) {
                          return Material(
                            child: ListTile(
                              tileColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
                              onTap: () {
                                Navigator.of(context).push(CupertinoPageRoute<void>(
                                  title: scriptInfo['title'],
                                  builder: (context) => _ScriptDetailsPage(),
                                ));
                              },
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    scriptInfo['icon'],
                                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                                  ),
                                ],
                              ),
                              title: Text(
                                scriptInfo['title'],
                                style: TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color),
                              ),
                              subtitle: Text(
                                scriptInfo['description'],
                                style: TextStyle(
                                    color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5)),
                              ),
                            ),
                          );
                        } else {
                          return Divider(
                            color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5),
                          );
                        }
                      },
                      childCount: scripts.length * 2 - 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ScriptDetailsPage extends StatelessWidget {
  bool _fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        trailing: CupertinoButton(
          child: Icon(
            CupertinoIcons.play_fill,
            color: CupertinoColors.activeGreen,
          ),
          padding: const EdgeInsets.all(0),
          onPressed: () {
            log('Play/stop button pressed');
          },
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            log('Toggling fullscreen...');
            if (_fullscreen) {
              SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
            } else {
              SystemChrome.setEnabledSystemUIOverlays([]);
            }

            _fullscreen = !_fullscreen;
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
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
      ),
      backgroundColor: CupertinoColors.black,
    );
  }
}

class _PageRoute<T> extends CupertinoPageRoute<T> {
  _PageRoute({
    @required WidgetBuilder builder,
    String title,
  }) : super(builder: builder, title: title);

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
