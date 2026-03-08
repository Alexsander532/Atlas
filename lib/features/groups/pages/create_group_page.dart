/// ============================================================================
/// CREATE GROUP PAGE - Criar Novo Desafio
/// ============================================================================
///
/// Formulário para criar um novo desafio de leitura.
/// Campos: Nome, Descrição, Duração em dias.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../cubit/group_cubit.dart';
import '../cubit/group_state.dart';
import '../repositories/group_repository.dart';
import '../widgets/invite_share_widget.dart';

/// Página para criar um novo desafio.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _durationDays = 21;
  bool _isCreating = false;

  // Opções pré-definidas de duração
  static const List<int> _durationOptions = [7, 14, 21, 30, 60, 90];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          if (state is GroupCreated) {
            setState(() => _isCreating = false);
            // Define o novo grupo como ativo através do AuthCubit
            context.read<AuthCubit>().updateActiveGroup(state.group.id);
            // Mostra o código de convite
            _showInviteCodeDialog(
              context,
              state.group.inviteCode,
              state.group.name,
            );
          }
          if (state is GroupError) {
            setState(() => _isCreating = false);
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
            appBar: AppBar(title: const Text('Criar Desafio')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'Novo Desafio de Leitura 📖',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie um desafio e convide seus amigos para participar!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Desafio *',
                        hintText: 'Ex: Restauração 30 dias',
                        prefixIcon: const Icon(Icons.emoji_events),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'O nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descrição (opcional)',
                        hintText: 'Descreva o objetivo do desafio...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Duração
                    Text(
                      'Duração do Desafio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Opções de duração
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _durationOptions.map((days) {
                        final isSelected = _durationDays == days;
                        return ChoiceChip(
                          label: Text('$days dias'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _durationDays = days);
                            }
                          },
                          selectedColor: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Info card sobre duração
                    Card(
                      elevation: 0,
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'O desafio terá duração de $_durationDays dias. Cada check-in diário vale 1 ponto.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botão criar
                    FilledButton.icon(
                      onPressed: _isCreating
                          ? null
                          : () => _createGroup(context, authState),
                      icon: _isCreating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreating ? 'Criando...' : 'Criar Desafio'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _createGroup(BuildContext context, AuthAuthenticated authState) {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    context.read<GroupCubit>().createGroup(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      durationDays: _durationDays,
    );
  }

  void _showInviteCodeDialog(
    BuildContext context,
    String inviteCode,
    String groupName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desafio Criado! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Compartilhe o código abaixo para convidar seus amigos:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            InviteShareWidget(inviteCode: inviteCode, groupName: groupName),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            child: const Text('Ir para o Desafio'),
          ),
        ],
      ),
    );
  }
}
