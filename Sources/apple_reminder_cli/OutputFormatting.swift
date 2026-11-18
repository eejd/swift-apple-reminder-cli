import Foundation
import RemindCore

enum OutputFormat: Equatable {
  case standard
  case table
  case plain
  case json
  case quiet
}

struct ListSummary: Codable, Sendable, Equatable {
  let id: String
  let title: String
  let reminderCount: Int
  let overdueCount: Int
}

struct AuthorizationSummary: Codable, Sendable, Equatable {
  let status: String
  let authorized: Bool
}

struct PolicyListSummary: Codable, Sendable, Equatable {
  let name: String
  let configured: ReminderPolicyRule?
  let effective: EffectiveReminderPolicyRule
}

struct PolicySummary: Codable, Sendable, Equatable {
  let path: String
  let authorizationStatus: String
  let defaults: EffectiveReminderPolicyRule
  let lists: [PolicyListSummary]
}

enum OutputRenderer {
  static func printReminders(_ reminders: [ReminderItem], format: OutputFormat) {
    switch format {
    case .standard:
      printRemindersStandard(reminders)
    case .table:
      printRemindersTable(reminders)
    case .plain:
      printRemindersPlain(reminders)
    case .json:
      printJSON(reminders)
    case .quiet:
      Swift.print(reminders.count)
    }
  }

  static func printSearchResults(_ reminders: [ReminderItem], format: OutputFormat) {
    if format == .standard {
      printSearchResultsStandard(reminders)
    } else {
      printReminders(reminders, format: format)
    }
  }

  static func printReminder(_ reminder: ReminderItem, format: OutputFormat) {
    switch format {
    case .standard:
      let due =
        reminder.dueDate.map {
          DateParsing.formatDisplay($0, isDateOnly: reminder.dueDateIsAllDay)
        } ?? "no due date"
      let recurrence = recurrenceSuffix(for: reminder)
      Swift.print("✓ \(reminder.title) [\(reminder.listName)] — \(due)\(recurrence)")
    case .table:
      printRemindersTable([reminder])
    case .plain:
      Swift.print(plainLine(for: reminder))
    case .json:
      printJSON(reminder)
    case .quiet:
      break
    }
  }

  static func printReminderDetail(_ reminder: ReminderItem, format: OutputFormat) {
    switch format {
    case .standard, .table:
      printReminderDetailStandard(reminder)
    case .plain:
      Swift.print(plainLine(for: reminder))
    case .json:
      printJSON(reminder)
    case .quiet:
      Swift.print(reminder.id)
    }
  }

  static func printDeleteResult(_ count: Int, format: OutputFormat) {
    switch format {
    case .standard, .table:
      Swift.print("Deleted \(count) reminder(s)")
    case .plain:
      Swift.print("\(count)")
    case .json:
      let payload = ["deleted": count]
      printJSON(payload)
    case .quiet:
      break
    }
  }

  static func printAuthorizationStatus(_ status: RemindersAuthorizationStatus, format: OutputFormat) {
    switch format {
    case .standard, .table:
      Swift.print("Reminders access: \(status.displayName)")
    case .plain:
      Swift.print(status.rawValue)
    case .json:
      printJSON(AuthorizationSummary(status: status.rawValue, authorized: status.isAuthorized))
    case .quiet:
      Swift.print(status.isAuthorized ? "1" : "0")
    }
  }

  static func printPolicy(_ summary: PolicySummary, format: OutputFormat) {
    switch format {
    case .standard, .table:
      printPolicyStandard(summary)
    case .plain:
      printPolicyPlain(summary)
    case .json:
      printJSON(summary)
    case .quiet:
      Swift.print(summary.lists.count)
    }
  }

  static func printPolicyLists(_ entries: [PolicyListEntry], format: OutputFormat) {
    switch format {
    case .standard, .table:
      if entries.isEmpty {
        Swift.print("No lists found")
        return
      }
      for entry in entries.sorted(by: { $0.name < $1.name }) {
        Swift.print("\(entry.name)\(entry.hasOverride ? " [override]" : "")")
      }
    case .plain:
      for entry in entries.sorted(by: { $0.name < $1.name }) {
        Swift.print("\(entry.name)\t\(entry.hasOverride ? "1" : "0")")
      }
    case .json:
      printJSON(entries)
    case .quiet:
      Swift.print(entries.count)
    }
  }

  private static func printRemindersStandard(_ reminders: [ReminderItem]) {
    let sorted = ReminderFiltering.sort(reminders)
    guard !sorted.isEmpty else {
      Swift.print("No reminders found")
      return
    }
    for (index, reminder) in sorted.enumerated() {
      Swift.print("[\(index + 1)] \(standardLine(for: reminder))")
    }
  }

  private static func printRemindersPlain(_ reminders: [ReminderItem]) {
    let sorted = ReminderFiltering.sort(reminders)
    for reminder in sorted {
      Swift.print(plainLine(for: reminder))
    }
  }

  private static func printRemindersTable(_ reminders: [ReminderItem]) {
    let sorted = ReminderFiltering.sort(reminders)
    guard !sorted.isEmpty else {
      Swift.print("No reminders found")
      return
    }
    Swift.print(["ID", "Status", "Due", "Priority", "List", "Title"].joined(separator: "\t"))
    for reminder in sorted {
      let due =
        reminder.dueDate.map {
          DateParsing.formatDisplay($0, isDateOnly: reminder.dueDateIsAllDay)
        } ?? ""
      Swift.print(
        [
          shortID(reminder.id),
          reminder.isCompleted ? "done" : "open",
          due,
          reminder.priority == .none ? "" : reminder.priority.rawValue,
          reminder.listName,
          reminder.title,
        ].joined(separator: "\t"))
    }
  }

  private static func printSearchResultsStandard(_ reminders: [ReminderItem]) {
    let sorted = ReminderFiltering.sort(reminders)
    guard !sorted.isEmpty else {
      Swift.print("No reminders found")
      return
    }
    for reminder in sorted {
      Swift.print("\(standardLine(for: reminder)) id=\(reminder.id)")
    }
  }

  private static func standardLine(for reminder: ReminderItem) -> String {
    let status = reminder.isCompleted ? "x" : " "
    let due =
      reminder.dueDate.map {
        DateParsing.formatDisplay($0, isDateOnly: reminder.dueDateIsAllDay)
      } ?? "no due date"
    let priority = reminder.priority == .none ? "" : " priority=\(reminder.priority.rawValue)"
    let recurrence = recurrenceSuffix(for: reminder)
    return "[\(status)] \(reminder.title) [\(reminder.listName)] — \(due)\(priority)\(recurrence)"
  }

  private static func printReminderDetailStandard(_ reminder: ReminderItem) {
    Swift.print("ID: \(reminder.id)")
    Swift.print("Title: \(reminder.title)")
    Swift.print("List: \(reminder.listName)")
    Swift.print("Status: \(reminder.isCompleted ? "completed" : "open")")
    Swift.print("Priority: \(reminder.priority.rawValue)")

    if let dueDate = reminder.dueDate {
      Swift.print("Due: \(DateParsing.formatDisplay(dueDate, isDateOnly: reminder.dueDateIsAllDay))")
    }
    if let alarmDate = reminder.alarmDate {
      Swift.print("Alarm: \(DateParsing.formatDisplay(alarmDate))")
    }
    if let recurrenceRule = reminder.recurrenceRule {
      Swift.print("Repeat: \(recurrenceRule.displayString)")
    }
    if let locationTrigger = reminder.locationTrigger {
      Swift.print(
        "Location: \(locationTrigger.address) (\(locationTrigger.proximity.rawValue), \(locationTrigger.radius)m)")
    }
    if let url = reminder.url {
      Swift.print("URL: \(url.absoluteString)")
    }
    if let creationDate = reminder.creationDate {
      Swift.print("Created: \(DateParsing.formatDisplay(creationDate))")
    }
    if let lastModifiedDate = reminder.lastModifiedDate {
      Swift.print("Modified: \(DateParsing.formatDisplay(lastModifiedDate))")
    }
    if let completionDate = reminder.completionDate {
      Swift.print("Completed: \(DateParsing.formatDisplay(completionDate))")
    }
    if let notes = reminder.notes, !notes.isEmpty {
      Swift.print("Notes:")
      Swift.print(notes)
    }
  }

  private static func plainLine(for reminder: ReminderItem) -> String {
    let due: String
    if let dueDate = reminder.dueDate {
      due =
        reminder.dueDateIsAllDay
        ? dateOnlyFormatter().string(from: dueDate)
        : isoFormatter().string(from: dueDate)
    } else {
      due = ""
    }
    return [
      reminder.id,
      reminder.listName,
      reminder.isCompleted ? "1" : "0",
      reminder.priority.rawValue,
      due,
      reminder.title,
    ].joined(separator: "\t")
  }

  private static func printPolicyStandard(_ summary: PolicySummary) {
    Swift.print("Policy file: \(summary.path)")
    Swift.print("Reminders access: \(summary.authorizationStatus)")
    Swift.print("")
    Swift.print("Defaults:")
    for capability in ReminderPolicyCapability.allCases {
      Swift.print("  \(capability.rawValue): \(summary.defaults.value(for: capability) ? "allow" : "deny")")
    }

    if summary.lists.isEmpty {
      Swift.print("")
      Swift.print("Lists:")
      Swift.print("  No list-specific policy entries")
      return
    }

    Swift.print("")
    Swift.print("Lists:")
    for list in summary.lists.sorted(by: { $0.name < $1.name }) {
      Swift.print("  \(list.name)")
      if let configured = list.configured {
        Swift.print("    overrides: \(configuredOverrideString(configured))")
      } else {
        Swift.print("    overrides: (none)")
      }
      Swift.print("    effective: \(effectiveRuleString(list.effective))")
    }
  }

  private static func printPolicyPlain(_ summary: PolicySummary) {
    Swift.print(["path", summary.path, summary.authorizationStatus].joined(separator: "\t"))
    Swift.print(["defaults", effectiveRuleString(summary.defaults)].joined(separator: "\t"))
    for list in summary.lists.sorted(by: { $0.name < $1.name }) {
      let configured = list.configured.map(configuredOverrideString) ?? ""
      Swift.print(["list", list.name, configured, effectiveRuleString(list.effective)].joined(separator: "\t"))
    }
  }

  private static func configuredOverrideString(_ rule: ReminderPolicyRule) -> String {
    let parts = ReminderPolicyCapability.allCases.compactMap { capability -> String? in
      guard let value = rule.configuredValue(for: capability) else { return nil }
      return "\(capability.rawValue)=\(value ? "allow" : "deny")"
    }
    return parts.isEmpty ? "(none)" : parts.joined(separator: ", ")
  }

  private static func effectiveRuleString(_ rule: EffectiveReminderPolicyRule) -> String {
    ReminderPolicyCapability.allCases
      .map { "\($0.rawValue)=\(rule.value(for: $0) ? "allow" : "deny")" }
      .joined(separator: ", ")
  }

  static func printJSON<T: Encodable>(_ payload: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(payload)
      if let json = String(data: data, encoding: .utf8) {
        Swift.print(json)
      }
    } catch {
      Swift.print("Failed to encode JSON: \(error)")
    }
  }

  private static func isoFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }

  private static func dateOnlyFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }

  private static func recurrenceSuffix(for reminder: ReminderItem) -> String {
    reminder.recurrenceRule.map { " repeat=\($0.displayString)" } ?? ""
  }

  private static func shortID(_ id: String) -> String {
    String(id.prefix(8))
  }
}
