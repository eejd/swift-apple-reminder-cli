import Commander
import Foundation
import RemindCore

enum CompletionCommand {
  static var spec: CommandSpec {
    CommandSpec(
      name: "completion",
      abstract: "Generate shell completion",
      discussion: "Prints a generated completion script.",
      signature: CommandSignatures.withRuntimeFlags(
        CommandSignature(
          arguments: [
            .make(label: "shell", help: "zsh|bash", isOptional: true)
          ]
        )
      ),
      usageExamples: [
        "apple_reminder_cli completion zsh",
        "apple_reminder_cli completion bash",
      ]
    ) { values, _ in
      let shell = values.argument(0) ?? "zsh"
      switch shell {
      case "zsh":
        Swift.print(zsh())
      case "bash":
        Swift.print(bash())
      default:
        throw RemindCoreError.operationFailed("Unsupported shell: \(shell) (use zsh|bash)")
      }
    }
  }

  private static var commands: [String] {
    CommandRouter.commandSpecs.map(\.name)
  }

  private static func zsh() -> String {
    """
    #compdef apple_reminder_cli
    _apple_reminder_cli() {
      local -a commands
      commands=(\(commands.map { "'\($0):apple_reminder_cli \($0)'" }.joined(separator: " ")))
      if (( CURRENT == 2 )); then
        _describe 'command' commands
      else
        _arguments '*:argument:_files'
      fi
    }
    _apple_reminder_cli "$@"
    """
  }

  private static func bash() -> String {
    """
    _apple_reminder_cli_completion() {
      local cur="${COMP_WORDS[COMP_CWORD]}"
      if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "\(commands.joined(separator: " "))" -- "$cur") )
      fi
    }
    complete -F _apple_reminder_cli_completion apple_reminder_cli
    """
  }
}
