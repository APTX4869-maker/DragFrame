import CoreGraphics
import XCTest
@testable import DragFrameCore

final class ModifierShortcutTests: XCTestCase {
    func testDefaultShortcutDisplay() {
        XCTAssertEqual(ModifierShortcut.default.displayString, "⇧⌥")
        XCTAssertEqual(ModifierShortcut.default.spokenDescription, "Shift + Option")
    }

    func testCGEventFlagsConversion() {
        let shortcut = ModifierShortcut(cgEventFlags: [.maskControl, .maskAlternate, .maskShift])
        XCTAssertEqual(shortcut, [.control, .option, .shift])
    }

    func testValidityRejectsEmptyAndUnknownBits() {
        XCTAssertFalse(ModifierShortcut().isValid)
        XCTAssertFalse(ModifierShortcut.control.isValid)
        XCTAssertFalse(ModifierShortcut(rawValue: 1 << 10).isValid)
        XCTAssertTrue(ModifierShortcut.command.isValid)
    }
}

final class DragStateMachineTests: XCTestCase {
    func testDragRequiresConfiguredModifiers() {
        var machine = DragStateMachine()

        XCTAssertEqual(machine.mouseDown(at: .zero, modifiers: .option), .none)
        XCTAssertEqual(
            machine.mouseDragged(to: CGPoint(x: 30, y: 30), modifiers: .option),
            .none
        )
    }

    func testMovementThresholdAndRelease() {
        var machine = DragStateMachine()
        let modifiers: ModifierShortcut = [.shift, .option]

        XCTAssertEqual(machine.mouseDown(at: CGPoint(x: 10, y: 10), modifiers: modifiers), .none)
        XCTAssertEqual(machine.mouseDragged(to: CGPoint(x: 12, y: 11), modifiers: modifiers), .none)
        XCTAssertEqual(
            machine.mouseDragged(to: CGPoint(x: 20, y: 25), modifiers: modifiers),
            .show(CGRect(x: 10, y: 10, width: 10, height: 15))
        )
        XCTAssertEqual(machine.mouseUp(), .hide)
        XCTAssertEqual(machine.mouseUp(), .none)
    }

    func testExtraModifierIsAllowed() {
        var machine = DragStateMachine()
        let modifiers: ModifierShortcut = [.shift, .option, .command]

        _ = machine.mouseDown(at: .zero, modifiers: modifiers)
        XCTAssertEqual(
            machine.mouseDragged(to: CGPoint(x: 10, y: 10), modifiers: modifiers),
            .show(CGRect(x: 0, y: 0, width: 10, height: 10))
        )
    }

    func testReleasingRequiredModifierCancelsVisibleDrag() {
        var machine = DragStateMachine()
        let modifiers: ModifierShortcut = [.shift, .option]

        _ = machine.mouseDown(at: .zero, modifiers: modifiers)
        _ = machine.mouseDragged(to: CGPoint(x: 10, y: 10), modifiers: modifiers)

        XCTAssertEqual(machine.flagsChanged(to: .option), .hide)
        XCTAssertEqual(machine.mouseUp(), .none)
    }

    func testRectNormalizationInAllDirections() {
        let origin = CGPoint(x: 10, y: 20)

        XCTAssertEqual(
            DragStateMachine.normalizedRect(from: origin, to: CGPoint(x: 30, y: 40)),
            CGRect(x: 10, y: 20, width: 20, height: 20)
        )
        XCTAssertEqual(
            DragStateMachine.normalizedRect(from: origin, to: CGPoint(x: -5, y: 2)),
            CGRect(x: -5, y: 2, width: 15, height: 18)
        )
    }
}

final class DragCaptureStateTests: XCTestCase {
    func testDoesNotCaptureWhenRequiredModifiersAreMissing() {
        var state = DragCaptureState()

        XCTAssertFalse(
            state.mouseDown(modifiers: .option, requiredModifiers: [.shift, .option])
        )
        XCTAssertFalse(state.isCapturingMouseSequence)
        XCTAssertFalse(state.mouseDragged())
        XCTAssertFalse(state.mouseUp())
    }

    func testCapturesWholeMouseSequenceWhenShortcutIsHeldAtMouseDown() {
        var state = DragCaptureState()
        let modifiers: ModifierShortcut = [.shift, .option]

        XCTAssertTrue(
            state.mouseDown(modifiers: modifiers, requiredModifiers: [.shift, .option])
        )
        XCTAssertTrue(state.isCapturingMouseSequence)
        XCTAssertTrue(state.mouseDragged())
        XCTAssertTrue(state.mouseUp())
        XCTAssertFalse(state.isCapturingMouseSequence)
    }

    func testExtraModifierStillCapturesSequence() {
        var state = DragCaptureState()
        let modifiers: ModifierShortcut = [.shift, .option, .command]

        XCTAssertTrue(
            state.mouseDown(modifiers: modifiers, requiredModifiers: [.shift, .option])
        )
        XCTAssertTrue(state.mouseDragged())
    }

    func testInvalidRequiredShortcutNeverCaptures() {
        var state = DragCaptureState()

        XCTAssertFalse(
            state.mouseDown(modifiers: .option, requiredModifiers: [])
        )
        XCTAssertFalse(
            state.mouseDown(modifiers: [.control, .option], requiredModifiers: [.control, .option])
        )
    }

    func testCancelEndsCapturedSequence() {
        var state = DragCaptureState()

        XCTAssertTrue(
            state.mouseDown(modifiers: [.shift, .option], requiredModifiers: [.shift, .option])
        )
        state.cancel()

        XCTAssertFalse(state.isCapturingMouseSequence)
        XCTAssertFalse(state.mouseDragged())
        XCTAssertFalse(state.mouseUp())
    }
}

final class CoordinateConverterTests: XCTestCase {
    func testQuartzToAppKitConversion() {
        XCTAssertEqual(
            CoordinateConverter.appKitPoint(
                fromQuartz: CGPoint(x: -200, y: 1200),
                primaryScreenMaxY: 900
            ),
            CGPoint(x: -200, y: -300)
        )
    }
}

final class ShortcutSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "DragFrameCoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testPersistsValidShortcut() {
        let settings = ShortcutSettings(defaults: defaults)
        XCTAssertTrue(settings.set(.command, enabled: true))

        let reloaded = ShortcutSettings(defaults: defaults)
        XCTAssertEqual(reloaded.shortcut, [.shift, .option, .command])
    }

    func testMigratesAnyShortcutContainingControl() {
        let legacy: ModifierShortcut = [.control, .option]
        defaults.set(NSNumber(value: legacy.rawValue), forKey: ShortcutSettings.storageKey)

        let settings = ShortcutSettings(defaults: defaults)

        XCTAssertEqual(settings.shortcut, .default)
        XCTAssertEqual(
            (defaults.object(forKey: ShortcutSettings.storageKey) as? NSNumber)?.uintValue,
            ModifierShortcut.default.rawValue
        )
    }

    func testPreservesSupportedCustomShortcut() {
        let custom: ModifierShortcut = [.command, .option]
        defaults.set(NSNumber(value: custom.rawValue), forKey: ShortcutSettings.storageKey)

        let settings = ShortcutSettings(defaults: defaults)

        XCTAssertEqual(settings.shortcut, custom)
    }

    func testRejectsControlBinding() {
        let settings = ShortcutSettings(defaults: defaults)

        XCTAssertFalse(settings.set(.control, enabled: true))
        XCTAssertEqual(settings.shortcut, .default)
        XCTAssertNotNil(settings.validationMessage)
    }

    func testRejectsRemovingLastModifier() {
        defaults.set(NSNumber(value: ModifierShortcut.command.rawValue), forKey: ShortcutSettings.storageKey)
        let settings = ShortcutSettings(defaults: defaults)

        XCTAssertFalse(settings.set(.command, enabled: false))
        XCTAssertEqual(settings.shortcut, .command)
        XCTAssertNotNil(settings.validationMessage)
    }

    func testResetUsesDefault() {
        let settings = ShortcutSettings(defaults: defaults)
        settings.set(.command, enabled: true)
        settings.resetToDefault()

        XCTAssertEqual(settings.shortcut, .default)
    }
}
