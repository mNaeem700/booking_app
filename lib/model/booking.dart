import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String salonId;
  final String serviceId; // optional: SKU or index
  final String serviceName;
  final DateTime scheduledAt; // combined date+time
  final String status; // pending / confirmed / cancelled
  final int price;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.salonId,
    required this.serviceId,
    required this.serviceName,
    required this.scheduledAt,
    required this.status,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toCreateMap() => {
    'userId': userId,
    'salonId': salonId,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'status': status,
    'price': price,
  };

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      salonId: data['salonId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      price: (data['price'] is int)
          ? data['price'] as int
          : int.tryParse('${data['price'] ?? 0}') ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
