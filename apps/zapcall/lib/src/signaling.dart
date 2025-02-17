import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zapcall/src/logger.dart';
import 'package:zapcall/src/types.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
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

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  VoidCallback? onCallEnd;

  final db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Json>>? sub1;
  StreamSubscription<QuerySnapshot<Json>>? sub2;
  StreamSubscription<QuerySnapshot<Json>>? sub3;

  Future<String> createRoom() async {
    final roomRef = db.collection('rooms').doc();

    l('Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    // TODO(albin): when it assings
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    final callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      l('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap() as Json);
    };

    // Add code for creating a room
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    l('Created offer: $offer');

    final roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    final roomId = roomRef.id;
    l('New room created with SDK offer. Room ID: $roomId');
    currentRoomText = 'Current room is $roomId - You are the caller!';
    // Created a Room

    // peerConnection?.onAddStream = (MediaStream stream) {
    //   l("Add remote stream");
    // };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      l('Got remote track: ${event.streams[0]}');
      remoteStream = event.streams[0];
      onAddRemoteStream?.call(remoteStream!);

      event.streams[0].getTracks().forEach((track) {
        l('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    // Listening for remote session description below
    sub1?.cancel();
    sub1 = roomRef.snapshots().listen((snapshot) async {
      l('Got updated room: ${snapshot.data()}');

      final data = snapshot.data()!;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'] as String?,
          data['answer']['type'] as String?,
        );

        l('Someone tried to connect');
        await peerConnection?.setRemoteDescription(answer);
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    sub2?.cancel();
    sub2 =
        roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          l('Got new remote ICE candidate: ${jsonEncode(data)}');
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
    // Listen for remote ICE candidates above

    return roomId;
  }

  Future<void> joinRoom(String roomId) async {
    l(roomId);
    final roomRef = db.collection('rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();
    l('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      l('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      final calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          l('onIceCandidate: complete!');
          return;
        }
        l('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap() as Json);
      };
      // Code for collecting ICE candidate above

      peerConnection?.onTrack = (RTCTrackEvent event) {
        l('Got remote track: ${event.streams[0]}');
        remoteStream = event.streams[0];
        onAddRemoteStream?.call(remoteStream!);
        event.streams[0].getTracks().forEach((track) {
          l('Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
        });
      };

      // Code for creating SDP answer below
      final data = roomSnapshot.data()!;
      l('Got offer $data');
      final offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(
          offer['sdp'] as String?,
          offer['type'] as String?,
        ),
      );
      final answer = await peerConnection!.createAnswer();
      l('Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      final roomWithAnswer = <String, dynamic>{
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      sub3?.cancel();
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

  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    final stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': !true});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
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

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      l('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      l('Connection state change: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        onCallEnd?.call();
      }
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      l('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      l('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      l('Add remote stream');
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }

  void dispose() {
    sub1?.cancel();
    sub2?.cancel();
    sub3?.cancel();
    localStream?.dispose();
    remoteStream?.dispose();
    peerConnection?.dispose();
  }
}
