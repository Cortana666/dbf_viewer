import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:collection/collection.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'package:dbf_viewer/about.dart';
import 'package:dbf_viewer/index.dart';
import 'package:dbf_viewer/info.dart';
import 'package:dbf_viewer/table.dart' as data_table;

void main(List<String> args) {
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    if (arguments['window_type'] == 'open') {
      runApp(data_table.Table(
        windowController: WindowController.fromWindowId(windowId),
        args: arguments,
      ));
    }
    if (arguments['window_type'] == 'about') {
      runApp(About(
        windowController: WindowController.fromWindowId(windowId),
        args: arguments,
      ));
    }
    if (arguments['window_type'] == 'info') {
      runApp(Info(
        windowController: WindowController.fromWindowId(windowId),
        args: arguments,
      ));
    }
  } else {
    runApp(const App());
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'DBF Viewer',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const Index(),
      debugShowCheckedModeBanner: true,
    );
  }
}
