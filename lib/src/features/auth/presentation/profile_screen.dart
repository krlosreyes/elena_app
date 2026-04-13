import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; 
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go('/login');
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("EXPEDIENTE METABÓLICO", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        automaticallyImplyLeading: false, 
      ),
      body: authState.when(
        data: (user) => user == null 
          ? const Center(child: Text("Sin conexión al nodo")) 
          : _buildFullProfile(context, ref, user, isDark),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Fallo de lectura: $e")),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildFullProfile(BuildContext context, WidgetRef ref, UserModel user, bool isDark) {
    final timeFormat = DateFormat('hh:mm a');
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _sectionHeader("HARDWARE BIOLÓGICO", isDark),
        _dataTile("ID Usuario", user.id.substring(0, 12) + "...", isDark),
        _dataTile("Nombre Completo", user.name, isDark),
        _dataTile("Edad Cronológica", "${user.age} años", isDark),
        _dataTile("Género Asignado", user.gender == 'M' ? "Masculino" : "Femenino", isDark),

        const SizedBox(height: 24),
        _sectionHeader("ANTROPOMETRÍA Y TALLAS", isDark),
        _dataTile("Estatura", "${user.height.toInt()} cm", isDark),
        _dataTile("Peso Actual", "${user.weight.toInt()} kg", isDark),
        _dataTile("Cintura", "${user.waistCircumference?.toInt() ?? 0} cm", isDark),
        _dataTile("Cuello", "${user.neckCircumference?.toInt() ?? 0} cm", isDark),
        _dataTile("Talla Camisa", user.shirtSize, isDark),
        _dataTile("Talla Pantalón", "${user.pantSize}", isDark),

        const SizedBox(height: 24),
        _sectionHeader("RITMOS CIRCADIANOS", isDark),
        _dataTile("Hora Despertar", timeFormat.format(user.profile.wakeUpTime ?? now), isDark),
        _dataTile("Hora Descanso", timeFormat.format(user.profile.sleepTime ?? now), isDark),
        _dataTile("Meta Primera Comida", timeFormat.format(user.profile.firstMealGoal ?? now), isDark),
        _dataTile("Meta Última Comida", timeFormat.format(user.profile.lastMealGoal ?? now), isDark),

        const SizedBox(height: 24),
        _sectionHeader("PROTOCOLO METABÓLICO", isDark),
        _dataTile("Comidas al Día", "${user.mealsPerDay ?? 3}", isDark),
        _dataTile("Protocolo de Ayuno", user.fastingProtocol ?? "Ninguno", isDark),
        _dataTile("Diagnósticos", (user.pathologies?.isNotEmpty ?? false) ? user.pathologies!.join(", ") : "Ninguno", isDark),

        const SizedBox(height: 40),
        
        ElevatedButton.icon(
          onPressed: () => _handleLogout(context, ref),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text("CERRAR SESIÓN DE HARDWARE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),

        const SizedBox(height: 12),

        TextButton.icon(
          onPressed: () => _showConfirm(context, ref),
          icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
          label: const Text("ELIMINAR TODOS LOS REGISTROS", 
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location == '/profile') currentIndex = 2;

    return BottomNavigationBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0: context.go('/dashboard'); break;
          case 2: context.go('/profile'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: "Análisis"),
        BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: "Perfil"),
      ],
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, 
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : const Color(0xFF64748B), letterSpacing: 1.5)),
    );
  }

  Widget _dataTile(String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, 
              textAlign: TextAlign.right,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Eliminar usuario?"),
        content: const Text("Se borrarán permanentemente tus datos de nam5."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteAccount(context, ref);
            }, 
            child: const Text("BORRAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}