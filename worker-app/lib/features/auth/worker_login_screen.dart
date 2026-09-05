import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../home/worker_home_screen.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  // Form Controllers - Email
  final _emailController = TextEditingController(text: 'rajesh.kumar@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  // Form Controllers - OTP
  final _phoneController = TextEditingController(text: '+919876543211');
  final _otpController = TextEditingController(text: '123456');

  // Form Controllers - Sign Up
  bool _isSignUpMode = false;
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  String _selectedTrade = 'Electrician';

  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _trades = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mason',
    'AC Repair',
    'Deep Cleaning',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  void _fillDemoRajesh() {
    setState(() {
      _tabController.index = 0;
      _emailController.text = AppConstants.defaultWorkerEmail;
      _passwordController.text = 'password123';
      _phoneController.text = AppConstants.defaultWorkerPhone;
      _otpController.text = '123456';
      _errorMessage = null;
    });
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.loginWithEmail(
        email: email,
        password: pass,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('access_token')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
          );
        } else {
          setState(() => _errorMessage = 'Sign in failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleOtpLogin() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.loginWithOtp(
        phone: phone.startsWith('+91') ? phone : '+91',
        otp: otp,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('access_token')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
          );
        } else {
          setState(() => _errorMessage = 'OTP verification failed. Use code 123456.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final phone = _signupPhoneController.text.trim();
    final pass = _signupPasswordController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Full Name is required.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Valid email is required.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.signupWithEmail(
        fullName: name,
        email: email,
        password: pass,
        phone: phone.isNotEmpty ? (phone.startsWith('+91') ? phone : '+91') : null,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('access_token')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrandingHeader(textTheme),
                const SizedBox(height: 24),
                _buildQuickDemoChip(textTheme),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonAlert.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.crimsonAlert.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.crimsonAlert, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.crimsonAlert,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.slateBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.slateNavy.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isSignUpMode ? _buildSignUpForm(textTheme) : _buildSignInForm(textTheme),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUpMode
                          ? 'Already a registered partner? Sign In'
                          : 'New tradesperson? Register as Trade Partner',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppTheme.slateNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingHeader(TextTheme textTheme) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppTheme.slateNavy,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.slateNavy.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.handyman, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          AppConstants.appName,
          style: textTheme.displayLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.slateNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.tagline,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: AppTheme.slateMuted,
          ),
        ),
        Text(
          AppConstants.taglineTa,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 11,
            color: AppTheme.slateMuted.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDemoChip(TextTheme textTheme) {
    return InkWell(
      onTap: _fillDemoRajesh,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.emeraldSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emeraldDark.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: AppTheme.emeraldOnline, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Fill Demo: Rajesh Kumar (Electrician)',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppTheme.emeraldDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'rajesh.kumar@example.com • +91 98765 43211',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.emeraldDark.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.emeraldDark, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInForm(TextTheme textTheme) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.slateLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.slateNavy,
            indicatorWeight: 3,
            labelColor: AppTheme.slateNavy,
            unselectedLabelColor: AppTheme.slateMuted,
            labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.email_outlined, size: 18), text: 'Email & Password'),
              Tab(icon: Icon(Icons.phone_android, size: 18), text: 'Mobile OTP'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmailSignInTab(textTheme),
                _buildOtpSignInTab(textTheme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSignInTab(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.alternate_email, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.slateNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Sign In as Trade Partner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSignInTab(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Registered Mobile Number',
            prefixIcon: const Icon(Icons.phone, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '6-Digit OTP (Dev default: 123456)',
            prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleOtpLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.slateNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Verify & Enter Partner Radar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.app_registration, color: AppTheme.slateNavy, size: 22),
              const SizedBox(width: 8),
              Text(
                'Trade Partner Registration',
                style: textTheme.headlineSmall?.copyWith(fontSize: 17, color: AppTheme.slateNavy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signupNameController,
            decoration: InputDecoration(
              labelText: 'Full Name (as in Aadhaar)',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.alternate_email, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signupPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number (+91)',
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedTrade,
            items: _trades.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedTrade = val);
            },
            decoration: InputDecoration(
              labelText: 'Primary Trade / Skill',
              prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _signupPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password (min 6 chars)',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Create Partner Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
