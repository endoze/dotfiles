# Merges $base[0] into the live settings: base scalars win, objects merge
# recursively, and arrays keep base entries first plus any local extras.
def merge($local; $base):
  if ($local | type) == "object" and ($base | type) == "object" then
    reduce ($base | keys_unsorted[]) as $k ($local;
      .[$k] = (if $local | has($k) then merge($local[$k]; $base[$k]) else $base[$k] end))
  elif ($local | type) == "array" and ($base | type) == "array" then
    reduce $local[] as $x ($base; if any(.[]; . == $x) then . else . + [$x] end)
  else $base
  end;

merge(.; $base[0])
