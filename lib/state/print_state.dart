import 'package:flutter/foundation.dart';

/// Immutable view state for the ticket QR printing flow, produced by the print
/// controller.
///
/// A print is triggered after a confirmed ticket registration. The controller
/// first checks the printer connection: if disconnected it surfaces
/// [PrintNotConnected] (the UI warns the Operator); while printing it surfaces
/// [Printing]; on success [PrintSuccess]; and on failure [PrintError], which
/// carries the [qrData] so the UI can prompt the Operator to retry the same
/// ticket.
@immutable
sealed class PrintState {
  const PrintState();
}

/// No print in progress.
@immutable
class PrintIdle extends PrintState {
  const PrintIdle();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintIdle && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PrintIdle()';
}

/// A print job is being sent to the Bluetooth printer.
@immutable
class Printing extends PrintState {
  const Printing();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Printing && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Printing()';
}

/// The ticket QR was printed successfully.
@immutable
class PrintSuccess extends PrintState {
  const PrintSuccess();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintSuccess && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PrintSuccess()';
}

/// No Bluetooth printer is connected. Retains [qrData] and the optional [title]
/// so the Operator can connect a printer and retry the same ticket.
@immutable
class PrintNotConnected extends PrintState {
  final String qrData;
  final String? title;

  const PrintNotConnected({required this.qrData, this.title});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintNotConnected &&
          runtimeType == other.runtimeType &&
          qrData == other.qrData &&
          title == other.title;

  @override
  int get hashCode => Object.hash(runtimeType, qrData, title);

  @override
  String toString() => 'PrintNotConnected(qrData: $qrData, title: $title)';
}

/// A print error occurred. Retains [qrData], the optional [title], and the
/// error [message] so the UI can prompt the Operator to retry the same ticket.
@immutable
class PrintError extends PrintState {
  final String qrData;
  final String? title;
  final String message;

  const PrintError({
    required this.qrData,
    required this.message,
    this.title,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintError &&
          runtimeType == other.runtimeType &&
          qrData == other.qrData &&
          title == other.title &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, qrData, title, message);

  @override
  String toString() =>
      'PrintError(qrData: $qrData, title: $title, message: $message)';
}
