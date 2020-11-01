import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScriptsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scripts = {
      'hello': {'title': 'Say hello world', 'icon': CupertinoIcons.airplane},
      'load': {'title': 'Show the CPU load', 'icon': CupertinoIcons.person_crop_square},
    };

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Connected to 192.168.1.100'),
      ),
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
                        final title = 'Hey dude blabla #$index';
                        return Material(
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(CupertinoPageRoute<void>(
                                title: title,
                                builder: (context) => _ScriptDetailsPage(),
                              ));
                            },
                            title: Text(title),
                          ),
                        );
                      },
                      childCount: 3,
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
      navigationBar: const CupertinoNavigationBar(),
      child: Center(
        child: Text('Hello World!'),
      ),
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
