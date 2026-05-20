import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  const SplashScreen({super.key, required this.next});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => widget.next));
    });
  }

  @override
  Widget build(BuildContext context) {
    const gothic = TextStyle(fontFamily: 'PirataOne', fontSize: 46, height: 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/branding/logo.png', width: 200),
            const SizedBox(height: 24),
            Text('John Wick', style: gothic.copyWith(color: Colors.white)),
            Text('Dev', style: gothic.copyWith(color: kAccentDefault)),
          ],
        ),
      ),
    );
  }
}
