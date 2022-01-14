import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:dbf_viewer/source.dart';
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
  bool isRead = false;

  RxInt pageRows = 20.obs;
  RxInt? sortIndex;
  RxBool sortAscending = false.obs;

  late String fileName;
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
                        _dbfDataSource.dataController[_dbf.recordLines - 1] =
                            {};
                        _dbf.field.forEach((key, value) {
                          row[key] = '';
                        });
                        row['_selfkey'] = _dbf.recordLines - 1;
                        _dbf.field.forEach((key, value) {
                          _dbfDataSource
                                  .dataController[_dbf.recordLines - 1]![key] =
                              TextEditingController();
                          _dbfDataSource
                              .dataController[_dbf.recordLines - 1]![key]
                              ?.text = '';
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
                            _dbf.data
                                .asMap()
                                .keys
                                .toList()
                                .reversed
                                .forEach((element) {
                              if (_dbfDataSource.select
                                  .contains(_dbf.data[element]['_selfkey'])) {
                                _dbf.data.removeAt(element);
                              }
                            });

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
                      if (Platform.isMacOS ||
                          Platform.isWindows ||
                          Platform.isLinux) {
                        String? outputFile = await FilePicker.platform.saveFile(
                          dialogTitle: 'Please select an output file:',
                          fileName: fileName,
                          type: FileType.any,
                          allowedExtensions: ['dbf'],
                        );

                        if (outputFile != null) {
                          File file = File(outputFile);
                          await file.writeAsBytes(_dbf.dbfSocket);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('导出完成'),
                              duration: Duration(milliseconds: 1000),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('手机端暂不支持导出功能'),
                            duration: Duration(milliseconds: 1000),
                            backgroundColor: Colors.red,
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
                      if (sortIndex == null) {
                        sortIndex = index.obs;
                      } else {
                        sortIndex?.value = index;
                      }
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
        allowedExtensions: ['dbf', 'DBF'],
      );

      if (result != null) {
        fileName = result.files.single.name;
        _dbfDataSource.init(context);
        isOpen.value = false;
        isRead = false;
        pageRows.value = 20;
        sortIndex = null;
        sortAscending.value = false;
        _searchController.text = '';
        _dbf.init(result.files.single.path ?? '');

        Timer.periodic(const Duration(microseconds: 200), (timer) async {
          if (!isRead && _dbf.isOpen) {
            isRead = true;
            for (var i = _dbfDataSource.dataController.length;
                i < _dbfDataSource.dataController.length + 10000;
                i++) {
              if (_dbfDataSource.dataController.length == _dbf.data.length) {
                timer.cancel();
                _dbfDataSource.sync();
                _dbfDataSource.flush();
                isOpen.value = true;

                if (Platform.isAndroid || Platform.isIOS) {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight
                  ]);
                }

                break;
              }

              _dbf.data[i].forEach((key, value) {
                if (!_dbfDataSource.dataController
                    .containsKey(_dbf.data[i]['_selfkey'])) {
                  _dbfDataSource.dataController[_dbf.data[i]['_selfkey']] = {};
                }
                _dbfDataSource.dataController[_dbf.data[i]['_selfkey']]![key] =
                    TextEditingController();
                _dbfDataSource.dataController[_dbf.data[i]['_selfkey']]![key]
                    ?.text = value.toString();
              });
            }

            isRead = false;
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
          duration: Duration(milliseconds: 1000),
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
