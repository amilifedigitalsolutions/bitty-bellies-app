sealed class AppError {
  final String message;
  const AppError(this.message);

  @override
  String toString() => message;
}

final class NetworkError extends AppError {
  const NetworkError([super.message = 'Network unavailable. Check your connection.']);
}

final class AuthError extends AppError {
  const AuthError([super.message = 'Authentication failed. Please sign in again.']);
}

final class NotFoundError extends AppError {
  const NotFoundError([super.message = 'The requested resource was not found.']);
}

final class PermissionError extends AppError {
  const PermissionError([super.message = 'You do not have permission to perform this action.']);
}

final class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(super.message, {this.fieldErrors = const {}});
}

final class ServerError extends AppError {
  final int? statusCode;
  const ServerError([super.message = 'Something went wrong on our end. Please try again.', this.statusCode]);
}

final class UnknownError extends AppError {
  const UnknownError([super.message = 'An unexpected error occurred.']);
}

final class NotConfirmedError extends AppError {
  final String email;
  const NotConfirmedError(this.email)
      : super('Please confirm your email before signing in.');
}

final class AlreadyRegisteredError extends AppError {
  const AlreadyRegisteredError()
      : super('An account with this email already exists.');
}
