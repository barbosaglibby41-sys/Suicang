import 'package:flutter/material.dart';
import '../domain/generation.dart';
import '../../../core/theme/suicang_theme.dart';

class GenerationSheet extends StatefulWidget {
  const GenerationSheet({required this.settings, required this.onChanged, super.key});
  final GenerationSettings settings;
  final ValueChanged<GenerationSettings> onChanged;

  @override
  State<GenerationSheet> createState() => _GenerationSheetState();
}

class _GenerationSheetState extends State<GenerationSheet> {
  late GenerationSettings _settings = widget.settings;

  void _update(GenerationSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('生成设置', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('这些参数会随当前会话保存，可在生成前快速调整。', style: TextStyle(fontSize: 12, color: SuicangTheme.muted)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _settings.model,
              decoration: const InputDecoration(labelText: '模型', border: OutlineInputBorder()),
              items: const [DropdownMenuItem(value: 'Claude', child: Text('Claude')), DropdownMenuItem(value: 'GPT-4o', child: Text('GPT-4o')), DropdownMenuItem(value: '本地模型', child: Text('本地模型'))],
              onChanged: (value) => value == null ? null : _update(_settings.copyWith(model: value)),
            ),
            const SizedBox(height: 14),
            _SliderRow(label: 'Temperature', value: _settings.temperature, min: 0, max: 2, divisions: 20, display: _settings.temperature.toStringAsFixed(2), onChanged: (value) => _update(_settings.copyWith(temperature: value))),
            _SliderRow(label: 'Top P', value: _settings.topP, min: 0, max: 1, divisions: 20, display: _settings.topP.toStringAsFixed(2), onChanged: (value) => _update(_settings.copyWith(topP: value))),
            _SliderRow(label: '重复惩罚', value: _settings.repetitionPenalty, min: 1, max: 1.5, divisions: 10, display: _settings.repetitionPenalty.toStringAsFixed(2), onChanged: (value) => _update(_settings.copyWith(repetitionPenalty: value))),
            _SliderRow(label: '最大输出', value: _settings.maxTokens.toDouble(), min: 256, max: 8192, divisions: 31, display: '${_settings.maxTokens} tokens', onChanged: (value) => _update(_settings.copyWith(maxTokens: value.round()))),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.display, required this.onChanged});
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Text(display, style: const TextStyle(color: SuicangTheme.primary, fontWeight: FontWeight.w700))]),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ],
      );
}
