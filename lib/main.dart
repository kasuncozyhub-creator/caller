import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'screens/admin_dashboard.dart';
import 'services/auto_caller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Lock orientation to portrait for dialer consistency
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Clean, modern light mode system style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const CallerApp());
}

class CallerApp extends StatelessWidget {
  const CallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dai Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF10B981), // Emerald 500
          secondary: Color(0xFF0F172A), // Slate 900
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const AdminDashboardScreen() : const DialerHomeScreen(),
    );
  }
}

class DialerHomeScreen extends StatefulWidget {
  const DialerHomeScreen({super.key});

  @override
  State<DialerHomeScreen> createState() => _DialerHomeScreenState();
}

class _DialerHomeScreenState extends State<DialerHomeScreen> with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('com.example.caller/direct_call');
  final TextEditingController _numberController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Auto Calling state properties
  AutoCaller? _autoCaller;
  bool _isAutoCallingRunning = false;
  String _autoCallingStatus = 'Idle. Waiting for admin to start job.';
  int _autoCallingCurrentIndex = 0;
  int _autoCallingTotalCount = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Hook up real-time firebase calling engine
    _autoCaller = AutoCaller(
      onStateChanged: (isRunning, statusMessage, currentIndex, totalCount) {
        if (mounted) {
          setState(() {
            _isAutoCallingRunning = isRunning;
            _autoCallingStatus = statusMessage;
            _autoCallingCurrentIndex = currentIndex;
            _autoCallingTotalCount = totalCount;
          });
        }
      },
    )..startListening();
  }

  @override
  void dispose() {
    _autoCaller?.stopListening();
    _numberController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Handle direct phone call automatically
  Future<void> _makePhoneCall() async {
    final String phoneNumber = _numberController.text.trim();
    if (phoneNumber.isEmpty) {
      _showWarningSnackBar('Please enter a phone number first!');
      return;
    }

    try {
      // 1. Safe permission handling before calling native direct-dialer API
      PermissionStatus status = await Permission.phone.status;
      if (status.isDenied || status.isLimited || status.isRestricted) {
        status = await Permission.phone.request();
      }

      if (status.isGranted) {
        // 2. Call directly with speakerphone enabled using our custom platform channel
        try {
          final bool? res = await _channel.invokeMethod<bool>(
            'callNumberWithSpeakerphone',
            {'phoneNumber': phoneNumber},
          );
          if (res != true) {
            await _fallbackToDialer(phoneNumber);
          }
        } catch (_) {
          // Fallback to flutter_phone_direct_caller if platform channel fails
          final bool? res = await FlutterPhoneDirectCaller.callNumber(phoneNumber);
          if (res != true) {
            await _fallbackToDialer(phoneNumber);
          }
        }
      } else {
        // 3. Fallback to pre-filled dialer if permission denied
        await _fallbackToDialer(phoneNumber);
      }
    } catch (e) {
      // 4. Clean error recovery
      await _fallbackToDialer(phoneNumber);
    }
  }

  // Fallback to url_launcher (which does not require CALL_PHONE permission)
  Future<void> _fallbackToDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showErrorSnackBar('Could not launch dialer: $e');
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B), // Amber 500
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Red 500
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _appendNumber(String digit) {
    HapticFeedback.lightImpact();
    setState(() {
      _numberController.text += digit;
    });
  }

  void _backspace() {
    HapticFeedback.lightImpact();
    setState(() {
      final text = _numberController.text;
      if (text.isNotEmpty) {
        _numberController.text = text.substring(0, text.length - 1);
      }
    });
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _numberController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInput = _numberController.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Real-time Auto-Calling sync job banner
                if (_isAutoCallingRunning)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AUTO-CALL ACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _autoCallingStatus,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // Large Display for Phone Number
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Formatted Text field
                      TextField(
                        controller: _numberController,
                        readOnly: true,
                        showCursor: true,
                        cursorColor: const Color(0xFF10B981),
                        cursorWidth: 2.5,
                        cursorHeight: 36,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter phone number',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Animated tap to clear instruction
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: hasInput ? 0.6 : 0.0,
                        child: const Text(
                          'Hold backspace to clear all',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Dial Pad Grid (Standard 3x4 Layout)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('1', ' '),
                        _buildDialKey('2', 'A B C'),
                        _buildDialKey('3', 'D E F'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('4', 'G H I'),
                        _buildDialKey('5', 'J K L'),
                        _buildDialKey('6', 'M N O'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('7', 'P Q R S'),
                        _buildDialKey('8', 'T U V'),
                        _buildDialKey('9', 'W X Y Z'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDialKey('*', ' '),
                        _buildDialKey('0', '+'),
                        _buildDialKey('#', ' '),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Bottom Call / Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Empty placeholder to balance spacing on the left
                    const SizedBox(width: 76),
                    
                    // Call Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.heavyImpact();
                        _makePhoneCall();
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981), // Emerald 500
                              Color(0xFF059669), // Emerald 600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    
                    // Backspace Button (Only visible when there's text input)
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: hasInput ? 1.0 : 0.0,
                        child: hasInput
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _backspace,
                                  onLongPress: _clearAll,
                                  borderRadius: BorderRadius.circular(100),
                                  child: const Center(
                                    child: Icon(
                                      Icons.backspace_rounded,
                                      color: Color(0xFF64748B),
                                      size: 26,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dial Key Button
  Widget _buildDialKey(String digit, String subText) {
    return _DialButton(
      digit: digit,
      subText: subText,
      onTap: () => _appendNumber(digit),
      onLongPress: digit == '0' ? () => _appendNumber('+') : null,
    );
  }
}

// Custom animated Dial Button for premium feel
class _DialButton extends StatefulWidget {
  final String digit;
  final String subText;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DialButton({
    required this.digit,
    required this.subText,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_DialButton> createState() => _DialButtonState();
}

class _DialButtonState extends State<_DialButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          _animationController.forward();
        },
        onTapUp: (_) {
          _animationController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        onLongPress: () {
          _animationController.reverse();
          if (widget.onLongPress != null) {
            widget.onLongPress!();
          }
        },
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Slate 100
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE2E8F0), // Slate 200
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.digit,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A), // Slate 900
                ),
              ),
              if (widget.subText.isNotEmpty && widget.subText != ' ')
                Text(
                  widget.subText,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Color(0xFF94A3B8), // Slate 400
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
