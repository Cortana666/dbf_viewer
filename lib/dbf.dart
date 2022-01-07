import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fast_gbk/fast_gbk.dart';

class Dbf {
  late Uint8List dbf;
  late Uint8List export;
  late int lines;
  late int first;
  late int length;
  late int p;
  late bool goon;
  late Map<String, Map<String, int>> field;
  late int line;
  late List<Map<String, dynamic>> data;
  late List<int> order;
  late Map<String, TextEditingController> dataController;

  void init(String path) {
    p = 0;
    goon = true;
    field = {};
    line = 0;
    data = [];
    order = [];
    dataController = {};

    File file = File(path);
    dbf = file.readAsBytesSync();

    lines =
        ByteData.view(Uint8List.fromList(dbf.getRange(4, 8).toList()).buffer)
            .getUint32(0, Endian.little);
    first =
        ByteData.view(Uint8List.fromList(dbf.getRange(8, 10).toList()).buffer)
            .getUint16(0, Endian.little);
    length =
        ByteData.view(Uint8List.fromList(dbf.getRange(10, 12).toList()).buffer)
            .getUint16(0, Endian.little);
    p += 32;

    while (goon) {
      Uint8List buf = Uint8List.fromList(dbf.getRange(p, p += 32).toList());
      if (buf.first == 13) {
        goon = false;
      } else {
        String name = String.fromCharCodes(
            Uint8List.fromList(buf.getRange(0, 11).toList()));
        int len = ByteData.view(
                Uint8List.fromList(buf.getRange(16, 17).toList()).buffer)
            .getUint8(0);
        int pre = ByteData.view(
                Uint8List.fromList(buf.getRange(17, 18).toList()).buffer)
            .getUint8(0);

        field[name] = {'len': len, 'pre': pre};
      }
    }

    p = first;
    Timer.periodic(const Duration(microseconds: 200), (timer) async {
      for (var x = 0; x < 10000; x++) {
        if (line == lines) {
          timer.cancel();
          break;
        }

        Uint8List delete = Uint8List.fromList(dbf.getRange(p, p += 1).toList());
        Uint8List buf =
            Uint8List.fromList(dbf.getRange(p, p += length - 1).toList());

        if (delete.first.toRadixString(16) == '20') {
          int i = 0;
          Map<String, dynamic> row = {};
          field.forEach((key, value) {
            row[key] = gbk
                .decode(buf.getRange(i, i += value['len'] ?? 0).toList())
                .trim();
          });
          data.add(row);
          order.add(line);
        }

        line++;
      }
    });
  }

  Map<String, dynamic> edit(int line, String name, String val) {
    if (val.length > (field[name]!['len'] ?? 0)) {
      return {'code': 2, 'message': '超出字段长度[${field[name]!['len'] ?? 0}位]'};
    }

    Uint8List value =
        Uint8List.fromList(gbk.encode(val.padRight(field[name]!['len'] ?? 0)));

    int start = first + length * line + 1;
    for (var item in field.keys) {
      if (item.substring(0, name.length) == name) {
        break;
      } else {
        start += field[item]!['len'] ?? 0;
      }
    }

    for (var i = 0; i < (field[name]!['len'] ?? 0); i++) {
      dbf[start] = value[i];
      start++;
    }

    return {'code': 1, 'message': '成功'};
  }

  Map<String, dynamic> delete(List<int> line) {
    Uint8List value = Uint8List.fromList([int.parse("0x2A")]);

    for (var item in line) {
      int start = first + length * order[item];
      dbf[start] = value[0];
    }

    return {'code': 1, 'message': '成功'};
  }
}
