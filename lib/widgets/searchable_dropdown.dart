import 'package:flutter/material.dart';
import '../theme.dart';

class SearchableDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Map<String, List<String>>? groupedItems;
  final ValueChanged<String?> onChanged;
  final String hintText;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    this.items = const [],
    this.groupedItems,
    required this.onChanged,
    this.hintText = '请选择',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _showSelectionModal(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hintText,
                    style: TextStyle(
                      color: value != null
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectionModal(
        title: label,
        items: items,
        groupedItems: groupedItems,
        selectedValue: value,
        onSelected: onChanged,
      ),
    );
  }
}

class SelectionModal extends StatefulWidget {
  final String title;
  final List<String> items;
  final Map<String, List<String>>? groupedItems;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;

  const SelectionModal({
    super.key,
    required this.title,
    required this.items,
    this.groupedItems,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<SelectionModal> createState() => _SelectionModalState();
}

class _SelectionModalState extends State<SelectionModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: widget.groupedItems != null
                ? _buildGroupedList()
                : _buildFlatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: widget.groupedItems!.length,
      itemBuilder: (context, index) {
        final groupName = widget.groupedItems!.keys.elementAt(index);
        final items = widget.groupedItems![groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  groupName,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ...items.map((item) => _buildItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildFlatList() {
    List<String> displayItems = [];

    if (widget.groupedItems != null) {
      for (var list in widget.groupedItems!.values) {
        displayItems.addAll(list);
      }
    } else {
      displayItems = widget.items;
    }

    if (displayItems.isEmpty) {
      return const Center(
        child: Text('暂无选项', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        return _buildItem(displayItems[index]);
      },
    );
  }

  Widget _buildItem(String item) {
    final isSelected = item == widget.selectedValue;
    return InkWell(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        widget.onSelected(item);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: isSelected ? AppTheme.primaryLight.withOpacity(0.3) : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
