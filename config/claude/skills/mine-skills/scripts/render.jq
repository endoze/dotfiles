# Renders extract.jq records as the mine-skills digest.
# Input: an array of records (jq -s). Args: $since, $until, $installed.

def tsv: map(tostring) | join("\t");

def table($title; $header; $rows):
  "## \($title)", ($header | join("\t")), ($rows[:40][] | tsv), "";

def counted(key):
  group_by(key)
  | map({
      key: (.[0] | key),
      count: length,
      sessions: (map(.s) | unique | length),
      projects: (map(.p) | unique | length),
      first: .[0]
    })
  | sort_by([-.count, -.sessions]);

def correction:
  test("^(no|nope|don't|do not|stop|never|wrong|actually|instead|why did you|i said|i told you|that's not|not what)\\b")
  or test("too much|too dense|too long|simpler");
. as $records
| (reduce ($records[] | select(.k == "e")) as $r ({}; if has($r.s) then . else .[$r.s] = $r.p end)) as $home
| [$records[] | .p = ($home[.s] // .p)] as $records
| [$records[] | select(.k == "e")] as $entries
| [$records[] | select(.k == "p")] as $prompts
| [$records[] | select(.k == "c")] as $slash
| [$records[] | select(.k == "b")] as $commands
| ([$records[] | select(.k == "k")]
    + [$slash[]
        | (.v | ltrimstr("/")) as $name
        | select(($installed | any(.name == $name)) or ($name | contains(":")))
        | . + {v: $name}]) as $skill_uses
| "# mine-skills digest",
  "window: \($since) .. \($until)",
  "sessions: \($entries | map(.s) | unique | length)  prompts: \($prompts | length)  projects: \($entries | map(.p) | unique | length)",
  "",
  if ($entries | length) == 0 then
    "nothing new since \($since)"
  else
    table("Projects"; ["sessions", "prompts", "last_active", "project"];
      $entries
      | group_by(.p)
      | map(.[0].p as $project
          | [ (map(.s) | unique | length),
              ([$prompts[] | select(.p == $project)] | length),
              (map(.d) | max),
              $project ])
      | sort_by([-.[0], -.[1]])),
    table("Slash commands"; ["count", "sessions", "command"];
      $slash | counted(.v) | map([.count, .sessions, .key])),
    table("Repeated prompts"; ["count", "sessions", "projects", "prompt"];
      $prompts | counted(.v) | map(select(.count >= 3) | [.count, .sessions, .projects, .key[0:200]])),
    table("Prompt openers"; ["count", "opener"];
      [$prompts[]
        | (.v | split(" ")) as $words
        | select($words | length >= 5)
        | . + {o: ($words[:5] | join(" "))}]
      | counted(.o) | map(select(.count >= 4) | [.count, .key])),
    table("Commands"; ["count", "sessions", "projects", "key", "example"];
      $commands | counted(.v) | map(select(.count >= 5) | [.count, .sessions, .projects, .key, .first.raw])),
    table("Corrections"; ["date", "project", "prompt"];
      [$prompts[] | select(.v | correction)] | sort_by(.d) | reverse | map([.d, .p, .raw])),
    table("Skill usage"; ["count", "skill"];
      $skill_uses | counted(.v) | map([.count, .key])),
    table("Unused skills"; ["skill", "changed_in_window"];
      ($skill_uses | map(.v)) as $used
      | [$installed[] | select(.name as $name | any($used[]; . == $name) | not) | [.name, .changed]]
      | sort)
  end
