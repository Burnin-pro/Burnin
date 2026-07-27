import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

/// Cinematic Splash Screen — Plays a full-screen video before transitioning to the app.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    
    // Fallback for Web autoplay block or precision issues: max 10 seconds.
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_navigating) {
        _checkAuthAndNavigate();
      }
    });

    // Initialize the local video asset with mixWithOthers so it can play during Google Meet / calls
    _controller = VideoPlayerController.asset(
      'assets/videos/splashscreen.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )
      ..initialize().then((_) {
        // Ensure the first frame is shown and start playing
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _controller.play();
        }
      });

    // Listen to the video playback state to trigger navigation when it ends
    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (!_controller.value.isPlaying &&
        _controller.value.isInitialized) {
      final position = _controller.value.position.inMilliseconds;
      final duration = _controller.value.duration.inMilliseconds;
      
      // Allow a 100ms margin for Web floating point precision issues
      if (duration > 0 && position >= duration - 100) {
        _checkAuthAndNavigate();
      }
    }
  }

  void _checkAuthAndNavigate() async {
    if (_navigating || !mounted) return;
    _navigating = true;

    // Ask for permission compulsory after splash finishes
    await LocalNotificationService.instance.requestPermission();

    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    
    if (user != null) {
      _navigateTo('/menu');
    } else {
      _navigateTo('/login');
    }
  }

  void _navigateTo(String routeName) {
    // Because we are using named routes in MaterialApp, we can simply use:
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to auth changes in case the login state resolves very late
    ref.listen(authStateProvider, (prev, next) {
      // We wait for the video to finish before navigating.
      // If the video is already done and we were waiting on auth, check now.
      if (!next.isLoading && _controller.value.isInitialized && !_controller.value.isPlaying) {
         final duration = _controller.value.duration.inMilliseconds;
         final position = _controller.value.position.inMilliseconds;
         if (duration > 0 && position >= duration - 100) {
           _checkAuthAndNavigate();
         }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, // Keeps it sleek while loading
      body: SizedBox.expand(
        child: _isVideoInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
