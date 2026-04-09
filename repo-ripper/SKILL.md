# repo-ripper Skill

This skill provides guidelines for structured note-taking and documentation for software codebases. It is designed to create a cohesive, deeply linked knowledge base by ripping through a repository and documenting its design and implementation.

## Requirements

- Extend the global `note-writer` skill.
- Implement a dual-tag system combining the call-graph structure with the subject domain.

## Tagging Convention

Notes must use a dual-tag system to categorize content both by its level of abstraction, i.e. its location in the software architecture, and its conceptual domain.

NEVER use tags that conflict with existing ones in the knowledge garden: if we already have `#math/algebra/groups` somewhere, do not write `#math/groups`. You can use ripgrep `rg` or skim `sk` to search in the existing knowledge garden so that your tags don't conflict with them.

### 1. Call-Graph Tags
These tags mirror the package's module hierarchy or call-graph. The root is always the public API or package name, ending with the specific struct, trait, function, or concept being documented. This info can be extracted by using `rg` in this repository (which files call this component?).

**Format**: `#<package-name>/<module>/<sub-module>/<this-component>`

**Examples**:
- `#spenso/tensors/data/DenseTensor` (Documenting a specific struct)
- `#spenso/structure/representation/Lorentz` (Documenting a trait or module)
- `#react/hooks/useEffect` (Documenting a specific function)
- `#numpy/linalg/svd` (Documenting a specific function in a math library)

### 2. Domain Tags
These tags categorize the underlying subject matter or technology.

**Format**: `#<domain>/<sub-domain>`

**Examples**:
- `#computer-science/rust`
- `#math/algebra`
- `#physics/quantum-mechanics`
- `#system-design/architecture`

## Note Structure

Every technical note must follow a strict logical flow that maps to a "Design -> Implement -> MWE -> Caveats" structure:

1.  **Motivation (Design Principle)**
    *   **Purpose**: The high-level theory, design principle, or motivation. Why does this module/component exist?
    *   **Content**: What problem does it solve? What is the core abstraction idea?
    *   **Rule**: *Never hide abstractions with syntax sugar.* Expose the raw, underlying design principle clearly before introducing how the language or framework makes it easier to use in wiki notes.

2.  **Discussion (Implementation Detail)**
    *   **Purpose**: Technical implementation details.
    *   **Content**: How is the design principle actually realized in the code? What are the key data structures or algorithms used under the hood? 

3.  **Result (Minimum Working Example - MWE)**
    *   **Purpose**: Practical code snippet demonstrating usage.
    *   **Content**: A minimal, self-contained, and reproducible code block showing how to use the component.

4.  **Remark (Caveats & Composition)**
    *   **Purpose**: Known limitations, warnings, edge cases, and interactions.
    *   **Content**: How does this compose with other modules or tools? What are the performance implications? What should the user *not* do?

5.  **Glossary** (Optional but recommended)
    *   **Purpose**: Definitions for key terms used in the note.

## Narration Flow

Maintain a **coherent narration flow** throughout the note. The text should read like a continuous explanation, seamlessly weaving in and out of code blocks. Do not just dump code; introduce it logically, and explain its aftermath.

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
> this ensures that our raw data correctly matches the library's internal ordering. Note that because we use `expect`, we explicitly crash to prevent silent data corruption down the line.

## Organization

- **Flat Notes**: Core technical notes detailing individual components, structs, or functions should be organized flatly within a main package directory (e.g., `<package-name>/`). These are atomic. Read ~/silverbullet-space-agent/atomic_notes.md to understand what is an atomic note.
- **Tutorial/ Folder**: Non-atomic, long-form content that "joins the dots", puts the concrete concepts into proper context and higher-level use cases. These notes connect the disparate flat notes into comprehensive guides, tutorials, or architectural overviews, focusing heavily on exposing core abstraction ideas. These live in `<package-name>/Tutorial/`.
- NEVER write tutorials before writing enough atomic notes. Tutorials can only build up on atomic notes, NOT replace them. NEVER try to explain everything in a tutorial; use wiki-links `[[...]]` to link to atomic notes instead.
- For each software package, there should be nothing other than atomic notes and non-atomic tutorials. Anything you write down is either atomic note explaining a detailed component or a "connector" that joins concepts already discussed in atomic notes.
