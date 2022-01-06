import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fast_gbk/fast_gbk.dart';

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
  bool isChoose = false;
  bool isOpen = false;
  bool isRead = false;
  late Timer readTimer;
  late Map<String, int> fieldInfo;

  int pageRows = 20;
  int? sortIndex;
  bool sortAscending = false;

  late Uint8List dbf;

  final DbfDataSource _dbfDataSource = DbfDataSource();
  final Dbf _dbf = Dbf();
  final TextEditingController _searchController = TextEditingController();

  Widget _initBody() {
    if (isChoose) {
      if (isOpen) {
        List<DataColumn> title = [];

        fieldInfo.forEach((key, value) {
          title.add(
            DataColumn(
                label: Text(
                  key,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                onSort: (index, ascSort) {
                  sortIndex = index;
                  sortAscending = ascSort;
                  _dbfDataSource.sort(key, ascSort);
                  setState(() {});
                }),
          );
        });

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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('添加功能开发中'),
                          duration: Duration(milliseconds: 100),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    top: 20,
                  ),
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('删除功能开发中'),
                          duration: Duration(milliseconds: 100),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                        await file.writeAsBytes(dbf);

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
              sortColumnIndex: sortIndex,
              sortAscending: sortAscending,
              columns: title,
              source: _dbfDataSource,
              rowsPerPage: pageRows,
              showFirstLastButtons: true,
              availableRowsPerPage: const [20, 50, 100, 500, 1000],
              onRowsPerPageChanged: (value) {
                pageRows = value!;
                setState(() {});
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
    if (!isChoose) {
      isChoose = true;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dbf'],
      );

      if (result != null) {
        if (isRead) {
          readTimer.cancel();
        }
        isOpen = false;
        isRead = false;
        pageRows = 20;
        sortIndex = null;
        sortAscending = false;
        _dbfDataSource.init();
        fieldInfo = {};
        setState(() {});

        _dbf.init(result.files.single.path ?? '');

        // readFile(result.files.single.path ?? '');
      }

      isChoose = false;
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

  void readFile(String path) async {
    File file = File(path);
    dbf = await file.readAsBytes();
    int p = 0;
    int line = 0;
    bool goon = true;
    p += 32;

    int recordCount =
        ByteData.view(Uint8List.fromList(dbf.getRange(4, 8).toList()).buffer)
            .getUint32(0, Endian.little);
    int firstRecord =
        ByteData.view(Uint8List.fromList(dbf.getRange(8, 10).toList()).buffer)
            .getUint16(0, Endian.little);
    int recordLength =
        ByteData.view(Uint8List.fromList(dbf.getRange(10, 12).toList()).buffer)
            .getUint16(0, Endian.little);

    while (goon && p <= file.lengthSync()) {
      Uint8List buf = Uint8List.fromList(dbf.getRange(p, p + 32).toList());
      p += 32;
      if (buf.first == 13) {
        goon = false;
      } else {
        List fieldNameCodes = buf.getRange(0, 11).toList();
        int fieldNameP = 0;
        for (var item in fieldNameCodes) {
          if (item == 0) {
            break;
          }
          fieldNameP++;
        }
        String fieldName = String.fromCharCodes(
            Uint8List.fromList(buf.getRange(0, fieldNameP).toList()));
        int fieldLen = ByteData.view(
                Uint8List.fromList(buf.getRange(16, 17).toList()).buffer)
            .getUint8(0);

        fieldInfo[fieldName] = fieldLen;
      }
    }

    p = firstRecord + 1;

    isRead = true;
    readTimer =
        Timer.periodic(const Duration(microseconds: 100), (timer) async {
      for (var i = 0; i < 10000; i++) {
        if (line == recordCount) {
          isRead = false;
          timer.cancel();
          break;
        }
        int j = 0;
        Map row = {};

        int q = p + recordLength;
        if (q > dbf.length) {
          q = dbf.length;
        }

        Uint8List buf = Uint8List.fromList(dbf.getRange(p, q).toList());
        p += recordLength;

        fieldInfo.forEach((key, value) {
          int k = j + value;
          if (k > recordLength) {
            k = recordLength;
          }

          row[key] = gbk.decode(buf.getRange(j, k).toList()).trim();
          j += value;
        });

        _dbfDataSource.source.add(row);
        line++;
      }

      _dbfDataSource.sync();
      _dbfDataSource.flush();

      isOpen = true;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFile,
        child: const Icon(Icons.folder_open),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
