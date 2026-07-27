# FAE Skill: Wiki Search

Query the P2P wiki mesh from anywhere on the X0X network.

## Capabilities

- Search wiki pages by keyword
- Read page content
- List all pages on the mesh
- Diff between versions

## Implementation

Connects to llm-wiki MCP endpoint and returns results through X0X DM to requesting agent.

```
FAE ──MCP──▶ llm-wiki:18765 ──search──▶ tantivy index
  │
  └──X0X DM──▶ requesting agent
```

## Configuration

- `wiki.endpoint` in FAE config
- Pages cached in local SQLite for offline mesh access
