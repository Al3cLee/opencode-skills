# repo-ripper Rust LSP Enhancement - Test Plan

## Test Environment

- **Location**: `skills/tmp/testrepo/`
- **Tools**: `rg` (ripgrep), `sd`, LSP (rust-analyzer)
- **Test repo**: Minimal Rust crate with `DenseTensor` and `FooBar`

## Test Structure

```
testrepo/
├── Cargo.toml
└── src/
    ├── main.rs              # mod foo, use DenseTensor, struct FooBar
    ├── foo/
    │   ├── mod.rs            # pub mod dense_tensor;
    │   └── dense_tensor.rs   # pub struct DenseTensor, pub fn process_tensor
    ├── foobar.rs             # struct FooBar {}
    └── weird.rs              # struct Foo[0] {}, struct F[0]G {}, struct F[0] {}
```

## Test Categories

### A. Default rg-based Workflow (unchanged - regression tests)

These tests verify the existing rg/fd/sd workflow still works correctly.

#### A1. Symbol escape (CamelCase)
```bash
SYMBOL_NAME="DenseTensor"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
# Expected: DenseTensor (no change)
```

#### A2. Symbol escape (with brackets)
```bash
SYMBOL_NAME="F[0]"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
# Expected: F\[0\]
```

#### A3. Definition search with (?!\w)
```bash
SYMBOL_NAME="DenseTensor"
KEYWORDS="struct|fn"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
rg -nP "(${KEYWORDS})\s+${SYMBOL_ESCAPED}(?!\w)" . -l
# Expected: ./src/foo/dense_tensor.rs
```

#### A4. Cross-reference CSV generation
```bash
rg -n "DenseTensor" . | sd '^./' '' | sd '^(.+):(\d+):(.*)$' '$1,$2,"$3"'
# Expected: CSV with file,line,context rows
```

### B. Rust LSP Enhancement (new tests)

These tests verify the LSP-based workflow produces more precise results.

#### B1. Activation condition check
- Verify `Cargo.toml` exists in package root => Rust mode active
- Verify LSP server responds => use LSP operations
- If LSP unavailable => fall back to rg-based workflow

#### B2. Definition search via LSP (workspaceSymbol)
```
LSP(
  operation: "workspaceSymbol",
  filePath: "src/main.rs",
  line: 1,
  character: 1
)
```
- Expected: Finds `DenseTensor` as a struct in `src/foo/dense_tensor.rs`
- Advantage over rg: Resolves re-exports, distinguishes definition from reference

#### B3. Definition verification (goToDefinition)
```
LSP(
  operation: "goToDefinition",
  filePath: "src/main.rs",
  line: 3,
  character: 25
)
```
- Expected: Navigates to `src/foo/dense_tensor.rs:1:13` (the actual struct definition)
- Advantage over rg: Resolves `use foo::dense_tensor::DenseTensor` back to original definition

#### B4. Cross-reference discovery via LSP (findReferences)
```
LSP(
  operation: "findReferences",
  filePath: "src/foo/dense_tensor.rs",
  line: 1,
  character: 13
)
```
- Expected: Finds all references including:
  - `src/main.rs:3:25` (use statement)
  - `src/main.rs:6:12` (constructing instance)
  - `src/foo/dense_tensor.rs:1:13` (definition)
  - `src/foo/dense_tensor.rs:5:24` (function parameter)
- Advantage over rg: Catches references in patterns, type positions, trait bounds

#### B5. Trait implementation discovery (goToImplementation)
```
LSP(
  operation: "goToImplementation",
  filePath: "src/main.rs",
  line: 13,
  character: 8
)
```
- Expected: Finds `impl Debug for FooBar`, `impl Clone for FooBar`, `impl PartialEq for FooBar`
- Advantage over rg: Captures `#[derive]` expansions, resolves blanket impls

#### B6. Call hierarchy (incomingCalls)
```
LSP(
  operation: "prepareCallHierarchy",
  filePath: "src/foo/dense_tensor.rs",
  line: 5,
  character: 7
)

LSP(
  operation: "incomingCalls",
  filePath: "src/foo/dense_tensor.rs",
  line: 5,
  character: 7
)
```
- Expected: `main` calls `process_tensor` (population of "Exposed To" section)

#### B7. Module structure (documentSymbol)
```
LSP(
  operation: "documentSymbol",
  filePath: "src/foo/dense_tensor.rs",
  line: 1,
  character: 1
)
```
- Expected: Struct `DenseTensor` with field `data`, function `process_tensor`
- Advantage over rg: Structured hierarchy with nesting, types, visibility

### C. Comparison Tests (rg vs LSP)

#### C1. Re-export resolution
- **rg**: `use foo::dense_tensor::DenseTensor` in main.rs finds the `use` line
- **LSP**: `goToDefinition` on that use resolves to actual struct in `dense_tensor.rs:1`
- **Winner**: LSP (semantic resolution)

#### C2. Derived trait discovery
- **rg**: Cannot find `Debug`, `Clone`, `PartialEq` implementations for `FooBar` (they're derive macros)
- **LSP**: `goToImplementation` on `FooBar` finds all three derived traits
- **Winner**: LSP (macro expansion awareness)

#### C3. Pattern matching references
- If code had `match x { DenseTensor { data } => ... }`, rg might miss it or produce false positives
- **LSP**: `findReferences` correctly identifies pattern match usage as a reference
- **Winner**: LSP (semantic analysis)

## Results

| Test | Category | Status |
|------|----------|--------|
| A1   | rg regression | PASS |
| A2   | rg regression | PASS |
| A3   | rg regression | PASS |
| A4   | rg regression | PASS |
| B2   | LSP workspaceSymbol | PENDING (requires LSP session) |
| B3   | LSP goToDefinition | PENDING (requires LSP session) |
| B4   | LSP findReferences | PENDING (requires LSP session) |
| B5   | LSP goToImplementation | PENDING (requires LSP session) |
| B6   | LSP call hierarchy | PENDING (requires LSP session) |
| B7   | LSP documentSymbol | PENDING (requires LSP session) |

Note: LSP-based tests (B2-B7) require an interactive opencode session with rust-analyzer running.
They cannot be run via bash scripting alone. The rg regression tests (A1-A4) are fully automated.