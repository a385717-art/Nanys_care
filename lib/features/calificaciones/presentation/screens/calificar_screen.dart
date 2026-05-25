import 'package:flutter/material.dart';
import '../../data/calificaciones_repository.dart';

class CalificarScreen extends StatefulWidget {
  final String citaId;
  final String cuidadorId;
  final String nombreCuidador;

  const CalificarScreen({
    super.key,
    required this.citaId,
    required this.cuidadorId,
    required this.nombreCuidador,
  });

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  final _repo = CalificacionesRepository();
  final _comentario = TextEditingController();
  int _estrellas = 5;
  bool _loading = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviarResena() async {
    setState(() => _loading = true);
    try {
      await _repo.registrarCalificacion(
        citaId: widget.citaId,
        cuidadorId: widget.cuidadorId,
        estrellas: _estrellas,
        comentario: _comentario.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calificación enviada. ¡Muchas gracias!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calificar Servicio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Evalúa tu experiencia con \${widget.nombreCuidador}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => IconButton(
                      icon: Icon(i < _estrellas ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                      onPressed: () => setState(() => _estrellas = i + 1),
                    )),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _comentario,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Comentario / Reseña adicional', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _enviarResena, child: const Text('Enviar Calificación')),
                  )
                ],
              ),
            ),
    );
  }
}
