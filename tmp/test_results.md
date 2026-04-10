# repo-ripper SKILL.md Test Results

## Test Environment

- **Location**: `.tmp/testrepo/`
- **Tools**: `rg` (ripgrep 15.1.0 with PCRE2), `sd` (1.0.0), bash
- **Test repo structure**:
  ```
  testrepo/
  ├── src/
  │   ├── foo/
  │   │   └── DenseTensor.rs   # struct DenseTensor { data: Vec<i32> }, fn process_tensor(t: DenseTensor) {}
  │   ├── foobar.rs            # struct FooBar {}
  │   ├── weird.rs             # struct Foo[0] {}, struct F[0]G {}, struct F[0] {}
  │   └── mod.rs               # mod dense_tensor;
  ```

## Test Results

### Test 1: Symbol escape (CamelCase)

```bash
#!/bin/bash
SYMBOL_NAME="DenseTensor"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
echo "Input: $SYMBOL_NAME"
echo "Escaped: $SYMBOL_ESCAPED"
```

**Output**:
```
Input: DenseTensor
Escaped: DenseTensor
```

Result: No escaping needed for simple CamelCase symbols.

---

### Test 2: Symbol escape (with brackets)

```bash
#!/bin/bash
SYMBOL_NAME="Foo[0]"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
echo "Input: $SYMBOL_NAME"
echo "Escaped: $SYMBOL_ESCAPED"
```

**Output**:
```
Input: Foo[0]
Escaped: Foo\[0\]
```

Result: Both `[` and `]` are properly escaped for use in regex patterns.

---

### Test 3: Symbol escape (bracket symbol with G suffix - negative case)

```bash
#!/bin/bash
SYMBOL_NAME="F[0]"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
echo "Input: $SYMBOL_NAME"
echo "Escaped: $SYMBOL_ESCAPED"
```

**Output**:
```
Input: F[0]
Escaped: F\[0\]
```

Result: Properly escaped for boundary matching.

---

### Test 4: Definition search (with word boundary)

```bash
#!/bin/bash
cd .tmp/testrepo
SYMBOL_NAME="DenseTensor"
PACKAGE_ROOT="."
KEYWORDS="struct|fn"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
rg -nP "(${KEYWORDS})\s+${SYMBOL_ESCAPED}(?!\w)" "$PACKAGE_ROOT" -l
```

**Output**:
```
./src/foo/DenseTensor.rs
```

Result: Found the file containing the struct definition using `(?!\w)` lookahead.

---

### Test 5: Candidate gathering (with test exclusion)

```bash
#!/bin/bash
cd .tmp/testrepo
SYMBOL_NAME="DenseTensor"
PACKAGE_ROOT="."
KEYWORDS="struct|fn"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
candidates=$(rg -nP "(${KEYWORDS})\s+${SYMBOL_ESCAPED}(?!\w)" "$PACKAGE_ROOT" -l | rg -v '/(test|spec|bench)/')
echo "$candidates"
```

**Output**:
```
./src/foo/DenseTensor.rs
```

Result: Correctly excludes no files (no test/spec/bench dirs in this repo).

---

### Test 6: Path transformation

```bash
#!/bin/bash
cd .tmp/testrepo
PACKAGE_ROOT="."
PACKAGE_NAME="testrepo"
SYMBOL_NAME="DenseTensor"
candidates="./src/foo/DenseTensor.rs"
echo "$candidates" | sd "^$PACKAGE_ROOT/" '' | sd '\.[^.]*$' '' | sd '^(.+)$' "#$PACKAGE_NAME/\$1/$SYMBOL_NAME"
```

**Output**:
```
#testrepo/src/foo/DenseTensor/DenseTensor
```

Result: Correctly strips package root, removes extension, and formats as `#package/path/component`.

---

### Test 7: Fallback search (rg -F fixed string)

```bash
#!/bin/bash
cd .tmp/testrepo
SYMBOL_NAME="DenseTensor"
PACKAGE_ROOT="."
rg -F -w "$SYMBOL_NAME" "$PACKAGE_ROOT" -l
```

**Output**:
```
./src/foo/DenseTensor.rs
```

Result: Fixed-string mode works correctly as fallback when keyword regex search returns nothing.

---

### Test 8: Cross-reference discovery (CSV output with quoted context)

```bash
#!/bin/bash
cd .tmp/testrepo
SYMBOL_NAME="DenseTensor"
SEARCH_PATH="."
rg -n "$SYMBOL_NAME" "$SEARCH_PATH" | sd "^$SEARCH_PATH/" '' | sd '^(.+):(\d+):(.*)$' '$1,$2,"$3"'
```

**Output**:
```
src/foo/DenseTensor.rs,1,"struct DenseTensor { data: Vec<i32> }"
src/foo/DenseTensor.rs,2,"fn process_tensor(t: DenseTensor) {}"
```

Result: CSV format `file,line,"context"` is correctly generated with quoted context field.

---

### Test 9: Boundary behavior - (?!\w) vs \b for brackets

This test demonstrates why `(?!\w)` is used instead of `\b` for bracket symbols.

Test file `weird.rs` contains:
```
struct Foo[0] {}   (line 1)
struct F[0]G {}     (line 2)
struct F[0] {}      (line 3)
```

```bash
#!/bin/bash
cd .tmp/testrepo
echo "=== Content of weird.rs ==="
cat -n src/weird.rs
echo "=== Search for F[0] with (?!\w) ==="
SYMBOL_NAME="F[0]"
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')
rg -nP "struct\s+${SYMBOL_ESCAPED}(?!\w)" .
```

**Output**:
```
=== Content of weird.rs ===
     1	struct Foo[0] {}
     2	struct F[0]G {}
     3	struct F[0] {}
=== Search for F[0] with (?!\w) ===
./src/weird.rs:3:struct F[0] {}
```

Result: `(?!\w)` correctly matches `F[0]` (line 3) but NOT `F[0]G` (line 2). With `\b`, the behavior would be reversed - it would incorrectly match `F[0]G` and fail to match `F[0]`.

---

### Test 10: Cross-reference search patterns

```bash
#!/bin/bash
cd .tmp/testrepo
SYMBOL_NAME="DenseTensor"
SEARCH_PATH="."
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')

echo "=== 1. Import-style: use DenseTensor ==="
echo "use DenseTensor;" > /tmp/test_import.rs
rg -nP "(import|use|require|from|include)\b.*${SYMBOL_ESCAPED}(?!\w)" /tmp/test_import.rs

echo "=== 2. Call pattern: DenseTensor() ==="
echo "DenseTensor()" > /tmp/test_call.rs
rg -nP "${SYMBOL_ESCAPED}(?!\w)\s*\(" /tmp/test_call.rs

echo "=== 3. Member pattern: DenseTensor.foo ==="
echo "DenseTensor.foo" > /tmp/test_member.rs
rg -nP "${SYMBOL_ESCAPED}(?!\w)[\.:]" /tmp/test_member.rs

echo "=== 4. Fallback: -F -w ==="
rg -F -w "$SYMBOL_NAME" /tmp/test_import.rs /tmp/test_call.rs /tmp/test_member.rs

rm /tmp/test_import.rs /tmp/test_call.rs /tmp/test_member.rs
```

**Output**:
```
=== 1. Import-style: use DenseTensor ===
/tmp/test_import.rs:1:use DenseTensor;
=== 2. Call pattern: DenseTensor() ===
/tmp/test_call.rs:1:DenseTensor()
=== 3. Member pattern: DenseTensor.foo ===
/tmp/test_member.rs:1:DenseTensor.foo
=== 4. Fallback: -F -w ===
/tmp/test_import.rs:1:use DenseTensor;
/tmp/test_call.rs:1:DenseTensor()
/tmp/test_member.rs:1:DenseTensor.foo
```

Result: All cross-reference search patterns work correctly with the escaped symbol.

---

## Summary

| Test | Description | Status |
|------|-------------|--------|
| 1 | Symbol escape (CamelCase) | PASS |
| 2 | Symbol escape (with brackets) | PASS |
| 3 | Symbol escape (F[0] negative case) | PASS |
| 4 | Definition search with (?!\w) | PASS |
| 5 | Candidate gathering | PASS |
| 6 | Path transformation | PASS |
| 7 | Fallback search (rg -F) | PASS |
| 8 | Cross-reference discovery CSV | PASS |
| 9 | Boundary behavior (?!\w) | PASS |
| 10 | Cross-reference search patterns | PASS |

All tests passed. The replacement of `python3` with `sd` for regex escaping and `\b` with `(?!\w)` for proper word boundaries is verified working.

## Key Changes from Original

1. **Removed python3 dependency**: Symbol escaping now uses `sd` only
2. **Added `\]` to escape pattern**: `[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]` handles both `[` and `]`
3. **Replaced `\b` with `(?!\w)`**: Proper boundary that works for bracket symbols
4. **Added `-P` flag**: PCRE2 engine required for lookahead `(?!\w)`
5. **Quoted CSV context field**: `'$1,$2,"$3"'` prevents comma-splitting in context
