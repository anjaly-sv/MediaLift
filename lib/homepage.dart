import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlatformFile? pickedFile;
  VideoPlayerController? _videoController;
  bool _isVideo(PlatformFile file) => file.extension == 'mp4';
  double uploadProgress = 0.0;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(String title, String body, {double? progress}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'upload_channel',
      'File Upload',
      channelDescription: 'Shows progress of file upload',
      importance: Importance.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,title,body,platformDetails,
      payload: progress?.toString(),
    );
  }


  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final selectedFile = result.files.first;
      setState(() {
        pickedFile = selectedFile;
        uploadProgress = 0.0;
      });

      if (_isVideo(selectedFile)) {
        initializeVideoPlayer(File(selectedFile.path!));
      } else {
        disposeVideoPlayer();
      }

      // Start file upload
      await uploadFile(File(selectedFile.path!), selectedFile.name);
    }
  }
  Future<void> uploadFile(File file, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName');
      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes * 100;
        setState(() {
          uploadProgress = progress;
        });
        _showNotification(
          'Uploading...',
          '${progress.toStringAsFixed(2)}% uploaded',
          progress: progress,
        );
      });

      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();
        setState(() {
          uploadProgress = 100.0;
        });
        await _showNotification('Upload Complete', 'File uploaded successfully!');
        print('File uploaded successfully: $downloadUrl');
      });
    } catch (e) {
      print('Error uploading file: $e');
      await _showNotification('Upload Failed', 'Error: $e');
    }
  }
  void initializeVideoPlayer(File file) {
    disposeVideoPlayer();
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {});
      });
  }
  void disposeVideoPlayer() {
    _videoController?.dispose();
    _videoController = null;
  }
  Widget buildVideoPreview() {
    return _videoController != null && _videoController!.value.isInitialized
        ? Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        IconButton(
          icon: Icon(
            _videoController!.value.isPlaying
                ? Icons.pause_circle
                : Icons.play_circle,
            size: 48,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          },
        ),
      ],
    )
        : const CircularProgressIndicator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MediaLift"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: pickedFile == null
              ? const Text("No file selected.")
              : _isVideo(pickedFile!)
              ? buildVideoPreview()
              : Text("Picked File: ${pickedFile!.name}"),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickFile,
        child: const Icon(Icons.attach_file),
      ),
    );
  }
  void dispose() {
    disposeVideoPlayer();
    super.dispose();
  }
}
