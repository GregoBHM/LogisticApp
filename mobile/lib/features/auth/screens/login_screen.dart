import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import '../../../core/network/error_handler.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  bool get _formValido {
    final emailOk = _emailCtrl.text.trim().contains('@') && _emailCtrl.text.trim().contains('.');
    final passOk = _passCtrl.text.length >= 6;
    if (_isRegisterMode) return emailOk && passOk && _nombreCtrl.text.trim().length >= 2;
    return emailOk && passOk;
  }

  Future<void> _submit() async {
    if (!_formValido) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isRegisterMode) {
        await repo.signUp(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          nombre: _nombreCtrl.text,
        );
      } else {
        await repo.signIn(
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
      }
    } catch (e) {
      setState(() => _error = ErrorHandler.parse(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/icon.png', width: 64, height: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text('GyL Logistic', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(
                    _isRegisterMode ? 'Crea tu cuenta' : 'Gestión de inventario y ventas',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 48),
                  if (_isRegisterMode) ...[
                    _buildField('Nombre completo', 'Tu nombre', _nombreCtrl),
                    const SizedBox(height: 12),
                  ],
                  _buildField('Correo electrónico', 'correo@ejemplo.com', _emailCtrl,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildPasswordField(),
                  if (!_isRegisterMode) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          if (_emailCtrl.text.trim().contains('@')) {
                            await ref.read(authRepositoryProvider).resetPassword(_emailCtrl.text);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Revisa tu correo para restablecer la contraseña.')),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.negativeSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.negative.withValues(alpha: 0.2)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.negative, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: Listenable.merge([_emailCtrl, _passCtrl, _nombreCtrl]),
                    builder: (context, child) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_formValido && !_isLoading) ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cream,
                          foregroundColor: AppColors.background,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor: AppColors.textMuted,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                            : Text(_isRegisterMode ? 'Crear cuenta' : 'Iniciar sesión', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegisterMode ? '¿Ya tienes cuenta? ' : '¿No tienes cuenta? ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => setState(() { _isRegisterMode = !_isRegisterMode; _error = null; }),
                        child: Text(
                          _isRegisterMode ? 'Inicia sesión' : 'Regístrate',
                          style: const TextStyle(color: AppColors.cream, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(hintText: hint, label: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Mínimo 6 caracteres',
        label: const Text('Contraseña', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 18),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
