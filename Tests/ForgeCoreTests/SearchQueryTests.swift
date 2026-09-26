// Created by Dino Catalinac on 26.09.2026.

import ForgeCore
import Testing

struct SearchQueryTests {

    @Test(arguments: ["check in", "checkin", "CHECK-IN", "  check   in  ", "check", "in"])
    func matchesRegardlessOfCaseAndSeparators(query: String) {
        #expect(SearchQuery(query).matches("Check-in"))
    }

    @Test
    func matchesWordsInAnyOrder() {
        #expect(SearchQuery("york new").matches("New York"))
    }

    @Test
    func ignoresAccents() {
        #expect(SearchQuery("cafe").matches("Café Crème"))
        #expect(SearchQuery("café").matches("Cafe"))
    }

    @Test
    func requiresEveryWord() {
        #expect(!SearchQuery("new london").matches("New York"))
    }

    @Test(arguments: ["", "   ", "-"])
    func emptyQueryMatchesEverything(query: String) {
        #expect(SearchQuery(query).isEmpty)
        #expect(SearchQuery(query).matches("Anything"))
    }
}
