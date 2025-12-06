enum WeatherFailureReason {
  network,
  invalidResponse,
  parsing,
  unknown,
}

class WeatherFailure {
  const WeatherFailure(this.reason, {this.message});

  final WeatherFailureReason reason;
  final String? message;
}

class WeatherResult<T> {
  const WeatherResult.success(this.value)
      : failure = null,
        isSuccess = true;
  const WeatherResult.failure(this.failure)
      : value = null,
        isSuccess = false;

  final T? value;
  final WeatherFailure? failure;
  final bool isSuccess;
}
