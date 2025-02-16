import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/room.dart';
import 'package:zapcall/src/logger.dart';
import 'package:zapcall/src/types.dart';

class CallScreen extends StatefulWidget {
  const CallScreen.call({
    required String this.userId,
    super.key,
  })  : isIncoming = false,
        roomId = null;

  const CallScreen.answer({
    required String this.roomId,
    super.key,
  })  : isIncoming = true,
        userId = null;

  final bool isIncoming;

  final String? userId;
  final String? roomId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late String? roomId = widget.roomId;

  bool get isIncoming => widget.isIncoming;

  final appUserId = FirebaseAuth.instance.currentUser!.uid;

  // final signaling = Signaling();
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // TODO(albin):
    Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (!mounted) return timer.cancel();
        setState(() {});
      },
    );

    _setStatusBarDark();

    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await _getPermissions();

    // signaling.onAddRemoteStream = ((stream) {
    //   _remoteRenderer.srcObject = stream;
    //   setState(() {});
    // });

    // signaling.onCallEnd = () {
    //   Navigator.of(context).pop();
    // };

    // if (false)
    //
    if (isIncoming) {
      await _answerCall();
    } else {
      await _requestCall();
    }
  }

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Future<void> _getPermissions() async {
    final stream = await navigator.mediaDevices.getUserMedia(
      {'video': true, 'audio': true},
    );
    _localRenderer.srcObject = stream;
    // signaling.localStream = stream;
    localStream = stream;
    _remoteRenderer.srcObject = await createLocalMediaStream('key');
  }

  static const configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      }
    ],
  };

  Future<void> _requestCall() async {
    roomId = await createRoom();
  }

  StreamSubscription<DocumentSnapshot<RoomModel>>? sub1;
  StreamSubscription<QuerySnapshot<Json>>? sub2;
  StreamSubscription<QuerySnapshot<Json>>? sub3;

  Future<String> createRoom() async {
    final roomRef = Db.roomsRef.doc();

    peerConnection = await createPeerConnection(configuration);

    // registerPeerConnectionListeners();

    // TODO(albin): when it assings
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    final callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap() as Json);
    };

    // Add code for creating a room
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    final roomWithOffer = {'offer': offer.toMap()};

    // await roomRef.set(roomWithOffer);
    await roomRef.set(
      RoomModel(
        info: RoomInfoModel(
          // name: 'The Room',
          fromId: appUserId,
          toId: widget.userId!,
        ),
        offer: offer.toMap() as Json,
      ),
    );
    final roomId = roomRef.id;
    // currentRoomText = 'Current room is $roomId - You are the caller!';
    // Created a Room

    // peerConnection?.onAddStream = (MediaStream stream) {
    //   l("Add remote stream");
    // };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      remoteStream = event.streams[0];
      // onAddRemoteStream?.call(remoteStream!);

      _remoteRenderer.srcObject = remoteStream;

      event.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    };

    // Listening for remote session description below
    await sub1?.cancel();
    sub1 = roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data()!;
      if (peerConnection?.getRemoteDescription() != null &&
          data.answer != null) {
        final answer = RTCSessionDescription(
          data.answer?['sdp'] as String?,
          data.answer?['type'] as String?,
        );
        await peerConnection?.setRemoteDescription(answer);
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    await sub2?.cancel();
    sub2 =
        roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'] as String?,
              data['sdpMid'] as String?,
              data['sdpMLineIndex'] as int?,
            ),
          );
        }
      }
    });
    return roomId;
  }

  Future<void> _answerCall() async {
    await joinRoom();
  }

  Future<void> joinRoom() async {
    final roomRef = Db.roomsRef.doc(widget.roomId);
    final roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(configuration);

      // registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      final calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          return;
        }
        calleeCandidatesCollection.add(candidate.toMap() as Json);
      };
      // Code for collecting ICE candidate above

      peerConnection?.onTrack = (RTCTrackEvent event) {
        remoteStream = event.streams[0];
        // onAddRemoteStream?.call(remoteStream!);
        _remoteRenderer.srcObject = remoteStream;
        event.streams[0].getTracks().forEach((track) {
          remoteStream?.addTrack(track);
        });
      };

      // Code for creating SDP answer below
      final data = roomSnapshot.data()!;
      final offer = data.offer;
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(
          offer?['sdp'] as String?,
          offer?['type'] as String?,
        ),
      );
      final answer = await peerConnection!.createAnswer();

      await peerConnection!.setLocalDescription(answer);

      final roomWithAnswer = <String, dynamic>{
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      await sub3?.cancel();
      sub3 =
          roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (final document in snapshot.docChanges) {
          final data = document.doc.data()!;
          l(data);
          l('Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'] as String?,
              data['sdpMid'] as String?,
              data['sdpMLineIndex'] as int?,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    rtcDispose();
    _setStatusBarLight();
    super.dispose();
  }

  void rtcDispose() {
    sub1?.cancel();
    sub2?.cancel();
    sub3?.cancel();
    localStream?.dispose();
    remoteStream?.dispose();
    peerConnection?.dispose();
  }

  void _setStatusBarLight() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _setStatusBarDark() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
    );
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
                            : const Icon(Icons.videocam_off_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // mic, hang, video
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isFullScreen
                  ? const SizedBox.shrink(key: Key('full'))
                  : Align(
                      key: const Key('normal'),
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
                                  padding: const EdgeInsets.all(15),
                                ),
                                onPressed: _onTapMic,
                                icon:
                                    Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                              ),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(15),
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: _onTapHang,
                                icon: const Icon(Icons.call_end),
                              ),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(15),
                                ),
                                onPressed: _onTapVideo,
                                icon: Icon(
                                  _isVideoOn
                                      ? Icons.videocam
                                      : Icons.videocam_off,
                                ),
                              ),
                              if (!kIsWeb)
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(15),
                                  ),
                                  onPressed: _onSwitchCamera,
                                  icon:
                                      const Icon(Icons.switch_camera_outlined),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isMicOn = true;
  void _onTapMic() {
    setState(() {
      _isMicOn = !_isMicOn;
      localStream?.getAudioTracks()[0].enabled = _isMicOn;
    });
  }

  bool _isVideoOn = true;
  void _onTapVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
      localStream?.getVideoTracks()[0].enabled = _isVideoOn;
    });
    // for (final t in _localRenderer.srcObject!.getVideoTracks()) {
    //   t.enabled = !_isVideoOn;
    // }
  }

  Future<void> _onSwitchCamera() async {
    await Helper.switchCamera(localStream!.getVideoTracks()[0]);
  }

  Future<void> _onTapHang() async {
    try {
      if (_isVideoOn) _onTapVideo();
      if (_isMicOn) _onTapMic();
      await hangUp(_localRenderer, roomId);
      Navigator.of(context).pop();
    } catch (e) {
      l('error: $e');
    }
  }

  Future<void> hangUp(RTCVideoRenderer localVideo, String? roomId) async {
    final tracks = localVideo.srcObject!.getTracks();
    for (final track in tracks) {
      track.stop();
    }

    remoteStream?.getTracks().forEach((track) => track.stop());
    peerConnection?.close();

    sub1?.cancel();

    if (roomId != null) {
      final db = FirebaseFirestore.instance;
      final roomRef = db.collection('rooms').doc(roomId);
      final calleeCandidates =
          await roomRef.collection('calleeCandidates').get();
      for (final document in calleeCandidates.docs) {
        document.reference.delete();
      }

      final callerCandidates =
          await roomRef.collection('callerCandidates').get();
      for (final document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  bool _isFullScreen = false;
  void _onTapScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }
}
