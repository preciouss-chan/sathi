class ConnectedPerson {
  ConnectedPerson({
    required this.uid,
    required this.displayName,
    required this.connectCode,
    required this.connectedAt,
  });

  final String uid;
  final String displayName;
  final String connectCode;
  final DateTime connectedAt;
}
