export const SessionBootstrapPlugin = async () => {
  return {
    "tui.prompt.append": async (_input, output) => {
      const reminder = "Use the native skill-driven workflow in this repository. Check .opencode/commands for entrypoints and load relevant skills from .opencode/skills when a task matches."
      if (typeof output.prompt === "string" && !output.prompt.includes(reminder)) {
        output.prompt = `${output.prompt}\n\n${reminder}`
      }
    },
  }
}
