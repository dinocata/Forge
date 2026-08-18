import Foundation
import ForgeCore
import Testing

/// What happens to a state when one operation is asked for while another is still in flight.
///
/// The rule is that the most recently started operation owns the state, and no earlier one may
/// write to it — not its result, not its loading, and not the state it captured on the way in.
@MainActor
struct AsyncStateSupersessionTests {

    /// A parked operation, so "still in flight" is arranged rather than raced for.
    private final class Gate {
        private var continuation: CheckedContinuation<Void, Never>?
        private var isOpen = false

        func wait() async {
            guard !isOpen else { return }
            await withCheckedContinuation { continuation = $0 }
        }

        func open() {
            isOpen = true
            continuation?.resume()
            continuation = nil
        }
    }

    /// The bug this pins: a superseded operation unwinds into `resetOnCancellation` and writes the
    /// state it captured before the newer one existed, undoing a result the user is looking at.
    @Test(.timeLimit(.minutes(1)))
    func aSupersededOperationCannotUndoTheOneThatReplacedIt() async {
        let state = AsyncState<Int>()
        let gate = Gate()

        let superseded = Task {
            await state.perform {
                await gate.wait()
                return 1
            }
        }

        // Let the first operation reach its park before the second is asked for.
        await Task.yield()
        superseded.cancel()

        await state.perform { 2 }
        gate.open()
        _ = await superseded.value

        #expect(state.value == 2)
    }

    /// The same rule for an operation that is slow rather than cancelled: it finished last, but it
    /// stopped owning the state the moment the next one was asked for.
    @Test(.timeLimit(.minutes(1)))
    func aLateResultFromAnEarlierOperationIsDropped() async {
        let state = AsyncState<Int>()
        let gate = Gate()

        let slow = Task {
            await state.perform {
                await gate.wait()
                return 1
            }
        }

        await Task.yield()
        await state.perform { 2 }
        gate.open()
        _ = await slow.value

        #expect(state.value == 2)
    }

    /// Superseding is not the same as the caller giving up: a `.task` that is cancelled because its
    /// view went away still expects the state it found to be put back.
    @Test(.timeLimit(.minutes(1)))
    func aCallerCancellingOnItsOwnStillRestoresTheStateItFound() async {
        let state = AsyncState(initialValue: 7)
        let gate = Gate()

        let cancelled = Task {
            await state.perform {
                await gate.wait()
                return 1
            }
        }

        await Task.yield()
        cancelled.cancel()
        gate.open()
        _ = await cancelled.value

        #expect(state.value == 7)
    }
}
