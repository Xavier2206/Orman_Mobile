import '../../../app/theme/orman_semantic_colors.dart';

OrmanSemanticRole contractStatusRole(String status) =>
    switch (status.toUpperCase()) {
      'VIGENTE' => OrmanSemanticRole.success,
      'PROGRAMADO' => OrmanSemanticRole.info,
      'FINALIZADO' => OrmanSemanticRole.neutral,
      'RESCINDIDO' => OrmanSemanticRole.warning,
      _ => OrmanSemanticRole.neutral,
    };

OrmanSemanticRole installmentStatusRole(String status) =>
    switch (status.toUpperCase()) {
      'PENDIENTE' => OrmanSemanticRole.warning,
      'PARCIAL' => OrmanSemanticRole.info,
      'PAGADA' => OrmanSemanticRole.success,
      'ANULADA' => OrmanSemanticRole.danger,
      _ => OrmanSemanticRole.neutral,
    };
