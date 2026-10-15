import ForgeCore
import Testing

struct AppVersionTests {

    @Test(arguments: [("1", AppVersion(major: 1)), ("1.2", AppVersion(major: 1, minor: 2)), ("1.2.3", AppVersion(major: 1, minor: 2, patch: 3)), ("10.0.1", AppVersion(major: 10, patch: 1)), ("01.2", AppVersion(major: 1, minor: 2))])
    func parsesUpToThreeIntegersWithMissingOnesAsZero(_ string: String, _ expected: AppVersion) {
        #expect(AppVersion(string) == expected)
    }

    @Test(arguments: ["", ".", "1.", ".1", "1..2", "1.2.3.4", "1.a", "v1.0", "1.0-beta", " 1.0", "-1", "+1", "1.٣"])
    func rejectsMalformedStrings(_ string: String) {
        #expect(AppVersion(string) == nil)
    }

    @Test(arguments: [("1.0", "1.0.1"), ("1.9", "1.10"), ("1.2.3", "2"), ("9", "10"), ("0.9.9", "1")])
    func ordersNumerically(_ lower: String, _ higher: String) throws {
        let lower = try #require(AppVersion(lower)), higher = try #require(AppVersion(higher))
        #expect(lower < higher)
        #expect(!(higher < lower))
    }

    @Test func describesAllThreeNumbers() {
        #expect(AppVersion("1.2")?.description == "1.2.0")
    }
}
