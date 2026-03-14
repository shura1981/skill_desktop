import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../models/person.dart';

class FormWindowPage extends ConsumerStatefulWidget {
  const FormWindowPage({super.key});

  @override
  ConsumerState<FormWindowPage> createState() => _FormWindowPageState();
}

class _FormWindowPageState extends ConsumerState<FormWindowPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _estaturaCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _ciudadCtrl.dispose();
    _celularCtrl.dispose();
    _pesoCtrl.dispose();
    _estaturaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final person = Person(
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        celular: _celularCtrl.text.trim(),
        peso: double.parse(_pesoCtrl.text.trim()),
        estatura: double.parse(_estaturaCtrl.text.trim()),
      );
      await DatabaseHelper.instance.insert(person);
      // Refresh the main window's table
      ref.invalidate(personsProvider);
      _closeWindow();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _closeWindow() {
    final viewId = View.of(context).viewId;
    ref.read(windowTitleProvider.notifier).unregister(viewId);
    if (viewId != 0) {
      ui.PlatformDispatcher.instance.closeView(viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewId = View.of(context).viewId;
    final title = ref.watch(windowTitleProvider)[viewId] ?? 'Ventana';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: _closeWindow,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            children: [
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _nombresCtrl,
                      label: 'Nombres',
                      hint: 'Ingrese los nombres',
                      validator: _requiredValidator,
                    ),
                  ),
                  Expanded(
                    child: _buildField(
                      controller: _apellidosCtrl,
                      label: 'Apellidos',
                      hint: 'Ingrese los apellidos',
                      validator: _requiredValidator,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _ciudadCtrl,
                      label: 'Ciudad',
                      hint: 'Ciudad de residencia',
                      validator: _requiredValidator,
                    ),
                  ),
                  Expanded(
                    child: _buildField(
                      controller: _celularCtrl,
                      label: 'Número de celular',
                      hint: '+57 300 000 0000',
                      validator: _requiredValidator,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _pesoCtrl,
                      label: 'Peso (kg)',
                      hint: '70.5',
                      validator: _numericValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildField(
                      controller: _estaturaCtrl,
                      label: 'Estatura (m)',
                      hint: '1.75',
                      validator: _numericValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: .end,
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                    onPressed: _saving ? null : _closeWindow,
                  ),
                  FilledButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      validator: validator,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    return null;
  }

  String? _numericValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
    if (double.tryParse(value.trim()) == null) return 'Ingrese un número válido';
    return null;
  }
}
