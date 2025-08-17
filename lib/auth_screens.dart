import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordSetupScreen extends StatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  _PasswordSetupScreenState createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> 
    with TickerProviderStateMixin {
  String _enteredPassword = '';
  String _confirmPassword = '';
  bool _isSettingPassword = true;
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.05, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.05, 0), end: const Offset(0.03, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.03, 0), end: const Offset(-0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    ));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appPassword', _enteredPassword);
    await prefs.setBool('isFirstLaunch', false);
    if (!mounted) return;
    
    setState(() {
      _errorMessage = '✓';
    });
    
    _pulseController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    Navigator.pushReplacementNamed(context, '/splash');
  }

  void _onNumberPressed(int number) async {
    setState(() {
      if (_isSettingPassword) {
        if (_enteredPassword.length < 6) {
          _enteredPassword += number.toString();
          if (_enteredPassword.length == 6) {
            _errorMessage = '';
            _isSettingPassword = false;
          }
        }
      } else {
        if (_confirmPassword.length < 6) {
          _confirmPassword += number.toString();
        }
        
        if (_confirmPassword.length == 6) {
          if (_confirmPassword == _enteredPassword) {
            _savePassword();
          } else {
            _errorMessage = 'Passwords do not match';
            _enteredPassword = '';
            _confirmPassword = '';
            _isSettingPassword = true;
            _shakeController.forward(from: 0);
          }
        }
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_isSettingPassword) {
        if (_enteredPassword.isNotEmpty) {
          _enteredPassword = _enteredPassword.substring(0, _enteredPassword.length - 1);
        }
      } else {
        if (_confirmPassword.isNotEmpty) {
          _confirmPassword = _confirmPassword.substring(0, _confirmPassword.length - 1);
        }
      }
    });
  }

  Widget _buildPasswordIndicator(String password) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < password.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(isFilled ? 0.3 : 0.5),
              width: isFilled ? 0 : 1.5,
            ),
            color: isFilled ? Colors.white : Colors.transparent,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _enteredPassword.isEmpty ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: const Text(
                'SECURE ACCESS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SlideTransition(
              position: _shakeAnimation,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutQuart,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _isSettingPassword ? 'Create Password' : 'Confirm Password',
                        key: ValueKey(_isSettingPassword),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordIndicator(
                      _isSettingPassword ? _enteredPassword : _confirmPassword,
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _errorMessage,
                  key: ValueKey(_errorMessage),
                  style: TextStyle(
                    color: _errorMessage == '' ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: List.generate(9, (index) {
                return _NumberButton(
                  number: index + 1,
                  onPressed: _onNumberPressed,
                );
              })..addAll([
                const SizedBox.shrink(),
                _NumberButton(
                  number: 0,
                  onPressed: _onNumberPressed,
                ),
                _BackspaceButton(
                  onPressed: _onBackspacePressed,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordEntryScreen extends StatefulWidget {
  const PasswordEntryScreen({super.key});

  @override
  _PasswordEntryScreenState createState() => _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends State<PasswordEntryScreen> 
    with TickerProviderStateMixin {
  String _enteredPassword = '';
  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.05, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.05, 0), end: const Offset(0.03, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.03, 0), end: const Offset(-0.02, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.02, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    ));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('appPassword') ?? '';
    
    if (_enteredPassword == savedPassword) {
      setState(() {
      });
      
      _pulseController.forward();
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/splash');
    } else {
      setState(() {
        _errorMessage = 'Incorrect password';
        _enteredPassword = '';
      });
      _shakeController.forward(from: 0);
    }
  }

  void _onNumberPressed(int number) {
    setState(() {
      if (_enteredPassword.length < 6) {
        _enteredPassword += number.toString();
        if (_enteredPassword.length == 6) {
          _checkPassword();
        }
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_enteredPassword.isNotEmpty) {
        _enteredPassword = _enteredPassword.substring(0, _enteredPassword.length - 1);
      }
    });
  }

  Widget _buildPasswordIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _enteredPassword.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(isFilled ? 0.3 : 0.5),
              width: isFilled ? 0 : 1.5,
            ),
            color: isFilled ? Colors.white : Colors.transparent,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            SlideTransition(
              position: _shakeAnimation,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: _buildPasswordIndicator(),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _errorMessage,
                  key: ValueKey(_errorMessage),
                  style: TextStyle(
                    color: _errorMessage == '✓' ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              padding: const EdgeInsets.symmetric(horizontal: 60),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: List.generate(9, (index) {
                return _NumberButton(
                  number: index + 1,
                  onPressed: _onNumberPressed,
                );
              })..addAll([
                const SizedBox.shrink(),
                _NumberButton(
                  number: 0,
                  onPressed: _onNumberPressed,
                ),
                _BackspaceButton(
                  onPressed: _onBackspacePressed,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final Function(int) onPressed;

  const _NumberButton({
    required this.number,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(number),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackspaceButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Icon(
            Icons.backspace,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}