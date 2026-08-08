import 'package:flutter/material.dart';

import '../../../core/services/auth_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../customers/views/customer_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    final success =
    await AuthService.login(_controller.text);

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration:
          const Duration(milliseconds: 420),

          pageBuilder: (context, animation,
              secondaryAnimation) {
            return const CustomerListPage();
          },

          transitionsBuilder: (context, animation,
              secondaryAnimation, child) {
            // Fade animation
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            // Scale animation
            final scale = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            );

            // Slight upward movement
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
              'Oops! Your son says that is not the correct name 😅'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _anim,
          curve: Curves.easeOut,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                children: [
                  // Comic avatar
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.gold
                              .withValues(alpha: 0.22),
                          AppTheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppTheme.gold,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold
                              .withValues(alpha: 0.25),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '👦',
                        style: TextStyle(
                          fontSize: 84,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Secret Family Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Answer the funny question set by your son to unlock the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Comic speech bubble
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                      BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.gold
                            .withValues(alpha: 0.16),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: const [
                        Text(
                          '💬',
                          style: TextStyle(
                              fontSize: 30),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Before opening this app, tell me…\nWhat does your son insist you call him? 😎👦',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  TextField(
                    controller: _controller,
                    obscureText: _obscure,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type the secret answer',
                      hintStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.gold,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() =>
                          _obscure = !_obscure);
                        },
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.gold,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.surface2,
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: AppTheme.gold
                              .withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AppTheme.gold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient:
                      AppTheme.goldGradient,
                      borderRadius:
                      BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold
                              .withValues(alpha: 0.30),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed:
                      _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.transparent,
                        shadowColor:
                        Colors.transparent,
                        foregroundColor:
                        Colors.black,
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                              20),
                        ),
                      ),
                      icon: _loading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.black,
                        ),
                      )
                          : const Icon(
                          Icons.key_rounded),
                      label: Text(
                        _loading
                            ? 'Checking...'
                            : 'Unlock App',
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Hint: Just ask your youngest son 😎',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _anim.dispose();
    super.dispose();
  }
}