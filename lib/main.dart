import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ship_info_app/screen/webview_screen.dart';

import 'provider/ship_provider.dart';

void main() => runApp(
      const ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ShipListPage(),
        ),
      ),
    );

class ShipListPage extends ConsumerStatefulWidget {
  const ShipListPage({super.key});

  @override
  ConsumerState<ShipListPage> createState() => _ShipListPageState();
}

class _ShipListPageState extends ConsumerState<ShipListPage> {
  final regionController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipListProvider);
    final notifier = ref.read(shipListProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('출조 정보 조회')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: regionController,
              decoration: InputDecoration(
                labelText: '지역 입력 (예: 통영)',
                suffixIcon: regionController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          regionController.clear();
                          notifier.reset();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => ref.refresh(shipListProvider),
              onSubmitted: (text) {
                FocusScope.of(context).unfocus(); // 키보드 내리기
                notifier.fetchAll(regionController.text);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "선택된 날짜: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 14),
                ),
                TextButton(
                  onPressed: _selectDate,
                  child: const Text("날짜 선택"),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus(); // 키보드 내리기
                await notifier.fetchAll(regionController.text);
              },
              child: const Text('검색'),
            ),
            Text('총 ${state.ships.length}건 검색됨',
                style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            if (state.isLoading)
              const CircularProgressIndicator()
            else if (state.ships.isEmpty)
              const Text('결과 없음')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: state.ships.length,
                  itemBuilder: (_, i) {
                    final s = state.ships[i];
                    final sdate =
                        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                    final url =
                        'https://www.sunsang24.com/ship/list/?ship_no=${s.shipNo}&sdate=$sdate';

                    return Card(
                      child: ListTile(
                        title: Text(
                            '${i + 1}. ${s.name} (${s.areaMain} ${s.areaSub})'),
                        subtitle: Text('${s.fishType} / 남은자리: ${s.remain}'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WebViewScreen(url: url),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
