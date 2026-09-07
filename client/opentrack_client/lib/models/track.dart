class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationSecs;
  final String filePath;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSecs,
    required this.filePath,
  });
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track (
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      durationSecs: json['duration_secs'] as int,
      filePath: json['file_path'] as String,
    );
  }
}