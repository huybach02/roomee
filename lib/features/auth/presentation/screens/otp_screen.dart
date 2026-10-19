import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_notification.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/utils/constanst.dart';

class OtpScreen extends StatefulWidget {
  final String? destination;
  final String? purpose;
  final Future<void> Function(String otp)? onVerify;
  final Future<void> Function()? onResend;

  const OtpScreen({
    super.key,
    this.destination,
    this.purpose,
    this.onVerify,
    this.onResend,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _initialCountdownSeconds = 60;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _countdownTimer;
  int _secondsRemaining = _initialCountdownSeconds;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (index) {
      final node = FocusNode();
      node.addListener(() {
        if (mounted) setState(() {});
      });
      node.onKeyEvent = (focusNode, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[index].text.isEmpty && index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();
            _clearError();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
      return node;
    });

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = _initialCountdownSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Hỗ trợ dán (paste) chuỗi mã OTP
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        int pasteIdx = 0;
        final startIdx = digits.length == _otpLength ? 0 : index;
        for (
          int i = startIdx;
          i < _otpLength && pasteIdx < digits.length;
          i++
        ) {
          _controllers[i].text = digits[pasteIdx];
          pasteIdx++;
        }
        final nextEmpty = _controllers.indexWhere((c) => c.text.isEmpty);
        if (nextEmpty != -1) {
          _focusNodes[nextEmpty].requestFocus();
        } else {
          _focusNodes[_otpLength - 1].requestFocus();
        }
        _clearError();
        return;
      }
    }

    if (value.isNotEmpty) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = TextSelection.collapsed(
        offset: _controllers[index].text.length,
      );
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }
    _clearError();
  }

  AuthBloc? _getAuthBloc() {
    try {
      return context.read<AuthBloc>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      setState(() {
        _errorMessage = t('validateErrors.otpInvalid');
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (widget.onVerify != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.onVerify!(otp);
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      final email = widget.destination ?? '';
      final authBloc = _getAuthBloc();
      if (authBloc != null) {
        authBloc.add(AuthVerifyOtpEvent(email: email, otp: otp));
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _errorMessage = null;
    });

    if (widget.onResend != null) {
      setState(() {
        _isResending = true;
      });
      try {
        await widget.onResend!();
        if (mounted) {
          AppNotification.showSuccess(context, t('otpSentSuccess'));
          _startCountdown();
        }
      } catch (e) {
        if (mounted) {
          AppNotification.showError(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isResending = false;
          });
        }
      }
    } else {
      final email = widget.destination ?? '';
      final authBloc = _getAuthBloc();
      if (authBloc != null) {
        authBloc.add(AuthResendOtpEvent(email));
      }
    }
  }

  Widget _buildOtpBox(int index) {
    final bool isFocused = _focusNodes[index].hasFocus;
    final bool hasValue = _controllers[index].text.isNotEmpty;
    final bool hasError = _errorMessage != null;

    final Color borderColor;
    if (hasError) {
      borderColor = DefaultColors.danger;
    } else if (isFocused || hasValue) {
      borderColor = DefaultColors.primary;
    } else {
      borderColor = DefaultColors.border;
    }

    return Container(
      width: 46,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DefaultColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isFocused ? 2.0 : 1.2),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: FontSizes.medium,
          fontWeight: FontWeight.bold,
          color: DefaultColors.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (val) => _onDigitChanged(index, val),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required bool isLoading,
    required bool isResending,
  }) {
    final String subtitle =
        (widget.destination != null && widget.destination!.isNotEmpty)
        ? t('otpSubtitle', {'target': widget.destination!})
        : t('otpDefaultSubtitle');

    return Scaffold(
      backgroundColor: DefaultColors.white,
      appBar: AppBar(
        backgroundColor: DefaultColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DefaultColors.primary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Image.asset(
                  logoAssetPath,
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('otpTitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FontSizes.medium,
                  fontWeight: FontWeight.bold,
                  color: DefaultColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: FontSizes.standard,
                  color: DefaultColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Dãy 6 ô nhập mã PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _otpLength,
                  (index) => _buildOtpBox(index),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: FontSizes.small,
                    color: DefaultColors.danger,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Gửi lại mã & Bộ đếm ngược
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t('didNotReceiveCode'),
                    style: const TextStyle(
                      fontSize: FontSizes.standard,
                      color: DefaultColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_secondsRemaining > 0)
                    Text(
                      t('resendCodeIn', {'seconds': '$_secondsRemaining'}),
                      style: const TextStyle(
                        fontSize: FontSizes.standard,
                        fontWeight: FontWeight.w600,
                        color: DefaultColors.textHint,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: isResending ? null : _resendOtp,
                      child: Text(
                        t('resendCode'),
                        style: const TextStyle(
                          fontSize: FontSizes.standard,
                          fontWeight: FontWeight.bold,
                          color: DefaultColors.primary,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 36),

              // Nút Xác nhận
              AppButton(
                text: t('verify'),
                onPressed: _submitOtp,
                isLoading: isLoading,
                type: AppButtonType.primary,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = _getAuthBloc();
    if (authBloc != null) {
      return BlocConsumer<AuthBloc, AuthState>(
        bloc: authBloc,
        listener: (context, state) {
          if (state is AuthOtpVerified) {
            AppNotification.showSuccess(context, t('otpVerifiedSuccess'));
            context.go(AppRoutes.login);
          } else if (state is AuthOtpSent) {
            AppNotification.showSuccess(context, t('otpSentSuccess'));
            _startCountdown();
          } else if (state is AuthFailure) {
            setState(() {
              _errorMessage = state.message;
            });
          }
        },
        builder: (context, state) {
          final isBlocLoading = state is AuthLoading;
          return _buildScaffold(
            context,
            isLoading: _isLoading || isBlocLoading,
            isResending: _isResending || (isBlocLoading && _secondsRemaining == 0),
          );
        },
      );
    }

    return _buildScaffold(
      context,
      isLoading: _isLoading,
      isResending: _isResending,
    );
  }
}
