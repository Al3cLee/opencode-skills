---
name: note-writer
description: Guide for writing technical notes and documents. Covers structure, organization, and style for physics, mathematics, and computer science notes. Use when writing reports, documentation, or any technical content.
keywords:
  - writing
  - technical writing
  - style guide
  - documentation
  - technical notes
  - report writing
  - physics notes
  - math notes
  - CS notes
---

# Technical Writing Style Guide

## Purpose

This guide defines the standards for writing technical documents, including reports, code documentation, and technical notes. Always follow this guide when producing any technical content.

## Definition of Technical Content

**Technical content** refers to notes or documents that require a certain amount of technical knowledge to work through and understand, as opposed to shallow notes that are merely quotes and comments. Technical notes are often written by hand first and then typeset. For subjects like physics and mathematics, almost all notes are technical.

---

## Narration Stages

Every technical note or document should follow a four-part structure:

1. motivation
2. discussion
3. results
4. remarks

Each part is called a "narration stage". After all four stages are reached, you have completed a narration cycle. Then, you may start again with a new motivation stage.

ALL technical notes are ALWAYS a combination of one or more narration cycles. Each narration cycle always contains the four parts. A technical note's structure can look like this:

```markdown
**Motivation.** ...
**Discussion.** ...
**Result.** ...
**Remark.**...
**Remark.**

**Motivation.** Building on our previous result, we are now curious to define... via... which we do not know yet... so let us consider...
**Discussion.** ...
**Result.** ...
**Remark.**...
```

### 1. Motivation

Start with motivation paragraphs that establish the context against which the question or topic to be considered is set. The motivation raises the question that the rest of the document will address.

### 2. Discussion

After the motivation paragraph, engage in detailed discussion. In mathematics this is often organized in a "claim-proof" structure, but qualitative arguments (which are not formally rigorous) and analogies are often invoked in other fields.

**Important**: Do not write down the word "proof" explicitly before starting the discussion. Simply let the discussion proceed naturally after the motivation paragraph.

### 3. Results

When the discussion yields a result, explicitly write down a result paragraph. For math notes this is typically a theorem; for physics this paragraph summarizes the result and may include qualitative descriptions.

Each "result" should:
- Be a summary of either a theoretical result or an experimental finding
- Begin with assumptions
- Expand on methods
- Emphasize the end results obtained

Example format: "For [xx], assuming [xxx], by doing [xxx] and [xxx], we have that [xxx]."

### 4. Remarks

After arriving at a result, take time to reflect on the Q&A session and make remarks. Remarks can be qualitative arguments which, without understanding technical details, are hard to appreciate. Imagine there is an inquisitive reader who might challenge your argument, and answer this inquisitive reader.

Following each result, include remarks concerning:
- The result's scope: this follows from the key assumptions made during the derivation.
- Room for improvement: this follows from the result's scope and derivation.
---
## Style Conventions

- ALWAYS use a bold run-in title in the first paragraph of each part: the first paragraph of motivation should be `**Motivation. ** We consider ...`, etc.
- Titles indicate **topics**, not sections of the structure. DO NOT use markdown headings to indicate narration stage.
- ALWAYS use a continuous narration flow, in spite of non-text elements inserted into a paragraph, e.g. code blocks, equations, pictures. NEVER let these disrupt your narration flow. For code blocks, let your narration flow into the comments in the code, and then flow back to text.
- NEVER use bullet lists for purposes other than plainly listing things.

---

## Domain-Specific Guidelines

### Physics Notes

**Separation of Formalism and Applications**: A physical formalism (i.e., a "theory") and its applications are often written in the same chapter in textbooks. This prevents the reader from separating the specifics from general considerations and postulates. In technical physics notes, separate the formalism from its applications.

**Problem with Context-Limited Examples**: A theory is often elaborated exclusively within the context of an example. While a good motivational part is always appreciated, being limited to one specific case can be annoying (e.g., a chapter on angular momentum that only discusses spin-1/2).

**Approach**:
- Take notes on the formalism without relying on its applications
- When only knowing about a specific case, take notes on this case only and refrain from naming the note as "some theory"

### Computer Science Notes

**Logical Order Challenges**: In computer science, especially the less "theoretical" parts, logical reasoning is not usually the key. Instead, various concepts are often intertwined, one depending on another without having an overall pre-determined logical order.

**Approach**:
- Find good motivation first. Software cannot take shape without solid motivation. The motivation is often that a tedious task can be automated with code.
- Start with this motivation and bring up new concepts that it produces.
- When earlier concepts require later ones to elaborate, do not hesitate to mention the later ones (in wiki-links). Arranging concepts in a perfectly logical order is against the nature of programs—functionalities are developed with each other in mind, not in a rigid logical sequence.

**Clarity Enhancements**:
- ALWAYS provide a glossary of technical terms: any new jargon introduced in this note MUST be included.
- Always try to provide a real-life example which seem trivial but embeds insightful conceptual progress.
- Provide a minimum working example for each key concept.
