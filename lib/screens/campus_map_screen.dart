import 'dart:async';
import 'package:flutter/material.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _loadImage() {
    final imageProvider = const AssetImage('assets/images/map.jpg');
    _imageStream = imageProvider.resolve(ImageConfiguration.empty);
    
    _imageListener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingProgress = 1.0;
          });
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
    
    _imageStream?.addListener(_imageListener!);
    
    // 模擬載入進度更新
    _simulateLoadingProgress();
  }

  void _simulateLoadingProgress() {
    if (!mounted) return;
    
    const duration = Duration(milliseconds: 50);
    const increment = 0.02; // 每次增加 2%
    
    Future.delayed(duration, () {
      if (mounted && _isLoading && _loadingProgress < 0.9) {
        setState(() {
          _loadingProgress += increment;
        });
        _simulateLoadingProgress();
      }
    });
  }

  void _removeImageListener() {
    if (_imageListener != null && _imageStream != null) {
      _imageStream!.removeListener(_imageListener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('校園地圖'),
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildMapWidget(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '載入中... ${(_loadingProgress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          maxScale: 6.0,
          minScale: 0.1,
          child: Center(
            child: Image.asset(
              'assets/images/map.jpg',
              // 設定寬度為螢幕寬度，但不使用 fit 參數避免變形
              width: constraints.maxWidth,
              filterQuality: FilterQuality.high,
              errorBuilder: _buildErrorWidget,
            ),
          ),
        );
      },
    );
  }

  // 錯誤顯示 Widget
  Widget _buildErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          '地圖載入失敗',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0.0;
            });
            _loadImage();
          },
          child: const Text('重新載入'),
        ),
      ],
    );
  }
} 