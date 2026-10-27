# shellcheck shell=bash

# Drops DefaultAPI endpoints which are not in allowedEndpoints.
remove_unused_endpoints() {
  local file="$OUTPUT_DIR/APIs/DefaultAPI.swift"
  local allowed generated missing e
  allowed="$(jq -r '.allowedEndpoints[]' "$ALLOWED_FILE" | sort)"
  generated="$(sed -n '/^protocol DefaultAPIEndpoints {/,$p' "$file" \
    | sed -nE 's/^    func ([a-zA-Z]+)\(.*/\1/p' | sort)"
  missing="$(comm -23 <(echo "$allowed") <(echo "$generated"))"
  if [ -n "$missing" ]; then
    echo "Allowed endpoints missing from DefaultAPI: $missing" >&2
    exit 1
  fi
  for e in $(comm -13 <(echo "$allowed") <(echo "$generated")); do
    awk -v e="$e" '
      $0 ~ "^    open func " e "\\(" { skip = 1; next }
      skip && $0 == "    }"          { skip = 0; next }
      skip                            { next }
      $0 ~ "^    func " e "\\("      { next }
      { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  done
}

# Drops VideoEvent cases which are not in allowedEvents.
remove_unused_events() {
  local file="$OUTPUT_DIR/Models/VideoEvent.swift"
  local allowed generated missing e
  allowed="$(jq -r '.allowedEvents[]' "$ALLOWED_FILE" | sort)"
  generated="$(sed -nE 's/^    case type[A-Za-z]+\(([A-Za-z]+)\)$/\1/p' "$file" | sort)"
  missing="$(comm -23 <(echo "$allowed") <(echo "$generated"))"
  if [ -n "$missing" ]; then
    echo "Allowed events missing from VideoEvent: $missing" >&2
    exit 1
  fi
  for e in $(comm -13 <(echo "$allowed") <(echo "$generated")); do
    EVENT="$e" perl -0777 -pi -e '
      my $e = quotemeta $ENV{EVENT};
      s/^    case type$e\($e\)\n//m;
      s/^        case \.type$e\(let value\):\n.*\n//mg;
      s/^        (\} else )?if dto\.type == "[^"]*" \{\n.*decode\($e\.self\)\n.*\.type$e\(value\)\n//m;
    ' "$file"
  done
  # The decode chain has to start with `if` when its first branch is removed.
  perl -0777 -pi -e 's/(WSEventMapping\.self\)\n        )\} else if/$1if/' "$file"
}

# Drops model properties listed in removedProperties.
remove_properties() {
  local model file p type
  for model in $(jq -r '.removedProperties | keys[]' "$ALLOWED_FILE"); do
    file="$OUTPUT_DIR/Models/$model.swift"
    for p in $(jq -r --arg m "$model" '.removedProperties[$m][]' "$ALLOWED_FILE"); do
      # Deprecated fields get a computed var, which the steps below miss.
      if ! grep -qE "^ +public var $p: [^{]+$" "$file"; then
        echo "Removed property missing or deprecated: $model.$p" >&2
        exit 1
      fi
      type="$(sed -nE "s/^ +public var $p: \[?([A-Za-z]+).*/\1/p" "$file")"
      awk -v p="$p" '
        function flush() { for (i = 1; i <= n; i++) print b[i]; n = 0 }
        { s = $0; sub(/^[[:space:]]+/, "", s) }
        s ~ /^\/\/\//                           { b[++n] = $0; next }
        s ~ "^public var " p ": "               { n = 0; next }
        s ~ "^self\\." p " = " p "$"            { next }
        s ~ "^self\\." p " = try container\\.decode(IfPresent)?\\(.*, forKey: \\." p "\\)$" { next }
        s ~ "^lhs\\." p " == rhs\\." p "( &&)?$" { next }
        s ~ "^hasher\\.combine\\(" p "\\)$"      { next }
        s ~ "^try container\\.encode(IfPresent)?\\(" p ", forKey: \\." p "\\)$" { next }
        s ~ /^public init\(/ {
          sub("\\(" p ": [^,)]*, ", "("); sub(", " p ": [^,)]*", ""); sub("\\(" p ": [^,)]*\\)", "()")
        }
        { flush(); print }
      ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
      # Drop the `&&` left dangling when the last field of an == chain goes.
      perl -0777 -pi -e 's/ &&(\n\s*\})/$1/g' "$file"
      remove_unused_nested_enum "$file" "$type"
    done
  done
}

# Drops a nested enum when nothing else in the file uses it.
remove_unused_nested_enum() {
  local file="$1" type="$2"
  grep -q "^    public enum $type:" "$file" || return 0
  awk -v t="$type" '
    function flush() { for (i = 1; i <= n; i++) print b[i]; n = 0 }
    !skip && /^    \/\/\//            { b[++n] = $0; next }
    $0 ~ "^    public enum " t ":" { n = 0; skip = 1; next }
    skip && $0 == "    }"          { skip = 0; next }
    skip                            { next }
    { flush(); print }
  ' "$file" > "$file.tmp"
  if grep -qw "$type" "$file.tmp"; then rm "$file.tmp"; else mv "$file.tmp" "$file"; fi
}

# Restores the property types listed in retypedProperties.
retype_properties() {
  local model file p old new
  for model in $(jq -r '.retypedProperties | keys[]' "$ALLOWED_FILE"); do
    file="$OUTPUT_DIR/Models/$model.swift"
    for p in $(jq -r --arg m "$model" '.retypedProperties[$m] | keys[]' "$ALLOWED_FILE"); do
      new="$(jq -r --arg m "$model" --arg p "$p" '.retypedProperties[$m][$p]' "$ALLOWED_FILE")"
      old="$(sed -nE "s/^ +public var $p: ([^{]+)$/\1/p" "$file")"
      if [ -z "$old" ]; then
        echo "Retyped property missing or deprecated: $model.$p" >&2
        exit 1
      fi
      # Optional types get a nil default in the init and the IfPresent coders.
      P="$p" O="$old" N="$new" perl -0777 -pi -e '
        my ($p, $o, $n) = ($ENV{P}, $ENV{O}, $ENV{N});
        my $d = $n =~ /\?$/ ? " = nil" : "";
        my $c = $n =~ /\?$/ ? "IfPresent" : "";
        my $t = $n =~ s/\?$//r;
        s/^(\h+public var \Q$p\E: )\Q$o\E$/$1$n/m;
        s/([(,]\h*)\Q$p\E: \Q$o\E(?: = nil)?(?=[,)])/$1$p: $n$d/;
        s/^(\h+self\.\Q$p\E = try container\.decode)(?:IfPresent)?\(.*\.self(, forKey: \.\Q$p\E\))$/$1$c($t.self$2/m;
        s/^(\h+try container\.encode)(?:IfPresent)?(\(\Q$p\E, forKey: \.\Q$p\E\))$/$1$c$2/m;
      ' "$file"
      remove_unused_nested_enum "$file" "$(sed -E 's/^\[?([A-Za-z]+).*/\1/' <<< "$old")"
    done
  done
}

# Drops the enum cases listed in removedEnumCases. Keys are Model or Model.Enum.
remove_enum_cases() {
  local entry model name file c
  for entry in $(jq -r '.removedEnumCases | keys[]' "$ALLOWED_FILE"); do
    model="${entry%%.*}"
    name="${entry#*.}"
    file="$OUTPUT_DIR/Models/$model.swift"
    for c in $(jq -r --arg e "$entry" '.removedEnumCases[$e][]' "$ALLOWED_FILE"); do
      if ! awk -v t="$name" -v c="$c" '
        function flush() { for (i = 1; i <= n; i++) print b[i]; n = 0 }
        !inside && $0 ~ ("^ *public enum " t ":") {
          inside = 1; ind = substr($0, 1, match($0, /[^ ]/) - 1); print; next
        }
        inside && $0 == ind "}"                                         { inside = 0 }
        inside && $0 ~ ("^" ind "    (///|@available)")                 { b[++n] = $0; next }
        inside && $0 ~ ("^" ind "    case " c "( = \"[^\"]*\")?$")    { n = 0; removed = 1; next }
        { flush(); print }
        END { exit !removed }
      ' "$file" > "$file.tmp"; then
        rm "$file.tmp"
        echo "Removed enum case missing: $entry.$c" >&2
        exit 1
      fi
      mv "$file.tmp" "$file"
    done
  done
}

# Drops models which DefaultAPI and VideoEvent do not reach.
remove_unused_models() {
  local models_dir="$OUTPUT_DIR/Models"
  local all reachable previous model
  all="$(ls "$models_dir" | sed 's/\.swift$//' | sort)"
  reachable="VideoEvent"
  until [ "$reachable" = "$previous" ]; do
    previous="$reachable"
    reachable="$(
      sed "s|.*|$models_dir/&.swift|" <<< "$previous" \
        | xargs cat "$OUTPUT_DIR/APIs/DefaultAPI.swift" \
        | grep -vE '^[[:space:]]*//' \
        | grep -oE '[A-Za-z_][A-Za-z0-9_]*' \
        | cat - <(echo "$previous") | sort -u | comm -12 - <(echo "$all")
    )"
  done
  for model in $(comm -23 <(echo "$all") <(echo "$reachable")); do
    rm "$models_dir/$model.swift"
  done
}

# Narrows models to the coding direction DefaultAPI uses. The generator makes
# every model Codable, so the unused coder only adds binary size.
apply_coding_directions() {
  local models_dir="$OUTPUT_DIR/Models"
  local classified generated model
  classified="$(jq -r '.codableModels[], .decodableModels[], .encodableModels[]' "$ALLOWED_FILE" | sort)"
  generated="$(ls "$models_dir" | sed 's/\.swift$//' | sort)"
  # Also fails for a model in more than one list.
  if [ "$classified" != "$generated" ]; then
    echo "Models must be in exactly one coding list (< listed, > generated):" >&2
    diff <(echo "$classified") <(echo "$generated") >&2
    exit 1
  fi
  sed -i '' 's/send<Response: Codable>/send<Response: Decodable>/' "$OUTPUT_DIR/APIs/DefaultAPI.swift"
  for model in $(jq -r '.decodableModels[]' "$ALLOWED_FILE"); do
    narrow_coding "$models_dir/$model.swift" "$model" Decodable
  done
  for model in $(jq -r '.encodableModels[]' "$ALLOWED_FILE"); do
    narrow_coding "$models_dir/$model.swift" "$model" Encodable
  done
}

# Replaces Codable with the given direction and drops the unused coder.
# JSONEncodable goes too for Decodable, its default needs Encodable.
narrow_coding() {
  M="$2" D="$3" perl -0777 -pi -e '
    my ($m, $d) = ($ENV{M}, $ENV{D});
    s/^(public [a-z ]+ \Q$m\E: .*)\bCodable\b/$1$d/m or die "Codable model missing: $m\n";
    if ($d eq "Decodable") {
      s/^(public [a-z ]+ \Q$m\E: .*), JSONEncodable\b/$1/m;
      # Enums with synthesized encoding have no encode(to:).
      s/\n    public func encode\(to encoder: Encoder\) throws \{\n.*?\n    \}\n//s;
    } else {
      s/\n    public init\(from decoder: Decoder\) throws \{\n.*?\n    \}\n//s
        or die "init(from:) missing: $m\n";
    }
  ' "$1"
}

# Moves the endpoints in v2Endpoints to their /api/v2 path, as the SDK uses
# them. The v1 spec lists them under /video.
keep_existing_v2_endpoints() {
  local file="$OUTPUT_DIR/APIs/DefaultAPI.swift"
  local e
  for e in $(jq -r '.v2Endpoints[]' "$ALLOWED_FILE"); do
    if ! awk -v e="$e" '
      $0 ~ "^    open func " e "\\(" { inside = 1 }
      inside && sub(/path = "\/video\//, "path = \"/api/v2/video/") { moved = 1; inside = 0 }
      inside && $0 == "    }"          { inside = 0 }
      { print }
      END { exit !moved }
    ' "$file" > "$file.tmp"; then
      rm "$file.tmp"
      echo "v2 endpoint or its /video path missing: $e" >&2
      exit 1
    fi
    mv "$file.tmp" "$file"
  done
}

# Drops the StringCodingKey lets which no model uses. The generator writes
# one per wire key of every model in the spec.
remove_unused_string_coding_keys() {
  local file="$OUTPUT_DIR/StringCodingKey.swift"
  grep -rhoE 'forKey: \.`?[A-Za-z0-9_]+' "$OUTPUT_DIR/Models" \
    | sed -E 's/.*\.`?//' | sort -u \
    | awk '
      NR == FNR                     { used[$0]; next }
      $1 == "static" && $2 == "let" {
        key = $3; sub(/:$/, "", key); gsub(/`/, "", key)
        if (!(key in used)) next
      }
      { print }
    ' - "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
