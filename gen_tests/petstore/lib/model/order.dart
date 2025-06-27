import 'package:meta/meta.dart';
import 'package:petstore/model/order_status_prop.dart';
import 'package:petstore/model_helpers.dart';

@immutable
class Order {
  const Order({
    this.id,
    this.petId,
    this.quantity,
    this.shipDate,
    this.status,
    this.complete,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      petId: json['petId'] as int?,
      quantity: json['quantity'] as int?,
      shipDate: maybeParseDateTime(json['shipDate'] as String?),
      status: OrderStatusProp.maybeFromJson(json['status'] as String?),
      complete: json['complete'] as bool?,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static Order? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Order.fromJson(json);
  }

  final int? id;
  final int? petId;
  final int? quantity;
  final DateTime? shipDate;
  final OrderStatusProp? status;
  final bool? complete;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'quantity': quantity,
      'shipDate': shipDate?.toIso8601String(),
      'status': status?.toJson(),
      'complete': complete,
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([id, petId, quantity, shipDate, status, complete]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        id == other.id &&
        petId == other.petId &&
        quantity == other.quantity &&
        shipDate == other.shipDate &&
        status == other.status &&
        complete == other.complete;
  }
}
