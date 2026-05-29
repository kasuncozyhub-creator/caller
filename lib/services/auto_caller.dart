import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        'phoneNumber': doc.get('phoneNumber') as String,
        'name': doc.get('name') as String,
      }).toList();
      
      if (_numbersQueue.isEmpty) {
        onStateChanged(false, 'Calling stopped: No numbers found in database.', 0, 0);
        _isRunning = false;
        return;
      }
      
      // Call first number immediately
      _executeNextCall();
      
      // Schedule subsequent calls
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
      await _channel.invokeMethod('callNumberWithSpeakerphone', {'phoneNumber': number});
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
