import 'dart:io';
import 'dart:typed_data';

class Dbf {
  late Uint8List dbf;

  final Map<String, Map<String, dynamic>> header = {
    'edition': {
      'length': 1,
    },
    'time': {
      'length': 3,
    },
    'lines': {
      'length': 4,
    },
    'first': {
      'length': 2,
    },
    'length': {
      'length': 2,
    },
    'mark': {
      'length': 20,
    },
  };

  final Map<String, Map<String, dynamic>> record = {
    'name': {
      'length': 11,
    },
    'type': {
      'length': 1,
    },
    'mark1': {
      'length': 4,
    },
    'length': {
      'length': 1,
    },
    'precise': {
      'length': 1,
    },
    'mark2': {
      'length': 2,
    },
  };

  final Map typeMap = {
    '2': 'FoxBASE',
    '3': 'FoxBASE+/dBASE III PLUS，无备注',
    '30': 'Visual FoxPro',
    '43': 'dBASE IV SQL 表文件，无备注',
    '63': 'dBASE IV SQL 系统文件，无备注',
    '83': 'FoxBASE+/dBASE III PLUS，有备注',
    '8B': 'dBASE IV，有备注',
    'CB': 'dBASE IV SQL 表文件，有备注',
    'F5': 'FoxPro 2.x（或更早版本），有备注',
    'FB': 'FoxBASE',
  };

  void init(String path) {
    File file = File(path);
    dbf = file.readAsBytesSync();

    type = typeMap[dbf.getRange(0, 1).first.toRadixString(16)];
    updateTime =
        '${dbf.getRange(1, 2).first.toString()}-${dbf.getRange(2, 3).first.toString()}-${dbf.getRange(3, 4).first.toString()}';
    lines =
        ByteData.view(Uint8List.fromList(dbf.getRange(4, 8).toList()).buffer)
            .getUint32(0, Endian.little);
    rowLength =
        ByteData.view(Uint8List.fromList(dbf.getRange(10, 12).toList()).buffer)
            .getUint16(0, Endian.little);

    print(dbf.getRange(12, 28));
    print(dbf.getRange(28, 29));
    print(dbf.getRange(29, 30));
    print(dbf.getRange(30, 32));
    // tableMark = tableMarkMap[dbf.getRange(28, 29).first.toRadixString(16)];

    print(type);
    print(updateTime);
    print(lines);
    print(rowLength);
  }
  // late String path;
  // int p = 0;
  // int line = 0;

  // read() {

  //   trans();
  // }

  // trans() {
  //   bool goon = true;
  //   p += 32;

  //   int recordCount =
  //       ByteData.view(Uint8List.fromList(dbf.getRange(4, 8).toList()).buffer)
  //           .getUint32(0, Endian.little);
  //   int firstRecord =
  //       ByteData.view(Uint8List.fromList(dbf.getRange(8, 10).toList()).buffer)
  //           .getUint16(0, Endian.little);
  //   int recordLength =
  //       ByteData.view(Uint8List.fromList(dbf.getRange(10, 12).toList()).buffer)
  //           .getUint16(0, Endian.little);

  //   while (goon && p <= file.lengthSync()) {
  //     Uint8List buf = Uint8List.fromList(dbf.getRange(p, p + 32).toList());
  //     p += 32;
  //     if (buf.first == 13) {
  //       goon = false;
  //     } else {
  //       List fieldNameCodes = buf.getRange(0, 11).toList();
  //       int fieldNameP = 0;
  //       for (var item in fieldNameCodes) {
  //         if (item == 0) {
  //           break;
  //         }
  //         fieldNameP++;
  //       }
  //       String fieldName = String.fromCharCodes(
  //           Uint8List.fromList(buf.getRange(0, fieldNameP).toList()));
  //       int fieldLen = ByteData.view(
  //               Uint8List.fromList(buf.getRange(16, 17).toList()).buffer)
  //           .getUint8(0);

  //       fieldInfo[fieldName] = fieldLen;
  //     }
  //   }

  //   p = firstRecord + 1;

  //   isRead = true;
  //   readTimer =
  //       Timer.periodic(const Duration(microseconds: 100), (timer) async {
  //     for (var i = 0; i < 10000; i++) {
  //       if (line == recordCount) {
  //         isRead = false;
  //         timer.cancel();
  //         break;
  //       }
  //       int j = 0;
  //       Map row = {};

  //       int q = p + recordLength;
  //       if (q > dbf.length) {
  //         q = dbf.length;
  //       }

  //       Uint8List buf = Uint8List.fromList(dbf.getRange(p, q).toList());
  //       p += recordLength;

  //       fieldInfo.forEach((key, value) {
  //         int k = j + value;
  //         if (k > recordLength) {
  //           k = recordLength;
  //         }

  //         row[key] = gbk.decode(buf.getRange(j, k).toList()).trim();
  //         j += value;
  //       });

  //       _dbfDataSource.source.add(row);
  //       line++;
  //     }

  //     _dbfDataSource.sync();
  //     _dbfDataSource.flush();

  //     isOpen = true;
  //     setState(() {});
  //   });
  // }
  // }
}
