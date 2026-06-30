# swift-binary-parser-primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Binary parsing primitives — the `Binary.Parseable` byte-stream deserialization protocol, the closure-based `Binary.Parser<Value>` witness, and the `Binary.Machine` defunctionalized engine that parses borrowed byte cursors without crossing a closure boundary.

---

## Key Features

- **`Binary.Parseable` protocol** — streaming byte deserialization, the symmetric peer of `Binary.Serializable`. `parse(from:)` consumes a prefix from a `RangeReplaceableCollection` cursor, advancing the source on success and leaving it untouched on failure.
- **`Binary.Parser<Value>` witness** — a closure-based plain witness conforming to the canonical ``Parser.`Protocol` `` with `Input = Byte.Input` and `Failure = Binary.Machine.Fault`.
- **`Binary.Machine` engine** — a defunctionalized parser that represents programs as `Instruction` data so a `~Escapable` borrowed byte cursor never crosses a closure boundary.
- **Parse-access ergonomics** — `parser.parse.whole(bytes)` requires every byte consumed; `parser.parse.prefix(bytes)` returns the value and the count of bytes consumed.
- **Typed failures** — `Binary.Parse.Failure` (`insufficient` / `malformed` / `outOfRange`) for during-parse defects, and `Binary.Parse.Error` for the whole-buffer post-condition.
- **Integer parsers** — `Binary.Parse.Inline<Count, Element>` parses a fixed-size `InlineArray` of `FixedWidthInteger`, alongside the re-exported `Binary.LEB128` variable-length integer namespace.

---

## Quick Start

Stdlib integers conform to `Binary.Parseable` out of the box, and the byte source acts as a cursor — parsing consumes the prefix and advances it. Conform your own types by reading fields from that same cursor:

```swift
import Binary_Parseable_Primitives

// Canonical little-endian, consuming the prefix.
var bytes: [Byte] = [0x78, 0x56, 0x34, 0x12]
let magic = try UInt32.parse(from: &bytes)  // 0x12345678; `bytes` now empty

struct Header { var magic: UInt32; var length: UInt32 }

extension Header: Binary.Parseable {
    static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> Header
    where Source.Element == Byte {
        Header(
            magic: try UInt32.parse(from: &source),
            length: try UInt32.parse(from: &source)
        )
    }
}
```

`Binary.Parseable` lives in the `Binary Parseable Primitives` module, which is imported on its own; the umbrella `Binary Parser Primitives` re-exports the witness, machine, parse-access, and integer modules.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-binary-parser-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Binary Parser Primitives", package: "swift-binary-parser-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26.

---

## Architecture

Seven library products plus a test-support module. Each product maps to a same-named target.

| Product | Purpose |
|---------|---------|
| `Binary Parser Primitives` | Umbrella. `@_exported` re-exports the Input, Machine, Borrowed, Parse, and Integer modules plus `Binary`, the `Byte Parser` substrate, `Parser`, and the `Binary.LEB128` namespace. |
| `Binary Parseable Primitives` | The `Binary.Parseable` streaming-deserialization protocol, its `Binary.Parse.Failure` typed error, and stdlib / `Tagged` / `Array` conformances. Imported on its own — the umbrella does not re-export it. |
| `Binary Parse Primitives` | The `Binary.Parse` namespace: `Binary.Parse.Access` ergonomics (`parse.whole` / `parse.prefix`), `Binary.Parse.Error`, and validation / conversion / variable-length helpers. |
| `Binary Machine Primitives` | The `Binary.Parser<Value>` closure witness and the `Binary.Machine` defunctionalized engine (`Instruction`, `Program`, `Fault`, builders, combinators). |
| `Binary Borrowed Primitives` | The borrowed-`Span` parse engine, extending the span protocol for `~Escapable` byte views. |
| `Binary Input Primitives` | Re-export shim surfacing `Byte.Input` and the parser substrate for source compatibility. |
| `Binary Integer Primitives` | Integer parsers — `Binary.Parse.Inline<Count, Element>` for fixed-size `InlineArray`, plus the re-exported `Binary.LEB128` variable-length namespace. |
| `Binary Parser Primitives Test Support` | Re-exports the targets for test consumers. |

Import the narrowest product you need: `Binary Parseable Primitives` for the protocol path, the umbrella `Binary Parser Primitives` for the witness, machine, and integer parsers.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
