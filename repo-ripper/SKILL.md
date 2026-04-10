---
name: repo-ripper
description: Guide for documenting software codebases using a dual-tag system combining call-graph structure with subject domain. This skill should be used when analyzing a repository and writing cross-linked implementation notes and tutorials.
keywords:
  - code documentation
  - repository analysis
  - note-taking
  - knowledge base
  - software design
  - implementation documentation
---

# repo-ripper Skill

Produce a cohesive, cross-linked knowledge base for software packages by documenting architecture and implementation with a dual-tag system.

## Trigger Contract

Use this skill when the task requires repository analysis and durable documentation artifacts.

- Use when: producing atomic component notes, component relationship maps, and package tutorials.
- Do not use when: making code changes only, answering one-off code questions, or writing non-technical prose.
- Deliverables:
  - Atomic notes under `<package-name>/` (one component per note)
  - Optional tutorials under `<package-name>/Tutorial/` after sufficient atomic notes exist
  - Discovery CSV files under `<package-name>/.discovery/`

## Dependencies and Resources

- Extend the global `note-writer` skill for general technical writing quality.
- Use `declaration-keywords.csv` to map language to declaration keywords.
- Use `references/cli-tools.md` for tool references, installation commands, and command rationale.
- Use `references/narration-flow.md` for coherent narration examples.
- If `~/silverbullet-space-agent/atomic_notes.md` is unavailable, apply this fallback rule: keep notes atomic (exactly one component per note) and link related ideas with `[[wikilinks]]` instead of duplicating content.

## Tagging Convention

Use a dual-tag system to classify notes along two independent axes:
1. Location in architecture (location tag)
2. Conceptual domain (domain tag)

Never create tags that conflict with existing garden tags. Search first with `rg` or `sk` (if available) before introducing new tags.

### 1) Location Tags

Encode component location from source tree path.

- Format: `#<package-name>/<dir-path>/<this-component>`
- Preserve directory structure as-is; do not strip `src/`, `lib/`, or similar segments.
- Keep package root as prefix source for deterministic conversion.

Examples:
- `#spenso/src/tensors/data/dense/DenseTensor`
- `#spenso/src/structure/lorentz/Lorentz`
- `#react/src/hooks/useEffect`
- `#numpy/numpy/linalg/linalg/svd`

### 2) Domain Tags

Encode conceptual domain.

- Format: `#<domain>/<sub-domain>/<smaller-subdomain-if-any>`

Examples:
- `#computer-science/rust`
- `#math/algebra/groups`
- `#physics/quantum-mechanics`
- `#system-design/architecture`

## Locate Package Root

Ask the user for the package root path at session start. Use automatic detection only as fallback.

Use marker discovery:

```bash
fd -d3 '(Cargo\.toml|pyproject\.toml|go\.mod|Package\.toml|package\.json|setup\.py|CMakeLists\.txt|Mix\.exs|dune-project)'
```

Choose the marker directory that contains the component definition file being documented.

Determine package name:
- Prefer explicit manifest `name` field when present.
- Otherwise use marker directory name.

## Tag Assignment Workflow

Derive location tags deterministically from component definition paths.

### Step 1: Identify language

Infer language from file extension or user input.
Read declaration keywords from `declaration-keywords.csv`.

### Step 2: Search for definition (hardened)

Always quote shell variables and path values.
Escape symbol text before interpolation in regex using `sd`.

```bash
SYMBOL_NAME="<SymbolName>"
PACKAGE_ROOT="<package-root-dir>"
KEYWORDS="keyword1|keyword2|..."
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')

rg -nP "(${KEYWORDS})\s+${SYMBOL_ESCAPED}(?!\w)" "$PACKAGE_ROOT" -l
```

Fallback if keyword search returns nothing:

```bash
rg -F -w "$SYMBOL_NAME" "$PACKAGE_ROOT" -l
```

Use heuristic judgment to separate defining occurrences from plain mentions in fallback mode.

### Step 3: Gather candidates

Exclude files under `test/`, `spec/`, and `bench/` first.
If exclusion yields zero results, rerun without exclusion.

```bash
candidates=$(rg -nP "(${KEYWORDS})\s+${SYMBOL_ESCAPED}(?!\w)" "$PACKAGE_ROOT" -l | rg -v '/(test|spec|bench)/')
if [ -z "$candidates" ]; then
  candidates=$(rg -nP "(${KEYWORDS})\s+${SYMBOL_ESCAPED}(?!\w)" "$PACKAGE_ROOT" -l)
fi
```

For multi-definition components (for example: Julia multi-methods, Rust trait impls, C++ headers and sources), generate one location tag per defining file and place all such tags below YAML frontmatter and above the H1 title, one tag per line.

Tie-breaker rule for ambiguous candidates:
1. Prefer declarations in non-generated source files.
2. Prefer declarations closest to canonical module path for the package.
3. Keep all candidates if ambiguity remains and mark caveat in `Remark`.

### Step 4: Convert file paths to tags

For each candidate path:
1. Strip package root prefix
2. Strip file extension
3. Prepend `#<package-name>/`
4. Append `/<SymbolName>`

```bash
echo "$candidates" | while IFS= read -r path; do
  printf '%s\n' "$path" \
    | sd '^<package-root-dir>/' '' \
    | sd '\\.[^.]*$' '' \
    | sd '^(.+)$' '#<package-name>/$1/<SymbolName>'
done
```

Example conversion:

```
spenso/src/tensors/data/dense.rs
-> #spenso/src/tensors/data/dense/DenseTensor

spenso/src/tensors/math/add.rs
-> #spenso/src/tensors/math/add/DenseTensor
```

## Cross-Reference Discovery

After assigning tags, discover references to the component.
Accept heuristic coverage; prioritize useful wikilinks over perfect static analysis.

### Search strategy

Run in order and stop when sufficient:

```bash
SYMBOL_ESCAPED=$(echo "$SYMBOL_NAME" | sd '[\[\]\.\*\+\?\^\$\{\}\(\)\|\\]' '\\$0')

rg -nP "(import|use|require|from|include)\b.*${SYMBOL_ESCAPED}(?!\w)" "<search-path>"
rg -nP "${SYMBOL_ESCAPED}(?!\w)\s*\(" "<search-path>"
rg -nP "${SYMBOL_ESCAPED}(?!\w)[\.:]" "<search-path>"
rg -F -w "$SYMBOL_NAME" "<search-path>"
```

1. Import-style references: matches `use Foo`, `import Foo`, etc.
2. Call/member references: matches `foo(` and `foo.` patterns
3. Fallback literal references: fixed-string whole-word match

### Record results

Write to `./discovery/<component-name>.csv` with `file,line,context` columns.

```bash
rg -n "<SymbolName>" "<search-path>" \
  | sd '^<repo-root>/' '' \
  | sd '^(.+):(\\d+):(.*)$' '$1,$2,"$3"' \
  >> "./discovery/<component-name>.csv"
```

When writing the note for `<component-name>`, load `./discovery/<component-name>.csv`, derive tags from file paths via Tag Assignment, and create `[[wikilinks]]` to referencing components.

## Note Structure

Follow strict flow: Design -> Implement -> MWE -> Caveats.

Place dual tags immediately below YAML frontmatter and above H1.

Required sections:
1. Motivation (Design Principle)
2. Encapsulates (Downward Abstraction)
3. Exposed To (Upward Abstraction)
4. Discussion (Implementation Detail)
5. Result (Minimum Working Example)
6. Remark (Caveats and Composition)
7. Glossary (Mandatory)

Section requirements:
- Motivation: state the core abstraction and problem solved; state raw design principle before syntax sugar.
- Encapsulates: link internal modules/types/utilities with `[[wikilinks]]`.
- Exposed To: link external callers/importers using discovery output.
- Discussion: explain data structures, algorithms, and realization details.
- Result: provide minimal self-contained reproducible usage snippet.
- Remark: document limitations, edge cases, composition constraints, performance implications, and anti-patterns.
- Glossary: define key terms used in the note.

For narration guidance and examples, read `references/narration-flow.md`.

## Organization Rules

- Keep core component notes flat under `<package-name>/`.
- Keep each atomic note focused on exactly one component.
- Store long-form architecture/tutorial content under `<package-name>/Tutorial/`.
- Write tutorials only after enough atomic notes exist to support cross-linking.
- Keep all documentation as either atomic notes or tutorials; avoid a third category.

## Validation Checklist

Before finishing, verify all items:

1. Metadata and trigger fitness
   - Note fits this skill's trigger contract.
   - Output artifacts match requested deliverables.
2. Tag correctness
   - Location tag path is deterministic and extension-free.
   - Domain tag is specific and non-conflicting with existing tags.
   - Multi-definition tags are complete and one-per-line.
3. Structural completeness
   - Sections 1-7 exist in required order.
   - `Glossary` is present and non-empty.
4. Evidence and linking
   - `Encapsulates` and `Exposed To` contain meaningful `[[wikilinks]]`.
   - Discovery CSV exists and is consistent with links.
5. Example quality
   - MWE is minimal, reproducible, and consistent with current APIs.
6. Caveats and precision
   - `Remark` covers limitations and composition/performance notes.
   - Ambiguities are explicitly called out.

## Operational Notes

- Keep instruction style imperative and deterministic.
- Prefer explicit file paths and quoted shell arguments in examples.
- Preserve all major decisions as auditable text in notes rather than implicit assumptions.
