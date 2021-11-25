import 'package:flutter/material.dart';

class DbfDataSource extends DataTableSource {
  String keyword = '';
  List<Map> list = [];
  List<Map> source = [];

  void sync() {
    if (keyword.isNotEmpty) {
      list = [];
      for (var item in source) {
        bool isHave = false;
        item.forEach((key, value) {
          if (value == keyword) {
            isHave = true;
          }
        });

        if (isHave) {
          list.add(item);
        }
      }
    } else {
      list = source;
    }
  }

  void flush() {
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    List<DataCell> row = [];
    list[index].forEach((key, value) {
      row.add(DataCell(
        SelectableText(value),
      ));
    });
    return DataRow(cells: row);
  }

  @override
  int get rowCount => list.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
