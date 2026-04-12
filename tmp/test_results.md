# repo-ripper Rust LSP Enhancement - Test Results

## Test Environment

- **Location**: `skills/tmp/testrepo/`
- **Tools**: `rg` (ripgrep with PCRE2), `sd` (1.0.0), LSP (rust-analyzer via opencode lsp tool)
- **Environment**: `OPENCODE_EXPERIMENTAL=true`
- **Test repo**: Minimal Rust crate with `DenseTensor`, `FooBar`, and module structure

## LSP Test Results

### B2. workspaceSymbol - PASS

```
LSP(operation: "workspaceSymbol", filePath: "src/main.rs", line: 1, character: 1)
```

Result: Returned `DenseTensor` (kind: 23/Struct) at `src/foo/dense_tensor.rs:0:11` and `FooBar` (kind: 23/Struct) at `src/main.rs:13:7`.

Bridged to repo-ripper: Replaces rg keyword search in Step 2. workspaceSymbol returns symbol kind codes (23=Struct, 12=Function, etc.) with exact locations.

### B3. goToDefinition - PASS

```
LSP(operation: "goToDefinition", filePath: "src/main.rs", line: 3, character: 25)
```

Result: Resolved to `src/foo/dense_tensor.rs:4:7-4:21` (the `process_tensor` function — char 25 in `use foo::dense_tensor::{process_tensor, DenseTensor}` lands on `process_tensor`).

Key advantage: A `use` statement resolved through the module system to the actual definition, which rg cannot do.

### B4. findReferences - PASS

```
LSP(operation: "findReferences", filePath: "src/foo/dense_tensor.rs", line: 1, character: 13)
```

Result: Found 4 references:
1. `src/main.rs:2:40-2:51` — `DenseTensor` in use statement
2. `src/main.rs:5:12-5:23` — `DenseTensor` in struct literal
3. `src/foo/dense_tensor.rs:4:25-4:36` — `DenseTensor` as parameter type
4. `src/foo/dense_tensor.rs:0:11-0:22` — definition site (DenseTensor struct name)

Key advantage over rg: Identifies type-position references (parameter type, constructor) that are semantically precise.

### B5. goToImplementation - PASS (position-sensitive)

```
LSP(operation: "goToImplementation", filePath: "src/main.rs", line: 14, character: 8)
```

Result: Found 3 implementations:
1. `src/main.rs:12:16-12:21` — `Debug` (from `#[derive]`)
2. `src/main.rs:12:9-12:14` — `Clone` (from `#[derive]`)
3. `src/main.rs:12:23-12:32` — `PartialEq` (from `#[derive]`)

Note: `goToImplementation` at line 13 char 8 (`FooBar` keyword) returned empty. Works at line 14 char 8 (the `struct FooBar {}` line). Need to position on the struct definition itself, not the keyword.

Key advantage over rg: Captures `#[derive]` macro expansions that rg cannot find.

### B6. Call hierarchy - PARTIAL

**prepareCallHierarchy** - PASS:
Returned `process_tensor` (kind: 12/Function, detail: `pub fn process_tensor(t: DenseTensor)`).

**incomingCalls** - EMPTY:
No results found for incomingCalls on `process_tensor`.

**outgoingCalls** - EMPTY:
No results found for outgoingCalls on `process_tensor`.

Analysis: `process_tensor` is called from `main` (line 9), but incomingCalls returned empty. This may be a rust-analyzer limitation for simple projects or the call hierarchy requires a call graph index.

### B7. documentSymbol - PASS

```
LSP(operation: "documentSymbol", filePath: "src/foo/dense_tensor.rs", line: 1, character: 1)
```

Result:
1. `DenseTensor` (kind: 23/Struct, range: line 0-2)
2. `data` (kind: 8/Field, range: line 1:4-1:22, containerName: "DenseTensor")
3. `process_tensor` (kind: 12/Function, range: line 4:0-4:40)

Key advantage: Structured hierarchy with nesting, kind tags, and containerName. rg needs multiple passes to reconstruct this.

### B_foo. hover - PARTIAL (position-sensitive)

- char 12 on DenseTensor usage: returned `[null]`
- char 8 on `#[derive]`: returned derive macro docs
- char 7 on `struct` keyword: returned generic struct docs

Hover is useful but position-sensitive and may return generic docs instead of type-specific information.

## Comparison: rg vs LSP

| Aspect | rg-based (default) | LSP-based (Rust) | Observations |
|--------|--------------------|--------------------|--------------|
| Definition search | Regex keyword match | workspaceSymbol + goToDefinition | LSP resolves through module system |
| Cross-references | Import/call/member patterns | findReferences (exact, semantic) | LSP identifies type-position refs |
| Re-exports | Missed or false positive | Resolved via goToDefinition | LSP traced `use` to definition |
| Trait impls | `impl.*for` grep | goToImplementation | LSP found `#[derive]` expansions |
| Call relationships | `symbol(` pattern | incomingCalls/outgoingCalls | **LSP returned empty for this test** |
| Module contents | Regex per file | documentSymbol (structured) | LSP gave hierarchy with containerName |
| Macro expansions | Not found | Partially found | LSP found derive impls via goToImplementation |
| Build artifacts | Needs `--glob '!target'` | Not searched | LSP is semantic-only |
| Position sensitivity | N/A | Critical | goToImplementation needs exact struct position |

## Summary

| Test | Operation | Result |
|------|-----------|--------|
| B2 | workspaceSymbol | PASS |
| B3 | goToDefinition | PASS |
| B4 | findReferences | PASS |
| B5 | goToImplementation | PASS (position-sensitive) |
| B6 | prepareCallHierarchy | PASS |
| B6 | incomingCalls | EMPTY |
| B6 | outgoingCalls | EMPTY |
| B7 | documentSymbol | PASS |
| B_foo | hover | PARTIAL (position-sensitive) |

**Key finding**: `incomingCalls`/`outgoingCalls` returned empty for `process_tensor` despite being called from `main`. This may be a rust-analyzer limitation or requires more project complexity. The other 5 operations (workspaceSymbol, goToDefinition, findReferences, goToImplementation, documentSymbol) all work reliably.