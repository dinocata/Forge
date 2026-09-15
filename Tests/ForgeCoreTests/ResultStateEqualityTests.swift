import ForgeCore
import Observation
import Testing

/// How two states compare, which is what decides whether observers of an ``AsyncState`` are told.
@MainActor
struct ResultStateEqualityTests {

    /// A value with no `Equatable` conformance, such as a screen's presentation model.
    private final class Payload {}

    /// Set from an observation callback, which must be `Sendable`.
    private final class Flag: @unchecked Sendable {
        var isSet = false
    }

    @Test func successesThatCannotBeComparedAreNotEqual() {
        #expect(ResultState.success(Payload()) != ResultState.success(Payload()))
    }

    /// Void cannot conform to `Equatable`, but has only one value, so it must not count as a change.
    @Test func voidSuccessesAreEqual() {
        #expect(ResultState<Void>.success == .success)
    }

    @Test func equatableSuccessesCompareByValue() {
        #expect(ResultState.success(1) == ResultState.success(1))
        #expect(ResultState.success(1) != ResultState.success(2))
    }

    /// The bug this pins: `@Observable` skips notifying when the new value equals the old one, so a
    /// success that could not be compared and answered `true` left a view on the previous result.
    @Test func replacingASuccessThatCannotBeComparedNotifiesObservers() {
        let state = AsyncState(initialValue: Payload(), animation: nil)
        let didChange = Flag()

        withObservationTracking {
            _ = state.state
        } onChange: {
            didChange.isSet = true
        }

        state.updateState(.success(Payload()))

        #expect(didChange.isSet)
    }
}
