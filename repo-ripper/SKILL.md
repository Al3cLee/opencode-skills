---
name: repo-ripper
description: Guide for documenting software codebases using a dual-tag system combining call-graph structure with subject domain. Use when analyzing a repository and documenting its design and implementation to create a cohesive, cross-linked knowledge base.
keywords:
  - code documentation
  - repository analysis
  - note-taking
  - knowledge base
  - software design
  - implementation documentation
---

# repo-ripper Skill

This skill provides guidelines for structured note-taking and documentation for software codebases. It produces a cohesive, cross-linked knowledge base by systematically analyzing a repository's architecture and documenting each component's design and implementation.

## Requirements

- Extend the global `note-writer` skill.
- Implement a dual-tag system combining the call-graph structure with the subject domain.

## Tagging Convention

Notes must use a dual-tag system to categorize content along two independent axes: (1) where the component sits in the software architecture (call-graph tag), and (2) what conceptual domain it belongs to (domain tag).

NEVER create tags that conflict with existing ones in the knowledge garden: if `#math/algebra/groups` already exists, do not write `#math/groups`. Before creating tags, search the existing knowledge garden with `rg` or `sk` to check for conflicts.

### 1. Call-Graph Tags

These tags encode the component's position in the source tree. The root is always the package name, followed by the directory path (preserved as-is from the file system), ending with the specific type, interface, function, or concept being documented.

**Format**: `#<package-name>/<dir-path>/<this-component>`

**Examples**:
- `#spenso/src/tensors/data/dense/DenseTensor` (documenting a type in `src/tensors/data/dense.rs`)
- `#spenso/src/structure/lorentz/Lorentz` (documenting a function in `src/structure/lorentz.rs`)
- `#react/src/hooks/useEffect` (documenting a function)
- `#numpy/numpy/linalg/linalg/svd` (documenting a function; folder structure preserved as-is)

### 2. Domain Tags

These tags categorize the underlying subject matter or technology.

**Format**: `#<domain>/<sub-domain>/<smaller-subdomain-if-any>`

**Examples**:
- `#computer-science/rust`
- `#math/algebra/groups`
- `#physics/quantum-mechanics`
- `#system-design/architecture`

## Locate Package Root

Before assigning any tags, determine the package root — the directory containing the project manifest. This is a one-time step per ripping session.

```bash
fd -d3 '(Cargo\.toml|pyproject\.toml|go\.mod|Package\.toml|package\.json|setup\.py|CMakeLists\.txt|Mix\.exs|dune-project)'
```

Pick the marker closest to the source files being documented. For monorepos with multiple markers, select the one whose directory contains the component's definition file.

**Package name**: use the directory name of the marker file, unless the manifest contains an explicit `name` field (e.g., `name = "spenso"` in `Cargo.toml`, `"name": "spenso"` in `package.json`).

## Tag Assignment

Call-graph tags are derived deterministically from the component's file path in the source tree. The folder structure is preserved as-is — no stripping of `src/`, `lib/`, or similar segments.

### Step 1: Identify the language

Determine the language from file extensions or user input. Look up declaration keywords in `declaration-keywords.csv`.

### Step 2: Search for the definition

```bash
rg "(keyword1|keyword2|...)\s+<SymbolName>" -l
```

Fallback if the keyword search returns nothing:

```bash
rg -w "<SymbolName>" -l
```

### Step 3: Tie-break among candidates

When multiple files declare the same symbol, select the canonical definition:

1. Exclude files under `test/`, `spec/`, `bench/` directories
2. Among the remaining candidates, sort by shallowest path (fewest `/` segments), then alphabetically
3. If all candidates were excluded in step 1, fall back to the full unsorted list and apply step 2 only

```bash
candidates=$(rg "(keyword1|keyword2|...)\s+<SymbolName>" -l | rg -v '/(test|spec|bench)/')
if [ -z "$candidates" ]; then
  candidates=$(rg "(keyword1|keyword2|...)\s+<SymbolName>" -l)
fi
echo "$candidates" | awk -F/ '{print NF, $0}' | sort -t' ' -k1,1n -k2 | cut -d' ' -f2- | head -1
```

**Multi-definition components** (Julia multi-methods, Rust trait impls, extension methods): one tag per conceptual component. All non-canonical definition sites are recorded in the cross-reference CSV (see below), not as separate tags.

### Step 4: Convert the file path to a tag

1. Strip the package root directory prefix
2. Strip the file extension
3. Prepend `#<package-name>/`, append `/<SymbolName>`

```bash
echo "<winning-path>" \
  | sd '^<package-root-dir>/' '' \
  | sd '\.[^.]*$' '' \
  | sd '^(.+)$' '#<package-name>/$1/<SymbolName>'
```

**Example**: package root `spenso/`, package name `spenso`, winning path `spenso/src/tensors/data/dense.rs`, symbol `DenseTensor`:

```
spenso/src/tensors/data/dense.rs
→ src/tensors/data/dense          (strip prefix + extension)
→ #spenso/src/tensors/data/dense/DenseTensor
```

## Cross-Reference Discovery

After assigning a tag, discover which other components reference this one. This is heuristic — it catches direct imports and calls but may miss indirect references (callbacks, dynamic dispatch, event handlers). That is acceptable: the goal is useful wikilinks between notes, not a complete dependency graph.

### Search strategy

Apply in order; stop when you have enough results:

1. **Import statements**: `rg -n "(import|use|require|from|include)\b.*<SymbolName>"`
2. **Call sites**: `rg -w "<SymbolName>\s*\(" -l` and `rg -w "<SymbolName>[\.:]" -l`
3. **Fallback**: `rg -w "<SymbolName>" -l`

### Record results

Write findings to `./discovery/<component-name>.csv` with columns `file,line,context`:

```bash
rg -n "<SymbolName>" <search-path> \
  | sd '^<repo-root>/' '' \
  | sd '^(.+):(\d+):(.*)$' '$1,$2,$3' \
  >> ./discovery/<component-name>.csv
```

**When writing the note** for `<component-name>`, read `./discovery/<component-name>.csv` and use its entries to create `[[wikilinks]]` to referencing components — derive their tags from file paths via the Tag Assignment procedure.


## Note Structure

Every technical note must follow a strict logical flow that maps to a "Design -> Implement -> MWE -> Caveats" structure:

1.  **Motivation (Design Principle)**
    *   **Purpose**: The high-level theory, design principle, or motivation. Why does this module/component exist?
    *   **Content**: What problem does it solve? What is the core abstraction idea?
    *   **Rule**: *Never hide abstractions behind syntactic sugar.* State the raw design principle clearly before showing how a language or framework simplifies its expression.

2.  **Discussion (Implementation Detail)**
    *   **Purpose**: Technical implementation details.
    *   **Content**: How is the design principle realized in the code? What are the key data structures or algorithms used internally?

3.  **Result (Minimum Working Example - MWE)**
    *   **Purpose**: Practical code snippet demonstrating usage.
    *   **Content**: A minimal, self-contained, reproducible code block showing how to use the component.

4.  **Remark (Caveats & Composition)**
    *   **Purpose**: Known limitations, warnings, edge cases, and interactions.
    *   **Content**: How does this compose with other modules or tools? What are the performance implications? What should the user *not* do?

5.  **Glossary** (Optional but recommended)
    *   **Purpose**: Definitions for key terms used in the note.

## Narration Flow

Maintain a **coherent narration flow** throughout the note. The text should read like a continuous explanation, weaving code blocks into the prose logically. Do not dump code without context; introduce each snippet and explain its outcome.

**Example of Bad Flow**:
> Here is how to create a tensor.
> ```rust
> let tensor = DenseTensor::new(struct, data);
> ```
> Tensors are useful.

**Example of Good Coherent Flow**:
> To instantiate our data structure, we combine the pre-defined skeleton with our raw numerical values. We do this by calling the constructor, which expects the sorted structure
> ```rust
> // and the raw data,
> let tensor = DenseTensor::new(perm_struct.structure, raw_data)
> // to produce the final tensor, where we crash if the data size does not match
>     .expect("Data size must match structure volume");
> ```
> This ensures that our raw data correctly matches the library's internal ordering. Note that because we use `expect`, we explicitly crash to prevent silent data corruption down the line.

## Organization

- **Flat Notes**: Core technical notes detailing individual components (types, functions, modules) should be organized flatly within a main package directory (e.g., `<package-name>/`). These are atomic — each note covers exactly one component. Read `~/silverbullet-space-agent/atomic_notes.md` to understand atomic notes.
- **Tutorial/ Folder**: Long-form content that connects atomic notes into broader context — architectural overviews, tutorials, and guides that show how components compose. These live in `<package-name>/Tutorial/`.
- NEVER write tutorials before writing enough atomic notes. Tutorials build on atomic notes via `[[wikilinks]]`; they must not duplicate content that belongs in an atomic note.
- For each software package, write only atomic notes and tutorial notes. Every piece of documentation is either an atomic note explaining one component in detail, or a tutorial that links atomic notes together.
