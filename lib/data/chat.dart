class ChatMessagePacket {
  final ChatMessage message;

  const ChatMessagePacket({
    required this.message
  });

  static ChatMessagePacket fromPacket(dynamic packet) {
    return ChatMessagePacket(
      message: ChatMessage.fromPacket(packet['message']),
    );
  }
}

class ChatHistoryPacket {
  final List<ChatMessage> messages;

  const ChatHistoryPacket({
    required this.messages,
  });

  static ChatHistoryPacket fromPacket(dynamic packet) {
    return ChatHistoryPacket(
      messages: ChatMessage.fromListPacket(packet['messages']),
    );
  }
}

class ChatMessage {
  final int id;
  final String author;
  final int date;
  final String messageRaw;
  final int replyingToId;
  final bool replyShouldMention;
  final List<ChatBadge> badges;
  final List<String> authorNameClass;
  final int authorNameColor;
  final bool authorWasShadowBanned;
  final ChatStrippedFaction? strippedFaction;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.date,
    required this.messageRaw,
    required this.replyingToId,
    required this.replyShouldMention,
    required this.badges,
    required this.authorNameClass,
    required this.authorNameColor,
    required this.authorWasShadowBanned,
    required this.strippedFaction,
  });

  static ChatMessage fromPacket(dynamic packet) {
    List<String> authorNameClass = [];
    // if (packet['authorNameClass'] != null) {
    //   authorNameClass = (packet['authorNameClass'] as List<dynamic>).map((e) => e.toString()).toList();
    // }
    ChatStrippedFaction? strippedFaction;
    if (packet['strippedFaction'] != null) {
      strippedFaction = ChatStrippedFaction.fromPacket(packet['strippedFaction']);
    }
    return ChatMessage(
      id: packet['id'],
      author: packet['author'],
      date: packet['date'],
      messageRaw: packet['message_raw'],
      replyingToId: packet['replyingToId'],
      replyShouldMention: packet['replyShouldMention'],
      badges: ChatBadge.fromListPacket(packet['badges']),
      authorNameClass: authorNameClass,
      authorNameColor: packet['authorNameColor'],
      authorWasShadowBanned: packet['authorWasShadowBanned'],
      strippedFaction: strippedFaction,
    );
  }

  static List<ChatMessage> fromListPacket(dynamic packet) {
    return (packet as List<dynamic>).map((packetMessage) => fromPacket(packetMessage)).toList().reversed.toList();
  }
}

class ChatBadge {
  final String displayName;
  final String tooltip;
  final String type;
  final String? cssIcon;

  const ChatBadge({
    required this.displayName,
    required this.tooltip,
    required this.type,
    this.cssIcon,
  });

  static ChatBadge fromPacket(dynamic packet) {
    return ChatBadge(
      displayName: packet['displayName'],
      tooltip: packet['tooltip'],
      type: packet['type'],
      cssIcon: packet['cssIcon'],
    );
  }
  
  static List<ChatBadge> fromListPacket(dynamic packet) {
    return (packet as List<dynamic>).map((packetBadge) => fromPacket(packetBadge)).toList();
  }
}

class ChatStrippedFaction {
  final int id;
  final String name;
  final String tag;
  final int color;

  const ChatStrippedFaction({
    required this.id,
    required this.name,
    required this.tag,
    required this.color,
  });

  static ChatStrippedFaction fromPacket(dynamic packet) {
    return ChatStrippedFaction(
      id: packet['id'],
      name: packet['name'],
      tag: packet['tag'],
      color: packet['color'],
    );
  }
}
