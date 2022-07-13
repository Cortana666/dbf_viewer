import 'package:flutter/material.dart';
import 'package:dbf_viewer/dbf.dart';

class DbfSource extends DataTableSource {
  String keyword = '';
  List<int> select = [];
  late Dbf dbfController;
  late BuildContext mainContext;
  List<Map<String, dynamic>> list = [];
  Map<int, Map<String, TextEditingController>> dataController = {};

  void init(BuildContext context, Dbf dbf) {
    dbfController = dbf;
    mainContext = context;
    keyword = '';
    list = [];
    select = [];
    dataController = {};
  }

  void sort(String key, bool ascSort) {
    list.sort((a, b) {
      if (ascSort) {
        return a[key].compareTo(b[key]);
      } else {
        return b[key].compareTo(a[key]);
      }
    });
    flush();
  }

  void sync() {
    if (keyword.isNotEmpty) {
      list = [];
      for (var i = 0; i < dbfController.data.length; i++) {
        bool isHave = false;
        dbfController.data[i].forEach((key, value) {
          if (value == keyword) {
            isHave = true;
          }
        });

        if (isHave) {
          list.add(dbfController.data[i]);
        }
      }
    } else {
      list = dbfController.data;
    }
  }

  void flush() {
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    List<DataCell> row = [];
    dbfController.field.forEach((key, value) {
      row.add(DataCell(
        TextField(
          controller: dataController[list[index]['_selfkey']]![key],
          onChanged: (String val) {
            Map<String, dynamic> res =
                dbfController.edit(list[index]['_selfkey'], key, val);
            if (res['code'] == 1) {
              for (var element in dbfController.data) {
                if (element['_selfkey'] == list[index]['_selfkey']) {
                  element[key] = val;
                }
              }
            } else {
              for (var element in dbfController.data) {
                if (element['_selfkey'] == list[index]['_selfkey']) {
                  dataController[list[index]['_selfkey']]![key]?.text =
                      element[key];
                }
              }
              ScaffoldMessenger.of(mainContext).showSnackBar(
                SnackBar(
                  content: Text(res['message']),
                  duration: const Duration(milliseconds: 1000),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: InputBorder.none,
          ),
        ),
      ));
    });

    return DataRow(
      cells: row,
      selected: select.contains(list[index]['_selfkey']),
      onSelectChanged: (selected) {
        if (selected!) {
          select.add(list[index]['_selfkey']);
        } else {
          select.remove(list[index]['_selfkey']);
        }
        flush();
      },
    );
  }

  @override
  int get rowCount => list.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
