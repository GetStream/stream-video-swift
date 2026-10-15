# Optional skill setup

Check the active agent's project and global skills. Reuse existing installations and session choices.
Do not repeat a declined offer unless requirements change.
Use helpers according to the [shared rules](../AGENTS.md#communicate-clearly).

## Suggested companions

Installation is optional. Explain each missing skill's benefit before offering it.

| Skill | Upstream source | Benefit |
| --- | --- | --- |
| `ponytail` | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | Keeps changes small and reuses existing code. Reduces unnecessary abstractions. |
| `i-have-adhd` | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | Makes the next action clear. Uses bounded steps and visible progress. |
| `asd-ste100` | [danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill) | Makes instructions and reports easier to interpret. Preserves conditions and uncertainty. |

If declined, continue with the repository workflow. Helpers cannot relax TDD gates or user authorization.

## Ask before installation

1. Identify the current agent from the host context. Ask if it is unclear.
   Check its supported CLI identifier, such as `codex`, `cursor`, or `claude-code`.
2. Explain the missing skills, sources, and benefits. Ask which to install and use.
   Ask for project scope (this checkout) or global scope (all user projects).
3. For any additional required skill, explain the dependent task step and available fallback.
   Obtain the same skill, scope, and agent choices. Continue independent work while awaiting an answer.
4. Check the source and exact skill name. Use only the [skills.sh CLI](https://skills.sh/docs/cli).
   Ask before installing a missing CLI runtime or overwriting a modified installation.
5. Check the installed skill for the chosen scope and agent. Read it and apply it.
   Explain any required reload before claiming activation.
   Report installed names, scope, agent, and generated project files.

## Installation commands

Replace every placeholder. Run project installations from the repository root.
The [CLI documentation](https://github.com/vercel-labs/skills#available-options)
defines the `--skill`, `--agent`, and `--global` options.

```sh
npx skills add <source> --skill <skill-name> --agent <agent-id>
```

Add `--global` only for the approved global scope. Always supply the active agent with `--agent`.
Never select other agents, use `--all`, or use an agent wildcard.
Use `--yes` only after the user approves the exact skill, scope, and agent.
Check with `npx skills list --agent <agent-id>`. Add `--global` for global installations.
If the CLI does not support the agent, report the limit and use the local workflow files.
