import 'package:flutter/material.dart';
import '../../data/citas_repository.dart';

class CalificarModal extends StatefulWidget {
  final Map<String, dynamic> cita;
  final VoidCallback onCalificado;

  const CalificarModal({super.key, required this.cita, required this.onCalificado});

  @override
  State<CalificarModal> createState() => _CalificarModalState();
}

class _CalificarModalState extends State<CalificarModal> {
  final _repo = CitasRepository();
  final _comentarioCtrl = TextEditingController();
  int _puntuacion = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _submitting = true);
    try {
      await _repo.calificarCita(
        citaId: widget.cita['id'],
        cuidadorId: widget.cita['cuidador_id'],
        puntuacion: _puntuacion,
        comentario: _comentarioCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por calificar el servicio!')),
        );
        widget.onCalificado();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al calificar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Califica a tu Cuidador', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _puntuacion ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () => setState(() => _puntuacion = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos tu experiencia...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _enviar,
            child: _submitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Guardar Calificación'),
          ),
        ],
      ),
    );
  }
}