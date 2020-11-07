import 'package:flutter/cupertino.dart';

abstract class AppPage extends StatefulWidget {
  final pageActiveNotifier = ValueNotifier<bool>(false);

  void onNavigatedToPage() {
    pageActiveNotifier.value = true;
  }

  void onNavigatedAwayFromPage() {
    pageActiveNotifier.value = false;
  }
}
