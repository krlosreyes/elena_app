import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/features/authentication/application/auth_controller.dart';
import 'package:elena_app/src/features/glucose/data/glucose_repository.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_model.dart';

// Pillar H color
const _kPurple = Color(0xFFCE93D8);

class GlucoseInputSheet extends ConsumerStatefulWidget {
  const GlucoseInputSheet({super.key});

  @override
  ConsumerState<GlucoseInputSheet> createState() => _GlucoseInputSheetState();
}

class _GlucoseInputSheetState extends ConsumerState<GlucoseInputSheet> {
  final _controller = TextEditingController();
  String _selectedTag = 'Ayunas';
  bool _isLoading = false;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final List<String> _tags = ['Ayunas', 'Post-comida', 'Antes de dormir'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveLog() async {
    final value = double.tryParse(_controller.text);
    if (value == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user != null) {
        final timestamp = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final log = GlucoseLog(
          id: '',
          value: value,
          timestamp: timestamp,
          tag: _selectedTag,
        );

        await ref.read(glucoseRepositoryProvider).addLog(uid: user.uid, log: log);
        if (mounted) context.pop();
      }
    } catch (e) {
      debugPrint('Error saving glucose: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Glucose risk color
  Color _glucoseColor(double? v) {
    if (v == null) return _kPurple;
    if (v < 70) return Colors.orange;
    if (v <= 99) return const Color(0xFF00FFB2);
    if (v <= 125) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = double.tryParse(_controller.text);
    final accentColor = _glucoseColor(parsed);

    // Background: dark card matching scaffold
    final bg = const Color(0xFF121212);

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: accentColor.withOpacity(0.3), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ───────────────────────────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bloodtype_outlined, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Registrar Glucosa',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Value input ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.robotoMono(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '---',
                      hintStyle: GoogleFonts.robotoMono(
                        fontSize: 32,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
                Text(
                  'mg/dL',
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Date & Time ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _PickerTile(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd/MM/yyyy').format(_selectedDate),
                onTap: _pickDate,
              )),
              const SizedBox(width: 10),
              Expanded(child: _PickerTile(
                icon: Icons.schedule_outlined,
                label: _selectedTime.format(context),
                onTap: _pickTime,
              )),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tags ─────────────────────────────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag;
                return Padding(
                  padding: EdgeInsets.only(
                    right: tag == _tags.last ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTag = tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPurple.withOpacity(0.18)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kPurple.withOpacity(0.6) : Colors.white12,
                        ),
                      ),
                      child: Text(
                        tag,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? _kPurple : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Save button ──────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isLoading || parsed == null) ? null : _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple.withOpacity(0.85),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'GUARDAR',
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable picker tile ────────────────────────────────────────────────────
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white38),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
