import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../models/checkin_model.dart';
import '../services/checkin_service.dart';
import 'checkin_detail_page.dart';

class CheckinHistoryPage extends StatefulWidget {
  const CheckinHistoryPage({super.key});

  @override
  State<CheckinHistoryPage> createState() => _CheckinHistoryPageState();
}

class _CheckinHistoryPageState extends State<CheckinHistoryPage> {
  final CheckinService _checkinService = CheckinService();
  List<CheckinModel> _checkins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckins();
  }

  Future<void> _loadCheckins() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      try {
        final checkins = await _checkinService.getUserCheckins(
          authState.user.id,
          groupId: null, // Busca global
          limit: 100, // Limite razoavel
        );
        if (mounted) {
          setState(() {
            _checkins = checkins;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar check-ins: $e')),
          );
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF7F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Histórico de check-ins',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checkins.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _checkins.length,
              itemBuilder: (context, index) {
                final checkin = _checkins[index];
                return _buildCheckinCard(context, checkin);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum check-in encontrado.',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinCard(BuildContext context, CheckinModel checkin) {
    final theme = Theme.of(context);
    final dateFormatted = _formatDate(checkin.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckinDetailPage(checkin: checkin),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem da esquerda
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: checkin.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(checkin.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: checkin.imageUrl == null
                    ? Icon(Icons.menu_book, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 16),
              // Textos da direita
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkin.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatted,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (checkin.description != null &&
                        checkin.description!.isNotEmpty)
                      Text(
                        checkin.description!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
