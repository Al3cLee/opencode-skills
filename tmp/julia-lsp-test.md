# Julia LSP Test Results

## Test Environment

- **Location**: `skills/tmp/testrepo-jl/`
- **Language**: Julia 1.12.4
- **LSP Server**: LanguageServer.jl
- **Config**: `opencode.json` with custom julials command in project root
- **Status**: Requires opencode restart to activate juliials connection

## Project Structure

```
testrepo-jl/
├── Project.toml        # [deps] LanguageServer = "..."
├── Manifest.toml
├── opencode.json       # LSP config for julials
├── main.jl             # Abstract types, concrete types, println calls
└── fight.jl             # fight() with 6 dispatch methods
```

### main.jl Key Symbols (1-indexed)

| Line | Symbol | Type |
|------|--------|------|
| 1 | `AbstractAnimal` | abstract type |
| 3 | `Dog` | struct (subtype of AbstractAnimal) |
| 7 | `Cat` | struct (subtype of AbstractAnimal) |
| 11 | `Cock` | struct (subtype of AbstractAnimal) |
| 15 | `Human{FT<:Real}` | parametric struct (subtype of AbstractAnimal) |
| 27-30 | `fight(...)` | function calls |

### fight.jl Key Symbols (1-indexed)

| Line | Symbol | Type |
|------|--------|------|
| 1 | `fight(a::AbstractAnimal, b::AbstractAnimal)` | fallback method |
| 5 | `fight(a::Dog, b::Cat)` | specific method |
| 7 | `fight(a::Cat, b::Dog)` | specific method |
| 9 | `fight(a::Human{<:Real}, b::AbstractAnimal)` | specific method |
| 11 | `fight(a::AbstractAnimal, b::Human{<:Real})` | specific method |
| 13 | `fight(hum1::Human{T}, hum2::Human{T}) where {T<:Real}` | parametric method |

## Verification

```
$ julia main.jl
fight(Cock(true), Cat("red")) = draw
fight(Dog("blue"), Cat("white")) = win
fight(Human(180), Cat("white")) = win
fight(Human(170), Human(180)) = loss
```

All outputs match expected results from julia-example.md.

## LSP Operations Test Plan

**Note**: These tests require opencode to be restarted with the julials config active.
The `opencode.json` is in the project root at `tmp/testrepo-jl/opencode.json`.

### B2. workspaceSymbol

```
LSP(operation: "workspaceSymbol", filePath: "main.jl", line: 1, character: 1)
```

Expected: Finds `AbstractAnimal`, `Dog`, `Cat`, `Cock`, `Human`, `fight` across the project.

**Julia-specific**: Should return all symbols including methods of `fight`.

### B3. goToDefinition

Test resolution of `fight` function call to its definitions:

```
LSP(operation: "goToDefinition", filePath: "main.jl", line: 27, character: 36)
```

Position: char 36 in `fight(Cock(true), Cat("red"))` — on the `fight` call.

Expected: Jumps to `fight.jl:1` (the generic method) or shows all method definitions.

**Julia-specific question**: Does goToDefinition on a multimethod call resolve to:
1. The most specific method?
2. The generic fallback method?
3. All methods?
4. The function object (not a specific method)?

### B4. findReferences

Find all references to the `fight` function:

```
LSP(operation: "findReferences", filePath: "fight.jl", line: 1, character: 10)
```

Expected: Finds all 4 call sites in `main.jl` (lines 27-30) plus all 6 method definitions in `fight.jl`.

**Julia-specific question**: Does findReferences distinguish between:
- Method definitions (lines 1, 5, 7, 9, 11, 13 in fight.jl)
- Call sites (lines 27, 28, 29, 30 in main.jl)

### B5. goToImplementation (CRITICAL TEST)

This is the key test for Julia multiple dispatch. On an abstract type:

```
LSP(operation: "goToImplementation", filePath: "main.jl", line: 1, character: 17)
```

Position: on `AbstractAnimal` in `abstract type AbstractAnimal end`.

**Expected**: Returns all concrete subtypes:
1. `Dog` (main.jl:3)
2. `Cat` (main.jl:7)
3. `Cock` (main.jl:11)
4. `Human` (main.jl:15)

**VS findReferences** on the same position would return: every place `AbstractAnimal` appears in type annotations, `where` clauses, and method signatures — not just the subtypes.

Also test on the `fight` function:

```
LSP(operation: "goToImplementation", filePath: "fight.jl", line: 1, character: 10)
```

**Expected**: Returns all 6 method dispatches of `fight`.

This is the key difference from Rust: Julia's `goToImplementation` on a function returns **all method dispatches**, whereas in Rust it would return **trait implementations**.

### B6. Call hierarchy

```
LSP(operation: "prepareCallHierarchy", filePath: "fight.jl", line: 1, character: 10)
LSP(operation: "incomingCalls", filePath: "fight.jl", line: 1, character: 10)
LSP(operation: "outgoingCalls", filePath: "fight.jl", line: 1, character: 10)
```

Expected:
- `incomingCalls`: `main` (the caller in main.jl lines 27-30)
- `outgoingCalls`: nothing for the generic fallback (it just returns "draw")

**Rust comparison**: In Rust, `incomingCalls`/`outgoingCalls` returned empty. Julia's LanguageServer may have different behavior.

### B7. documentSymbol

```
LSP(operation: "documentSymbol", filePath: "main.jl", line: 1, character: 1)
LSP(operation: "documentSymbol", filePath: "fight.jl", line: 1, character: 1)
```

Expected for main.jl:
- `AbstractAnimal` (kind: abstract type / class)
- `Dog` with field `color` (nested)
- `Cat` with field `color` (nested)
- `Cock` with field `gender` (nested)
- `Human` with field `height` (nested, parametric)
- Top-level statements (includes, printlns)

Expected for fight.jl:
- `fight` methods (may appear as separate symbols or grouped)

**Julia-specific question**: How does LanguageServer.jl represent multimethods in documentSymbol?
- As one symbol `fight` with multiple signatures?
- As separate symbols per method?

### B_foo. hover

```
LSP(operation: "hover", filePath: "fight.jl", line: 1, character: 10)
```

Expected: Shows docstring/type info for `fight`. Julia functions without docstrings may return minimal info.

## Key Differences from Rust LSP Test

| Aspect | Rust (rust-analyzer) | Julia (LanguageServer.jl) |
|--------|----------------------|---------------------------|
| `goToImplementation` on type | Finds trait impls (`#[derive]`) | Finds subtypes (concrete structs/subtypes) |
| `goToImplementation` on function | N/A in Rust | Finds all method dispatches |
| `findReferences` on function | Finds usages | Finds call sites + all method definitions |
| `documentSymbol` for functions | Single function | Multiple dispatch methods? |
| Multiple dispatch | Not applicable | Core semantic distinction |
| Server startup | Fast (~1s) | Slow (~5-10s Julia compilation) |
| `incomingCalls`/`outgoingCalls` | Empty in test | Unknown — to be tested |

## Results

*To be filled in after opencode restart with julials active.*

| Test | Operation | Target | Result |
|------|-----------|--------|--------|
| B2 | workspaceSymbol | project-wide | PENDING |
| B3 | goToDefinition | `fight` call in main.jl:27 | PENDING |
| B4 | findReferences | `fight` definition in fight.jl:1 | PENDING |
| B5a | goToImplementation | `AbstractAnimal` in main.jl:1 | PENDING |
| B5b | goToImplementation | `fight` in fight.jl:1 | PENDING |
| B6a | prepareCallHierarchy | `fight` in fight.jl:1 | PENDING |
| B6b | incomingCalls | `fight` in fight.jl:1 | PENDING |
| B6c | outgoingCalls | `fight` in fight.jl:1 | PENDING |
| B7a | documentSymbol | main.jl | PENDING |
| B7b | documentSymbol | fight.jl | PENDING |
| B_foo | hover | `fight` in fight.jl:1 | PENDING |