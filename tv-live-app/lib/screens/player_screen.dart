import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../providers/channel_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isFullScreen = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupTVRemote();
  }

  void _setupTVRemote() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final provider = context.read<ChannelProvider>();
      
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          _switchChannel(-1, provider);
          return true;
        case LogicalKeyboardKey.arrowDown:
          _switchChannel(1, provider);
          return true;
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          _togglePlayPause();
          return true;
        case LogicalKeyboardKey.back:
          if (_isFullScreen) {
            _toggleFullScreen();
          } else {
            Navigator.pop(context);
          }
          return true;
      }
    }
    return false;
  }

  void _switchChannel(int direction, ChannelProvider provider) {
    final current = provider.currentChannel;
    if (current == null) return;

    final currentIndex = provider.channels.indexWhere((c) => c.id == current.id);
    if (currentIndex < 0) return;

    int newIndex = currentIndex + direction;
    if (newIndex < 0) newIndex = provider.channels.length - 1;
    if (newIndex >= provider.channels.length) newIndex = 0;

    final newChannel = provider.channels[newIndex];
    provider.switchChannel(newChannel);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _initializePlayer();
  }

  void _togglePlayPause() {
    if (_chewieController != null) {
      if (_chewieController!.isPlaying) {
        _chewieController!.pause();
      } else {
        _chewieController!.play();
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _initializePlayer() {
    final provider = context.read<ChannelProvider>();
    final channel = provider.currentChannel;

    if (channel == null || channel.url.isEmpty) {
      setState(() {
        _error = '未选择频道';
        _isLoading = false;
      });
      return;
    }

    // 释放旧控制器
    _videoController?.dispose();
    _chewieController?.dispose();

    // 创建新控制器
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(channel.url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    _videoController!.addListener(() {
      if (_videoController!.value.isInitialized) {
        setState(() => _isLoading = false);
      }
      if (_videoController!.value.hasError) {
        setState(() {
          _error = '播放失败';
          _isLoading = false;
        });
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      showControlsOnInitialize: true,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: false,
      showOptions: false,
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _videoController?.dispose();
    _chewieController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(
      builder: (context, provider, child) {
        final channel = provider.currentChannel;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 视频播放器
              Center(
                child: _chewieController != null &&
                        _videoController!.value.isInitialized
                    ? Chewie(controller: _chewieController!)
                    : _error != null
                        ? _buildErrorState()
                        : _buildLoadingState(),
              ),
              // 顶部信息栏
              if (!_isFullScreen) _buildAppBar(channel),
              // 频道切换提示
              if (_isLoading && _error == null) _buildChannelIndicator(channel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(Channel? channel) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            channel?.name ?? '播放器',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _toggleFullScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFF1E88E5)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '正在加载频道...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(
          _error ?? '加载失败',
          style: TextStyle(color: Colors.red[300], fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _initializePlayer,
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelIndicator(Channel? channel) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                channel?.name ?? '加载中',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
