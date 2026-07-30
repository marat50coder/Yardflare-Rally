/// Persisted routing decision. Values are what the coordinator writes to
/// `CoopSafe` after the first-launch dispatch resolves.
enum PortalRoute {
  game,
  web,
  unset;

  String get storageValue => switch (this) {
    PortalRoute.game => 'game',
    PortalRoute.web => 'web',
    PortalRoute.unset => 'unset',
  };

  static PortalRoute parse(String? value) => switch (value) {
    'web' => PortalRoute.web,
    'game' => PortalRoute.game,
    _ => PortalRoute.unset,
  };
}

/// Result of a single config-endpoint request.
class RelayReply {
  const RelayReply({
    required this.accepted,
    this.url,
    this.expiresAt,
    this.reason,
  });

  factory RelayReply.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expires'];
    return RelayReply(
      accepted: json['ok'] == true,
      url: json['url'] is String ? json['url'] as String : null,
      expiresAt: rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? ''),
      reason: json['message']?.toString(),
    );
  }

  factory RelayReply.rejected(String reason) =>
      RelayReply(accepted: false, reason: reason);

  final bool accepted;
  final String? url;
  final int? expiresAt;
  final String? reason;

  bool get hasDestination => accepted && (url?.isNotEmpty ?? false);
}

/// Outcome of the boot pipeline. The boot screen inspects the concrete
/// subtype to pick which page to push next.
sealed class NightHold {
  const NightHold();
}

final class HomeHold extends NightHold {
  const HomeHold();
}

final class WebHold extends NightHold {
  const WebHold(this.url, {this.coldLaunch = false});

  final String url;
  final bool coldLaunch;
}

final class DarkHold extends NightHold {
  const DarkHold({required this.returnToGame});

  final bool returnToGame;
}
