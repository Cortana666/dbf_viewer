import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'package:dbf_viewer/menu.dart';

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  int _pageIndex = 0;
  Map<int, Map<String, String>> history = {};

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: Menu().menu(),
      body: MacosWindow(
        sidebar: Sidebar(
          minWidth: 200,
          builder: (context, scrollController) => SidebarItems(
            currentIndex: _pageIndex,
            onChanged: (index) async {
              final prefs = await SharedPreferences.getInstance();
              int? counter = prefs.getInt('counter');
              if (counter != null) {
                for (var i = 0; i <= counter; i++) {
                  history[i] = {
                    'name': prefs.getString('file_{$i}_name')!,
                    'path': prefs.getString('file_{$i}_path')!
                  };
                }
              }
              setState(() => _pageIndex = index);
            },
            items: const [
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.home),
                label: Text('首页'),
              ),
              SidebarItem(
                leading:
                    MacosIcon(CupertinoIcons.rectangle_stack_fill_badge_plus),
                label: Text('历史记录'),
              ),
            ],
          ),
        ),
        child: IndexedStack(
          index: _pageIndex,
          children: [
            const HomePage(),
            HistoryPage(
              history: history,
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MacosScaffold(
          toolBar: ToolBar(
            title: const Text('首页'),
            actions: [
              ToolBarIconButton(
                label: '左边栏',
                icon: const MacosIcon(CupertinoIcons.sidebar_left),
                showLabel: false,
                tooltipMessage: '左边栏',
                onPressed: () {
                  MacosWindowScope.of(context).toggleSidebar();
                },
              )
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return const Center(
                  child: Text('欢迎使用'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.history,
  });

  final Map<int, Map<String, String>> history;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MacosScaffold(
          toolBar: ToolBar(
            title: const Text('历史记录'),
            actions: [
              ToolBarIconButton(
                label: '左边栏',
                icon: const MacosIcon(CupertinoIcons.sidebar_left),
                showLabel: false,
                tooltipMessage: '左边栏',
                onPressed: () {
                  MacosWindowScope.of(context).toggleSidebar();
                },
              )
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                if (history.isEmpty) {
                  return const Center(
                    child: Text('历史记录'),
                  );
                } else {
                  return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: history.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Material(
                            child: ListTile(
                                onTap: () async {
                                  final window =
                                      await DesktopMultiWindow.createWindow(
                                          jsonEncode(
                                    {
                                      'window_type': 'open',
                                      'path': history[index]!['path'],
                                      'name': history[index]!['name']
                                    },
                                  ));
                                  debugPrint('$window');
                                  window
                                    ..setFrame(const Offset(0, 0) &
                                        const Size(1366, 768))
                                    ..center()
                                    ..setTitle(history[index]!['path'] ?? '')
                                    ..show();
                                },
                                title: Text(
                                    '${history[index]!['name']}(${history[index]!['path']})')));
                      });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
