# Git and PowerShell Command Reference

A quick-reference guide for managing permissions, installing dependencies, and executing PowerShell scripts inside Linux environments like GitHub Codespaces and GitHub Actions runners.

## File Permissions & Git Tracking

### Grants Permission
Use these commands when you encounter a `Permission denied` error.

```bash
# Fix locally/instantly inside your current Linux/Codespaces terminal
chmod +x HelloWorld.ps1

# Force Git to track execution permissions so it works after pushing to GitHub
git update-index --add --chmod=+x HelloWorld.ps1

# Stage all changes before committing
git add HelloWorld.ps1

# Save changes to repository history
git commit -m "Fix script permissions and make executable"

# Push the permission fix to the remote repository
git push
```

### Useful Permission Verification
```bash
# Check current file permissions in Linux (look for 'x' which means executable)
ls -l HelloWorld.ps1

# Check file permissions as tracked by Git (executable files show 100755)
git ls-files --stage HelloWorld.ps1
```

---

## PowerShell Environment Setup

### Installation (Debian/Ubuntu-based Linux)
If the environment lacks the `pwsh` command, update the package manager and install it.

```bash
# Fetch the latest package lists from repositories
sudo apt-get update

# Install PowerShell automatically without prompting for confirmation
sudo apt-get install -y powershell
```

---

## Script Execution

### Run PowerShell Script
Always specify the interpreter if your default shell environment is Bash.

```bash
# Execute the script directly using the PowerShell interpreter
pwsh ./HelloWorld.ps1

# Alternative: Execute by passing a script block or command string directly
pwsh -Command "Write-Host 'Testing PowerShell engine'"
```

### Profile & Version Utility
```bash
# Check your current PowerShell engine version details
pwsh -Command "\$PSVersionTable"

# Locate the current user's PowerShell profile path on Linux
pwsh -Command "\$PROFILE"
```