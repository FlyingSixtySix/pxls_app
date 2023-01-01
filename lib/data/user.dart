import 'chat.dart';

class User {
  final String username;
  final List<Role> roles;
  final int pixelCount;
  final int pixelCountAllTime;
  final bool banned;
  final int? banExpiry;
  final String banReason;
  final String method;
  final PlacementOverrides placementOverrides;
  final bool chatBanned;
  final String chatBanReason;
  final bool chatBanIsPermanent;
  final int chatBanExpiry;
  final bool renameRequested;
  final String discordName;
  final int chatNameColor;

  const User({
    required this.username,
    required this.roles,
    required this.pixelCount,
    required this.pixelCountAllTime,
    required this.banned,
    required this.banExpiry,
    required this.banReason,
    required this.method,
    required this.placementOverrides,
    required this.chatBanned,
    required this.chatBanReason,
    required this.chatBanIsPermanent,
    required this.chatBanExpiry,
    required this.renameRequested,
    required this.discordName,
    required this.chatNameColor,
  });

  static User fromPacket(dynamic packet) {
    return User(
      username: packet['username'],
      roles: Role.fromListPacket(packet['roles']),
      pixelCount: packet['pixelCount'],
      pixelCountAllTime: packet['pixelCountAllTime'],
      banned: packet['banned'],
      banExpiry: packet['banExpiry'],
      banReason: packet['banReason'],
      method: packet['method'],
      placementOverrides: PlacementOverrides.fromPacket(packet['placementOverrides']),
      chatBanned: packet['chatBanned'],
      chatBanReason: packet['chatbanReason'],
      chatBanIsPermanent: packet['chatbanIsPerma'],
      chatBanExpiry: packet['chatbanExpiry'],
      renameRequested: packet['renameRequested'],
      discordName: packet['discordName'],
      chatNameColor: packet['chatNameColor'],
    );
  }
}

class Role {
  final String id;
  final String name;
  final bool guest;
  final bool defaultRole;
  final List<Role> inherits;
  final List<ChatBadge> badges;
  final List<String> permissions;

  const Role({
    required this.id,
    required this.name,
    required this.guest,
    required this.defaultRole,
    required this.inherits,
    required this.badges,
    required this.permissions,
  });

  static Role fromPacket(dynamic packet) {
    return Role(
      id: packet['id'],
      name: packet['name'],
      guest: packet['guest'],
      defaultRole: packet['defaultRole'],
      inherits: Role.fromListPacket(packet['inherits']),
      badges: ChatBadge.fromListPacket(packet['badges']),
      permissions: (packet['permissions'] as List<dynamic>).map((packetPermission) {
        print('mapped packetPermission $packetPermission');
        return packetPermission.toString();
      }).toList(),
    );
  }

  static List<Role> fromListPacket(dynamic packet) {
    return (packet as List<dynamic>).map((packetRole) => fromPacket(packetRole)).toList();
  }
}

class PlacementOverrides {
  final bool ignoreCooldown;
  final bool canPlaceAnyColor;
  final bool ignorePlacemap;

  const PlacementOverrides({
    required this.ignoreCooldown,
    required this.canPlaceAnyColor,
    required this.ignorePlacemap,
  });

  static PlacementOverrides fromPacket(dynamic packet) {
    return PlacementOverrides(
      ignoreCooldown: packet['ignoreCooldown'],
      canPlaceAnyColor: packet['canPlaceAnyColor'],
      ignorePlacemap: packet['ignorePlacemap'],
    );
  }
}
