import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/auth_service_provider.dart';
import '../domain/auth_failure.dart';
import 'auth_error_notice.dart';
import 'auth_form_scaffold.dart';

class VerifyPendingScreen extends ConsumerStatefulWidget {
  const VerifyPendingScreen({
    required this.email,
    this.initialStatusText,
    super.key,
  });

  final String email;
  final String? initialStatusText;

  @override
  ConsumerState<VerifyPendingScreen> createState() =>
      _VerifyPendingScreenState();
}

class _VerifyPendingScreenState extends ConsumerState<VerifyPendingScreen> {
  bool _isSubmitting = false;
  late String? _statusText = widget.initialStatusText;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      title: 'Verify your email',
      subtitle:
          'We sent a verification email to ${widget.email.isEmpty ? 'your address' : widget.email}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Open the link in your email before signing in. If you did not receive it, resend verification.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_statusText != null) ...[
            const SizedBox(height: 12),
            Text(
              _statusText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          if (_errorText != null)
            AuthErrorNotice(
              message: _errorText!,
              onRetry: widget.email.isEmpty ? null : _resendVerificationEmail,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isSubmitting || widget.email.isEmpty
                ? null
                : _resendVerificationEmail,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.mark_email_read_outlined),
            label: const Text('Resend verification'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.goNamed(loginRouteName),
            icon: const Icon(Icons.login),
            label: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusText = null;
      _errorText = null;
    });

    try {
      await ref
          .read(authServiceProvider)
          .resendVerificationEmail(email: widget.email);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = 'Verification email resent.';
      });
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code == AuthFailureCode.rateLimited) {
        setState(() {
          _statusText =
              'A verification email was already sent recently. Please wait a moment before requesting another one.';
        });
        return;
      }
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Unable to resend verification email.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
