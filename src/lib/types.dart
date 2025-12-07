// types.dart – DTO and Command Model definitions for API layer

// NOTE: Keep this file free of any Flutter imports to allow re-use on server or tests.

import 'models/generated_classes.dart';

/// Represents an authenticated session token pair returned by Supabase Auth.
class AuthSessionDto {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthSessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) => AuthSessionDto(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

// --------------------------- Resource DTOs --------------------------- //

/// Public trainer listing entry.
/// Mirrors [TrainerDirectory] entity but omits internal columns.
class TrainerDirectoryEntryDto {
  final String trainerId;
  final String displayName;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime updatedAt;

  const TrainerDirectoryEntryDto({
    required this.trainerId,
    required this.displayName,
    this.contactEmail,
    this.contactPhone,
    required this.updatedAt,
  });

  factory TrainerDirectoryEntryDto.fromEntity(TrainerDirectory e) =>
      TrainerDirectoryEntryDto(
        trainerId: e.trainerId,
        displayName: e.displayName,
        contactEmail: e.contactEmail,
        contactPhone: e.contactPhone,
        updatedAt: e.updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'trainerId': trainerId,
    'displayName': displayName,
    if (contactEmail != null) 'contactEmail': contactEmail,
    if (contactPhone != null) 'contactPhone': contactPhone,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

/// User profile DTO used across authenticated endpoints.
/// Excludes sensitive `passwordHash` column.
class UserDto {
  final String id;
  final String email;
  final String firstName;
  final String? lastName;
  final USER_ROLE role;
  final String? contactEmail;
  final String? contactPhone;
  final Map<String, dynamic> preferences;
  final bool isAnonymous;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDto({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.role,
    this.contactEmail,
    this.contactPhone,
    required this.preferences,
    required this.isAnonymous,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDto.fromEntity(Users e) => UserDto(
    id: e.id,
    email: e.email,
    firstName: e.firstName,
    lastName: e.lastName,
    role: e.role,
    contactEmail: e.contactEmail,
    contactPhone: e.contactPhone,
    preferences: e.preferences,
    isAnonymous: e.isAnonymous,
    deletedAt: e.deletedAt,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    'role': role.name,
    if (contactEmail != null) 'contactEmail': contactEmail,
    if (contactPhone != null) 'contactPhone': contactPhone,
    'preferences': preferences,
    'isAnonymous': isAnonymous,
    if (deletedAt != null) 'deletedAt': deletedAt!.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

/// Possible runtime status of a slot when returned via list/calendar endpoints.
enum SlotStatus { available, full, cancelled, past }

/// Slot availability DTO.
class SlotDto {
  final String id;
  final String trainerId;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final int capacity;
  final int?
  reserved; // number of already reserved seats (nullable, only present in some views)
  final SlotStatus? status; // runtime status derived by backend
  final String? notes;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SlotDto({
    required this.id,
    required this.trainerId,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.capacity,
    this.reserved,
    this.status,
    this.notes,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SlotDto.fromEntity(Slots e, {int? reserved, SlotStatus? status}) =>
      SlotDto(
        id: e.id,
        trainerId: e.trainerId,
        startAt: e.startAt,
        endAt: e.endAt,
        durationMinutes: e.durationMinutes,
        capacity: e.capacity,
        reserved: reserved,
        status: status,
        notes: e.notes,
        cancelledAt: e.cancelledAt,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'trainerId': trainerId,
    'startAt': startAt.toUtc().toIso8601String(),
    'endAt': endAt.toUtc().toIso8601String(),
    'durationMinutes': durationMinutes,
    'capacity': capacity,
    if (reserved != null) 'reserved': reserved,
    if (status != null) 'status': status!.name,
    if (notes != null) 'notes': notes,
    if (cancelledAt != null)
      'cancelledAt': cancelledAt!.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

/// Booking DTO with minimal nested slot & trainer info handled elsewhere.
class BookingDto {
  final String id;
  final String slotId;
  final String userId;
  final BOOKING_STATUS status;
  final DateTime statusChangedAt;
  final bool autoProcessed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingDto({
    required this.id,
    required this.slotId,
    required this.userId,
    required this.status,
    required this.statusChangedAt,
    required this.autoProcessed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingDto.fromEntity(Bookings e) => BookingDto(
    id: e.id,
    slotId: e.slotId,
    userId: e.userId,
    status: e.status,
    statusChangedAt: e.statusChangedAt,
    autoProcessed: e.autoProcessed,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slotId': slotId,
    'userId': userId,
    'status': status.name,
    'statusChangedAt': statusChangedAt.toUtc().toIso8601String(),
    'autoProcessed': autoProcessed,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

/// Historical record of booking status changes.
class BookingStatusHistoryDto {
  final BigInt id;
  final String bookingId;
  final BOOKING_STATUS previousStatus;
  final BOOKING_STATUS currentStatus;
  final DateTime changedAt;
  final String? changedBy;
  final bool autoProcessed;

  const BookingStatusHistoryDto({
    required this.id,
    required this.bookingId,
    required this.previousStatus,
    required this.currentStatus,
    required this.changedAt,
    this.changedBy,
    required this.autoProcessed,
  });

  factory BookingStatusHistoryDto.fromEntity(BookingStatusHistory e) =>
      BookingStatusHistoryDto(
        id: e.id,
        bookingId: e.bookingId,
        previousStatus: e.previousStatus,
        currentStatus: e.currentStatus,
        changedAt: e.changedAt,
        changedBy: e.changedBy,
        autoProcessed: e.autoProcessed,
      );

  Map<String, dynamic> toJson() => {
    'id': id.toString(),
    'bookingId': bookingId,
    'previousStatus': previousStatus.name,
    'currentStatus': currentStatus.name,
    'changedAt': changedAt.toUtc().toIso8601String(),
    if (changedBy != null) 'changedBy': changedBy,
    'autoProcessed': autoProcessed,
  };
}

/// Audit log entry DTO.
class ActivityLogDto {
  final String id;
  final LOG_ENTITY_TYPE entityType;
  final String entityId;
  final LOG_ACTION_TYPE action;
  final String? changedBy;
  final USER_ROLE? changedByRole;
  final Map<String, dynamic> changedFields;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ActivityLogDto({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.changedBy,
    this.changedByRole,
    required this.changedFields,
    required this.metadata,
    required this.createdAt,
  });

  factory ActivityLogDto.fromEntity(ActivityLogs e) => ActivityLogDto(
    id: e.id,
    entityType: e.entityType,
    entityId: e.entityId,
    action: e.action,
    changedBy: e.changedBy,
    changedByRole: e.changedByRole,
    changedFields: e.changedFields,
    metadata: e.metadata,
    createdAt: e.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType.name,
    'entityId': entityId,
    'action': action.name,
    if (changedBy != null) 'changedBy': changedBy,
    if (changedByRole != null) 'changedByRole': changedByRole!.name,
    'changedFields': changedFields,
    'metadata': metadata,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

/// Generic job execution summary (used by automation job endpoints).
class AutomationJobSummaryDto {
  final DateTime lastRunAt;
  final int processedBookings;
  final int durationMs;

  const AutomationJobSummaryDto({
    required this.lastRunAt,
    required this.processedBookings,
    required this.durationMs,
  });

  factory AutomationJobSummaryDto.fromJson(Map<String, dynamic> json) =>
      AutomationJobSummaryDto(
        lastRunAt: DateTime.parse(json['lastRunAt'] as String),
        processedBookings: json['processedBookings'] as int,
        durationMs: json['durationMs'] as int,
      );

  Map<String, dynamic> toJson() => {
    'lastRunAt': lastRunAt.toUtc().toIso8601String(),
    'processedBookings': processedBookings,
    'durationMs': durationMs,
  };
}

// --------------------------- Command Models --------------------------- //

/// Request payload for POST /slots
class CreateSlotCommand {
  final DateTime startAt;
  final DateTime endAt;
  final int capacity;
  final String? notes;

  const CreateSlotCommand({
    required this.startAt,
    required this.endAt,
    required this.capacity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'startAt': startAt.toUtc().toIso8601String(),
    'endAt': endAt.toUtc().toIso8601String(),
    'capacity': capacity,
    if (notes != null) 'notes': notes,
  };
}

/// Request payload for PATCH /slots/{slotId}
class UpdateSlotCommand {
  final DateTime? startAt;
  final DateTime? endAt;
  final int? capacity;
  final String? notes;

  const UpdateSlotCommand({
    this.startAt,
    this.endAt,
    this.capacity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    if (startAt != null) 'startAt': startAt!.toUtc().toIso8601String(),
    if (endAt != null) 'endAt': endAt!.toUtc().toIso8601String(),
    if (capacity != null) 'capacity': capacity,
    if (notes != null) 'notes': notes,
  };
}

/// Request payload for POST /slots/{slotId}/bookings
class CreateBookingCommand {
  final String? notes;
  final bool? autoProcessed;

  const CreateBookingCommand({this.notes, this.autoProcessed});

  Map<String, dynamic> toJson() => {
    if (notes != null) 'notes': notes,
    if (autoProcessed != null) 'autoProcessed': autoProcessed,
  };
}

/// Request payload for POST /bookings/{bookingId}:cancel
class CancelBookingCommand {
  final String reason;

  const CancelBookingCommand({required this.reason});

  Map<String, dynamic> toJson() => {'reason': reason};
}

/// Request body for POST /jobs/booking-status-sync
class BookingStatusSyncCommand {
  final DateTime? until;

  const BookingStatusSyncCommand({this.until});

  Map<String, dynamic> toJson() => {
    if (until != null) 'until': until!.toUtc().toIso8601String(),
  };
}

/// Paginated response DTO.
class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int pageSize;
  final int total;
  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.total,
  });
  Map<String, dynamic> toJson() => {
    'data': data,
    'page': page,
    'pageSize': pageSize,
    'total': total,
  };

  /// Generic factory that allows callers to provide a mapper from raw JSON to `T`.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) mapper,
  ) {
    return PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>).map(mapper).toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      total: json['total'] as int,
    );
  }

  PaginatedResponse<T> copyWith({
    List<T>? data,
    int? page,
    int? pageSize,
    int? total,
  }) => PaginatedResponse<T>(
    data: data ?? this.data,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    total: total ?? this.total,
  );
}
