import Testing

@testable import RemindCore
@testable import apple_reminder_cli

@MainActor
struct PermissionsHelpTests {
  @Test("Denied guidance includes terminal prompt workaround")
  func deniedGuidanceIncludesPromptWorkaround() {
    let guidance = PermissionsHelp.guidanceLines(for: .denied).joined(separator: "\n")
    #expect(guidance.contains("osascript"))
    #expect(guidance.contains("Reminders"))
  }
}
