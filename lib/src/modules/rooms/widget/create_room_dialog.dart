import 'package:flutter/material.dart';

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({
    super.key,
  });

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _enableSave = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: _nameController,
              onChanged: (value) {
                setState(() {
                  _enableSave = value.trim().isNotEmpty;
                });
              },
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Room Name',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _enableSave
                    ? () => Navigator.of(context)
                        .pop<String>(_nameController.text.trim())
                    : null,
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
