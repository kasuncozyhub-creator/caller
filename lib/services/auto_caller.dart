import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_service.dart';

class AutoCaller {
  static const _channel = MethodChannel('com.example.caller/direct_call');
  final FirebaseService _firebaseService = FirebaseService();
  
  StreamSubscription? _jobSubscription;
  Timer? _timer;
  
  List<Map<String, dynamic>> _numbersQueue = [];
  int _currentIndex = 0;
  bool _isRunning = false;
  int _intervalMinutes = 5;
  
  // Callback to update UI
  final Function(bool isRunning, String statusMessage, int currentIndex, int totalCount) onStateChanged;

  AutoCaller({required this.onStateChanged});

  void startListening() {
    _jobSubscription = _firebaseService.getCallJob().listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final status = data['status'] ?? 'idle';
      final interval = data['interval_minutes'] ?? 5;
      
      if (status == 'running') {
        if (!_isRunning || _intervalMinutes != interval) {
          _intervalMinutes = interval;
          _startCallingCycle();
        }
      } else {
        if (_isRunning) {
          _stopCallingCycle();
        }
      }
    });
  }

  void stopListening() {
    _jobSubscription?.cancel();
    _timer?.cancel();
  }

  Future<void> _startCallingCycle() async {
    _timer?.cancel();
    _isRunning = true;
    _currentIndex = 0;
    
    onStateChanged(true, 'Fetching sync directory...', 0, 0);
    
    // Fetch numbers once when the job starts
    try {
      final numbersSnapshot = await FirebaseFirestore.instance.collection('numbers').orderBy('createdAt', descending: false).get();
      _numbersQueue = numbersSnapshot.docs.map((doc) => {
        'id': doc.id,
        'phoneNumber': doc.get('phoneNumber') as String,
        'name': doc.get('name') as String,
      }).toList();
      
      if (_numbersQueue.isEmpty) {
        onStateChanged(false, 'Calling stopped: No numbers found in database.', 0, 0);
        _isRunning = false;
        return;
      }
      
      // Display friendly waiting status message before the first call gap completes
      onStateChanged(
        true, 
        'Waiting $_intervalMinutes min(s) before first call...', 
        0, 
        _numbersQueue.length
      );
      
      // Schedule calls at designated intervals
      _timer = Timer.periodic(Duration(minutes: _intervalMinutes), (timer) {
        _executeNextCall();
      });
      
    } catch (e) {
      onStateChanged(false, 'Failed to fetch directory: $e', 0, 0);
      _isRunning = false;
    }
  }

  void _stopCallingCycle() {
    _timer?.cancel();
    _isRunning = false;
    _currentIndex = 0;
    _numbersQueue.clear();
    onStateChanged(false, 'Idle. Waiting for admin to start job.', 0, 0);
  }

  Future<void> _executeNextCall() async {
    if (_currentIndex >= _numbersQueue.length) {
      // Loop back to start of list if admin didn't stop the job, or stop. Let's loop.
      _currentIndex = 0;
    }
    
     final currentContact = _numbersQueue[_currentIndex];
    final docId = currentContact['id']!;
    final number = currentContact['phoneNumber']!;
    final name = currentContact['name']!;
    
    final displayName = name.isNotEmpty ? name : number;
    onStateChanged(
      true, 
      'Auto dialing $displayName (${_currentIndex + 1}/${_numbersQueue.length})', 
      _currentIndex, 
      _numbersQueue.length
    );
    
    try {
      // Ensure phone calling permission is granted
      PermissionStatus status = await Permission.phone.status;
      if (status.isDenied || status.isLimited || status.isRestricted) {
        status = await Permission.phone.request();
      }

      if (status.isGranted) {
        // Update calling status in Firestore
        FirebaseFirestore.instance.collection('numbers').doc(docId).update({
          'isCalled': true,
          'lastCalledAt': FieldValue.serverTimestamp(),
        }).catchError((e) => print('Error updating status: $e'));

        await _channel.invokeMethod('callNumberWithSpeakerphone', {'phoneNumber': number});
      } else {
        onStateChanged(
          true, 
          'Permission Denied: Cannot auto-dial without phone call permissions.', 
          _currentIndex, 
          _numbersQueue.length
        );
      }
    } on PlatformException catch (e) {
      onStateChanged(
        true, 
        'Direct Call Failed: ${e.message}. Attempting fallback...', 
        _currentIndex, 
        _numbersQueue.length
      );
    }
    
    _currentIndex++;
  }
}
