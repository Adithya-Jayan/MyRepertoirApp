import 'dart:convert';

class MidiTrackConfig {
  final Map<int, ChannelConfig> channels;

  MidiTrackConfig({required this.channels});

  factory MidiTrackConfig.fromJson(String jsonStr) {
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(jsonStr));
      final Map<String, dynamic> channelsData = Map<String, dynamic>.from(data['channels'] ?? {});
      final Map<int, ChannelConfig> channels = {};
      channelsData.forEach((key, value) {
        final int ch = int.tryParse(key.toString()) ?? 0;
        channels[ch] = ChannelConfig.fromMap(Map<String, dynamic>.from(value));
      });
      return MidiTrackConfig(channels: channels);
    } catch (e) {
      return MidiTrackConfig(channels: {});
    }
  }

  String toJson() {
    final Map<String, dynamic> data = {
      'channels': channels.map((key, value) => MapEntry(key.toString(), value.toMap())),
    };
    return jsonEncode(data);
  }

  MidiTrackConfig copyWith({Map<int, ChannelConfig>? channels}) {
    return MidiTrackConfig(
      channels: channels ?? this.channels,
    );
  }
}

class ChannelConfig {
  final String? name;
  final double volume; // 0.0 to 1.0
  final bool mute;

  ChannelConfig({
    this.name,
    this.volume = 1.0,
    this.mute = false,
  });

  factory ChannelConfig.fromMap(Map<String, dynamic> map) {
    return ChannelConfig(
      name: map['name'] as String?,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      mute: map['mute'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      'volume': volume,
      'mute': mute,
    };
  }

  ChannelConfig copyWith({
    String? name,
    double? volume,
    bool? mute,
    bool nameWasSet = false,
  }) {
    return ChannelConfig(
      name: nameWasSet ? name : (name ?? this.name),
      volume: volume ?? this.volume,
      mute: mute ?? this.mute,
    );
  }
}
