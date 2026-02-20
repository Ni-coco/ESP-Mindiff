import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:mindiff_app/utils/theme.dart';

/// A reusable custom dropdown button widget based on dropdown_button2
class CustomDropdownButton2 extends StatelessWidget {
  const CustomDropdownButton2({
    required this.hint,
    required this.value,
    required this.dropdownItems,
    required this.onChanged,
    this.dropdownLabels,
    this.selectedItemBuilder,
    this.hintAlignment,
    this.valueAlignment,
    this.buttonHeight,
    this.buttonWidth,
    this.buttonPadding,
    this.buttonDecoration,
    this.buttonElevation,
    this.icon,
    this.iconSize,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.itemHeight,
    this.itemPadding,
    this.dropdownHeight,
    this.dropdownWidth,
    this.dropdownPadding,
    this.dropdownDecoration,
    this.dropdownElevation,
    this.scrollbarRadius,
    this.scrollbarThickness,
    this.scrollbarAlwaysShow,
    this.offset = Offset.zero,
    this.labelText,
    this.prefixIcon,
    this.validator,
    super.key,
  });

  final String hint;
  final String? value;
  final List<String> dropdownItems;
  final Map<String, String>? dropdownLabels;
  final ValueChanged<String?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final Alignment? hintAlignment;
  final Alignment? valueAlignment;
  final double? buttonHeight, buttonWidth;
  final EdgeInsetsGeometry? buttonPadding;
  final BoxDecoration? buttonDecoration;
  final int? buttonElevation;
  final Widget? icon;
  final double? iconSize;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final double? itemHeight;
  final EdgeInsetsGeometry? itemPadding;
  final double? dropdownHeight, dropdownWidth;
  final EdgeInsetsGeometry? dropdownPadding;
  final BoxDecoration? dropdownDecoration;
  final int? dropdownElevation;
  final Radius? scrollbarRadius;
  final double? scrollbarThickness;
  final bool? scrollbarAlwaysShow;
  final Offset offset;
  final String? labelText;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    final borderColor = isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    
    Widget dropdown = DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Container(
          alignment: hintAlignment ?? Alignment.centerLeft,
          height: buttonHeight ?? 48,
          child: Align(
            alignment: hintAlignment ?? Alignment.centerLeft,
            child: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ),
        value: value,
        items: dropdownItems
            .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Container(
                    alignment: valueAlignment ?? Alignment.centerLeft,
                    child: Text(
                      dropdownLabels?[item] ?? item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          height: buttonHeight ?? 48,
          width: buttonWidth,
          padding: buttonPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: buttonDecoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                ),
                color: THelperFunctions.backgroundColor(context),
              ),
          elevation: buttonElevation,
        ),
        selectedItemBuilder: selectedItemBuilder != null
            ? (context) {
                // Wrap the custom selectedItemBuilder items to ensure vertical centering
                final items = selectedItemBuilder!(context);
                return items.map((widget) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    height: buttonHeight ?? 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: widget,
                    ),
                  );
                }).toList();
              }
            : (context) {
                return dropdownItems.map((String item) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    height: buttonHeight ?? 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dropdownLabels?[item] ?? item,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList();
              },
        iconStyleData: IconStyleData(
          icon: icon ?? const Icon(Icons.arrow_drop_down),
          iconSize: iconSize ?? 24,
          iconEnabledColor: iconEnabledColor ?? THelperFunctions.textColor(context),
          iconDisabledColor: iconDisabledColor,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: dropdownHeight ?? 200,
          width: dropdownWidth,
          padding: dropdownPadding,
          decoration: dropdownDecoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: THelperFunctions.backgroundColor(context),
              ),
          elevation: dropdownElevation ?? 8,
          offset: offset,
          scrollbarTheme: ScrollbarThemeData(
            radius: scrollbarRadius ?? const Radius.circular(40),
            thickness: scrollbarThickness != null
                ? MaterialStateProperty.all<double>(scrollbarThickness!)
                : null,
            thumbVisibility: scrollbarAlwaysShow != null
                ? MaterialStateProperty.all<bool>(scrollbarAlwaysShow!)
                : null,
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: itemHeight ?? 40,
          padding: itemPadding ?? const EdgeInsets.only(left: 16, right: 16),
        ),
      ),
    );

    // Wrap with InputDecoration if labelText or prefixIcon is provided
    if (labelText != null || prefixIcon != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    labelText!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          dropdown,
        ],
      );
    }

    return dropdown;
  }
}

