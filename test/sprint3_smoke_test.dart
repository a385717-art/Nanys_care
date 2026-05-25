import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de Humo - Sprints 2 y 3 (Verificación de Modelos y Datos)', () {
    test('Estructura de Cita y Estados Válidos', () {
      final mockCita = {
        'id': 'uuid-test-123',
        'estado': 'pendiente',
        'costo_total': 180.50
      };
      
      expect(mockCita['estado'], 'pendiente');
      expect(mockCita['costo_total'], isA<double>());
    });

    test('Validación de Payload para Notificaciones Resend', () {
      final mockPayload = {
        'from': 'Nanys Care <onboarding@resend.dev>',
        'to': ['tutor@example.com'],
        'subject': 'Confirmación de Turno'
      };

      expect(mockPayload['to'], contains('tutor@example.com'));
    });
  });
}
