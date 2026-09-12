import 'package:flutter/material.dart';

import '../../models/at_bat_result.dart';
import '../../providers/game_provider.dart';

/// 併殺（ダブルプレイ）の送球経路を組み立てるダイアログ。
void showDoublePlayRouteDialog(
  BuildContext context, {
  required GameNotifier notifier,
  String? errorPlayerId,
}) {
  List<String> route = [];
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDState) => AlertDialog(
        title: const Text('併殺の経路を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              width: double.infinity,
              child: Text(
                route.isEmpty ? "(未選択)" : route.join(" → "),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['投', '捕', '一', '二', '三', '遊', '左', '中', '右'].map((
                pos,
              ) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade900,
                  ),
                  onPressed: () {
                    setDState(() {
                      route.add(pos);
                    });
                  },
                  child: Text(pos),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                setDState(() {
                  route.clear();
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('クリア'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              String direction = route.join('→');
              if (direction.isEmpty) {
                direction = '併殺';
              }
              notifier.recordOrUpdateAtBat(
                AtBatResult.doublePlay,
                direction: direction,
                errorPlayerId: errorPlayerId,
              );
            },
            child: const Text('確定'),
          ),
        ],
      ),
    ),
  );
}
