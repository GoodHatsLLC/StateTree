import Foundation

// MIT License
//
// Copyright (c) 2021 Varun Santhanam
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
//
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// A type erased `AsyncSequence`
///
/// This type allows you to create APIs that return an `AsyncSequence` that allows consumers to
/// iterate over the sequence, without exposing the sequence's underlying type.
/// Typically, you wouldn't actually initialize this type yourself, but instead create one using the
/// `.eraseToAnyAsyncSequence()` operator also provided with this package.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct AnyAsyncSequence<Element>: AsyncSequence {

  // MARK: Lifecycle

  // MARK: - Initializers

  /// Create an `AnyAsyncSequence` from an `AsyncSequence` conforming type
  /// - Parameter sequence: The `AnySequence` type you wish to erase
  public init<T: AsyncSequence>(_ sequence: T) where T.Element == Element {
    self.makeAsyncIteratorClosure = { AnyAsyncIterator(sequence.makeAsyncIterator()) }
  }

  public init(_ sequence: some Sequence<Element>) {
    let asyncSeq = AsyncStream<Element> { continuation in
      for element in sequence {
        continuation.yield(element)
      }
      continuation.finish()
    }
    self.init(asyncSeq)
  }

  // MARK: Public

  // MARK: - API

  public struct AnyAsyncIterator: AsyncIteratorProtocol {
    private let nextClosure: () async throws -> Element?

    public init<T: AsyncIteratorProtocol>(_ iterator: T) where T.Element == Element {
      var iterator = iterator
      self.nextClosure = { try await iterator.next() }
    }

    public func next() async throws -> Element? {
      try await nextClosure()
    }
  }

  // MARK: - AsyncSequence

  public typealias Element = Element

  public typealias AsyncIterator = AnyAsyncIterator

  public func makeAsyncIterator() -> AsyncIterator {
    AnyAsyncIterator(makeAsyncIteratorClosure())
  }

  // MARK: Private

  private let makeAsyncIteratorClosure: () -> AsyncIterator

}
