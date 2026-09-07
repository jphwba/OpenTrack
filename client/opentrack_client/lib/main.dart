import 'package:flutter/material.dart';
import 'models/track.dart';
import 'services/api_service.dart';
import 'services/audio_service.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenTrack',
      theme: ThemeData(useMaterial3: true,
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorSchemeSeed: Colors.deepPurple),

      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _api = ApiService();
  final AudioPlayerService _audio = AudioPlayerService();
  late Future<List<Track>> _tracksFuture;
  Track? _currentTrack;

  @override
  void initState() {
    super.initState();
    _tracksFuture = _api.fetchTracks();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _playTrack(Track track) {
    setState(() => _currentTrack = track);
    _audio.playTrack(track.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text ('OpenTrack')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: _tracksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) {
                  return const Center(child: Text('no tracks'));
                }
                return ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      title: Text(track.title),
                      subtitle: Text('${track.artist} - ${track.album}'),
                      onTap: () => _playTrack(track),
                    );
                  },
                );
              }

            ),),
            if (_currentTrack != null) _PlayerBar(track: _currentTrack!, audio: _audio),
        ],
      ),
      );

  }
}

class _PlayerBar extends StatelessWidget {
  final Track track;
  final AudioPlayerService audio;

  const _PlayerBar({required this.track, required this.audio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // Check if need to adjust
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${track.title} - ${track.artist}', style: const TextStyle(fontWeight: FontWeight.bold)),
          StreamBuilder<Duration?>(stream: audio.durationStream, builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            return StreamBuilder<Duration>(stream: audio.positionStream, builder: (context, positionSnapshot) {
              final position = positionSnapshot.data ?? Duration.zero;
              final maxMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
              final clampedMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);
              return Slider(
                value: clampedMs, max: maxMs, onChanged: (value) => audio.seek(Duration(milliseconds: value.toInt())),
              );
            },);
          },),
          StreamBuilder<PlayerState>(
            stream: audio.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                iconSize: 36,
                icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                onPressed: () => playing ? audio.pause() : audio.resume(),
              );
            },
          ),
        ],
      ),
    );
  }
}
