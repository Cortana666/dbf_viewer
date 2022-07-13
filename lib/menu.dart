import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class Menu {
  List<MenuItem> menu() {
    return [
      PlatformMenu(
        label: 'DbfViewer',
        menus: [
          PlatformMenuItem(
            label: '关于',
            onSelected: () async {
              final window = await DesktopMultiWindow.createWindow(jsonEncode(
                {
                  'window_type': 'about',
                },
              ));
              debugPrint('$window');
              window
                ..setFrame(const Offset(0, 0) & const Size(350, 350))
                ..center()
                ..setTitle('关于DBF Viewer')
                ..show();
            },
          ),
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.quit,
          ),
        ],
      ),
      PlatformMenu(
        label: '文件',
        menus: [
          PlatformMenuItem(
            label: '打开...',
            onSelected: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dbf', 'DBF'],
              );

              if (result != null) {
                final prefs = await SharedPreferences.getInstance();
                int? counter = prefs.getInt('counter');
                if (counter == null) {
                  counter = 0;
                  await prefs.setInt('counter', counter);
                  await prefs.setString(
                      'file_{$counter}_name', result.files.single.name);
                  await prefs.setString(
                      'file_{$counter}_path', result.files.single.path!);
                } else {
                  bool isHistory = false;
                  for (var i = 0; i <= counter; i++) {
                    if (prefs.getString('file_{$i}_path') ==
                        result.files.single.path) {
                      isHistory = true;
                    }
                  }
                  if (!isHistory) {
                    counter++;
                    await prefs.setInt('counter', counter);
                    await prefs.setString(
                        'file_{$counter}_name', result.files.single.name);
                    await prefs.setString(
                        'file_{$counter}_path', result.files.single.path!);
                  }
                }

                final window = await DesktopMultiWindow.createWindow(jsonEncode(
                  {
                    'window_type': 'open',
                    'path': result.files.single.path,
                    'name': result.files.single.name
                  },
                ));
                debugPrint('$window');
                window
                  ..setFrame(const Offset(0, 0) & const Size(1366, 768))
                  ..center()
                  ..setTitle(result.files.single.name)
                  ..show();
              }
            },
          )
        ],
      ),
    ];
  }
}
