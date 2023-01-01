import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import 'package:wakelock/wakelock.dart';

import 'dart:ui' as ui;

import 'package:pxls_app/StreamListener.dart';
import 'package:pxls_app/data/chat.dart';
import 'package:pxls_app/screens/chat.dart';

import 'package:badges/badges.dart';

import '../data/pxls.dart';
import '../data/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Pxls pxls;
  late Future<Pxls> futurePxls;
  late List<dynamic> lastPacketBatch = [];
  late int pingCount = 0;

  List<ChatMessage> chatMessages = [];

  late Future<WebSocket> futureWebSocket = WebSocket.connect("wss://pxls.space/ws", headers: {
    'Cookie': 'pxls-token='
  });
  // late Future<WebSocket> futureWebSocket = WebSocket.connect("ws://192.168.1.11:4567/ws", headers: {
  //   'Cookie': 'pxls-token=1|YYqqHAdRlBrqBtAqEfPxibtbNYLMDdlXr'
  // });
  late WebSocket webSocket;

  @override
  void initState() {
    super.initState();
    futurePxls = Pxls.fetchInit();
    Wakelock.enable();
  }

  @override
  void dispose() {
    webSocket.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Builder(
            builder: (context) {
              return Badge(
                badgeContent: Text('$pingCount', style: const TextStyle(color: Colors.white)),
                position: BadgePosition.bottomEnd(bottom: 10, end: 10),
                child: IconButton(
                  icon: const Icon(Icons.chat),
                  padding: const EdgeInsets.only(right: 12),
                  // onPressed: () => Scaffold.of(context).openEndDrawer(),
                  onPressed: () => Navigator.of(context).push(
                      PageRouteBuilder(pageBuilder: (context, _, __) => ChatScreen(pxls: pxls, chatMessages: chatMessages, webSocket: webSocket))
                  ),
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              );
            }
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<Pxls>(
            future: futurePxls,
            builder: (context, pxlsSnapshot) {
              if (pxlsSnapshot.hasData) {
                pxls = pxlsSnapshot.data!;

                return FutureBuilder<WebSocket>(
                  future: futureWebSocket,
                  builder: (context, webSocketSnapshot) {
                    if (webSocketSnapshot.hasData) {
                      webSocket = webSocketSnapshot.data!;

                      var hasRequestedChatHistory = false;

                      return PxlsStreamBuilder(
                        initialData: const [],
                        fold: (summary, value) => [...summary, value],
                        stream: webSocket,
                        builder: (context, socketSnapshot) {
                          if (socketSnapshot.hasData) {
                            late Offset tapOffset;

                            if (!hasRequestedChatHistory) {
                              webSocket.add('{"type":"ChatHistory"}');
                              hasRequestedChatHistory = true;
                            }

                            return StatefulBuilder(
                              builder: (context, setState) {
                                if (lastPacketBatch != socketSnapshot.data!) {
                                  lastPacketBatch = socketSnapshot.data!;
                                  for (var rawPacket in socketSnapshot.data!) {
                                    var packet = jsonDecode(rawPacket);
                                    print(packet);
                                    if (packet['type'] == 'pixel') {
                                      for (dynamic pixel in packet['pixels']) {
                                        int x = pixel['x'];
                                        int y = pixel['y'];
                                        int color = pixel['color'];
                                        // print(pixel);
                                        pxls.rawPixels[y * pxls.info.width + x] = pxls.paletteIndexToInt(color);
                                        ui.decodeImageFromPixels(pxls.rawPixels.buffer.asUint8List(), pxls.info.width, pxls.info.height, ui.PixelFormat.rgba8888, (result) {
                                          // Need to setState to trigger build
                                          setState(() {
                                            // print('setState');
                                            pxls.image = result;
                                          });
                                        });
                                      }
                                    } else if (packet['type'] == 'chat_message') {
                                      ChatMessage message = ChatMessagePacket.fromPacket(packet).message;
                                      if (chatMessages.length >= 300) {
                                        chatMessages.removeAt(0);
                                      }
                                      chatMessages.add(message);
                                      print(pxls.user);
                                      if (message.messageRaw.contains(pxls.user!.username)) {
                                        setState(() {
                                          pingCount++;
                                        });
                                      }
                                    } else if (packet['type'] == 'chat_history') {
                                      List<ChatMessage> history = ChatHistoryPacket.fromPacket(packet).messages;
                                      chatMessages = history;
                                      for (var message in history) {
                                        if (message.messageRaw.contains(pxls.user!.username)) {
                                          setState(() {
                                            pingCount++;
                                          });
                                        }
                                      }
                                    } else if (packet['type'] == 'userinfo') {
                                      print('packet is userinfo');
                                      User user = User.fromPacket(packet);
                                      print('fromPacket user is');
                                      print(user);
                                      setState(() {
                                        pxls.user = User.fromPacket(packet);
                                        print(pxls.user);
                                      });
                                    }
                                  }
                                }
                                return Container(
                                  color: Colors.black,
                                  child: InteractiveViewer(
                                      boundaryMargin: const EdgeInsets.all(250),
                                      minScale: 0.1,
                                      maxScale: 50,
                                      constrained: false,
                                      clipBehavior: Clip.hardEdge,
                                      child: GestureDetector(
                                        onTap: () {
                                          var x = tapOffset.dx.toInt();
                                          var y = tapOffset.dy.toInt();
                                          var encoded = jsonEncode({
                                            "type": "pixel",
                                            "x": x,
                                            "y": y,
                                            "color": 0
                                          });
                                          // webSocket.add(encoded);
                                        },
                                        onTapDown: (details) {
                                          setState(() {
                                            tapOffset = details.localPosition;
                                          });
                                        },
                                        onLongPressDown: (details) {

                                        },
                                        child: RawImage(
                                          filterQuality: FilterQuality.none,
                                          image: pxls.image,
                                        ),
                                      )
                                  ),
                                );
                              },
                            );
                          } else if (socketSnapshot.hasError) {
                            return Text('Could not load socket connection: ${socketSnapshot.error}');
                          }

                          return const Text('Building socket...');
                        },
                      );
                    } else if (webSocketSnapshot.hasError) {
                      return Text('WebSocket error: ${webSocketSnapshot.error}');
                    }

                    return const Text('Connecting socket...');
                  },
                );
              } else if (pxlsSnapshot.hasError) {
                return Text('Error loading Pxls information: ${pxlsSnapshot.error}');
              }

              return const Text('Fetching Pxls information...');
            }
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                print('Tapped Profile');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Factions'),
            ),
            ListTile(
              title: const Text('Stats'),
            ),
          ],
        ),
      ),
    );
  }
}
