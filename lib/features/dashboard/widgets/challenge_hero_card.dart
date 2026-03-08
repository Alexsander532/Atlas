import 'package:flutter/material.dart';
import '../../groups/models/group_model.dart';

/// Card principal de destaque do desafio no Dashboard.
///
/// Exibe a imagem de capa do grupo com um overlay contendo
/// informações rápidas de ranking e tempo restante.
class ChallengeHeroCard extends StatelessWidget {
  final GroupModel group;
  final String? leaderName;
  final String? leaderImageUrl;
  final int leaderScore;
  final int userScore;
  final VoidCallback? onTap;

  const ChallengeHeroCard({
    super.key,
    required this.group,
    this.leaderName,
    this.leaderImageUrl,
    this.leaderScore = 0,
    this.userScore = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ====== IMAGEM DE CAPA ======
              _buildCoverImage(),

              // ====== OVERLAY GRADIENTE ======
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),

              // ====== TÍTULO DO GRUPO (OPCIONAL NO OVERLAY SE NÃO ESTIVER NO APPBAR) ======
              Positioned(
                top: 20,
                left: 20,
                child: Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // ====== CARD DE ESTATÍSTICAS SOBREPOSTO ======
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 90,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Líder
                      _buildStatColumn(
                        context,
                        label: 'Líder',
                        value: '$leaderScore',
                        image: leaderImageUrl != null
                            ? CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(leaderImageUrl!),
                              )
                            : CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.amber,
                                child: Text(
                                  (leaderName?.isNotEmpty == true
                                          ? leaderName![0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),

                      // Divisória vertical
                      Container(width: 1, height: 40, color: Colors.grey[200]),

                      // Você
                      _buildStatColumn(
                        context,
                        label: 'Você',
                        value: '$userScore',
                        image: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Text(
                            'VC',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Divisória vertical
                      Container(width: 1, height: 40, color: Colors.grey[200]),

                      // Dias restantes
                      _buildStatColumn(
                        context,
                        label: 'dias restantes',
                        value: '${group.daysRemaining}',
                        image: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: Colors.black87,
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
      ),
    );
  }

  Widget _buildCoverImage() {
    if (group.imageUrl != null && group.imageUrl!.isNotEmpty) {
      return Image.network(
        group.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white24),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Widget image,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        image,
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
