# Intake: adding a task with its own workspace and commander

Run this only when the human explicitly asks to add a task with its own workspace and
commander (for example "add workspace for ...", "create a new commander for ..."). The
Mayor sets the task up; the work itself, including filing its issue, belongs to the
commander. Pick a provisional name for the task and `<topic>-cmd` for the agent.

1. **Keep the handoff.** Copy any handoff document the human points at out of `/tmp`
   (it can vanish) into a git-ignored work folder beside the ledger, such as
   `<vault>/.local/<provisional name>/handoff.md`. Confirm with `git check-ignore -v
   <path>`: older files under that folder may still be tracked, and handoffs can hold
   material that must not be published.
2. **Write the brief**, `BRIEF.md` in the same folder:
   - the human's request verbatim, with date and time;
   - the facts the Mayor checked (related workspaces from the roster, the sources read),
     marking what it did not check;
   - `references/commander-brief.md` as the protocol;
   - that until the Mayor names its Inbox project folder, it reports by `report.sh`
     (urgent with `--urgent yes`) and in its own pane, never in the Inbox;
   - that it reports a fixed issue ID and any delegation by `report.sh --kind other`;
   - that outward actions still need the human's direct confirmation.
   Filing the issue and a desk note follow the commander's own rules; relay the human's
   instructions about them verbatim instead of adding Mayor defaults.
3. **Create the workspace and the commander.**

   ```bash
   herdr workspace create --cwd <cwd> --label "<provisional name>--<title>" --no-focus
   herdr agent start <name> --kind claude --pane <root pane> -- --model <model> --effort <effort> --name <name>
   herdr pane rename <root pane> <name>
   ```

   Use the model and effort the human named, else the other commanders'. Afterwards
   check that `~/.claude/settings.json` still has its previous `model`: a `/model`
   switch rewrites the global default.
4. **Register and brief.** Add the roster row (focus), run `$S/mayor.sh snapshot`, add the
   ledger section, and relay `[mayor から] … <BRIEF path> を読み、そのとおりに進めてください。`
   with `$S/mayor.sh relay`. A new session has the Inbox tool from the start. Confirm the
   commander turned `working`: a codex commander may first show a hooks-trust prompt for
   the human, and input sent right after that answer can be lost.
5. **Give the project once the ID is fixed.** When the commander reports its issue ID,
   run `$S/mayor.sh project <name> <issue>` (`inbox.md`), fix the ledger section, run
   `snapshot`, and relay the folder's absolute path. A task without a tracker issue
   keeps its provisional name as the ID: run `project` before step 4 and put the folder
   in the brief. Never create a folder under a provisional ID that will be replaced.
6. **Delegations.** When a commander hands part of its work to a new workspace and agent,
   it reports the workspace, agent, item, cwd and the delegate's issue ID by
   `report.sh --kind other` (again once the ID is fixed, if it was not yet). Add the delegate to the
   roster as a commander of its own. Once the ID is fixed, run `project` for the delegate
   and relay the folder to both the delegate and its parent. If the delegate's brief does
   not point at `references/commander-brief.md`, send it the Protocol 2 brief. It asks
   the human in the Inbox directly, in its own project.
7. Add a summary message for the new commander (`inbox.md`, "The Mayor's summary").
