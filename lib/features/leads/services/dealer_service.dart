import 'package:sales_management/core/network/api_constants.dart';
import 'package:sales_management/core/services/base_api_service.dart';

import '../models/dealer_model.dart';


class DealerService {
  final BaseApiService _apiService;

  DealerService(this._apiService);

  Future<List<Dealer>> getDealers(int salesId) async {
    final endpoint = EndpointConfig(url: '/api/dealers?salesId=$salesId', method: 'GET');

    final responseData = await _apiService.request<List<dynamic>>(
      endpoint,
      options: VanguardeRequestOptions(showLoader: true),
    );

    return responseData?.map((e) => Dealer.fromJson(e)).toList() ?? [];
  }

  Future<void> createDealer(Dealer dealer) async {
    final endpoint = EndpointConfig(url: '/api/dealers', method: 'POST');

    await _apiService.request(
      endpoint,
      body: dealer.toPayload(),
      options: VanguardeRequestOptions(
        showLoader: true,
        successMessage: 'Dealer created successfully!',
      ),
    );
  }
}