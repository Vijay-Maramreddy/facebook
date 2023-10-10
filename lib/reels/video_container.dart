import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoContainer extends StatefulWidget {
  final String videoUrl;
  final String? alignment;

  const VideoContainer({this.alignment,required this.videoUrl, Key? key}) : super(key: key);

  @override
  _VideoContainerState createState() => _VideoContainerState();
}

class _VideoContainerState extends State<VideoContainer> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  late Timer _progressTimer;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: 16 / 9, // Adjust the aspect ratio as needed
      autoPlay: true,
      looping: true,
      showControls: false, // Hide Chewie controls
    );

    // Set up a timer to update the progress indicator
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_videoPlayerController.value.isPlaying) {
        setState(() {
          _progress = _videoPlayerController.value.position.inMilliseconds / _videoPlayerController.value.duration.inMilliseconds;
        });
      }
    });

    // Listen for video end and restart it
    _videoPlayerController.addListener(() {
      if (_videoPlayerController.value.position >= _videoPlayerController.value.duration) {
        setState(() {
          _progress = 0.0; // Reset the progress to zero when the video completes
        });
        _videoPlayerController.seekTo(Duration(milliseconds: 0));
        _videoPlayerController.play();
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    _progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Alignment? alignment;

    switch (widget.alignment) {
      case 'left':
        alignment = Alignment.centerLeft;
        break;
      case 'right':
        alignment = Alignment.centerRight;
        break;
      default:
        alignment = Alignment.center;
    }
    // print(alignment);
    return Align(
      alignment: alignment,
      child: Column(
        children: [
          Container(
            width:550,
            height: 300,
            child: Stack(
              alignment: alignment,
              children: [
                Chewie(controller: _chewieController),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _progress,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Change the color as needed
            backgroundColor: Colors.grey, // Change the background color as needed
          ),
        ],
      ),
    );
  }
}