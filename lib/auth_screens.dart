import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordSetupScreen extends StatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  _PasswordSetupScreenState createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> 
    with SingleTickerProviderStateMixin {
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
            _errorMessage = 'Passcodes do not match';
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
          child: isFilled ? ScaleTransition(
            scale: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _shakeController,
                curve: Interval(
                  0.0,
                  0.3,
                  curve: Curves.elasticOut,
                ),
              ),
            ),
          ) : null,
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
                        _isSettingPassword ? 'Create Passcode' : 'Confirm Passcode',
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
        _errorMessage = 'Incorrect passcode';
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
          child: isFilled ? ScaleTransition(
            scale: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _shakeController,
                curve: Interval(
                  0.0,
                  0.3,
                  curve: Curves.elasticOut,
                ),
              ),
            ),
          ) : null,
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

class _NumberButton extends StatefulWidget {
  final int number;
  final Function(int) onPressed;

  const _NumberButton({
    required this.number,
    required this.onPressed,
  });

  @override
  __NumberButtonState createState() => __NumberButtonState();
}

class __NumberButtonState extends State<_NumberButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 15),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 1.0, curve: Curves.easeOut),
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed(widget.number);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorAnimation.value,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2 * _controller.value),
                    blurRadius: _elevationAnimation.value,
                    spreadRadius: _elevationAnimation.value / 2,
                  ),
                ],
              ),
              child: Center(
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Text(
                    widget.number.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.3 * _controller.value),
                          blurRadius: 10 * _controller.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BackspaceButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BackspaceButton({
    required this.onPressed,
  });

  @override
  __BackspaceButtonState createState() => __BackspaceButtonState();
}

class __BackspaceButtonState extends State<_BackspaceButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..scale(_scaleAnimation.value)
              ..rotateZ(_rotationAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorAnimation.value,
              ),
              child: Center(
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: const Icon(
                    Icons.backspace,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}