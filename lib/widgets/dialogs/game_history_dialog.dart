import 'package:flutter/material.dart';

import '../../models/game_state.dart';

/// 記録済みイベントをタイムライン表示し、個別に削除できるダイアログ。
void showGameHistoryDialog(
  BuildContext context, {
  required GameState state,
  required ValueChanged<int> onDeleteEvent,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.history, color: Colors.green),
          SizedBox(width: 8),
          // 幅の狭い端末（最大幅480px）でもタイトルがはみ出さないようにする。
          Flexible(child: Text('試合イベント履歴（タイムライン）')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: state.events.isEmpty
            ? const Text(
                'まだイベントが記録されていません。',
                style: TextStyle(color: Colors.grey),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: state.events.length,
                itemBuilder: (context, idx) {
                  final ev = state.events[idx];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: ev.isTop
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                        child: Text(
                          '${ev.inning}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text(
                        '${ev.isTop ? "表" : "裏"} | ${ev.description}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '得点: ${ev.runs}点 | アウト増: ${ev.addedOuts}'
                        '${ev.isIgnored ? " ※3アウト後のため集計対象外" : ""}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        tooltip: 'このイベントを削除',
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDeleteEvent(ev.eventId);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
          },
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
