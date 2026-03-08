import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/checkin_model.dart';
import '../../../core/widgets/image_viewer_page.dart';
import '../pages/profile_page.dart';

/// Item de check-in na timeline do grupo.
///
/// Suporta dois layouts:
/// - Simples: Ícone colorido + Título + Nome (para posts sem foto)
/// - Detalhado: Foto grande + Título + Nome + Ações (para posts com foto)
class CheckinTimelineItem extends StatelessWidget {
  final CheckinModel checkin;
  final bool isCurrentUser;

  const CheckinTimelineItem({
    super.key,
    required this.checkin,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    if (checkin.imageUrl != null && checkin.imageUrl!.isNotEmpty) {
      return _buildDetailedLayout(context);
    }
    return _buildSimpleLayout(context);
  }

  /// Layout simples (Imagem 1 da referência)
  Widget _buildSimpleLayout(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat(
      'h:mm a',
    ).format(checkin.createdAt).toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ====== ÍCONE CIRCULAR ======
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),

          // ====== CONTEÚDO ======
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkin.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          userId: checkin.userId,
                          userName: checkin.userName,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      if (isCurrentUser)
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'AL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        checkin.userName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Layout detalhado com foto (Imagem 4 e 5 da referência)
  Widget _buildDetailedLayout(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat(
      'h:mm a',
    ).format(checkin.createdAt).toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====== IMAGEM ======
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerPage(imageUrl: checkin.imageUrl!),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.network(
                checkin.imageUrl!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====== USER INFO ======
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          userId: checkin.userId,
                          userName: checkin.userName,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        child: Text(checkin.userName[0].toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkin.userName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${DateFormat('d de MMMM', 'pt_BR').format(checkin.createdAt)} às $timeStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ====== TÍTULO ======
                Text(
                  checkin.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                // ====== AÇÕES / STATUS (MOCK) ======
                Row(
                  children: [
                    _buildChip(Icons.access_time, '1 hr 30 min'),
                    const SizedBox(width: 8),
                    _buildChip(Icons.sentiment_satisfied_alt, ''),
                  ],
                ),

                const SizedBox(height: 16),

                // ====== CAMPO DE COMENTÁRIO (MOCK) ======
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'AL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          'Aa',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Enviar',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
