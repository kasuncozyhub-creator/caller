import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const DialerHomeScreen(),
    );
  }
}

class DialerHomeScreen extends StatefulWidget {
  const DialerHomeScreen({super.key});

  @override
  State<DialerHomeScreen> createState() => _DialerHomeScreenState();
}

class _DialerHomeScreenState extends State<DialerHomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _numberController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _numberController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Handle number dial launch
  Future<void> _makePhoneCall() async {
    final String phoneNumber = _numberController.text.trim();
    if (phoneNumber.isEmpty) {
      _showWarningSnackBar('Please enter a phone number first!');
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showErrorSnackBar('Could not launch dialer app: $e');
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
                const SizedBox(height: 24),

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
