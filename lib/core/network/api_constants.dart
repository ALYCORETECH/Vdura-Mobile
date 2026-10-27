class EndpointConfig {
  final String url;
  final String method;
  const EndpointConfig({required this.url, required this.method});
}

class VanguardeRequestOptions {
  final Map<String, dynamic>? pathParams;
  final bool showLoader;
  final String? successMessage;

  VanguardeRequestOptions({
    this.pathParams,
    this.showLoader = true,
    this.successMessage,
  });
}

class ApiEndpoints {
  static const authLogin = EndpointConfig(url: '/api/auth/login', method: 'POST');

  // Dealers
  static const getDealerById = EndpointConfig(url: '/api/dealers/{dealerId}', method: 'GET');
  static const updateDealer = EndpointConfig(url: '/api/dealers/{dealerId}', method: 'PUT');
  static const deleteDealer = EndpointConfig(url: '/api/dealers/{dealerId}', method: 'DELETE');
}

class OrderEndpoints {
  static const getAllOrders = EndpointConfig(url: '/api/orders', method: 'GET');
  static const createOrder = EndpointConfig(url: '/api/orders', method: 'POST');
}