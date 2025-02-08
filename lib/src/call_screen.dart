import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zapcall/src/logger.dart';
import 'package:zapcall/src/signaling.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.roomId,
  });

  final String? roomId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final db = FirebaseFirestore.instance;
  late final roomsRef = db.collection('rooms');

  late String? roomId = widget.roomId;

  bool get isCalling => widget.roomId == null;
  bool get isAnswering => !isCalling;

  final signaling = Signaling();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // TODO(albin):
    Timer.periodic(
      Duration(seconds: 2),
      (timer) {
        if (!mounted) return timer.cancel();
        setState(() {});
      },
    );

    _setStatusBarDark();

    _init();
  }

  Future<void> _init() async {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    await _getPermissions();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    signaling.onCallEnd = () {
      Navigator.of(context).pop();
    };

    // if (false)
    //
    if (isCalling) {
      _requestCall();
    } else {
      _answerCall();
    }
  }

  Future<void> _getPermissions() async {
    final stream = await navigator.mediaDevices.getUserMedia(
      {'video': true, 'audio': true},
    );
    _localRenderer.srcObject = stream;
    signaling.localStream = stream;
    _remoteRenderer.srcObject = await createLocalMediaStream('key');
  }

  void _requestCall() async {
    roomId = await signaling.createRoom();
  }

  void _answerCall() async {
    await signaling.joinRoom(widget.roomId!);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    signaling.dispose();
    _setStatusBarLight();
    super.dispose();
  }

  void _setStatusBarLight() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));
  }

  void _setStatusBarDark() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    _setStatusBarDark();

    return GestureDetector(
      onTap: _onTapScreen,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // remote
            RTCVideoView(
              _remoteRenderer,
            ),

            // local
            Align(
              alignment: Alignment.topRight,
              child: SafeArea(
                // top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.2,
                    child: AspectRatio(
                      aspectRatio: _localRenderer.videoValue.aspectRatio,
                      child: Card(
                        elevation: 0,
                        color: cs.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: _isVideoOn
                            ? RTCVideoView(
                                _localRenderer,
                                mirror: true,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              )
                            : Icon(Icons.videocam_off_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // mic, hang, video
            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: _isFullScreen
                  ? SizedBox.shrink(key: Key('full'))
                  : Align(
                      key: Key('normal'),
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            spacing: 30,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.all(15),
                                ),
                                onPressed: _onTapMic,
                                icon:
                                    Icon(_isMuted ? Icons.mic_off : Icons.mic),
                              ),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.all(15),
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: _onTapHang,
                                icon: Icon(Icons.call_end),
                              ),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  padding: EdgeInsets.all(15),
                                ),
                                onPressed: _onTapVideo,
                                icon: Icon(
                                  _isVideoOn
                                      ? Icons.videocam
                                      : Icons.videocam_off,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }

  bool _isMuted = false;
  void _onTapMic() {
    setState(() {
      _localRenderer.muted = _isMuted = !_isMuted;
    });
  }

  bool _isVideoOn = true;
  void _onTapVideo() {
    for (final t in _localRenderer.srcObject!.getVideoTracks()) {
      t.enabled = !_isVideoOn;
    }
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
  }

  Future<void> _onTapHang() async {
    try {
      if (_isVideoOn) _onTapVideo();
      try {
        if (!_isMuted) _onTapMic();
      } catch (_) {}
      await signaling.hangUp(_localRenderer, roomId);
      Navigator.of(context).pop();
    } catch (e) {
      l('error: $e');
    }
  }

  bool _isFullScreen = false;
  void _onTapScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }
}
