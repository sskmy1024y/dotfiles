# CLAUDE.md

## Notifications to users

When a task is completed or you need to ask the user to confirm before executing the command, be sure to execute the following command to notify the user: If you request confirmation, be sure to run the command before doing so.

```bash

osascript -e 'display notification "Claude code" with title "<insert claude message>" sound name "Glass"'

```
