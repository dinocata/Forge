// Created by Dino Catalinac on 29.07.2026.

import Foundation

public extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension RandomAccessCollection {
    /// Returns adjacent elements whose ascending keys bracket `value`.
    ///
    /// The collection must be sorted in ascending order by `keyPath`. Returns `nil` when the
    /// collection has fewer than two elements or `value` falls outside its bounds.
    func elementsBracketing<Value: Comparable>(
        _ value: Value,
        by keyPath: KeyPath<Element, Value>
    ) -> (lower: Element, upper: Element)? {
        guard count >= 2 else { return nil }

        let firstIndex = startIndex
        let lastIndex = index(before: endIndex)
        guard self[firstIndex][keyPath: keyPath] <= value,
              value <= self[lastIndex][keyPath: keyPath] else {
            return nil
        }

        var lowerIndex = firstIndex
        var upperIndex = lastIndex

        while distance(from: lowerIndex, to: upperIndex) > 1 {
            let distance = distance(from: lowerIndex, to: upperIndex)
            let middleIndex = index(lowerIndex, offsetBy: distance / 2)

            if self[middleIndex][keyPath: keyPath] < value {
                lowerIndex = middleIndex
            } else {
                upperIndex = middleIndex
            }
        }

        return (self[lowerIndex], self[upperIndex])
    }
}
