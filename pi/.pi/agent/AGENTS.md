Codemode

Before any multi-tool step, ask: could this be one codemode script?

Use codemode unprompted for:
- 3+ independent calls
- Large output to filter or summarize in-script
- Loops, pagination, conditional follow-ups
- Undeclared (MCP) tools
- `models.classify()` / `generateImages()`

Use direct tools for:
- Single or dependent calls
- Small, precise edits
- Interactive step-by-step work

In scripts, use `Promise.allSettled()` for parallel calls and return distilled results only.
