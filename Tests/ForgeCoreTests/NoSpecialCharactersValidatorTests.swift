// Created by Dino Catalinac on 08.10.2026.

import ForgeCore
import Testing

struct NoSpecialCharactersValidatorTests {

    @Test func lettersAndNumbersAlwaysPass() throws {
        try NoSpecialCharactersValidator(inputName: "Name", allowing: []).validate("Squat5x5")
    }

    @Test func hyphensAndUnderscoresAreAllowedByDefault() throws {
        let validator = NoSpecialCharactersValidator(inputName: "Name")

        try validator.validate("push-up_v2")
        #expect(throws: ValidationError.self) { try validator.validate("push up") }
    }

    @Test(arguments: [
        (NoSpecialCharactersValidator.AllowedCharacter.space, "Belt Squat"),
        (.hyphen, "T-Bar"),
        (.underscore, "row_wide"),
        (.apostrophe, "Farmer's"),
        (.apostrophe, "Farmer’s"),
        (.parenthesis, "Squat(Machine)")
    ])
    func eachAllowedCharacterPassesOnlyWhenAllowed(character: NoSpecialCharactersValidator.AllowedCharacter, input: String) throws {
        try NoSpecialCharactersValidator(inputName: "Name", allowing: [character]).validate(input)

        let others = Set(NoSpecialCharactersValidator.AllowedCharacter.allCases).subtracting([character])
        #expect(throws: ValidationError.self) {
            try NoSpecialCharactersValidator(inputName: "Name", allowing: others).validate(input)
        }
    }

    @Test func anythingElseIsRefused() {
        let everything = Set(NoSpecialCharactersValidator.AllowedCharacter.allCases)

        for input in ["Squat!", "Row / V-Grip", "Press.", "A&B"] {
            #expect(throws: ValidationError.self, "\(input)") {
                try NoSpecialCharactersValidator(inputName: "Name", allowing: everything).validate(input)
            }
        }
    }

    @Test func theMessageNamesWhatIsAllowed() {
        #expect(throws: ValidationError.invalidFormat("Name can only contain letters, numbers, spaces, hyphens, and underscores")) {
            try NoSpecialCharactersValidator(inputName: "Name", allowing: [.space, .hyphen, .underscore]).validate("!")
        }
        #expect(throws: ValidationError.invalidFormat("Name can only contain letters and numbers")) {
            try NoSpecialCharactersValidator(inputName: "Name", allowing: []).validate("!")
        }
    }
}
