# Binary Parser Primitives Scope

The identity surface of `swift-binary-parser-primitives` and what lies outside it.

## Identity

`swift-binary-parser-primitives` is a **discipline package**: it adds the
binary-parsing discipline to the **upstream-owned `Binary` namespace**
(declared in `swift-binary-primitives`). Every type it defines is
`extension Binary.{…}` — `Binary.Machine`, `Binary.Parse`, `Binary.Parseable`,
the byte-stream input surface — never the `Binary` namespace itself.

Because the package OWNS no top-level namespace of its own (it only extends an
upstream root), it has **no zero-dep `Binary Primitive` root target** per the
`[MOD-017]` root-applicability rule (sharpened 2026-06-23 during the L1
core-dissolution sweep): a package that extends an upstream-owned namespace
(`extension Binary {…}`) has no zero-dep content of its own, so it mints no
root — it splits into sub-namespace modules + umbrella instead.

The `enum Binary` root, the `Binary.Borrowed`/`Byte` substrate, and the
`Parser` machinery this discipline builds on are all upstream. This package
consumes them; it does not own them.

## Owner targets

- **Binary Input Primitives** — re-export shim surfacing `Byte.Input` (owned by
  `swift-byte-parser-primitives`) plus the `Binary`/`Parser` substrate this
  discipline parses against. No declarations of its own.
- **Binary Machine Primitives** — the `Binary.Machine` interpreter discipline
  (the stateful parse machine).
- **Binary Borrowed Primitives** — the borrowing/span-backed parse engine
  (`Cursor<Byte>` over `Span.`Protocol``).
- **Binary Parse Primitives** — the `Binary.Parse` access surface
  (`Binary.Parse.Variable` / `.Access` and friends).
- **Binary Parseable Primitives** — the `Binary.Parseable` sibling protocol
  (relocated from `swift-binary-primitives`).
- **Binary Integer Primitives** — the integer-parser bridges
  (`Binary.Parse.Inline: Parser.`Protocol``) and re-exported `Binary.LEB128`.
- **Binary Parser Primitives** — umbrella; re-exports root-equivalent
  externals + all sub-namespaces so consumers write `import Binary_Parser_Primitives`.
- **Binary Parser Primitives Core** — **DEPRECATED transitional shim** (L1
  core-dissolution sweep 2026-06-23). Exports-only; re-exports the dissolved
  Core surface (`Binary_Primitives` + `Parser_Primitives`). No declarations.
  Removed in the cleanup wave.
- **Binary Parser Primitives Test Support** — published test-fixtures product.

## Out of scope

- **The `Binary` namespace itself**, `Binary.Borrowed`, `Byte` →
  `swift-binary-primitives` / `swift-byte-primitives`. Upstream-owned; consumed
  here, not owned.
- **The `Parser` machinery** (`Parser.`Protocol``, the parser substrate) →
  `swift-parser-primitives`. Upstream; this package applies it to binary.
- **`Binary.Coder`** (the per-integer coder transformation domain) →
  `swift-binary-coder-primitives` per `[MOD-DOMAIN]`. Coder is a different
  transformation domain from Parser.
- **The LEB128 parser bridge** (`Binary.LEB128.Unsigned/Signed: Parser.`Protocol``)
  → `swift-binary-leb128-parser-primitives` per `[MOD-014]` (integration
  package); the shared decode arithmetic → `swift-binary-leb128-primitives`.

## Evaluation rule

Sub-target additions are evaluated against this scope. A proposed addition that
extends the `Binary` parsing discipline (a new `extension Binary.{…}` parse
surface) lands as / within a sub-namespace target here. A proposed addition
that belongs to a different transformation domain (Coder), to the upstream
`Binary`/`Parser`/`Byte` roots, or to an integration package, extracts to its
owning sibling — never into this package, and never as a new package-owned root
(this package owns no root).
