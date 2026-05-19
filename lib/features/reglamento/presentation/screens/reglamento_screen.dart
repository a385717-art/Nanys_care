// lib/features/reglamento/presentation/screens/reglamento_screen.dart
// US13 — Seccion de reglamento del cuidador

import 'package:flutter/material.dart';

class ReglamentoScreen extends StatelessWidget {
  const ReglamentoScreen({super.key});

  static const _sections = [
    _Sec(icon: Icons.verified_user_outlined, title: 'Conducta profesional', items: [
      'Llegar puntual a cada servicio acordado.',
      'Mantener una actitud respetuosa con el nino y su familia en todo momento.',
      'No usar el telefono celular de forma personal durante el servicio.',
      'Informar de inmediato cualquier accidente o situacion inusual al tutor.',
    ]),
    _Sec(icon: Icons.child_care, title: 'Cuidado del menor', items: [
      'Nunca dejar al nino solo sin supervision adecuada.',
      'Respetar las indicaciones de alimentacion y rutinas del tutor.',
      'No administrar medicamentos sin autorizacion expresa del tutor.',
      'Reportar cualquier senal de malestar fisico o emocional del menor.',
    ]),
    _Sec(icon: Icons.lock_outline, title: 'Privacidad y confidencialidad', items: [
      'No compartir informacion personal de la familia en redes sociales.',
      'No tomar fotografias del menor sin el consentimiento del tutor.',
      'Mantener confidencialidad sobre el domicilio y rutina de la familia.',
    ]),
    _Sec(icon: Icons.handshake_outlined, title: 'Acuerdos y pagos', items: [
      'Cumplir el horario y duracion del servicio acordado en la plataforma.',
      'En caso de cancelacion, notificar con al menos 24 horas de anticipacion.',
      'Las tarifas son las publicadas en el perfil; no cobrar montos diferentes.',
    ]),
    _Sec(icon: Icons.report_outlined, title: 'Consecuencias por incumplimiento', items: [
      'El incumplimiento puede resultar en la suspension temporal de la cuenta.',
      'Faltas graves resultaran en eliminacion permanente de la plataforma.',
      'Los tutores podran reportar conductas inapropiadas a traves de la app.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reglamento de la plataforma')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.gavel, color: Colors.white, size: 32),
              SizedBox(height: 12),
              Text('Reglamento de conducta', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Al usar Nanys Care, todos los cuidadores aceptan y se comprometen a cumplir las siguientes normas.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 20),
          ..._sections.map((s) => _SectionCard(section: s)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF0EDFF), borderRadius: BorderRadius.circular(12)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Color(0xFF6B4EFF), size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Este reglamento puede actualizarse. Te notificaremos ante cualquier cambio.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B4EFF)))),
            ]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Sec {
  const _Sec({required this.icon, required this.title, required this.items});
  final IconData icon; final String title; final List<String> items;
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.section});
  final _Sec section;
  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: scheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.section.icon, color: scheme.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.section.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
            ]),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...widget.section.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                ]))),
            ],
          ]),
        ),
      ),
    );
  }
}