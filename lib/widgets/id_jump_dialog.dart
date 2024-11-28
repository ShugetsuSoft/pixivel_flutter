import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/illust_detail_page.dart';
import '../pages/illustrator_profile_page.dart';
import '../models/illust.dart';

class IdJumpDialog extends StatefulWidget {
  const IdJumpDialog({super.key});

  @override
  State<IdJumpDialog> createState() => _IdJumpDialogState();
}

class _IdJumpDialogState extends State<IdJumpDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isIllustrator = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleJump(BuildContext context) {
    final id = int.tryParse(_controller.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的ID')),
      );
      return;
    }

    Navigator.of(context).pop();
    if (_isIllustrator) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => IllustratorProfilePage(userId: id),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => IllustDetailPage(
          illustId: id,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('输入ID'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'ID',
              hintText: '输入作品或画师ID',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _handleJump(context),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('作品'),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('画师'),
              ),
            ],
            selected: {_isIllustrator},
            onSelectionChanged: (value) {
              setState(() {
                _isIllustrator = value.first;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => _handleJump(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
