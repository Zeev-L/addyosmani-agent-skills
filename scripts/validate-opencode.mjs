import fs from "node:fs"
import path from "node:path"

const root = process.cwd()
const requiredFiles = [
  "AGENTS.md",
  ".opencode/commands",
  ".opencode/skills",
  ".opencode/agents",
]

for (const rel of requiredFiles) {
  if (!fs.existsSync(path.join(root, rel))) {
    throw new Error(`Missing required path: ${rel}`)
  }
}

const skillRoot = path.join(root, ".opencode", "skills")
for (const entry of fs.readdirSync(skillRoot, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue
  const skillFile = path.join(skillRoot, entry.name, "SKILL.md")
  if (!fs.existsSync(skillFile)) {
    throw new Error(`Missing SKILL.md for skill: ${entry.name}`)
  }
  const content = fs.readFileSync(skillFile, "utf8")
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/)
  if (!match) throw new Error(`Missing frontmatter: ${skillFile}`)
  const frontmatter = match[1]
  const name = frontmatter.match(/^name:\s*(.+)$/m)?.[1]?.trim()
  const description = frontmatter.match(/^description:\s*(.+)$/m)?.[1]?.trim()
  if (!name || !description) {
    throw new Error(`Missing required skill frontmatter fields: ${skillFile}`)
  }
  if (name !== entry.name) {
    throw new Error(`Skill name mismatch: directory=${entry.name} frontmatter=${name}`)
  }
}

const openCodeDocs = [
  "README.md",
  "AGENTS.md",
  "docs/opencode-setup.md",
  "docs/getting-started.md",
]
const forbidden = [".claude/commands", ".claude-plugin", "CLAUDE.md"]
for (const rel of openCodeDocs) {
  const content = fs.readFileSync(path.join(root, rel), "utf8")
  for (const token of forbidden) {
    if (content.includes(token)) {
      throw new Error(`Found stale Claude reference '${token}' in ${rel}`)
    }
  }
}

console.log("OpenCode repository validation passed")
