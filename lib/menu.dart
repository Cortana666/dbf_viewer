import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class Menu extends StatefulWidget {
  const Menu({Key? key, required this.body, required this.arg})
      : super(key: key);
  final Widget body;
  final dynamic arg;

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
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

                  final window =
                      await DesktopMultiWindow.createWindow(jsonEncode(
                    {
                      'window_type': 'open',
                      'path': result.files.single.path,
                      'name': result.files.single.name,
                    },
                  ));
                  debugPrint('$window');
                  window
                    ..setFrame(const Offset(0, 0) & const Size(800, 600))
                    ..center()
                    ..setTitle(result.files.single.name)
                    ..show();
                }
              },
            ),
            PlatformMenuItem(
              label: '另存为...',
              onSelected: () async {
                String? outputFile = await FilePicker.platform.saveFile(
                  dialogTitle: '请选择导出文件:',
                  type: FileType.any,
                  allowedExtensions: ['dbf'],
                );

                if (outputFile != null) {
                  File file = File(outputFile);
                  await file.writeAsBytes(widget.arg['dbf'].dbfSocket);
                }
              },
            ),
            PlatformMenuItem(
              label: '属性',
              onSelected: () async {
                Map<String, Map<String, dynamic>> field =
                    widget.arg['dbf'].field;
                final window = await DesktopMultiWindow.createWindow(jsonEncode(
                  {
                    'window_type': 'info',
                    'dbf_field': field,
                    'dbf_time': widget.arg['dbf'].updateTime,
                    'dbf_edition': widget.arg['dbf'].dbfEdition,
                    'dbf_line': widget.arg['dbf'].recordLines,
                  },
                ));
                debugPrint('$window');
                window
                  ..setFrame(const Offset(0, 0) & const Size(800, 600))
                  ..center()
                  ..setTitle('文件属性')
                  ..show();
              },
            ),
          ],
        ),
        PlatformMenu(
          label: '编辑',
          menus: [
            PlatformMenuItem(
              label: '添加空行',
              onSelected: () async {
                Map<String, dynamic> res = widget.arg['dbf'].add();
                if (res['code'] == 1) {
                  Map<String, dynamic> row = {};
                  widget.arg['source']
                      .dataController[widget.arg['dbf'].recordLines - 1] = {};
                  widget.arg['dbf'].field.forEach((key, value) {
                    row[key] = '';
                  });
                  row['_selfkey'] = widget.arg['dbf'].recordLines - 1;
                  widget.arg['dbf'].field.forEach((key, value) {
                    widget.arg['source'].dataController[
                            widget.arg['dbf'].recordLines - 1]![key] =
                        TextEditingController();
                    widget
                        .arg['source']
                        .dataController[widget.arg['dbf'].recordLines - 1]![key]
                        ?.text = '';
                  });

                  widget.arg['dbf'].data.add(row);
                  widget.arg['source'].sync();
                  widget.arg['source'].flush();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('添加完成，请编辑数据'),
                      duration: Duration(milliseconds: 1000),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            PlatformMenuItem(
              label: '删除选中',
              onSelected: () async {
                if (widget.arg['source'].select.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请勾选要删除的数据'),
                      duration: Duration(milliseconds: 1000),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  final String? res = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('警告'),
                      content: Text(
                          '确定是否删除${widget.arg['source'].select.length}条数据'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, '0'),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, '1'),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );

                  if (res == '1') {
                    Map<String, dynamic> res =
                        widget.arg['dbf'].delete(widget.arg['source'].select);
                    if (res['code'] == 1) {
                      widget.arg['dbf'].data
                          .asMap()
                          .keys
                          .toList()
                          .reversed
                          .forEach((element) {
                        if (widget.arg['source'].select.contains(
                            widget.arg['dbf'].data[element]['_selfkey'])) {
                          widget.arg['dbf'].data.removeAt(element);
                        }
                      });

                      widget.arg['source'].select = [];
                      widget.arg['source'].sync();
                      widget.arg['source'].flush();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('删除完成'),
                          duration: Duration(milliseconds: 1000),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ],
      body: widget.body,
    );
  }
}
