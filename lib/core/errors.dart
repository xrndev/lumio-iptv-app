/// Error con causa conocida, sin texto de usuario: la UI lo traduce al mostrarlo
/// (`localizedError`). Así `core` no depende del idioma de la interfaz.
enum AppErrorCode { invalidResponse, inactiveAccount, cannotConnect, httpStatus, downloadFailed, fileMissing }

class AppError implements Exception {
  const AppError(this.code, [this.arg = '']);

  final AppErrorCode code;

  /// Dato para el mensaje: estado de la cuenta, host, código HTTP, detalle…
  final String arg;

  @override
  String toString() => arg.isEmpty ? code.name : '${code.name}: $arg';
}
