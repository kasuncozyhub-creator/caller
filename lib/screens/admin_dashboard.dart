import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoggingIn = false;
  String? _loginError;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firebaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
          );
        }
        
        final user = snapshot.data;
        if (user == null) {
          return _buildLoginScreen();
        }
        
        return _buildDashboardScreen();
      },
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.06),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Admin Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to manage automated calling.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              
              // Email
              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'admin@caller.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Password
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_loginError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _loginError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              
              // Sign In Button
              ElevatedButton(
                onPressed: _isLoggingIn ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoggingIn
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });
    try {
      await _firebaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _loginError = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      });
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  Widget _buildDashboardScreen() {
    final TextEditingController numberAddController = TextEditingController();
    final TextEditingController nameAddController = TextEditingController();
    int selectedInterval = 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 12),
            Text(
              'Call Manager Admin',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _firebaseService.signOut(),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Panel
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Control panel summary & status
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firebaseService.getCallJob(),
                    builder: (context, snapshot) {
                      final status = snapshot.data?.get('status') ?? 'idle';
                      final currentInterval = snapshot.data?.get('interval_minutes') ?? 5;
                      final isRunning = status == 'running';

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isRunning ? const Color(0xFF10B981) : const Color(0xFF64748B)).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRunning ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: isRunning ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isRunning ? 'Active Calling Job' : 'Calling Stopped',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isRunning)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isRunning
                                        ? 'Calling Android client with a $currentInterval-minute gap.'
                                        : 'Select timer and click Start to initiate auto-calls on the physical phone.',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            // Quick Controls
                            const Text('Interval Gap: ', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            StatefulBuilder(
                              builder: (context, setDropState) {
                                return DropdownButton<int>(
                                  value: selectedInterval,
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('1 Minute')),
                                    DropdownMenuItem(value: 5, child: Text('5 Minutes')),
                                    DropdownMenuItem(value: 10, child: Text('10 Minutes')),
                                  ],
                                  onChanged: isRunning
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setDropState(() {
                                              selectedInterval = val;
                                            });
                                          }
                                        },
                                );
                              },
                            ),
                            const SizedBox(width: 24),
                            ElevatedButton.icon(
                              onPressed: isRunning
                                  ? () => _firebaseService.stopCallJob()
                                  : () => _firebaseService.startCallJob(selectedInterval),
                              icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                              label: Text(isRunning ? 'Stop calling' : 'Start calling'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isRunning ? Colors.red : const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Number Adding & Numbers List
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Adding Side Form
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Add New Contact',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 20),
                              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: numberAddController,
                                decoration: InputDecoration(
                                  hintText: '+1234567890',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Name (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameAddController,
                                decoration: InputDecoration(
                                  hintText: 'John Doe',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () async {
                                  final num = numberAddController.text.trim();
                                  final name = nameAddController.text.trim();
                                  if (num.isNotEmpty) {
                                    await _firebaseService.addNumber(num, name.isEmpty ? null : name);
                                    numberAddController.clear();
                                    nameAddController.clear();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Save Number'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      
                      // List of numbers
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Sync Directory',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 20),
                              StreamBuilder<QuerySnapshot>(
                                stream: _firebaseService.getNumbers(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  
                                  final docs = snapshot.data?.docs ?? [];
                                  if (docs.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        'No numbers added yet. Add numbers from the left panel.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFF64748B)),
                                      ),
                                    );
                                  }
                                  
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: docs.length,
                                    separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0)),
                                    itemBuilder: (context, index) {
                                      final doc = docs[index];
                                      final name = doc.get('name') as String;
                                      final number = doc.get('phoneNumber') as String;
                                      
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                                              child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 18),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name.isNotEmpty ? name : 'Unnamed Contact',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(number, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => _firebaseService.deleteNumber(doc.id),
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
