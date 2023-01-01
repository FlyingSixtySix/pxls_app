import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pxls_app/data/chat.dart';

import 'dart:ui' as ui;

import 'info.dart';
import 'user.dart';

class Pxls {
  final Info info;
  final Uint8List boardData;
  ui.Image image;

  Uint32List rawPixels;
  Uint32List convertedPalette;

  User? user;

  Pxls({
    required this.info,
    required this.boardData,
    required this.image,
    required this.rawPixels,
    required this.convertedPalette,
    this.user,
  });

  static Future<Pxls> fetchInit() async {
    var info = await fetchInfo();
    var boardData = await fetchBoardData();
    var image = await makeImage(boardData, info);

    var rawPixels = boardDataAsUint32List(boardData, info);
    var convertedPalette = paletteAsUint32List(info.palette);
    return Pxls(
      info: info,
      boardData: boardData,
      image: image,
      rawPixels: rawPixels,
      convertedPalette: convertedPalette,
    );
  }

  int paletteIndexToInt(int index) {
    if (index == 0xFF) {
      return 0x00000000;
    }
    if (index < 0) {
      return 0xFF000000;
    }
    return convertedPalette[index];
  }
}

Future<Info> fetchInfo() async {
  final response = await http.get(Uri.parse("https://pxls.space/info"));
  // final response = await http.get(Uri.parse("http://192.168.1.11:4567/info"));
  if (response.statusCode == 200) {
    return Info.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch info');
  }
}

Future<Uint8List> fetchBoardData() async {
  final response = await http.get(Uri.parse("https://pxls.space/boarddata"));
  // final response = await http.get(Uri.parse("http://192.168.1.11:4567/boarddata"));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to fetch board data');
  }
}

Uint32List paletteAsUint32List(List<PaletteColor> palette) {
  Uint32List converted = Uint32List(palette.length);
  for (int i = 0; i < palette.length; i++) {
    String hex = palette[i].value;
    String r = hex.substring(0, 2);
    String g = hex.substring(2, 4);
    String b = hex.substring(4, 6);
    converted[i] = int.parse('FF$b$g$r', radix: 16);
  }
  return converted;
}

int paletteIndexToInt(Uint32List convertedPalette, int index) {
  if (index == 0xFF) {
    return 0x00000000;
  }
  return convertedPalette[index];
}

Uint32List boardDataAsUint32List(Uint8List boardData, Info info) {
  Uint32List colors = Uint32List(info.width * info.height);
  Uint32List convertedPalette = paletteAsUint32List(info.palette);
  for (int i = 0; i < boardData.length; i++) {
    if (boardData[i] == 0xFF) {
      // Transparent
      colors[i] = 0x00000000;
      continue;
    }
    colors[i] = convertedPalette[boardData[i]];
  }
  return colors;
}

Uint8List boardDataAsImageData(Uint8List boardData, Info info) {
  return boardDataAsUint32List(boardData, info).buffer.asUint8List();
}

Future<ui.Image> makeImage(Uint8List boardData, Info info) async {
  final completer = Completer<ui.Image>();
  final pixels = boardDataAsImageData(boardData, info);
  ui.decodeImageFromPixels(pixels, info.width, info.height, ui.PixelFormat.rgba8888, completer.complete);
  return await completer.future;
}
