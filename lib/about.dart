import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class About extends StatelessWidget {
  const About({
    super.key,
    required this.windowController,
    required this.args,
  });

  final WindowController windowController;
  final Map? args;

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'DBF Viewer',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: MacosWindow(
        child: MacosScaffold(
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '关于DBF Viewer',
                        style: MacosTheme.of(context).typography.largeTitle,
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        '基于Flutter开发的DBF本地数据库文件查看编辑工具',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: true,
    );
  }
}
