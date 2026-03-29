class ConnectionRequest {
  ConnectionRequest({
    required this.fromUid,
    required this.fromDisplayName,
    required this.fromConnectCode,
    required this.createdAt,
  });

  final String fromUid;
  final String fromDisplayName;
  final String fromConnectCode;
  final DateTime createdAt;
}
