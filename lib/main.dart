import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'dart:ui' as ui;

import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(
      Phoenix(
        child: const PxlsApp(),
      ),
  );
}

class PxlsApp extends StatelessWidget {
  const PxlsApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pxls.space',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'pxls.space'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Future<Info> fetchInfo() async {
  final response = await http.get(Uri.parse("https://pxls.space/info"));
  if (response.statusCode == 200) {
    return Info.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch info');
  }
}

Future<Uint8List> fetchBoardData() async {
  final response = await http.get(Uri.parse("https://pxls.space/boarddata"));
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

class PaletteColor {
  final String name;
  final String value;

  const PaletteColor({
    required this.name,
    required this.value,
  });

  factory PaletteColor.fromJson(Map<String, dynamic> json) {
    return PaletteColor(name: json['name'], value: json['value']);
  }
}

class Info {
  final int width;
  final int height;
  final List<PaletteColor> palette;

  const Info({
    required this.width,
    required this.height,
    required this.palette,
  });

  factory Info.fromJson(Map<String, dynamic> json) {
    List<PaletteColor> palette = [];
    for (Map<String, dynamic> entry in json['palette']) {
      palette.add(PaletteColor.fromJson(entry));
    }
    return Info(
      width: json['width'],
      height: json['height'],
      palette: palette,
    );
  }
}

Future<ui.Image> makeImage(Uint8List boardData, Info info) async {
  final completer = Completer<ui.Image>();
  final pixels = boardDataAsImageData(boardData, info);
  ui.decodeImageFromPixels(pixels, info.width, info.height, ui.PixelFormat.rgba8888, completer.complete);
  return await completer.future;
}

class Pxls {
  final Info info;
  final Uint8List boardData;
  ui.Image image;

  Uint32List rawPixels;
  Uint32List convertedPalette;

  Pxls({
    required this.info,
    required this.boardData,
    required this.image,
    required this.rawPixels,
    required this.convertedPalette,
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
      convertedPalette: convertedPalette
    );
  }

  int paletteIndexToInt(int index) {
    if (index == 0xFF) {
      return 0x00000000;
    }
    return convertedPalette[index];
  }
}

class _MyHomePageState extends State<MyHomePage> {
  // late Future<Pxls> futurePxls;
  // late Uint32List rawPixels;
  // late Future<ui.Image> futureImage;
  // late Uint32List rawPalette;

  late Pxls pxls;
  late Future<Pxls> futurePxls;
  late Uint32List rawPixels = Uint32List(0);
  late Uint32List convertedPalette = Uint32List(0);
  late String lastPacket = '';

  final WebSocketChannel channel = WebSocketChannel.connect(Uri.parse("wss://pxls.space/ws"));

  @override
  void initState() {
    super.initState();
    futurePxls = Pxls.fetchInit();
    // Pxls.fetchInit().then((pxls) => {
    //   rawPixels = boardDataAsUint32List(pxls.boardData, pxls.info),
    //   makeImage(pxls.boardData, pxls.info).then((image) => {
    //     setState(() {
    //       this.pxls = pxls;
    //       convertedPalette = paletteAsUint32List(pxls.info.palette);
    //     })
    //   })
    // });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<Pxls>(
          future: futurePxls,
          builder: (context, pxlsSnapshot) {
            if (pxlsSnapshot.hasData) {
              pxls = pxlsSnapshot.data!;

              return StreamBuilder(
                stream: channel.stream,
                builder: (context, socketSnapshot) {
                  if (socketSnapshot.hasData) {
                    if (socketSnapshot.data != lastPacket) {
                      // Required to prevent loop with setState for image below
                      lastPacket = socketSnapshot.data;
                      var packet = jsonDecode(socketSnapshot.data);
                      if (packet['type'] == 'pixel') {
                        for (dynamic pixel in packet['pixels']) {
                          int x = pixel['x'];
                          int y = pixel['y'];
                          int color = pixel['color'];
                          pxls.rawPixels[y * pxls.info.width + x] = pxls.paletteIndexToInt(color);
                          ui.decodeImageFromPixels(pxls.rawPixels.buffer.asUint8List(), pxls.info.width, pxls.info.height, ui.PixelFormat.rgba8888, (result) {
                            // Need to setState to trigger build
                            setState(() {
                              pxls.image = result;
                            });
                          });
                        }
                      }
                    }
                    return Container(
                      color: Colors.white,
                      child: InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(250),
                          minScale: 0.1,
                          maxScale: 50,
                          constrained: false,
                          clipBehavior: Clip.hardEdge,
                          child: RawImage(
                            filterQuality: FilterQuality.none,
                            image: pxls.image,
                          )
                      ),
                    );
                  } else if (socketSnapshot.hasError) {
                    return Text('Could not load socket connection: ${socketSnapshot.error}');
                  }

                  return const CircularProgressIndicator();
                },
              );
            } else if (pxlsSnapshot.hasError) {
              return Text('Error loading Pxls information: ${pxlsSnapshot.error}');
            }

            return const CircularProgressIndicator();
          }
        )
        // child: FutureBuilder<Pxls>(
        //   future: futurePxls,
        //   builder: (context, snapshot) {
        //     if (snapshot.hasData) {
        //       pxls = snapshot.data!;
        //       var info = snapshot.data!.info;
        //       rawPixels = boardDataAsUint32List(pxls.boardData, info);
        //       rawPalette = paletteAsUint32List(info.palette);
        //
        //       if (channel.closeCode != null) {
        //         // We can't recover from any socket close - no pixel/chat replay, at least for now
        //         //Phoenix.rebirth(context);
        //       }
        //       return FutureBuilder(
        //         future: futureImage,
        //         builder: (context, imageSnapshot) {
        //           var rawImage = imageSnapshot.data!;
        //           return StreamBuilder(
        //             stream: channel.stream,
        //             builder: (streamContext, streamSnapshot) {
        //               var packet = jsonDecode(streamSnapshot.data);
        //               if (packet['type'] == 'pixel') {
        //                 for (dynamic pixel in packet['pixels']) {
        //                   int x = pixel['x'];
        //                   int y = pixel['y'];
        //                   int color = pixel['color'];
        //                   print('Update pixel at ($x, $y) with color $color');
        //                   rawPixels[y * pxls.info.width + x] = rawPalette[color];
        //                 }
        //               }
        //               return Container(
        //                 color: Colors.white,
        //                 child: InteractiveViewer(
        //                   boundaryMargin: const EdgeInsets.all(250),
        //                   minScale: 0.1,
        //                   maxScale: 50,
        //                   constrained: false,
        //                   clipBehavior: Clip.hardEdge,
        //                   child: StatefulBuilder(
        //                     builder: (context, setState) {
        //                       return RawImage(
        //                         filterQuality: FilterQuality.none,
        //                         image: rawImage,
        //                       );
        //                     },
        //                   ),
        //                 ),
        //               );
        //             }
        //           );
        //         }
        //       );
        //     } else if (snapshot.hasError) {
        //       return Text('Error loading Pxls: ${snapshot.error}');
        //     }
        //
        //     return const CircularProgressIndicator();
        //   },
        // ),
      ),
    );
  }
}
