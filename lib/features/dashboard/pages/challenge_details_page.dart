import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../groups/models/group_model.dart';
import '../services/ranking_service.dart';
import '../../groups/widgets/invite_share_widget.dart';
import 'profile_page.dart';

/// Página de detalhes do desafio (Imagem 3 da referência).
///
/// Apresenta o progresso do tempo, ranking e opções de convite.
class ChallengeDetailsPage extends StatelessWidget {
  final GroupModel group;
  final List<RankingItem> ranking;
  final String currentUserId;

  const ChallengeDetailsPage({
    super.key,
    required this.group,
    required this.ranking,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calcula progresso do tempo
    final totalDays = group.durationDays;
    final elapsedDays = group.daysElapsed;
    final progress = totalDays > 0 ? elapsedDays / totalDays : 0.0;

    final top5 = ranking.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== NOME DO GRUPO ======
            Text(
              group.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 24),

            // ====== BARRA DE PROGRESSO ======
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateInfo('Começa', group.startDate),
                _buildDateInfo('Termina', group.endDate),
              ],
            ),

            const SizedBox(height: 32),

            // ====== CÓDIGO DE CONVITE ======
            InviteShareWidget(
              inviteCode: group.inviteCode,
              groupName: group.name,
              // No layout do steady o "CONVIDAR" é um botão vermelho grande
              isDetailed: true,
            ),

            const SizedBox(height: 40),

            // ====== CLASSICAÇÕES ======
            Text(
              'Classificações',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            if (top5.isEmpty)
              const Center(child: Text('Nenhum dado de ranking disponível.'))
            else
              ...top5.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildRankingRow(context, item, index + 1);
              }),

            const SizedBox(height: 16),

            // Botão "Todas as classificações"
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // TODO: Ir para aba de classificação
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[50], // Cinza bem clarinho
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Todas as classificações',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    final dateStr = DateFormat("MMMM d, yyyy", "pt_BR").format(date);
    return Column(
      crossAxisAlignment: label == 'Começa'
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 13, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildRankingRow(
    BuildContext context,
    RankingItem item,
    int position,
  ) {
    final theme = Theme.of(context);
    final isMe = item.id == currentUserId;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              userId: item.id,
              userName: item.name,
              photoUrl: item.photoUrl,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isMe
                  ? theme.colorScheme.primary
                  : Colors.grey[200],
              child: Text(
                isMe ? 'AL' : item.name[0].toUpperCase(),
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Nome e Pontos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.totalCheckins} dias ativo',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),

            // Posição
            Text(
              '$positionº',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
