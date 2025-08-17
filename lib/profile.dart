import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _resetPassword(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('appPassword');
      await prefs.setBool('isFirstLaunch', true);
      
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PasswordSetupScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ошибка сброса пароля',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white, width: 2),
            ),
            elevation: 0,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'СБРОС ПАРОЛЯ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Вы уверены, что хотите сбросить пароль?\nВам нужно будет установить новый пароль.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            ),
                            child: const Text(
                              'ОТМЕНА',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetPassword(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            ),
                            child: const Text(
                              'СБРОСИТЬ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_reset, size: 28),
              SizedBox(width: 16),
              Text(
                'СБРОСИТЬ ПАРОЛЬ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}