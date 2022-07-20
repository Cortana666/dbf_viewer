import 'dart:async';

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'package:dbf_viewer/dbf.dart';
import 'package:dbf_viewer/dbf_source.dart';
import 'package:dbf_viewer/menu.dart';

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

    Widget body = MacosWindow(
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
    );

    return MacosApp(
      title: 'DBF Viewer',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Menu(
          body: body,
          arg: <String, dynamic>{'dbf': dbfController, 'source': dbfSource}),
      debugShowCheckedModeBanner: true,
    );
  }
}
