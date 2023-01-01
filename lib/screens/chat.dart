import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/chat.dart';
import '../data/pxls.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.pxls,
    required this.chatMessages,
    required this.webSocket,
  });

  final Pxls pxls;

  final List<ChatMessage> chatMessages;

  final WebSocket webSocket;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> messages = [];
  late ChatMessage lastMessage;
  List<ChatMessage> lastReceivedValue = [];

  ScrollController scrollController = ScrollController();

  late Timer timer;

  final dateFormatter = DateFormat.jm();

  void handleMessage(ChatMessage message) {
    setState(() {
      if (messages.length >= 300) {
        messages.removeAt(0);
      }
      messages.add(message);
    });
  }

  void handleHistory(List<ChatMessage> messages) {
    setState(() {
      this.messages = messages;
    });
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (lastMessage != widget.chatMessages.last) {
        setState(() {
          lastMessage = widget.chatMessages.last;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    lastMessage = widget.chatMessages.last;
    var i = -1;
    var chatElements = widget.chatMessages.map((chatMessage) {
      i++;
      return Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Color(i % 2 == 0 ? 0xFFD5D5D5 : 0x00000000),
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFBFBFBF),
              width: 1.0
            )
          ),
        ),
        child: Wrap(
          children: [
            // Timestamp
            Text(dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(chatMessage.date * 1000))),
            // Pixel count badge
            Container(
              padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFCCCCCC),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                chatMessage.badges.last.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF777700),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Author name
            Text(
              chatMessage.author,
              style: TextStyle(
                color: Color(0xFF000000 + widget.pxls.paletteIndexToInt(chatMessage.authorNameColor)),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(': '),
            // Message
            Text(chatMessage.messageRaw),
          ],
        ),
      );
    }).toList();

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xFFC5C5C5),
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overScroll) {
                  overScroll.disallowIndicator();
                  return false;
                },
                child: ListView(
                  scrollDirection: Axis.vertical,
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  children: chatElements,
                ),
              ),
            ),
            RawKeyboardListener(
              focusNode: FocusNode(),
              child: TextField(
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  widget.webSocket.add('{"message":"$value","replyingToId":0,"replyShouldMention":true,"type":"ChatMessage"}');
                },
                onChanged: (value) {
                  // TODO: widget.pxls.info.chatCharacterLimit
                  if (value.length >= 256) {
                    value = value.characters.getRange(0, 256).toString();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('pxls.space - 12:34'),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }
}