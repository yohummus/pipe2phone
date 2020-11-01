import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScriptsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scripts = [
      {
        'title': 'Say hello world',
        'description': 'Example script to just say "Hello World!"',
        'icon': CupertinoIcons.airplane,
      },
      {
        'title': 'Show the CPU load',
        'description': 'Shows the CPU load in regular intervals',
        'icon': CupertinoIcons.person_crop_square,
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
                        final scriptInfo = scripts[index];
                        return Material(
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(CupertinoPageRoute<void>(
                                title: scriptInfo['title'],
                                builder: (context) => _ScriptDetailsPage(),
                              ));
                            },
                            leading: Icon(scriptInfo['icon']),
                            title: Text(scriptInfo['title']),
                            subtitle: Text(scriptInfo['description']),
                          ),
                        );
                      },
                      childCount: scripts.length,
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
            log('Button pressed');
          },
        ),
      ),
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
