/// A class that represents a single-use data container with generic content.
class SingleUseData<T> {
  /// The internal storage for the one-time accessible data.
  T? _data;

  /// Creates a new SingleUseData instance with the given content.
  ///
  /// [data] The initial content to be stored in the container.
  SingleUseData(T data) : _data = data;

  /// Retrieves and clears the stored content.
  ///
  /// Returns the stored content if it hasn't been accessed yet, otherwise null.
  /// After calling this method, the content is cleared and can't be accessed again.
  T? consume() {
    final data = _data;
    _data = null;
    return data;
  }

  /// Checks if the content has been accessed.
  ///
  /// Returns true if the content is still available, false otherwise.
  bool get hasData => _data != null;
}
