import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fast_gbk/fast_gbk.dart';

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
  bool isOpen = false;
  bool isOpenSuccess = false;
  bool isError = false;
  final TextEditingController _searchController = TextEditingController();
  late Map<String, int> fieldInfo;
  final DbfDataSource _dbfDataSource = DbfDataSource();

  Widget _initBody() {
    if (isOpenSuccess) {
      List<DataColumn> title = [];

      fieldInfo.forEach((key, value) {
        title.add(
          DataColumn(
            label: SelectableText(
              key,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
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
                        _dbfDataSource.searchVal(_searchController.text);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            columns: title,
            source: _dbfDataSource,
            rowsPerPage: _dbfDataSource.search.length > 50
                ? 50
                : _dbfDataSource.search.length,
            showFirstLastButtons: true,
          ),
        ],
      );
    } else if (isOpen) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (isError) {
      return const Center(
        child: Text('文件打开失败'),
      );
    } else {
      return const Center(
        child: Text('请选择文件'),
      );
    }
  }

  void _openFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dbf'],
    );

    if (result != null) {
      isOpen = true;
      isOpenSuccess = false;
      setState(() {});

      int p = 0;
      _dbfDataSource.data = [];
      fieldInfo = {};
      bool goon = true;
      File file = File(result.files.single.path ?? '');
      Uint8List dbf = await file.readAsBytes();
      p += 32;

      int recordCount =
          ByteData.view(Uint8List.fromList(dbf.getRange(4, 8).toList()).buffer)
              .getUint32(0, Endian.little);
      int firstRecord =
          ByteData.view(Uint8List.fromList(dbf.getRange(8, 10).toList()).buffer)
              .getUint16(0, Endian.little);
      int recordLength = ByteData.view(
              Uint8List.fromList(dbf.getRange(10, 12).toList()).buffer)
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

      for (var i = 0; i < recordCount; i++) {
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

        _dbfDataSource.data.add(row);
      }
      _dbfDataSource.search = _dbfDataSource.data;

      if (!isError) {
        isOpenSuccess = true;
        isOpen = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFile,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class DbfDataSource extends DataTableSource {
  bool isSearch = false;
  late List<Map> data;
  List<Map> search = [];

  void searchVal(String keyword) {
    search = [];
    if (keyword.isNotEmpty) {
      for (var item in data) {
        bool isHave = false;
        item.forEach((key, value) {
          if (value == keyword) {
            isHave = true;
          }
        });

        if (isHave) {
          search.add(item);
        }
      }
    } else {
      search = data;
    }

    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    List<DataCell> row = [];
    search[index].forEach((key, value) {
      row.add(DataCell(
        SelectableText(value),
      ));
    });
    return DataRow(cells: row);
  }

  @override
  int get rowCount => search.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
