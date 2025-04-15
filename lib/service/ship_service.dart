import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/ship.dart';

class ShipService {
  static Future<List<Ship>> fetchAll(String regionText) async {
    try {
      final areaRes = await http.get(
        Uri.parse('https://api.sunsang24.com/ship/filter_area/general'),
      );

      final rawAreas = jsonDecode(areaRes.body)['area'] ?? [];
      final areas = rawAreas.whereType<Map<String, dynamic>>().expand((region) {
        final items = region['items'];
        if (items is! List) return <Map<String, String>>[];
        return items.whereType<Map<String, dynamic>>().map((item) {
          return {
            'area': item['area']?.toString() ?? item['no']?.toString() ?? '',
            'area_text': item['name']?.toString() ??
                item['title']?.toString() ??
                item['area_text']?.toString() ??
                '',
          };
        });
      }).toList();

      final cleaned = regionText.replaceFirst(
        RegExp(r'^(강원|경북|경남|전북|전남|충북|충남|제주|서울|경기|부산|대구|대전|광주|울산|세종)\s*'),
        '',
      );

      final target = areas.firstWhere(
        (a) => cleaned.contains(a['area_text']),
        orElse: () => <String, dynamic>{},
      );

      if (target.isEmpty) {
        debugPrint('❗ $regionText 지역 코드 찾을 수 없음');
        return [];
      }

      List<Ship> allShips = [];
      int page = 1;
      while (true) {
        final uri = Uri.parse('https://api.sunsang24.com/ship/list').replace(
          queryParameters: {
            'area': target['area'],
            'area_text': target['area_text'],
            'area_type': 'area',
            'page': page.toString(),
            'type': 'general',
          },
        );

        final res = await http.get(uri);
        final list = jsonDecode(res.body)['list'] ?? [];

        final ships = list
            .where((s) =>
                s['remain_embarkation_num'] != null &&
                s['remain_embarkation_num'] > 0)
            .map<Ship>((s) => Ship.fromJson({
                  'shipNo': s['ship']?['no'] ?? 0,
                  'name': s['ship']?['name'] ?? '이름없음',
                  'areaMain': s['ship']?['area_main'] ?? '지역미정',
                  'areaSub': s['ship']?['area_sub'] ?? '지역미정',
                  'fishType': s['fish_type'] ?? '어종 미상',
                  'remain': s['remain_embarkation_num'],
                }))
            .toList();

        debugPrint('✅ Page $page - ${ships.length}건');
        allShips.addAll(ships);

        if (list.length < 20) break; // 마지막 페이지로 판단
        page++;
      }
      debugPrint('📦 총 ${allShips.length}건의 배 정보를 가져왔습니다');

      return allShips;
    } catch (e) {
      debugPrint('❌ 오류 발생: $e');
      return [];
    }
  }
}
