# V021 Update Dock Failure Diagnosis

Observed failure pattern:

```text
VERSION=V015A
HEALTH=PASS
RESTART=PASS
WATCHER=PASS
BUNDLE=READY
RESULT=PASS
```

Meaning:
- Bali is healthy.
- The watcher is alive.
- The app restarts cleanly.
- The patch was not installed by Update Dock.

Likely cause:
- Update Dock ZIP validator/apply flow rejects the package format or does not run the install payload.

Decision:
- Treat Update Dock as a later subsystem to repair.
- Use the proven direct no-Python one-click runner for feature installs.
- Keep Update Dock tests separate from feature patches.
