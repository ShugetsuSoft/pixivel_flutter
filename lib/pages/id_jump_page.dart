import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'illust_detail_page.dart';
import 'illustrator_profile_page.dart';

class IdJumpPage extends StatefulWidget {
  const IdJumpPage({super.key});

  @override
  State<IdJumpPage> createState() => _IdJumpPageState();
}

class _IdJumpPageState extends State<IdJumpPage> {
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

    if (id < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID不能为负数')),
      );
      return;
    }

    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID不能为0')),
      );
      return;
    }

    if (_isIllustrator) {
      Navigator.of(context).push(MaterialPageRoute(
        settings: RouteSettings(name: 'illustrator_profile_$id'),
        builder: (context) => IllustratorProfilePage(
          userId: id,
        ),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        settings: RouteSettings(name: 'illust_detail_$id'),
        builder: (context) => IllustDetailPage(
          illustId: id,
        ),
      ));
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ID跳转',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'ID',
                    hintText: '输入作品或画师ID',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _handleJump(context),
                  icon: const Icon(Icons.search),
                  label: const Text('跳转'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
