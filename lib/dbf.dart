import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';

class Dbf {
  final Map<String, String> dbfEditions = {
    '2': 'FoxBASE',
    '3': 'FoxBASE+/Dbase III plus, no memo',
    '30': 'Visual FoxPro',
    '31': 'Visual FoxPro, autoincrement enabled',
    '43': 'dBASE IV SQL table files, no memo',
    '63': 'dBASE IV SQL system files, no memo',
    '83': 'FoxBASE+/dBASE III PLUS, with memo',
    '8b': 'dBASE IV with memo',
    'cb': 'dBASE IV SQL table files, with memo',
    'f5': 'FoxPro 2.x (or earlier) with memo',
    'fb': 'FoxBASE'
  };

  late String dbfEdition;
  late String updateTime;
  late int recordLines;
  late int recordLength;
  late Uint8List dbfSocket;
  late int firstRecordStart;

  int line = 0;
  int socketP = 0;
  bool goon = true;
  bool isRead = false;
  bool isOpen = false;
  List<Map<String, dynamic>> data = [];
  Map<String, Map<String, dynamic>> field = {};

  void init(String path) {
    line = 0;
    socketP = 0;
    goon = true;
    isRead = false;
    isOpen = false;
    data = [];
    field = {};

    File file = File(path);
    dbfSocket = file.readAsBytesSync();
    dbfEdition = Uint8List.fromList(dbfSocket.getRange(0, 1).toList())
        .first
        .toRadixString(16);
    dbfEdition = (dbfEditions.containsKey(dbfEdition)
        ? dbfEditions[dbfEdition]
        : dbfEdition)!;
    updateTime =
        '${dbfSocket.getRange(1, 2).first}-${dbfSocket.getRange(2, 3).first}-${dbfSocket.getRange(3, 4).first}';
    recordLines = ByteData.view(
            Uint8List.fromList(dbfSocket.getRange(4, 8).toList()).buffer)
        .getUint32(0, Endian.little);
    firstRecordStart = ByteData.view(
            Uint8List.fromList(dbfSocket.getRange(8, 10).toList()).buffer)
        .getUint16(0, Endian.little);
    recordLength = ByteData.view(
            Uint8List.fromList(dbfSocket.getRange(10, 12).toList()).buffer)
        .getUint16(0, Endian.little);
    socketP += 32;

    while (goon) {
      Uint8List buf = Uint8List.fromList(
          dbfSocket.getRange(socketP, socketP += 32).toList());
      if (buf.first == 13) {
        goon = false;
      } else {
        List<int> nameList = buf.getRange(0, 11).toList();
        nameList.removeWhere((item) => item == 0);
        String name = String.fromCharCodes(Uint8List.fromList(nameList));
        String type = String.fromCharCodes(
            Uint8List.fromList(buf.getRange(11, 12).toList()));
        int len = ByteData.view(
                Uint8List.fromList(buf.getRange(16, 17).toList()).buffer)
            .getUint8(0);
        int dec = ByteData.view(
                Uint8List.fromList(buf.getRange(17, 18).toList()).buffer)
            .getUint8(0);

        field[name] = {'type': type, 'len': len, 'dec': dec};
      }
    }

    socketP = firstRecordStart;
    Timer.periodic(const Duration(microseconds: 200), (timer) async {
      if (!isRead) {
        isRead = true;
        for (var x = 0; x < 10000; x++) {
          if (socketP == dbfSocket.length) {
            timer.cancel();
            isOpen = true;
            break;
          }

          Uint8List flag = Uint8List.fromList(
              dbfSocket.getRange(socketP, socketP += 1).toList());
          if (flag.first.toRadixString(16) == '1a') {
            timer.cancel();
            isOpen = true;
            break;
          }

          Uint8List buf = Uint8List.fromList(dbfSocket
              .getRange(socketP, socketP += recordLength - 1)
              .toList());
          if (flag.first.toRadixString(16) == '20') {
            int i = 0;
            Map<String, dynamic> row = {};
            field.forEach((key, value) {
              row[key] = gbk
                  .decode(buf.getRange(i, i += value['len'] as int).toList())
                  .trim();
            });
            row['_selfkey'] = line;
            data.add(row);
          }

          line++;
        }
        isRead = false;
      }
    });
  }

  void editTime() {
    dbfSocket[1] = int.parse(DateTime.now().year.toString().substring(2));
    dbfSocket[2] = DateTime.now().month;
    dbfSocket[3] = DateTime.now().day;
  }

  Map<String, dynamic> edit(int line, String name, String val) {
    if (val.length > (field[name]!['len'] ?? 0)) {
      return {'code': 2, 'message': '超出字段长度[${field[name]!['len'] ?? 0}位]'};
    }

    Uint8List value =
        Uint8List.fromList(gbk.encode(val.padRight(field[name]!['len'] ?? 0)));

    int start = firstRecordStart + recordLength * line + 1;
    for (var item in field.keys) {
      if (item.substring(0, name.length) == name) {
        break;
      } else {
        start += field[item]!['len'] as int;
      }
    }

    for (var i = 0; i < (field[name]!['len'] ?? 0); i++) {
      dbfSocket[start] = value[i];
      start++;
    }

    editTime();

    return {'code': 1, 'message': '成功'};
  }

  Map<String, dynamic> delete(List<int> line) {
    Uint8List value = Uint8List.fromList([int.parse("0x2A")]);

    for (var item in line) {
      int start = firstRecordStart + recordLength * item;
      dbfSocket[start] = value[0];
    }

    editTime();

    return {'code': 1, 'message': '成功'};
  }

  Map<String, dynamic> add() {
    List<int> rowData = dbfSocket.toList();

    Uint8List linesList = Uint8List(4)
      ..buffer.asByteData().setInt32(0, recordLines + 1, Endian.little);
    rowData[4] = linesList[0];
    rowData[5] = linesList[1];
    rowData[6] = linesList[2];
    rowData[7] = linesList[3];

    if (rowData.last.toRadixString(16) == '1a') {
      rowData.removeLast();
    }
    rowData.add(int.parse('0x20'));
    for (var i = 0; i < recordLength - 1; i++) {
      rowData.add(0);
    }
    rowData.add(int.parse('0x1A'));

    dbfSocket = Uint8List.fromList(rowData);

    recordLines++;

    editTime();

    return {'code': 1, 'message': '成功'};
  }
}
