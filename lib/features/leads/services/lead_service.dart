import 'package:sales_management/core/network/api_constants.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/features/leads/models/leads.model.dart';

class LeadService {
  final BaseApiService _apiService;

  LeadService(this._apiService);

  Future<List<Lead>> getLeads(int salesId) async {
    final endpoint = EndpointConfig(url: '/api/distributors?salesId=$salesId', method: 'GET');

    final responseData = await _apiService.request<List<dynamic>>(
      endpoint,
      options: VanguardeRequestOptions(showLoader: true),
    );

    return responseData?.map((e) => Lead.fromJson(e)).toList() ?? [];
  }

  Future<Lead> createLead(Lead lead, {bool showLoader = true}) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/distributors', method: 'POST'),
      body: lead.toPayload(),
      options: VanguardeRequestOptions(
        // ⬅️ Pass the flag down so BaseApiService doesn't interrupt our flow
        showLoader: showLoader,
        // ⬅️ Removed successMessage (we will handle it in the UI)
      ),
    );

    return Lead.fromJson(response);
  }
}