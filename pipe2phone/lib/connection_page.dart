import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConnectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
              padding: MediaQuery.of(context).padding,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index % 2 == 0) {
                      return Material(
                        child: ListTile(
                          tileColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
                          onTap: () {
                            log('Selected');
                          },
                          title: Text(
                            'Hello',
                            style: TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color),
                          ),
                          subtitle: Text(
                            'Blabla',
                            style:
                                TextStyle(color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5)),
                          ),
                          trailing: Icon(
                            CupertinoIcons.minus_circle,
                            color: CupertinoTheme.of(context).textTheme.textStyle.color,
                          ),
                        ),
                      );
                    } else {
                      return Divider(
                        color: CupertinoTheme.of(context).textTheme.textStyle.color.withOpacity(0.5),
                      );
                    }
                  },
                  childCount: 3 * 2 - 1,
                ),
              ))
        ],
      ),
    );
  }
}
