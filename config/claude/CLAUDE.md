# CLAUDE.md

## Update CLAUDE.md if necessary
If you have CLAUDE.md, please update it if necessary.
User instructions may include implementation background and project specifications. This information may be useful for future implementations.
Also, if the content already contradicts the content written in CLAUDE.md, please check with the user and update it to the latest information.
However, this information is important and should not include any unnecessary speculation.

## Notifications to users

When a task is completed or you need to ask the user to confirm before executing the command, be sure to execute the following command to notify the user.
Important: If you request confirmation, be sure to run the command before doing so.

```bash
osascript -e 'display notification "<insert claude message>" with title "Claude code" sound name "Glass"'
```

## Code editing notes
### When reading or editing TypeScript
When reading TypeScript code, please prioritize using the `mcp__typescript__lsmcp_*` MCP servers.
