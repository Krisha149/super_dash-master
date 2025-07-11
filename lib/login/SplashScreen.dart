// splash_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_dash/login/login.dart';
import 'package:video_player/video_player.dart';
import 'package:authentication_repository/authentication_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key, required this.authenticationRepository})
      : super(key: key);

  final AuthenticationRepository authenticationRepository;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _videoController = kIsWeb
        ? VideoPlayerController.networkUrl(
        Uri.parse('assets/audio/million_dream_splash.mp4'))
        : VideoPlayerController.asset('assets/audio/million_dream_splash.mp4');

    _videoController.initialize().then((_) {
      setState(() {});
      _videoController.play();

      _videoController.addListener(() {
        final isEnded = _videoController.value.position >= _videoController.value.duration;

        if (isEnded && !_videoController.value.isPlaying && !hasNavigated) {
          hasNavigated = true;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginGate(
                authenticationRepository: widget.authenticationRepository,
              ),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoController.value.isInitialized
          ? AspectRatio(
        aspectRatio: _videoController.value.aspectRatio,
        child: VideoPlayer(_videoController),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
