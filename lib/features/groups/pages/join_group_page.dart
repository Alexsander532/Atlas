/// ============================================================================
/// JOIN GROUP PAGE - Entrar em Desafio com Código
/// ============================================================================
///
/// Permite ao usuário colar/digitar um código de convite
/// e visualizar os detalhes do grupo antes de confirmar.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../cubit/group_cubit.dart';
import '../cubit/group_state.dart';
import '../repositories/group_repository.dart';

/// Página para entrar em um desafio usando código.
class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocProvider(
      create: (_) => GroupCubit(
        groupRepository: GroupRepository(),
        userId: authState.user.id,
      ),
      child: BlocConsumer<GroupCubit, GroupState>(
        listener: (context, state) {
          if (state is GroupJoined) {
            setState(() => _isJoining = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Entrou no desafio "${state.group.name}"! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
            // Volta e depois navega para dashboard
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
          if (state is GroupError) {
            setState(() => _isJoining = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Entrar em Desafio')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.link,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Entrar com Código',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite o código de convite que você recebeu para entrar em um desafio.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo do código
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Código de Convite',
                      hintText: 'Ex: ATLAS-XK7M',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: theme.textTheme.titleMedium?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Botão entrar
                  FilledButton.icon(
                    onPressed: _isJoining
                        ? null
                        : () => _joinGroup(context, authState),
                    icon: _isJoining
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _isJoining ? 'Entrando...' : 'Entrar no Desafio',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dica
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'O código de convite é fornecido pelo criador do desafio. Ele tem o formato ATLAS-XXXX.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _joinGroup(BuildContext context, AuthAuthenticated authState) {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o código de convite'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);
    context.read<GroupCubit>().joinGroup(code);
  }
}
