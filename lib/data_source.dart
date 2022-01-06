import 'package:flutter/material.dart';

class DbfDataSource extends DataTableSource {
  late String keyword;
  late List<Map> source;
  late List<Map> list;
  late Map<int, bool> select;

  void init() {
    keyword = '';
    source = [];
    list = [];
    select = {};
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
    return DataRow(
      cells: row,
      selected: select[index] ?? false,
      onSelectChanged: (selected) {
        select[index] = selected!;
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
