import type { Plugin } from "@opencode-ai/plugin"

export const NoCommitPushPlugin: Plugin = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash") {
        const cmd: string = (output.args as { command?: string })?.command ?? ""
        if (/git\s+commit/.test(cmd) || /git\s+push/.test(cmd)) {
          throw new Error(
            "Blocked: git commit and git push must be run manually by the user."
          )
        }
      }
    },
  }
}
