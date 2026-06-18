abstract class Failure {
  Failure(this.message);
  final String message;
}

class DatabaseFailure extends Failure {
  DatabaseFailure([super.message = "Database Error"]);
}

class NetworkFailure extends Failure {
  NetworkFailure([super.message = "Network Error"]);
}