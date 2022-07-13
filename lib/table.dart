import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'package:dbf_viewer/dbf.dart';
import 'package:dbf_viewer/dbf_source.dart';

class Table extends StatelessWidget {
  const Table({
    super.key,
    required this.windowController,
    required this.args,
  });

  final WindowController windowController;
  final Map? args;

  @override
  Widget build(BuildContext context) {
    final Dbf dbfController = Dbf();
    final DbfSource dbfSource = DbfSource();
    final TextEditingController searchController = TextEditingController();

    dbfController.init(args!['path']);
    dbfSource.init(context, dbfController);
    bool isOpen = false;
    bool isRead = false;
    int pageRows = 20;
    int sortIndex = -1;
    bool sortAscending = false;
    searchController.text = '';

    Timer.periodic(const Duration(microseconds: 200), (timer) async {
      if (!isRead && dbfController.isOpen) {
        isRead = true;
        for (var i = dbfSource.dataController.length;
            i < dbfSource.dataController.length + 10000;
            i++) {
          if (dbfSource.dataController.length == dbfController.data.length) {
            timer.cancel();
            dbfSource.sync();
            dbfSource.flush();
            isOpen = true;

            break;
          }

          dbfController.data[i].forEach((key, value) {
            if (!dbfSource.dataController
                .containsKey(dbfController.data[i]['_selfkey'])) {
              dbfSource.dataController[dbfController.data[i]['_selfkey']] = {};
            }
            dbfSource.dataController[dbfController.data[i]['_selfkey']]![key] =
                TextEditingController();
            dbfSource.dataController[dbfController.data[i]['_selfkey']]![key]
                ?.text = value.toString();
          });
        }

        isRead = false;
      }
    });

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
                  child: PaginatedDataTable(
                    header: Container(
                      margin: const EdgeInsets.only(
                        top: 20,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '待搜索文本',
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                              left: 5,
                            ),
                            height: 50,
                            child: ElevatedButton(
                              child: const Text('搜索'),
                              onPressed: () {
                                dbfSource.keyword = searchController.text;
                                dbfSource.sync();
                                dbfSource.flush();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Map<String, dynamic> res = dbfController.add();
                            if (res['code'] == 1) {
                              Map<String, dynamic> row = {};
                              dbfSource.dataController[
                                  dbfController.recordLines - 1] = {};
                              dbfController.field.forEach((key, value) {
                                row[key] = '';
                              });
                              row['_selfkey'] = dbfController.recordLines - 1;
                              dbfController.field.forEach((key, value) {
                                dbfSource.dataController[
                                        dbfController.recordLines - 1]![key] =
                                    TextEditingController();
                                dbfSource
                                    .dataController[
                                        dbfController.recordLines - 1]![key]
                                    ?.text = '';
                              });

                              dbfController.data.add(row);
                              dbfSource.sync();
                              dbfSource.flush();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('添加完成，请编辑数据'),
                                  duration: Duration(milliseconds: 1000),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            if (dbfSource.select.isEmpty) {
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
                                      '确定是否删除${dbfSource.select.length}条数据'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, '0'),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, '1'),
                                      child: const Text('确定'),
                                    ),
                                  ],
                                ),
                              );

                              if (res == '1') {
                                Map<String, dynamic> res =
                                    dbfController.delete(dbfSource.select);
                                if (res['code'] == 1) {
                                  dbfController.data
                                      .asMap()
                                      .keys
                                      .toList()
                                      .reversed
                                      .forEach((element) {
                                    if (dbfSource.select.contains(dbfController
                                        .data[element]['_selfkey'])) {
                                      dbfController.data.removeAt(element);
                                    }
                                  });

                                  dbfSource.select = [];
                                  dbfSource.sync();
                                  dbfSource.flush();

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
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                content: SingleChildScrollView(
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
                                          rows: dbfController.field.keys
                                              .map((key) {
                                            return DataRow(
                                              cells: <DataCell>[
                                                DataCell(SelectableText(key)),
                                                DataCell(SelectableText(
                                                    dbfController
                                                        .field[key]!['type'])),
                                                DataCell(SelectableText(
                                                    dbfController
                                                        .field[key]!['len']
                                                        .toString())),
                                                DataCell(SelectableText(
                                                    dbfController
                                                        .field[key]!['dec']
                                                        .toString())),
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
                                            label: SelectableText(
                                                dbfController.dbfEdition),
                                          ),
                                        ],
                                        rows: <DataRow>[
                                          DataRow(
                                            cells: <DataCell>[
                                              const DataCell(
                                                  SelectableText('更新时间')),
                                              DataCell(SelectableText(
                                                  dbfController.updateTime)),
                                            ],
                                          ),
                                          DataRow(
                                            cells: <DataCell>[
                                              const DataCell(
                                                  SelectableText('数据条数')),
                                              DataCell(SelectableText(
                                                  dbfController.recordLines
                                                      .toString())),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('关闭'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          top: 20,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            String? outputFile =
                                await FilePicker.platform.saveFile(
                              dialogTitle: 'Please select an output file:',
                              fileName: args!['name'],
                              type: FileType.any,
                              allowedExtensions: ['dbf'],
                            );

                            if (outputFile != null) {
                              File file = File(outputFile);
                              await file.writeAsBytes(dbfController.dbfSocket);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('导出完成'),
                                  duration: Duration(milliseconds: 1000),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download_for_offline_outlined),
                        ),
                      ),
                    ],
                    showCheckboxColumn: true,
                    sortColumnIndex: (sortIndex == -1) ? null : sortIndex,
                    sortAscending: sortAscending,
                    columns: dbfController.field.keys.map((key) {
                      return DataColumn(
                          label: Text(key),
                          onSort: (index, ascSort) {
                            dbfSource.sort(key, ascSort);
                            sortIndex = index;
                            sortAscending = ascSort;
                          });
                    }).toList(),
                    source: dbfSource,
                    rowsPerPage: pageRows,
                    showFirstLastButtons: true,
                    availableRowsPerPage: const [20, 50, 100, 200, 500],
                    onRowsPerPageChanged: (value) {
                      pageRows = value!;
                    },
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
