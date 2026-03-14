import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../fasting/presentation/fasting_controller.dart';

class ProtocolSelector extends ConsumerWidget {
  final String currentProtocol;

  const ProtocolSelector({
    super.key,
    required this.currentProtocol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Normalizar protocolo actual para asegurar coincidencia con la lista
    // Si viene "16:8", lo convertimos a "16/8"
    final normalizedProtocol = currentProtocol.replaceAll(':', '/');
    
    final List<String> options = ['12/12', '14/10', '16/8', '18/6', '20/4'];
    
    // Asegurar que el valor actual esté en la lista, si no, usar default
    final dropdownValue = options.contains(normalizedProtocol) ? normalizedProtocol : '16/8';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1E1E1E),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: dropdownValue,
            dropdownColor: const Color(0xFF2A2A2A),
            isDense: true, // Optimiza espacio para evitar desbordamientos
            icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white70),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                ref.read(fastingControllerProvider.notifier).setProtocol(newValue);
              }
            },
            items: options.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 13)), // Texto ligeramente más pequeño
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
