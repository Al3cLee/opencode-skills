---
name: knowledge-garden
description: This skill should be used when writing, editing, or organizing notes in a SilverBullet-based knowledge garden. It covers the tagging system, wikilink and transclusion syntax, atomic note style, and frontmatter conventions specific to this space.
keywords:
  - silverbullet
  - knowledge-garden
  - atomic-notes
  - wikilinks
  - transclusions
  - tagging
  - note-taking
  - pkm
  - zettelkasten
  - frontmatter
---

# Knowledge Garden Skill

## Purpose

This skill governs how to write, edit, and organize notes in a SilverBullet-based knowledge garden. The knowledge garden is a flat collection of interconnected markdown files where notes are linked by wikilinks, organized by a hierarchical tag system, and kept atomic — each note addresses one and only one topic.

## 1. Tagging System

Tags replace folders as the primary organization mechanism. Every note carries one or more hierarchical hashtags of the form:

```
#domain/subdomain/smaller_subdomain
```

### Rules

- Use lowercase with hyphens for multi-word segments: `#computer-science`, `#quantum-field-theory`.
- Slashes create hierarchy: `#physics/quantum-field-theory`, `#physics/condensed-matter`, `#physics/statistical-mechanics/spin-glass`.
- A note can have multiple tags when the topic spans domains, e.g. a note on second quantization may carry both `#physics/quantum-field-theory` and `#physics/condensed-matter`.
- Place page-level tags as standalone paragraphs (hashtags alone on a line) so they apply to the entire page, per SilverBullet scope rules.

### Where to put tags

There are two equivalent conventions used in this garden:

1. **Frontmatter `tags` list** — a YAML list under the `tags` key in the frontmatter.
2. **Inline hashtags** — standalone `#tag` lines in the body.

Either or both may appear. When using inline hashtags, place them immediately after the frontmatter, before the first heading. Example:

```markdown
---
finished: false
---

#physics/quantum-field-theory
#physics/condensed-matter

# Second Quantization
```

### Tag vs tags

SilverBullet distinguishes `tag` (the object type, always `"page"` for pages) from `tags` (user-defined topic tags). Never set `tag` manually; only set `tags`.

## 2. Markdown and Wikilink Syntax

This garden runs on SilverBullet, which extends CommonMark markdown. The key extensions are:

### Wikilinks (Internal Links)

- **Link to a page**: `[[page_name]]` — renders as a clickable link to that page.
- **Link with alias**: `[[page_name|display text]]` — the pipe `|` separates the target from the displayed label.
- **Link to a section**: `[[page_name#Section Title]]` — links to a specific heading within a page.
- **Link to a line**: `[[page_name@L5]]` — links to line 5 of the page.

### Markdown-style Internal Links

SilverBullet also supports `[display text](page_name)` for internal links. The wikilink syntax `[[...]]` is preferred in this garden for internal references.

### External Links

Use standard markdown: `[title](https://example.com)`.

### Transclusions (Content Embedding)

Transclusions embed content from another page inline:

- **Embed an entire page**: `![[page_name]]`
- **Embed a section**: `![[page_name#Header]]` — embeds only the content under that heading.

### When to Use Wikilinks vs Transclusions

- Use **wikilinks** `[[...]]` to reference or navigate to another note. This is the default way to connect notes.
- Use **transclusions** `![[...]]` only when the actual content of the other page should appear inline, e.g. embedding a shared definition or a template snippet.

## 3. Atomic Note Style

Every note in this garden should be atomic: it addresses **one and only one topic** and contains no more information than is absolutely necessary for that topic.

### Principles

1. **Focus**: One note, one topic. If a note starts to address two distinct questions, split it into two notes and link them.
2. **Clarity**: The note title (H1 heading) should precisely state the single topic. Avoid vague titles like "Miscellaneous" or "Chapter 3 Notes".
3. **Link over embed**: When a concept depends on another, link to it rather than duplicating its content. Let the reader follow links at their own pace.
4. **Self-contained**: A note should be understandable on its own or by following a small number of wikilinks, not by requiring the reader to have read a long sequence of preceding notes.

### Why Atomic

- Atomic notes make focusing easier for the writer.
- Atomic notes are easier to categorize (their tags align tightly with their content).
- Atomic notes are more likely to be actively used and memorized.
- Atomic notes are less intimidating for the reader.
- Atomic notes enable the reader to learn at their own pace along their own preferred path.

### Technical Notes

For technical notes (physics, mathematics, computer science), follow the narration-cycle structure from the `note-writer` skill: **motivation → discussion → results → remarks**. Separate narration cycles with horizontal rules (`---`). Titles indicate topics, not narration stages — do not use headings like "## Motivation".

## 4. When and How to Use Wikilinks

### When to Link

- **Every mention of a concept that has (or should have) its own note**: If you write "the [[Sochocki_formula]]" and that concept deserves its own atomic note, link it. If the note does not yet exist, link anyway — SilverBullet shows it as a broken link that can be followed to create the page.
- **Forward references**: In computer science notes especially, do not hesitate to link to concepts that have not been introduced yet. Arrange concepts in a natural rather than rigidly logical order.
- **Cross-domain connections**: When a note spans domains (e.g. both physics and math), link to the relevant notes in each domain.

### How to Link

- **First mention**: Link the first occurrence of a concept in a note. Subsequent mentions in the same note need not be linked unless clarity demands it.
- **Prefer `[[snake_case]]` page names**: Page names use `snake_case` (e.g. `[[mean_field_theory]]`, `[[second_quantization]]`). The H1 heading on the page may use title case or other formatting.
- **Section links for precision**: When referring to a specific part of a long note, use `[[page_name#Section]]` to link directly to the relevant section.

### When NOT to Link

- Do not link common words or concepts that are universal knowledge in the note's domain.
- Do not over-link within a single note; link the first mention and move on.

## 5. Frontmatter Convention

Every note must include YAML frontmatter with at minimum the `finished` attribute:

```yaml
---
finished: false
---
```

### The `finished` Attribute

- `finished: false` — the note is a work in progress and needs further editing. It will appear on the `unfinished_pages` query.
- `finished: true` — the note is in a stable state. This does not mean it will never be edited again, only that it is not actively incomplete.

**Default**: Always set `finished: false` when creating a new note. Change to `finished: true` only when the note reaches a coherent, self-contained state.

### Other Frontmatter Fields

- `tags`: A YAML list of topic tags (alternative or supplement to inline hashtags). Example: `tags: ["math/complex-analysis"]`.
- `url`, `date`, `title`: Used for reference pages (notes about external sources). See the reference page template.

## 6. Note Creation Workflow

1. Determine the single topic the note will address. If it covers more than one, split.
2. Create the file with `snake_case.md` naming.
3. Add frontmatter with `finished: false`.
4. Add tag(s) — either as frontmatter `tags` list or inline `#domain/subdomain` lines.
5. Write the H1 heading as the topic title.
6. Write the note body following the atomic and (for technical notes) narration-cycle principles.
7. Insert `[[wikilinks]]` for every concept that has or deserves its own note.
8. When the note reaches a coherent state, set `finished: true`.

## 7. Reference

- Knowledge garden overview: `knowledge_garden.md`
- Atomic notes philosophy: `atomic_notes.md`
- Tag system details: `tag_system.md`
- Technical note style: `technical_note.md`
- SilverBullet links: https://silverbullet.md/Link
- SilverBullet transclusions: https://silverbullet.md/Transclusions
- SilverBullet hashtags: https://silverbullet.md/Markdown/Hashtags
