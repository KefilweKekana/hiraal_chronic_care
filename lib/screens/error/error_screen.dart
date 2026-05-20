import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/biometric_service.dart';

class ErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const ErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Error'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.cloud_off, color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 20),
            const Text("We couldn't send your data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('There was a problem connecting to the server.\nYour data is safe and saved on this phone.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.inputBackground, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('What happened?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('No internet connection or the server is not\nresponding. Please try again.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('What you can do', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            _ActionItem(icon: Icons.wifi, title: 'Check your connection', subtitle: 'Make sure you have internet.'),
            _ActionItem(icon: Icons.refresh, title: 'Try again', subtitle: "We'll send your data now."),
            _ActionItem(icon: Icons.schedule, title: 'Send later', subtitle: "We'll try automatically when you're back online."),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: onRetry ?? () => Navigator.pop(context),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Now'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('Send Later'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified_user, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('Your data is safe. All unsent readings are saved on your phone.\nNothing is lost.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActionItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
        ],
      ),
    );
  }
}

class SessionExpiredScreen extends StatelessWidget {
  final VoidCallback onLogin;

  const SessionExpiredScreen({super.key, required this.onLogin});

  Future<void> _handleLogin(BuildContext context) async {
    final biometric = BiometricService.instance;
    final canCheck = await biometric.canCheckBiometrics;
    final isSupported = await biometric.isDeviceSupported;
    if (canCheck && isSupported) {
      final didAuth = await biometric.authenticate();
      if (didAuth) {
        onLogin();
        return;
      }
      // If biometric fails, show a snackbar and still allow manual login
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed. Please log in manually.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
    onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.lock_clock, color: AppColors.error, size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Session Expired', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('For your security, you have been\nlogged out.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your data is safe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                      Text('All unsent readings are saved on this\ndevice and will sync when you log in again.', style: TextStyle(fontSize: 12, color: AppColors.success)),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info, size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Why did this happen?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                      Text('Sessions expire after 30 minutes\nof inactivity to protect your account.', style: TextStyle(fontSize: 12, color: AppColors.warning)),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogin(context),
                  icon: const Icon(Icons.fingerprint, size: 20),
                  label: const Text('Log In Again'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogin(context),
                  icon: const Icon(Icons.home, size: 18),
                  label: const Text('Back to Welcome'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
