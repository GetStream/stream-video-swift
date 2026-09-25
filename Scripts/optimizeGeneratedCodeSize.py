#!/usr/bin/env python3
"""
Re-applies the binary-size optimisations we make on top of the OpenAPI
generator output.

`Scripts/generateCode.sh` overwrites everything under
`Sources/StreamVideo/OpenApi/generated`, so any size work done by hand is lost
on the next regeneration. This script is run right after the copy step to put
it back, and fails loudly when the generator output no longer matches what it
expects - that is the signal to revisit the transformation rather than to
silently ship a bigger binary.

Transformations:

1. `CodingKeys` drops `CaseIterable`. Nothing reads `CodingKeys.allCases`, but
   the conformance costs a witness table and a static array per model.
2. `DefaultAPI.send` stops carrying the middleware chain in its generic body,
   and the per-path-parameter escaping collapses into one helper. Both are
   internal; the public API is untouched.
3. Models split `Codable` into `Encodable` (requests) and `Decodable`
   (responses). See "Conformance split" below - this one *does* change the
   public API, which is why it is locked.

Usage:
    Scripts/optimizeGeneratedCodeSize.py
    Scripts/optimizeGeneratedCodeSize.py --update-conformance-lock
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GENERATED = ROOT / "Sources/StreamVideo/OpenApi/generated"
DEFAULT_API = GENERATED / "APIs/DefaultAPI.swift"
MODELS = GENERATED / "Models"
CONFORMANCE_LOCK = Path(__file__).resolve().parent / "generated-model-conformance.json"

# ---------------------------------------------------------------------------
# Conformance split
# ---------------------------------------------------------------------------
#
# A model only needs `Decodable` if the SDK decodes it and only `Encodable` if
# the SDK encodes it. Dropping the unused half removes the synthesised
# `init(from:)` or `encode(to:)` and its witness tables.
#
# The classification is *derived*, not hand-maintained: we take the types the
# generated client decodes (response bodies) and the types it encodes (request
# bodies) as roots, then close each set over stored-property types - a
# `Decodable` class needs every property type to be `Decodable` too.
#
# Two things are worth understanding before changing any of this:
#
# * `JSONEncodable` cannot outlive `Encodable`. StreamCore supplies
#   `encodeToJSON()` only through `extension JSONEncodable where Self:
#   Encodable`, so a model that drops `Encodable` drops `JSONEncodable` with
#   it - two public conformances, not one.
# * The split is a source-breaking change for apps that encode a response or
#   decode a request. That is what `ALWAYS_CODABLE` below is for, and why the
#   result is locked to a checked-in file: a spec change must never silently
#   move a public type from `Codable` to `Decodable`.

# Models that keep the full `Codable` conformance regardless of how the SDK
# itself uses them, together with everything they contain.
#
# This is a product decision, not a derived fact. The current entries are the
# types Stream's own code and test suite encode, which is a usable proxy for
# what apps encode - a response an app caches or an event it logs for
# analytics. Extend this list rather than weakening the derivation.
ALWAYS_CODABLE = {
    # Encoded by StreamVideoTests to build HTTP fixtures.
    "GetCallResponse",
    "GetEdgesResponse",
    "QueryCallsResponse",
    "RejectCallResponse",
    # Encoded by StreamVideoTests to build WebSocket fixtures.
    "CallModerationBlurEvent",
    "ConnectedEvent",
    "ConnectionErrorEvent",
    "HealthCheckEvent",
}

# Enums carry hand-written coding members that the split would have to rewrite.
# `VideoEvent` is handled explicitly below; every other enum stays `Codable`.
SPLITTABLE_ENUMS = {"VideoEvent"}


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def load_models() -> dict:
    """name -> {"path", "is_class", "properties": [type strings]}"""
    models = {}
    for path in sorted(MODELS.glob("*.swift")):
        source = path.read_text()
        match = re.search(r"^public (final class|enum) (\w+)", source, re.M)
        if not match:
            continue
        properties = [t.strip() for _, t in re.findall(r"^    public var (\w+): (.+?)$", source, re.M)]
        # Enum payloads reference models the same way stored properties do.
        properties += re.findall(r"^    case \w+\((\w+)\)$", source, re.M)
        models[match.group(2)] = {
            "path": path,
            "is_class": match.group(1) == "final class",
            "properties": properties,
        }
    return models


def classify(models: dict) -> dict:
    """name -> "codable" | "decodable" | "encodable" """
    names = set(models)
    contains = {
        name: set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", " ".join(info["properties"]))) & names
        for name, info in models.items()
    }

    api = DEFAULT_API.read_text()
    decoded = set(re.findall(r"jsonDecoder\.decode\((\w+)\.self", api)) & names
    encoded = set()
    for endpoint in re.finditer(r"open func \w+\((.*?)\) async throws -> \w+ \{(.*?)\n    \}", api, re.S):
        signature, body = endpoint.group(1), endpoint.group(2)
        for parameter in re.findall(r"request: (\w+)\n", body):
            declared = re.search(r"\b" + re.escape(parameter) + r": (\w+)", signature)
            if declared and declared.group(1) in names:
                encoded.add(declared.group(1))

    # Anything the SDK decodes outside the generated client (WebSocket events).
    for swift in (ROOT / "Sources").rglob("*.swift"):
        if MODELS in swift.parents:
            continue
        for match in re.finditer(r"decode(?:IfPresent)?\((\w+)\.self", swift.read_text()):
            if match.group(1) in names:
                decoded.add(match.group(1))

    unknown = ALWAYS_CODABLE - names
    if unknown:
        fail(f"ALWAYS_CODABLE names models that no longer exist: {sorted(unknown)}")
    decoded |= ALWAYS_CODABLE
    encoded |= ALWAYS_CODABLE

    def close_over(roots: set) -> set:
        seen, pending = set(), list(roots)
        while pending:
            name = pending.pop()
            if name in seen:
                continue
            seen.add(name)
            pending.extend(contains.get(name, ()))
        return seen

    decodable, encodable = close_over(decoded), close_over(encoded)

    result = {}
    for name, info in models.items():
        if not info["is_class"] and name not in SPLITTABLE_ENUMS:
            result[name] = "codable"
        elif name in decodable and name in encodable:
            result[name] = "codable"
        elif name in decodable:
            result[name] = "decodable"
        elif name in encodable:
            result[name] = "encodable"
        else:
            # Unreachable from either direction - keep both halves rather than
            # guess which one an app relies on.
            result[name] = "codable"
    return result


def check_lock(classification: dict, update: bool) -> None:
    if update:
        CONFORMANCE_LOCK.write_text(json.dumps(classification, indent=2, sort_keys=True) + "\n")
        print(f"Wrote {CONFORMANCE_LOCK.relative_to(ROOT)} ({len(classification)} models).")
        return

    if not CONFORMANCE_LOCK.exists():
        fail(f"{CONFORMANCE_LOCK.relative_to(ROOT)} is missing - run with --update-conformance-lock.")

    locked = json.loads(CONFORMANCE_LOCK.read_text())
    changes = [
        (name, locked.get(name, "(new model)"), classification[name])
        for name in sorted(classification)
        if locked.get(name) != classification[name]
    ]
    changes += [(name, locked[name], "(removed)") for name in sorted(locked) if name not in classification]
    if not changes:
        return

    print("error: the derived model conformances no longer match the lock file.", file=sys.stderr)
    print("Each line below is a public API change. Review it, then re-run with", file=sys.stderr)
    print("--update-conformance-lock to accept:", file=sys.stderr)
    for name, was, now in changes:
        print(f"    {name}: {was} -> {now}", file=sys.stderr)
    sys.exit(1)


def apply_conformances(models: dict, classification: dict) -> dict:
    counts = {"codable": 0, "decodable": 0, "encodable": 0}
    for name, kind in classification.items():
        counts[kind] += 1
        if kind == "codable":
            continue
        path = models[name]["path"]
        source = path.read_text()

        if models[name]["is_class"]:
            header = re.search(r"^public final class %s:(.*?)\{$" % re.escape(name), source, re.M | re.S)
        else:
            header = re.search(r"^public enum %s:(.*?)\{$" % re.escape(name), source, re.M | re.S)
        if not header:
            fail(f"Could not find the declaration of {name} to rewrite.")

        conformances = header.group(1)
        if kind == "decodable":
            rewritten = re.sub(r",\s*JSONEncodable", "", conformances.replace("Codable", "Decodable"))
        else:
            rewritten = conformances.replace("Codable", "Encodable")
        if rewritten == conformances:
            fail(f"{name} does not declare Codable - the generator output changed.")
        source = source[: header.start(1)] + rewritten + source[header.end(1) :]

        # A hand-written coding member for the half we just dropped has to go
        # with it. Only `VideoEvent` has one.
        if kind == "decodable":
            body = re.search(r"\n    public func encode\(to encoder: Encoder\) throws \{\n.*?\n    \}\n", source, re.S)
            if body:
                source = source[: body.start()] + "\n" + source[body.end() :]

        path.write_text(source)
    return counts


# ---------------------------------------------------------------------------
# DefaultAPI
# ---------------------------------------------------------------------------

def drop_case_iterable_from_coding_keys() -> int:
    """`CodingKeys.allCases` is never used, but `CaseIterable` makes the
    compiler emit a witness table and a static array for every model."""
    changed = 0
    for path in sorted(MODELS.glob("*.swift")):
        source = path.read_text()
        updated = source.replace(
            "enum CodingKeys: String, CodingKey, CaseIterable {",
            "enum CodingKeys: String, CodingKey {",
        )
        if updated != source:
            path.write_text(updated)
            changed += 1
    return changed


SEND_BEFORE = '''    func send<Response: Codable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {

        // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
        func makeError(_ error: Error) -> Error {
            error
        }

        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (Error) -> Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }

        let (data, _) = try await wrappingErrors {
            var next: (Request) async throws -> (Data, URLResponse) = { _request in
                try await wrappingErrors {
                    try await self.transport.execute(request: _request)
                } mapError: { error in
                    makeError(error)
                }
            }
            for middleware in middlewares.reversed() {
                let tmp = next
                next = {
                    try await middleware.intercept(
                        $0,
                        next: tmp
                    )
                }
            }
            return try await next(request)
        } mapError: { error in
            makeError(error)
        }

        return try await wrappingErrors {
            try deserializer(data)
        } mapError: { error in
            makeError(error)
        }
    }
'''

SEND_AFTER = '''    // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
    private static func makeError(_ error: Error) -> Error {
        error
    }

    /// Runs `request` through the middleware chain and returns the raw payload.
    ///
    /// Kept non-generic and never inlined so that the middleware chain is
    /// emitted once, instead of being specialised into every endpoint that
    /// calls `send(request:deserializer:)`.
    @inline(never)
    private func perform(request: Request) async throws -> Data {
        do {
            var next: (Request) async throws -> (Data, URLResponse) = { _request in
                do {
                    return try await self.transport.execute(request: _request)
                } catch {
                    throw Self.makeError(error)
                }
            }
            for middleware in middlewares.reversed() {
                let tmp = next
                next = {
                    try await middleware.intercept(
                        $0,
                        next: tmp
                    )
                }
            }
            let (data, _) = try await next(request)
            return data
        } catch {
            throw Self.makeError(error)
        }
    }

    // `Decodable` rather than `Codable`: response models no longer carry the
    // encoding half. See "Conformance split" in Scripts/optimizeGeneratedCodeSize.py.
    func send<Response: Decodable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {
        let data = try await perform(request: request)
        do {
            return try deserializer(data)
        } catch {
            throw Self.makeError(error)
        }
    }
'''

PATH_PARAMETER_HELPER = '''    /// Replaces the `{name}` placeholder in `path` with the percent-escaped
    /// `value`.
    ///
    /// Kept non-generic and never inlined so that the escaping sequence is
    /// emitted once, instead of once per path parameter across every endpoint.
    @inline(never)
    private static func substitutingPathParameter(
        _ name: String,
        with value: Any,
        in path: String
    ) -> String {
        let escaped = "\\(APIHelper.mapValueToPathItem(value))"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        return path.replacingOccurrences(
            of: "{\\(name)}",
            with: escaped,
            options: .literal,
            range: nil
        )
    }

'''

HELPER_ANCHOR = """    func makeRequest<T: Encodable>(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String,
        request: T
    ) throws -> Request {
"""

# The generator emits the same three-line escaping dance for every path
# parameter, either on one line or wrapped over several.
PATH_PARAMETER_PATTERNS = [
    re.compile(
        r'^([ \t]*)let (\w+)PreEscape = "\\\(APIHelper\.mapValueToPathItem\((\w+)\)\)"\n'
        r'[ \t]*let \2PostEscape = \2PreEscape\.addingPercentEncoding\(withAllowedCharacters: \.urlPathAllowed\) \?\? ""\n'
        r'[ \t]*path = path\.replacingOccurrences\(of: String\(format: "\{%@\}", "([^"]+)"\), '
        r"with: \2PostEscape, options: \.literal, range: nil\)\n",
        re.M,
    ),
    re.compile(
        r'^([ \t]*)let (\w+)PreEscape = "\\\(APIHelper\.mapValueToPathItem\((\w+)\)\)"\n'
        r'[ \t]*let \2PostEscape = \2PreEscape\.addingPercentEncoding\(withAllowedCharacters: \.urlPathAllowed\) \?\? ""\n'
        r"[ \t]*path = path\.replacingOccurrences\(\n"
        r'[ \t]*of: String\(format: "\{%@\}", "([^"]+)"\),\n'
        r"[ \t]*with: \2PostEscape,\n"
        r"[ \t]*options: \.literal,\n"
        r"[ \t]*range: nil\n"
        r"[ \t]*\)\n",
        re.M,
    ),
]


def optimize_default_api() -> int:
    source = DEFAULT_API.read_text()

    if SEND_BEFORE not in source:
        if "substitutingPathParameter" in source:
            fail(
                "DefaultAPI.swift has already been optimised. This script runs "
                "once, right after the generator; re-run generateCode.sh to "
                "start from fresh output."
            )
        fail(
            "DefaultAPI.send(request:deserializer:) no longer matches the "
            "expected generator output - the de-specialisation needs to be "
            "re-derived."
        )
    source = source.replace(SEND_BEFORE, SEND_AFTER)

    if HELPER_ANCHOR not in source:
        fail("Could not find makeRequest<T: Encodable> to anchor the path helper on.")
    source = source.replace(HELPER_ANCHOR, PATH_PARAMETER_HELPER + HELPER_ANCHOR, 1)

    substitutions = 0
    for pattern in PATH_PARAMETER_PATTERNS:
        source, count = pattern.subn(
            lambda m: f'{m.group(1)}path = Self.substitutingPathParameter("{m.group(4)}", with: {m.group(3)}, in: path)\n',
            source,
        )
        substitutions += count

    if substitutions == 0:
        fail("No path parameter escaping blocks found in DefaultAPI.swift.")
    if "PreEscape" in source:
        fail("Some path parameter escaping blocks were left unconverted.")

    DEFAULT_API.write_text(source)
    return substitutions


def main() -> None:
    if not DEFAULT_API.exists():
        fail(f"{DEFAULT_API} not found - run this after the generator.")

    update_lock = "--update-conformance-lock" in sys.argv

    models = load_models()
    classification = classify(models)
    check_lock(classification, update_lock)

    coding_keys = drop_case_iterable_from_coding_keys()
    parameters = optimize_default_api()
    counts = apply_conformances(models, classification)

    print(f"Dropped CaseIterable from CodingKeys in {coding_keys} models.")
    print(f"De-specialised DefaultAPI.send and collapsed {parameters} path parameters.")
    print(
        "Model conformances: "
        f"{counts['codable']} Codable, "
        f"{counts['decodable']} Decodable, "
        f"{counts['encodable']} Encodable."
    )


if __name__ == "__main__":
    main()
