/// Errors thrown while encoding/decoding `application/x-www-form-urlencoded` data.
///
/// Source: https://github.com/vapor/vapor/tree/f4b00a5350238fe896d865d96d64f12fcbbeda95/Sources/Vapor/URLEncodedForm
/// License: https://github.com/vapor/vapor/blob/main/LICENSE
enum URLEncodedFormError: Error {
  case malformedKey(key: Substring)
  case reachedNestingLimit
}
