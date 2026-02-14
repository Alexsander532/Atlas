/// ============================================================================
/// PHOTO CALENDAR - Calendário Visual com Fotos
/// ============================================================================
///
/// Widget de calendário mensal onde cada célula mostra a foto do check-in
/// daquele dia como thumbnail.
///
/// ============================================================================

import 'package:flutter/material.dart';

import '../../features/dashboard/models/checkin_model.dart';

/// Callback quando um dia com check-in é clicado.
typedef OnDayTap = void Function(CheckinModel checkin);

/// Widget de calendário com fotos.
class PhotoCalendar extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, CheckinModel> checkinsByDate;
  final OnDayTap? onDayTap;

  const PhotoCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.checkinsByDate,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Primeiro dia do mês
    final firstDayOfMonth = DateTime(year, month, 1);
    // Último dia do mês
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    // Dia da semana do primeiro dia (0 = Dom, 6 = Sáb)
    final firstWeekday = firstDayOfMonth.weekday % 7;
    // Total de dias no mês
    final daysInMonth = lastDayOfMonth.day;

    // Labels dos dias da semana
    const weekDays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return Column(
      children: [
        // Header com dias da semana
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map(
                  (day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Grid de dias
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            // Células vazias antes do primeiro dia
            if (index < firstWeekday) {
              return const SizedBox.shrink();
            }

            final day = index - firstWeekday + 1;
            final dateStr =
                '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final checkin = checkinsByDate[dateStr];
            final isToday = _isToday(year, month, day);

            return _buildDayCell(
              context: context,
              day: day,
              checkin: checkin,
              isToday: isToday,
              colorScheme: colorScheme,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required int day,
    required CheckinModel? checkin,
    required bool isToday,
    required ColorScheme colorScheme,
  }) {
    final hasPhoto = checkin?.imageUrl != null && checkin!.imageUrl!.isNotEmpty;
    final hasCheckin = checkin != null;

    return GestureDetector(
      onTap: checkin != null ? () => onDayTap?.call(checkin) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outline.withOpacity(0.3)),
          color: hasCheckin && !hasPhoto
              ? colorScheme.primaryContainer.withOpacity(0.5)
              : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto de fundo (se houver)
            if (hasPhoto)
              Image.network(
                checkin.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: colorScheme.primaryContainer,
                  child: Icon(Icons.book, color: colorScheme.primary, size: 20),
                ),
              ),

            // Overlay com número do dia
            Positioned(
              top: 2,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: hasPhoto ? Colors.black54 : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasPhoto ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            // Indicador de check-in sem foto
            if (hasCheckin && !hasPhoto)
              Center(
                child: Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(int year, int month, int day) {
    final now = DateTime.now();
    return now.year == year && now.month == month && now.day == day;
  }
}
