import Foundation
import ForgeCore
import Testing

struct DateProviderTests {
    @Test func providesCurrentDateByDefault() {
        let before = Date.now
        let date = DateProvider().now
        let after = Date.now

        #expect((before...after).contains(date))
    }

    @Test func providesFixedDateWhenSpecified() {
        let date = Date(timeIntervalSince1970: 1_000)

        #expect(DateProvider(date: date).now == date)
    }
}
