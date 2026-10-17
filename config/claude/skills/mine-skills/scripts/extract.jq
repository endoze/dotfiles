# Turns transcript lines into signal records for render.jq.
# Input: raw lines (jq -R). Args: $since, $until as YYYY-MM-DDTHH:MM:SSZ.

def project:
  (.cwd // "")
  | sub("/\\.claude/worktrees/.*$"; "")
  | sub("/\\.worktrees/.*$"; "")
  | ((split("/") | last) // "")
  | if . == "" then "unknown" else . end;

def texts:
  .message.content
  | if type == "string" then .
    elif type == "array" then .[] | select(type == "object" and .type == "text") | .text
    else empty end;

def noise:
  sub("^\\s+"; "")
  | startswith("<")
    or startswith("[Request interrupted")
    or startswith("Base directory for this skill")
    or startswith("This session is being continued");

def normalize:
  ascii_downcase
  | gsub("’"; "'")
  | gsub("https?://\\S+"; "<url>")
  | gsub("(?:~|\\.\\.?)?/?[\\w.@-]+(?:/[\\w.@-]+)+/?"; "<path>")
  | gsub("\\b[a-z][a-z0-9]*-[0-9]+\\b"; "<key>")
  | gsub("[0-9]+"; "<n>")
  | gsub("\\s+"; " ")
  | sub("^ "; "")
  | sub("[\\s.!?,;:]+$"; "");

def plumbing:
  ["cat", "sed", "grep", "rg", "head", "tail", "ls", "find", "fd", "echo", "printf", "wc",
   "awk", "sort", "uniq", "cut", "tr", "xargs", "tee", "cd", "pwd", "which", "type", "true",
   "false", "sleep", "test", "for", "while", "do", "done", "if", "then", "else", "fi",
   "export", "set", "source", "mkdir", "rm", "cp", "mv", "touch", "chmod", "diff", "stat",
   "file", "date", "env", "time", "perl", "ruby", "node", "python", "python3"];

def command_key:
  [split("\n")[0]
    | gsub("'[^']*'"; "''")
    | gsub("\"(?:[^\"\\\\]|\\\\.)*\""; "\"\"")
    | splits("\\s*(?:&&|\\|\\||;|\\|)\\s*")
    | sub("^\\s*(?:[A-Za-z_][A-Za-z0-9_]*=\\S*\\s*)+"; "")
    | [splits("\\s+") | select(length > 0)] as $tokens
    | select($tokens | length > 0)
    | ($tokens[0] | split("/") | last) as $tool
    | select(($tool | test("^[A-Za-z0-9_.][A-Za-z0-9_.+-]*$")) and (any(plumbing[]; . == $tool) | not))
    | [$tool] + [$tokens[1:][] | select(test("^[a-z][a-z0-9-]*$"))][:2]
    | join(" ")]
  | first // "";

fromjson?
| select(type == "object")
| select(.type == "user" or .type == "assistant")
| select(.isSidechain != true and .isMeta != true)
| select((.timestamp | type) == "string")
| select(.timestamp[0:19] >= $since[0:19] and .timestamp[0:19] < $until[0:19])
| {s: (.sessionId // ""), p: project, d: .timestamp[0:10]} as $at
| if .type == "user" then
    ($at + {k: "e"}),
    (texts as $text
      | ($text | [scan("<command-name>([^<]+)</command-name>")[0]] | .[] | $at + {k: "c", v: .}),
        ($text
          | select(noise | not)
          | normalize
          | select(length > 0) as $v
          | $at + {k: "p", v: $v, raw: ($text | gsub("\\s+"; " ") | sub("^ "; "") | .[0:200])}))
  else
    .message.content
    | if type == "array" then .[] else empty end
    | select(type == "object" and .type == "tool_use")
    | if .name == "Skill" then
        ((.input.skill // "") | tostring) as $skill
        | select($skill != "")
        | $at + {k: "k", v: $skill}
      elif .name == "Bash" then
        ((.input.command // "") | tostring) as $command
        | ($command | command_key) as $key
        | select($key != "")
        | $at + {k: "b", v: $key, raw: ($command | split("\n")[0] | .[0:120])}
      else empty end
  end
