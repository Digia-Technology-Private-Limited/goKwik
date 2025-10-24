// import 'package:flutter/material.dart';

class BaseResponse<T> {
  final T? data;
  final String? error;
  final bool? isSuccess;
  final int? statusCode;
  final bool? success;
  final DateTime? timestamp;
  final String? errorMessage;
  final String? error_msg;
  final String? requestId;

  BaseResponse({
    this.data,
    this.error,
    this.isSuccess,
    this.statusCode,
    this.success,
    this.timestamp,
    this.errorMessage,
    this.error_msg,
    this.requestId,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return BaseResponse(
      data: fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      error: json['error'] ?? "",
      isSuccess: json['isSuccess'],
      statusCode: json['status_code'] ?? 0,
      success: json['success'],
      timestamp: _handleTimestamp(json['timestamp']),
      errorMessage: json['error_msg'] ?? '',
    );
  }

  static DateTime? _handleTimestamp(dynamic timestamp) {
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }
}

sealed class Result<T> {
  const Result();

  bool get isSuccess;
  bool get isFailure;

  T getDataOrThrow();

  static Result<T> parseBaseResponse<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final baseResponse = BaseResponse<T>.fromJson(json, fromJson);
    if (baseResponse.isSuccess == true || baseResponse.success == true) {
      return Success(baseResponse.data!);
    } else {
      return Failure(
          baseResponse.errorMessage ?? baseResponse.error ?? 'Unknown error');
    }
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  bool get isSuccess => true;
  @override
  bool get isFailure => false;

  @override
  T getDataOrThrow() {
    return data;
  }
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);

  @override
  bool get isSuccess => false;
  @override
  bool get isFailure => true;

  @override
  T getDataOrThrow() {
    throw Exception("Failure: $message");
  }

  @override
  String toString() {
    return 'Failure: $message';
  }
}
