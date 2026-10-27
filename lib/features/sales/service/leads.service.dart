import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sales_management/features/leads/models/leads.model.dart';

class LeadService {

  // Simulates GET /api/distributors
  Future<List<Lead>> getLeads() async {
    // 1. Read the JSON file from your assets
    final String responseStr = await rootBundle.loadString('lib/core/distributor.json');

    // 2. Decode the JSON string into a Dart Map
    final Map<String, dynamic> jsonResponse = json.decode(responseStr);

    // 3. Check if success is true, then extract the 'data' array
    if (jsonResponse['success'] == true) {
      final List<dynamic> dataList = jsonResponse['data'];

      // 4. Convert every map in the array into a Lead object
      return dataList.map((json) => Lead.fromJson(json)).toList();
    }

    return [];
  }
}