import 'package:just_audio/just_audio.dart';
export 'package:just_audio/just_audio.dart' show PlayerState;
import 'api_service.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final ApiService _api = ApiService();
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> playTrack(String trackId) async {
    try {
      await _player.stop();
      final url = _api.streamUrl(trackId);
      await _player.setUrl(url);
      await _player.play();
    } catch (e, st) {
      print('playTrack func didnt work on $trackId: $e\n$st');
      rethrow;
    }
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();
  Future<void> seek(Duration position) async => _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}