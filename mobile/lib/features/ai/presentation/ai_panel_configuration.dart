import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../shared/state_management/async_value.dart';
import '../../../shared/state_management/global/ai_config_cubit.dart';
import '../../../shared/state_management/global/haptics_cubit_feedback.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/ai_config.dart';
import '../domain/ai_use_case_select_provider.dart';
import '../state_management/ai_bloc_check_connection.dart';

class AiConfigurationPanel extends StatelessWidget {
  const AiConfigurationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final createBloc = context.read<CreateAiConnectionBloc>();
    return BlocProvider(
      create: (_) => createBloc(),
      child: const _ConfigurationFields(),
    );
  }
}

class _ConfigurationFields extends StatefulWidget {
  const _ConfigurationFields();

  @override
  State<_ConfigurationFields> createState() => _ConfigurationFieldsState();
}

class _ConfigurationFieldsState extends State<_ConfigurationFields> {
  late final TextEditingController _keyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(
      text: context.read<AiConfigCubit>().state.apiKey,
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final config = context.watch<AiConfigCubit>().state;
    final options = AiProviderOptions.forProvider(config.provider);
    return BlocListener<AiConfigCubit, AiConfig>(
      listenWhen: (previous, current) => previous.apiKey != current.apiKey,
      listener: (_, config) {
        if (_keyController.text.trim() != config.apiKey) {
          _keyController.text = config.apiKey;
        }
      },
      child: Column(
        children: [
          _dropdown(
            colors,
            'AI Provider',
            config.provider,
            [
              for (final provider in AiProviderOptions.all)
                DropdownMenuItem(
                  value: provider.id,
                  child: Text(provider.label),
                ),
            ],
            (value) =>
                context.read<AiConfigCubit>().updateConfig(provider: value),
          ),
          _dropdown(
            colors,
            'AI Model',
            config.model,
            [
              for (final model in options.includingSavedModel(config.model))
                DropdownMenuItem(
                  value: model,
                  child: Text(
                    model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            (value) => context.read<AiConfigCubit>().updateConfig(model: value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(color: colors.textPrimary),
              onChanged: (value) => context.read<AiConfigCubit>().updateConfig(
                apiKey: value.trim(),
              ),
              decoration: InputDecoration(
                labelText: 'API Key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  tooltip: _obscureKey ? 'Show API key' : 'Hide API key',
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
          ),
          BlocConsumer<AiConnectionBloc, AsyncValue<AiConnectionCheck?>>(
            listener: (context, state) {
              final check = state.valueOrNull;
              if (check == null ||
                  check.config != context.read<AiConfigCubit>().state) {
                return;
              }
              final result = check.result;
              final haptics = context.read<HapticsCubit>();
              if (result.success) {
                haptics.lightImpact();
              } else {
                haptics.mediumImpact();
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(result.message)));
            },
            builder: (context, state) {
              final check = state.valueOrNull;
              final result = check?.config == config ? check?.result : null;
              return ListTile(
                title: Text(
                  'Test API Key',
                  style: AppTextStyles.bodyLargeBold(color: colors.textPrimary),
                ),
                subtitle: Text(
                  state.isLoading
                      ? 'Testing connection…'
                      : result?.message ?? 'Verify credentials with provider',
                ),
                leading: Icon(switch (result?.success) {
                  true => PhosphorIcons.checkCircle,
                  false => PhosphorIcons.warningCircle,
                  null => PhosphorIcons.lightning,
                }),
                trailing: state.isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () => context.read<AiConnectionBloc>().add(
                          AiConnectionRequested(config),
                        ),
                        child: const Text('Test'),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    AppColors colors,
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      initialValue: value,
      key: ValueKey((label, value)),
      dropdownColor: colors.surface,
      style: AppTextStyles.bodyLarge(color: colors.textPrimary),
      items: items,
      onChanged: onChanged,
    ),
  );
}
