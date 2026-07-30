// Created by Dino Catalinac on 30.07.2026.

import Foundation

public extension Calendar {

    func isDate(_ date: Date, inSame component: Component, as referenceDate: Date) -> Bool {
        guard
            let dateInterval = self.dateInterval(of: component, for: date),
            let referenceInterval = self.dateInterval(of: component, for: referenceDate)
        else {
            return false
        }

        return dateInterval.start == referenceInterval.start
    }
}
