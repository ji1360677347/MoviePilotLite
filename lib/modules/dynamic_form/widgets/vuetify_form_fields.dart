import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_form_parser.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_primitives.dart';

class VuetifySwitchField extends StatelessWidget {
  const VuetifySwitchField({super.key, required this.spec, this.controller});

  final VuetifySwitchFieldSpec spec;
  final DynamicFormController? controller;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    if (ctrl == null || spec.name == null) {
      return VuetifyFormRow(
        label: spec.label,
        trailing: CupertinoSwitch(value: spec.value, onChanged: null),
      );
    }

    return Obx(() {
      final value = ctrl.getBoolValue(spec.name);
      return VuetifyFormRow(
        label: spec.label,
        trailing: CupertinoSwitch(
          value: value,
          onChanged: (next) => ctrl.updateField(spec.name, next),
        ),
      );
    });
  }
}

class VuetifySelectField extends StatelessWidget {
  const VuetifySelectField({
    super.key,
    required this.spec,
    required this.controller,
  });

  final VuetifySelectFieldSpec spec;
  final DynamicFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.getValue(spec.name);
      final currentTitle = _currentTitle(current);

      return CupertinoListTile(
        title: Text(spec.label, style: const TextStyle(fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentTitle,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 14),
          ],
        ),
        onTap: () => _showPicker(context),
      );
    });
  }

  String _currentTitle(dynamic current) {
    if (spec.multiple && current is Iterable) {
      final values = current.toSet();
      final titles = <String>[];
      for (final item in spec.items) {
        if (values.contains(item.value)) {
          titles.add(item.title);
        }
      }
      return titles.join(', ');
    }

    for (final item in spec.items) {
      if (item.value == current) {
        return item.title;
      }
    }
    return '';
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: spec.items.map((item) {
          return CupertinoActionSheetAction(
            onPressed: () {
              controller.updateField(spec.name, item.value);
              Navigator.of(context).pop();
            },
            child: Text(item.title),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }
}

class VuetifyCronField extends StatelessWidget {
  const VuetifyCronField({super.key, required this.spec, this.controller});

  final VuetifyCronFieldSpec spec;
  final DynamicFormController? controller;

  @override
  Widget build(BuildContext context) {
    return VuetifyTextInputField(
      label: spec.label,
      hint: spec.hint,
      name: spec.name,
      controller: controller,
      maxLines: 1,
    );
  }
}
