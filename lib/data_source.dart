import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:dbf_viewer/dbf.dart';

class DbfDataSource extends DataTableSource {
  late String keyword;
  late List<Map<String, dynamic>> source;
  late List<Map<String, dynamic>> list;
  late List<int> select;
  final Dbf _dbf = Get.find();
  late BuildContext mainContext;

  void init(BuildContext context) {
    mainContext = context;
    keyword = '';
    source = [];
    list = [];
    select = [];
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
        TextField(
          controller: _dbf.dataController['${_dbf.order[index]}_$key'],
          onChanged: (String val) {
            Map<String, dynamic> res = _dbf.edit(index, key, val);
            if (res['code'] == 2) {
              ScaffoldMessenger.of(mainContext).showSnackBar(
                SnackBar(
                  content: Text(res['message']),
                  duration: const Duration(milliseconds: 500),
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
      selected: select.contains(index),
      onSelectChanged: (selected) {
        if (selected!) {
          select.add(index);
        } else {
          select.remove(index);
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
