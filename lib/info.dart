import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

class Info extends StatelessWidget {
  const Info({
    super.key,
    required this.windowController,
    required this.args,
  });

  final WindowController windowController;
  final Map? args;

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, dynamic>> field = {};
    args!['dbf_field'].forEach(
      (key, value) {
        field[key] = value;
      },
    );

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
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 10,
                          columns: const <DataColumn>[
                            DataColumn(
                              label: SelectableText('字段名称'),
                            ),
                            DataColumn(
                              label: SelectableText('字段类型'),
                            ),
                            DataColumn(
                              label: SelectableText('字段长度'),
                            ),
                            DataColumn(
                              label: SelectableText('小数位数'),
                            ),
                          ],
                          rows: field.keys.map((key) {
                            return DataRow(
                              cells: <DataCell>[
                                DataCell(SelectableText(key)),
                                DataCell(SelectableText(field[key]!['type'])),
                                DataCell(SelectableText(
                                    field[key]!['len'].toString())),
                                DataCell(SelectableText(
                                    field[key]!['dec'].toString())),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      DataTable(
                        columnSpacing: 10,
                        columns: <DataColumn>[
                          const DataColumn(
                            label: SelectableText('文件版本'),
                          ),
                          DataColumn(
                            label: SelectableText(args!['dbf_edition']),
                          ),
                        ],
                        rows: <DataRow>[
                          DataRow(
                            cells: <DataCell>[
                              const DataCell(SelectableText('更新时间')),
                              DataCell(SelectableText(args!['dbf_time'])),
                            ],
                          ),
                          DataRow(
                            cells: <DataCell>[
                              const DataCell(SelectableText('数据条数')),
                              DataCell(
                                  SelectableText(args!['dbf_line'].toString())),
                            ],
                          ),
                        ],
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
