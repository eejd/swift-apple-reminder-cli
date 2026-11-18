import Commander
import Foundation
import RemindCore

enum ShowCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "show",
      abstract: "Show reminders",
      discussion: "Filters: today, tomorrow, week, overdue, upcoming, open, completed, all, or a date string.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(
              label: "filter",
              help: "today|tomorrow|week|overdue|upcoming|open|completed|all|<date>",
              isOptional: true
            )
          ],
          options: [
            .make(
              label: "list",
              names: [.short("l"), .long("list")],
              help: "Limit to a specific list",
              parsing: .singleValue
            ),
            .make(
              label: "listID",
              names: [.long("list-id")],
              help: "Limit to a list by ID or ID prefix",
              parsing: .singleValue
            ),
          ]
        )
      ),
      usageExamples: [
        "apple_reminder_cli",
        "apple_reminder_cli today",
        "apple_reminder_cli show overdue",
        "apple_reminder_cli show 2026-01-04",
        "apple_reminder_cli show --list Work",
      ]
    ) { values, runtime in
      let listTarget = try CommandHelpers.listTarget(name: values.option("list"), id: values.option("listID"))
      let filterToken = values.argument(0)
      let policy = try ReminderPolicy.load()

      let filter: ReminderFilter
      if let token = filterToken {
        guard let parsed = ReminderFiltering.parse(token) else {
          throw RemindCoreError.operationFailed("Unknown filter: \"\(token)\"")
        }
        filter = parsed
      } else {
        filter = .today
      }

      let store = RemindersStore()
      try await store.requestAccess()
      if let listName = try await CommandHelpers.listTitle(listTarget, store: store) {
        if filter == .completed {
          try policy.ensureAllowed(.readCompleted, forListNamed: listName)
        } else {
          try policy.ensureReadable(listName: listName)
        }
      }

      let reminders = try await store.reminders(matching: listTarget)
      let filtered = ReminderFiltering.apply(policy.filterReadable(reminders), filter: filter)
      OutputRenderer.printReminders(filtered, format: runtime.outputFormat)
    }
  }
}
