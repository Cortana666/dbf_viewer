import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import 'package:dbf_viewer/data_source.dart';
import 'package:dbf_viewer/dbf.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DBF Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RxBool isChoose = false.obs;
  RxBool isOpen = false.obs;

  RxInt pageRows = 20.obs;
  RxInt? sortIndex;
  RxBool sortAscending = false.obs;

  final Dbf _dbf = Get.put(Dbf());
  final DbfDataSource _dbfDataSource = Get.put(DbfDataSource());
  final TextEditingController _searchController = TextEditingController();

  Widget _initBody() {
    if (isChoose.value) {
      if (isOpen.value) {
        return ListView(
          children: [
            PaginatedDataTable(
              header: Container(
                margin: const EdgeInsets.only(
                  top: 20,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _searchController,
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
                          _dbfDataSource.keyword = _searchController.text;
                          _dbfDataSource.sync();
                          _dbfDataSource.flush();
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
                      Map<String, dynamic> res = _dbf.add();
                      if (res['code'] == 1) {
                        Map<String, dynamic> row = {};
                        _dbf.field.forEach((key, value) {
                          row[key] = '';
                        });

                        _dbf.data.add(row);
                        _dbfDataSource.sync();
                        _dbfDataSource.flush();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('添加完成，请编辑数据'),
                            duration: Duration(milliseconds: 1000),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    top: 20,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (_dbfDataSource.select.isEmpty) {
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
                                '确定是否删除${_dbfDataSource.select.length}条数据'),
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
                              _dbf.delete(_dbfDataSource.select);
                          if (res['code'] == 1) {
                            _dbfDataSource.select
                                .sort((a, b) => b.compareTo(a));
                            for (var item in _dbfDataSource.select) {
                              _dbfDataSource.source.removeAt(item);
                              _dbf.order.removeAt(item);
                            }
                            _dbfDataSource.select = [];
                            _dbfDataSource.sync();
                            _dbfDataSource.flush();

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
                    icon: const Icon(Icons.delete),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    top: 20,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      String? outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'Please select an output file:',
                        fileName: 'output-file.dbf',
                        type: FileType.any,
                        allowedExtensions: ['dbf'],
                      );

                      if (outputFile != null) {
                        File file = File(outputFile);
                        await file.writeAsBytes(_dbf.dbf);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('导出完成'),
                            duration: Duration(milliseconds: 1000),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                  ),
                ),
              ],
              showCheckboxColumn: true,
              sortColumnIndex: sortIndex?.value,
              sortAscending: sortAscending.value,
              columns: _dbf.field.keys.map((key) {
                return DataColumn(
                    label: Text(
                      key,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    onSort: (index, ascSort) {
                      _dbfDataSource.sort(key, ascSort);
                      sortIndex?.value = index;
                      sortAscending.value = ascSort;
                    });
              }).toList(),
              source: _dbfDataSource,
              rowsPerPage: pageRows.value,
              showFirstLastButtons: true,
              availableRowsPerPage: const [20, 50, 100, 500, 1000],
              onRowsPerPageChanged: (value) {
                pageRows.value = value!;
              },
            ),
          ],
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    } else {
      return const Center(
        child: Text('请选择文件'),
      );
    }
  }

  void _openFile() async {
    if (!isChoose.value || (isChoose.value && isOpen.value)) {
      isChoose.value = true;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dbf'],
      );

      if (result != null) {
        _dbfDataSource.init(context);
        isOpen.value = false;
        pageRows.value = 20;
        sortIndex = null;
        sortAscending.value = false;
        int x = 0;
        _dbf.init(result.files.single.path ?? '');

        Timer.periodic(const Duration(microseconds: 200), (timer) async {
          int y = x;
          int j = x;
          int z = _dbf.data.length;
          if (_dbf.data.length - x >= 10000) {
            x += 10000;
            for (var i = y; i < j + 10000; i++) {
              _dbf.data[i].forEach((key, value) {
                _dbf.dataController['${_dbf.order[i]}_$key'] =
                    TextEditingController();
                _dbf.dataController['${_dbf.order[i]}_$key']?.text = value;
              });
            }
          } else {
            if (_dbf.data.length - x > 0) {
              x = z;
              for (var i = y; i < z; i++) {
                _dbf.data[i].forEach((key, value) {
                  _dbf.dataController['${_dbf.order[i]}_$key'] =
                      TextEditingController();
                  _dbf.dataController['${_dbf.order[i]}_$key']?.text = value;
                });
              }
            }
          }

          if (_dbf.lines == _dbf.line) {
            timer.cancel();

            _dbfDataSource.source = _dbf.data;
            _dbfDataSource.sync();
            _dbfDataSource.flush();
            isOpen.value = true;
          }
        });
      } else {
        if (!isOpen.value) {
          isChoose.value = false;
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在处理文件，请稍候'),
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: _initBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: _openFile,
          child: const Icon(Icons.folder_open),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}
