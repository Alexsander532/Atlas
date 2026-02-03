/// ============================================================================
/// DATE UTILS - Utilitários para Manipulação de Datas
/// ============================================================================
///
/// Funções auxiliares para trabalhar com datas no contexto de check-ins.
///
/// Formato padrão: yyyy-MM-dd (ex: 2024-01-15)
/// Este formato garante ordenação correta e é compatível com Firestore.
///
/// ============================================================================

/// Classe utilitária para manipulação de datas.
///
/// Todas as funções são estáticas para fácil acesso.
class AppDateUtils {
  // Construtor privado para evitar instanciação
  AppDateUtils._();

  // ============================================================
  // CONSTANTES
  // ============================================================

  /// Nomes dos dias da semana em português
  static const List<String> diasSemana = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  /// Nomes dos meses em português
  static const List<String> meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  // ============================================================
  // FORMATAÇÃO
  // ============================================================

  /// Formata data para o padrão de check-in (yyyy-MM-dd).
  ///
  /// Este formato é usado como ID de documentos no Firestore
  /// para garantir unicidade por dia.
  ///
  /// Exemplo:
  /// ```dart
  /// final dateKey = AppDateUtils.formatToCheckinKey(DateTime.now());
  /// // Retorna: "2024-01-15"
  /// ```
  static String formatToCheckinKey(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Retorna a chave de check-in para hoje.
  ///
  /// Útil para verificar se o usuário já fez check-in hoje.
  static String get todayKey => formatToCheckinKey(DateTime.now());

  /// Formata data para exibição amigável.
  ///
  /// Exemplo: "15 de Janeiro de 2024"
  static String formatToDisplay(DateTime date) {
    final day = date.day;
    final month = meses[date.month - 1];
    final year = date.year;
    return '$day de $month de $year';
  }

  /// Formata data curta para exibição.
  ///
  /// Exemplo: "15/01/2024"
  static String formatToShortDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Retorna uma descrição relativa da data.
  ///
  /// Exemplos:
  /// - "Hoje"
  /// - "Ontem"
  /// - "Há 3 dias"
  /// - "15/01/2024" (para datas mais antigas)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference < 7) {
      return 'Há $difference dias';
    } else {
      return formatToShortDisplay(date);
    }
  }

  // ============================================================
  // PARSING
  // ============================================================

  /// Converte string no formato yyyy-MM-dd para DateTime.
  ///
  /// Retorna null se o formato for inválido.
  static DateTime? parseCheckinKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // COMPARAÇÕES
  // ============================================================

  /// Verifica se duas datas são o mesmo dia.
  ///
  /// Ignora hora, minuto e segundo.
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Verifica se a data é hoje.
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Verifica se a data é ontem.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  // ============================================================
  // CÁLCULOS
  // ============================================================

  /// Calcula o número de dias entre duas datas.
  ///
  /// Ignora hora, minuto e segundo.
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Retorna o início do dia (00:00:00).
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Retorna o fim do dia (23:59:59.999).
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Retorna uma lista de datas dos últimos N dias.
  ///
  /// Útil para gerar histórico de check-ins.
  static List<DateTime> getLastNDays(int n) {
    final now = DateTime.now();
    return List.generate(n, (index) => now.subtract(Duration(days: index)));
  }
}
