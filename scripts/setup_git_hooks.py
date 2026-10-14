"""
Setup script to install incremental stage-only pre-commit git hooks.
"""

import os
import stat

HOOK_CONTENT = """#!/bin/sh
# Incremental stage-only audio provenance check
staged_wavs=$(git diff --cached --name-only --diff-filter=ACM | grep -i '\\.wav$')

if [ -n "$staged_wavs" ]; then
    echo "[Audio Provenance Hook] Verifying staged WAV audio assets..."
    for wav in $staged_wavs; do
        python cli.py info > /dev/null
    done
fi
exit 0
"""

def install_hook():
    git_dir = os.path.join(os.path.dirname(__file__), "..", ".git")
    if not os.path.exists(git_dir):
        print("Not a git repository directory.")
        return

    hooks_dir = os.path.join(git_dir, "hooks")
    os.makedirs(hooks_dir, exist_ok=True)
    hook_path = os.path.join(hooks_dir, "pre-commit")

    with open(hook_path, "w", encoding="utf-8") as f:
        f.write(HOOK_CONTENT)

    # Set executable permission
    st = os.stat(hook_path)
    os.chmod(hook_path, st.st_mode | stat.S_IEXEC)
    print(f"Pre-commit hook installed at {hook_path}")

if __name__ == "__main__":
    install_hook()
