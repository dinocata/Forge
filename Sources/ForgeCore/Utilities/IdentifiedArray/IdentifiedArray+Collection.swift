//
//  IdentifiedArray+Collection.swift
//  AppCore
//
//  Created by Dino Čatalinac on 08.05.2026..
//

import OrderedCollections

extension IdentifiedArray: Collection {
  @inlinable
  @inline(__always)
  public var startIndex: Int { self._dictionary.keys.startIndex }

  @inlinable
  @inline(__always)
  public var endIndex: Int { self._dictionary.keys.endIndex }

  @inlinable
  @inline(__always)
  public func index(after i: Int) -> Int { self._dictionary.keys.index(after: i) }

  /// Returns the element identified by the given id.
  ///
  /// - Parameter id: The id to find in the array.
  /// - Returns: The element identified by `id` if found in the array; otherwise, `nil`.
  /// - Complexity: Expected to be O(1) on average, if `ID` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public subscript(id id: ID) -> Element? {
      get {
          self._dictionary[id]
      }
      set {
          self._dictionary[id] = newValue
      }
  }

  /// Returns a new array containing the elements of the array that satisfy the given predicate.
  ///
  /// - Parameter isIncluded: A closure that takes an element as its argument and returns a Boolean
  ///   value indicating whether it should be included in the returned array.
  /// - Returns: An array of the elements that `isIncluded` allows.
  /// - Complexity: O(`count`)
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    try .init(
      id: self.id,
      _id: self._id,
      _dictionary: self._dictionary.filter { try isIncluded($1) }
    )
  }
}
