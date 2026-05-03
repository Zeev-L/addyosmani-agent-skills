# Using agent-skills with Cursor

## Setup

### Option 1: Rules Directory (Manual)

Cursor supports a `.cursor/rules/` directory for project-specific rules. This is the recommended way to manage active project context.

```bash
# Create the rules directory
mkdir -p .cursor/rules

# Copy skills you want as rules
cp /path/to/agent-skills/skills/test-driven-development/SKILL.md .cursor/rules/test-driven-development.md
cp /path/to/agent-skills/skills/code-review-and-quality/SKILL.md .cursor/rules/code-review-and-quality.md
cp /path/to/agent-skills/skills/incremental-implementation/SKILL.md .cursor/rules/incremental-implementation.md
```

Rules in this directory are automatically loaded into Cursor's context.

---

### Option 2: Automated Skill Sync (PowerShell)

If you have a local library of skills and want to quickly sync them into your project's Cursor rules, you can use this PowerShell script. It automates the process by scanning your master skills directory and porting each individual skill into your current project.

```powershell
# 1. Define where the actual skill folders live (Update this path to your local library)
$skillsPath = "C:\Path\To\Your\Skills\Library"

# 2. Get the folder names from that specific path
$folders = Get-ChildItem -Path $skillsPath -Directory | Select-Object -ExpandProperty Name

# 3. Loop through and copy
foreach ($folder in $folders) {
    $source = "$skillsPath\$folder\SKILL.md"
    $destination = ".cursor/rules/$folder.md"
    
    if (Test-Path $source) {
        # Ensure the destination folder exists so the copy command doesn't fail
        if (!(Test-Path ".cursor/rules")) { New-Item -ItemType Directory -Path ".cursor/rules" }
        
        cp $source $destination
        Write-Host "Copied: $folder" -ForegroundColor Green
    } else {
        Write-Host "Skipped: SKILL.md not found in $folder" -ForegroundColor Yellow
    }
}
```

#### Script Commands Explained:
* **`Get-ChildItem -Path $skillsPath -Directory`**: Looks into your main skills folder and grabs only the sub-directories (folders), ignoring individual files.
* **`Select-Object -ExpandProperty Name`**: Strips away the extra folder data so the script only keeps the simple folder name.
* **`Test-Path $source`**: A safety check that verifies `SKILL.md` actually exists in that folder before attempting to copy.
* **`New-Item -ItemType Directory`**: Automatically creates the `.cursor/rules` folder in your project if it doesn't exist, preventing errors.
* **`cp $source $destination`**: Copies the master skill file and renames it to match the folder name inside your project's rules directory.

---

### Option 3: .cursorrules File

Create a `.cursorrules` file in your project root with the essential skills inlined:

```bash
# Generate a combined rules file
cat /path/to/agent-skills/skills/test-driven-development/SKILL.md > .cursorrules
echo "\n---\n" >> .cursorrules
cat /path/to/agent-skills/skills/code-review-and-quality/SKILL.md >> .cursorrules
```

---

### Option 4: Notepads

Cursor's Notepads feature lets you store reusable context. Create a notepad for each skill you use frequently:

1.  Open **Cursor → Settings → Notepads**.
2.  Create a new notepad named `swe: Test-Driven Development`.
3.  Paste the content of `skills/test-driven-development/SKILL.md`.
4.  Reference it in chat with `@notepad swe: Test-Driven Development`.

---

## Recommended Configuration

### Essential Skills (Always Load)
Add these to `.cursor/rules/`:
* `test-driven-development.md` — TDD workflow and Prove-It pattern.
* `code-review-and-quality.md` — Five-axis review.
* `incremental-implementation.md` — Build in small verifiable slices.

### Phase-Specific Skills (Load as Notepads)
Create notepads for skills you use contextually:
* `swe: Spec Development` → `spec-driven-development/SKILL.md`.
* `swe: Frontend UI` → `frontend-ui-engineering/SKILL.md`.
* `swe: Security` → `security-and-hardening/SKILL.md`.
* `swe: Performance` → `performance-optimization/SKILL.md`.

---

## Usage Tips

1.  **Context Management**: Don't load all skills at once to avoid hitting context limits. Load 2-3 skills as rules and keep others as notepads.
2.  **Explicit Referencing**: Tell Cursor "Follow the test-driven-development rules for this change" to ensure it reads the loaded rules.
3.  **Agentic Reviews**: Copy `agents/code-reviewer.md` content and tell Cursor to "review this diff using this code review framework".
4.  **On-Demand Loading**: When working on specific tasks, reference relevant notepads (e.g., `@notepad performance-checklist`).
