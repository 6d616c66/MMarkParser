/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Grammar for Shell/Bash scripts. Handles # comments, variables,
/// string interpolation, command substitution, and common shell
/// built-in commands and keywords.
public struct ShellGrammar: Grammar {
    public var delimiters: CharacterSet
    public var syntaxRules: [SyntaxRule]

    public init() {
        var delimiters = CharacterSet.alphanumerics.inverted
        delimiters.remove("_")
        delimiters.remove("\"")
        delimiters.remove("'")
        delimiters.remove("`")
        delimiters.remove("$")
        delimiters.remove("#")
        delimiters.remove("-")
        delimiters.remove(".")
        delimiters.remove("/")
        self.delimiters = delimiters

        syntaxRules = [
            CommentRule(),
            DoubleQuoteStringRule(),
            SingleQuoteStringRule(),
            BacktickRule(),
            VariableRule(),
            NumberRule(),
            CallRule(),
            KeywordRule()
        ]
    }

    public func isDelimiter(_ delimiterA: Character,
                            mergableWith delimiterB: Character) -> Bool {
        switch (delimiterA, delimiterB) {
        case ("#", _):
            return delimiterB == "!"
        case ("$", _):
            return delimiterB == "{" || delimiterB == "("
        case ("-", _):
            return delimiterB == "-"
        case (".", _):
            return delimiterB == "/" || delimiterB == "."
        case ("/", _):
            return delimiterB == "/"
        case ("{", _), ("}", _):
            return false
        case ("[", _), ("]", _):
            return false
        case ("(", _), (")", _):
            return false
        default:
            return true
        }
    }
}

private extension ShellGrammar {
    static let keywords: Set<String> = [
        "if", "then", "else", "elif", "fi", "case", "esac",
        "for", "while", "until", "do", "done", "in",
        "select", "function", "return", "exit", "continue",
        "break", "declare", "local", "export", "readonly",
        "source", ".", "eval", "exec", "trap", "wait",
        "typeset", "unset", "set", "shift", "let", "read",
        "printf", "echo", "test", "[", "]]",
        "true", "false", "then", "time"
    ]

    /// Common shell built-in commands treated as keywords
    static let builtins: Set<String> = [
        "cd", "pwd", "ls", "cat", "grep", "sed", "awk", "find",
        "cp", "mv", "rm", "mkdir", "rmdir", "touch", "chmod",
        "chown", "ln", "tar", "gzip", "gunzip", "unzip",
        "head", "tail", "sort", "uniq", "wc", "cut", "tr",
        "diff", "patch", "comm", "tee", "xargs", "basename",
        "dirname", "realpath", "readlink", "which", "whereis",
        "type", "hash", "alias", "unalias", "bind", "help",
        "enable", "fc", "history", "disown", "fg", "bg",
        "jobs", "kill", "nice", "renice", "nohup", "timeout",
        "sleep", "date", "cal", "df", "du", "free", "uptime",
        "env", "printenv", "hostname", "id", "whoami", "who",
        "w", "last", "ps", "top", "htop", "lsof", "ulimit",
        "umask", "mkfifo", "mknod", "yes", "expr", "bc",
        "curl", "wget", "ssh", "scp", "rsync", "docker",
        "git", "npm", "npx", "yarn", "pip", "pip3", "brew",
        "apt", "apt-get", "yum", "dnf", "pacman", "cargo",
        "go", "rustc", "python", "python3", "node", "deno",
        "sudo", "su", "chsh", "passwd", "useradd", "usermod",
        "groupadd", "systemctl", "service", "journalctl"
    ]

    struct CommentRule: SyntaxRule {
        var tokenType: TokenType { return .comment }

        func matches(_ segment: Segment) -> Bool {
            // Single-line # comments (except shebang which starts with #!)
            if segment.tokens.current == "#" {
                return segment.tokens.next != "!"
            }
            if segment.tokens.current.hasPrefix("#") && !segment.tokens.current.hasPrefix("#!") {
                return true
            }
            if segment.tokens.onSameLine.contains(anyOf: "#") {
                return true
            }
            return false
        }
    }

    struct DoubleQuoteStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("\"") &&
               segment.tokens.current.hasSuffix("\"") {
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "\"", end: "\"") else {
                return false
            }
            return true
        }
    }

    struct SingleQuoteStringRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.hasPrefix("'") &&
               segment.tokens.current.hasSuffix("'") {
                return true
            }
            guard segment.isWithinStringLiteral(withStart: "'", end: "'") else {
                return false
            }
            return true
        }
    }

    struct BacktickRule: SyntaxRule {
        var tokenType: TokenType { return .string }

        func matches(_ segment: Segment) -> Bool {
            let startCount = segment.tokens.count(of: "`")
            return !startCount.isEven
        }
    }

    struct VariableRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            // $VAR, ${VAR}
            if token.hasPrefix("$") && token.count > 1 {
                return true
            }
            return false
        }
    }

    struct NumberRule: SyntaxRule {
        var tokenType: TokenType { return .number }

        func matches(_ segment: Segment) -> Bool {
            if segment.tokens.current.removing("_").isNumber {
                return true
            }
            guard segment.tokens.current == "." else {
                return false
            }
            guard let previous = segment.tokens.previous,
                  let next = segment.tokens.next else {
                return false
            }
            return previous.isNumber && next.isNumber
        }
    }

    struct CallRule: SyntaxRule {
        var tokenType: TokenType { return .call }

        func matches(_ segment: Segment) -> Bool {
            let token = segment.tokens.current
            guard token.startsWithLetter || token.first == "_" || token.first == "." else {
                return false
            }
            guard !keywords.contains(token) else {
                return false
            }
            guard builtins.contains(token) else {
                return false
            }
            // At start of command or after pipe/&&/||/;
            guard let previous = segment.tokens.previous else {
                return true
            }
            let commandSeparators: Set<String> = ["|", "&&", "||", ";", "|&", "(", "{"]
            guard commandSeparators.contains(previous) else {
                // Check if it's the first token on the line
                if segment.tokens.onSameLine.isEmpty {
                    return true
                }
                let lineStart = segment.tokens.onSameLine.first ?? ""
                return commandSeparators.contains(lineStart)
            }
            return true
        }
    }

    struct KeywordRule: SyntaxRule {
        var tokenType: TokenType { return .keyword }

        func matches(_ segment: Segment) -> Bool {
            return keywords.contains(segment.tokens.current)
        }
    }
}

private extension Segment {
    func isWithinStringLiteral(withStart start: String, end: String) -> Bool {
        if tokens.current.hasPrefix(start) {
            return true
        }
        if tokens.current.hasSuffix(end) {
            return true
        }
        var markerCounts = (start: 0, end: 0)
        for token in tokens.onSameLine {
            if token == start {
                if start != end || markerCounts.start == markerCounts.end {
                    markerCounts.start += 1
                } else {
                    markerCounts.end += 1
                }
            } else if token == end && start != end {
                markerCounts.end += 1
            } else {
                if token.hasPrefix(start) {
                    markerCounts.start += 1
                }
                if token.hasSuffix(end) {
                    markerCounts.end += 1
                }
            }
        }
        return markerCounts.start != markerCounts.end
    }
}