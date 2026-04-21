import 'dart:convert';

class CustomPlaylist {
  final String id;
  final String name;
  final List<int> songIds;

  CustomPlaylist({
    required this.id,
    required this.name,
    List<int>? songIds,
  }) : songIds = songIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
      };

  factory CustomPlaylist.fromJson(Map<String, dynamic> json) => CustomPlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        songIds: List<int>.from(json['songIds'] as List),
      );

  CustomPlaylist copyWith({String? name, List<int>? songIds}) => CustomPlaylist(
        id: id,
        name: name ?? this.name,
        songIds: songIds != null ? List<int>.from(songIds) : List<int>.from(this.songIds),
      );

  static List<CustomPlaylist> decodeList(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => CustomPlaylist.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<CustomPlaylist> playlists) {
    return jsonEncode(playlists.map((p) => p.toJson()).toList());
  }
}