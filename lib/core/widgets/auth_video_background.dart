import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A single persistent, muted background video for welcome + login.
/// Selects the correct aspect ratio for the current viewport.
class AuthVideoBackground extends StatelessWidget {
  const AuthVideoBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final portrait = constraints.maxWidth < 950;
        final video = portrait ? 'asset/bg/mobile.mp4' : 'asset/bg/web.mp4';
        final poster = portrait
            ? 'asset/bg/mobile_poster.jpg'
            : 'asset/bg/web_poster.jpg';

        if (MediaQuery.disableAnimationsOf(context)) {
          return Image.asset(poster, fit: BoxFit.cover);
        }

        return _VideoSurface(
          key: ValueKey(video),
          asset: video,
          poster: poster,
        );
      },
    );
  }
}

class _VideoSurface extends StatefulWidget {
  final String asset;
  final String poster;

  const _VideoSurface({
    super.key,
    required this.asset,
    required this.poster,
  });

  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<_VideoSurface>
    with WidgetsBindingObserver {
  late final VideoPlayerController _video;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _video = VideoPlayerController.asset(widget.asset);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _video.initialize();
      if (!mounted) return;
      await _video.setVolume(0);
      await _video.setLooping(true);
      if (!mounted) return;
      setState(() => _ready = true);
      await _video.play();
    } catch (error) {
      debugPrint('Welcome background video unavailable: $error');
      // The poster remains visible; auth still works.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state == AppLifecycleState.resumed) {
      _video.play();
    } else {
      _video.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          widget.poster,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: Color(0xFF173B70)),
        ),
        if (_ready && _video.value.size.width > 0)
          ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _video.value.size.width,
                  height: _video.value.size.height,
                  child: VideoPlayer(_video),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
