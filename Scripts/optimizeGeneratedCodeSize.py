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

None of the transformations change the public API or the behaviour of the
generated code.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GENERATED = ROOT / "Sources/StreamVideo/OpenApi/generated"
DEFAULT_API = GENERATED / "APIs/DefaultAPI.swift"
MODELS = GENERATED / "Models"


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

    func send<Response: Codable>(
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
        r'with: \2PostEscape, options: \.literal, range: nil\)\n',
        re.M,
    ),
    re.compile(
        r'^([ \t]*)let (\w+)PreEscape = "\\\(APIHelper\.mapValueToPathItem\((\w+)\)\)"\n'
        r'[ \t]*let \2PostEscape = \2PreEscape\.addingPercentEncoding\(withAllowedCharacters: \.urlPathAllowed\) \?\? ""\n'
        r'[ \t]*path = path\.replacingOccurrences\(\n'
        r'[ \t]*of: String\(format: "\{%@\}", "([^"]+)"\),\n'
        r'[ \t]*with: \2PostEscape,\n'
        r'[ \t]*options: \.literal,\n'
        r'[ \t]*range: nil\n'
        r'[ \t]*\)\n',
        re.M,
    ),
]


def optimize_default_api() -> int:
    source = DEFAULT_API.read_text()

    if SEND_BEFORE not in source:
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


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not DEFAULT_API.exists():
        fail(f"{DEFAULT_API} not found - run this after the generator.")

    models = drop_case_iterable_from_coding_keys()
    parameters = optimize_default_api()

    print(f"Dropped CaseIterable from CodingKeys in {models} models.")
    print(f"De-specialised DefaultAPI.send and collapsed {parameters} path parameters.")


if __name__ == "__main__":
    main()
