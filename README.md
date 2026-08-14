# Quadrim
4 in a row game in a 4 by 4 cube

This document will show how this game was constructed using vibe coding folowing [the workflow described here](https://github.com/evermeer/CodingAgentOrchestration/blob/main/docs/part-1-why-use-an-ai-coding-agent-cli.md#your-workflow)

## The documents

The idea was written three times, and the versions are kept apart on purpose.

| Document | What it is |
|---|---|
| [idea-v0.md](doc/history/idea-v0.md) | The original rough idea, as first written |
| [idea-v1.md](doc/tickets/done/idea-v1.md) | That idea made unambiguous — but still carrying five open questions and a fallback ladder for the top opponent |
| [idea-v1-brainstorming.md](doc/history/idea-v1-brainstorming.md) | v1 brainstormed with the Superpowers skill, which produced several options for each open question |
| [idea-v1-spec.md](doc/tickets/done/idea-v1-spec.md) | v1 turned into a spec with acceptance criteria, which the tickets were cut from |
| [idea-v1-spec-review.md](doc/history/idea-v1-spec-review.md) | v1 spec reviewed by the Agency Agents backend-architect, security-engineer, and product-manager |
| [design.md](doc/design.md) | The design for the first run experience of the game, created with Claude Design |
| [design-handoff.md](doc/DesignHandoff.md) | The design handoff for the first run experience of the game, created with Claude Design |
| [idea-v1-decisions.md](doc/tickets/done/idea-v1-decisions.md) | D01–D217. Every non-obvious choice made along the way, each with the question it answered and what it cost |
| [idea-v2.md](doc/idea-v2.md) | v1 rewritten against everything the build settled. No open functional questions |
| [idea-v2-additions.md](doc/idea-v2-additions.md) | v1 additions and improvements for the next version of the game |
| **[idea-v3.md](doc/idea-v3.md)** | **v2 rewritten with the additions folded into it — progression, monetisation, and a phone-only scope. This is the one to start from** |
| [idea-v3-brainstorming.md](doc/idea-v3-brainstorming.md) | v3 read back against the twenty-two tickets already built — where the spec and the code disagree, and in what order the rest gets built |
| **[idea-v3-spec.md](doc/idea-v3-spec.md)** | **v3 turned into a spec with acceptance criteria — the successor to idea-v1-spec.md, preserving its section numbers and criterion ids** |
| [idea-v3-decisions.md](doc/idea-v3-decisions.md) | D218–D277. The decisions that turned v2 and the additions into v3, and then v3 into a build plan |

`idea-v3.md` is the interesting one if you want to build this yourself. It folds all 277 decisions back into the brief, so the answers arrive with the questions instead of a year later — and it keeps the wrong turnings in, because those cost more time than the right ones saved.

## Starting the Vibe coding workflow

This is now written as a start from doc/idea-v0.md. When restarting the workflow, you can start from doc/idea-v3.md instead. The workflow is described in the [workflow document](https://github.com/evermeer/CodingAgentOrchestration/blob/main/docs/part-1-why-use-an-ai-coding-agent-cli.md#your-workflow)

**Prompt**
```
Here's a rough idea for a game in the file doc/idea-v0.md. Restate the
goal, list the assumptions and unknowns, and don't write any code yet. Ask me
any clarifying questions you need until the goal and constraints are
unambiguous before you summarize. The goal is to have a clear and unambiguous understanding of the game and its requirements before starting to write code.
Put all decisions in the file doc/idea-v1-decisions.md and put the result in the file doc/idea-v1.md
```

The result of that prompt was a [decisions](doc/tickets/done/idea-v1-decisions.md) document and a [final idea](doc/tickets/done/idea-v1.md) document.

**Prompt**
```	
Use the Superpowers brainstorming skill on the created file doc/idea-v1.md. 
Propose several approaches. Ask clarifying questions about the setup, functionality, design and
constraints before proposing options if anything is unclear.
Put the results in the file doc/idea-v1-brainstorming.md
Add all decisions to the file doc/idea-v1-decisions.md
```	

The result of that prompt was a [brainstorming](doc/history/idea-v1-brainstorming.md) document.

This next prompt overrides the write to tickets instructiions of the to-spec skill and instead 
asks to write a spec document. It also answers 2 questions from the brainstorming document.

**Prompt**
```
Use the Matt Skills to-spec skill to turn the doc/idea-v1.md plus the doc/idea-v1-brainstorming.md
into a spec for the game: goal, scope, non-goals, exposed endpoints, data and
acceptance criteria. Ask clarifying questions and don't finalize the spec until
any ambiguities are resolved. Follow recomended strategy A from the brainstorming document.
Use the sugested bots Pebble, Mote, Bramble, Kestrel, Marlin and Onyx.
Put the result in the file doc/idea-v1-spec.md
Add all decisions to the file doc/idea-v1-decisions.md
```

The result of that prompt was a [spec](doc/tickets/done/idea-v1-spec.md) document.

Again overriding the instructions of the to-tickets skill, this next prompt asks to 
break the spec into tickets as markdown files in the .doc/tickets folder.

**Prompt**
```
Use the Matt Skills to-tickets skill to break the doc/idea-v1-spec.md into
small, independently shippable tickets with dependencies and acceptance
criteria, ordered so each can be built, tested, and merged on its own. Ask
clarifying questions about scope or dependencies before finalizing the
breakdown. Store all tickets as a markdown file in the ./doc/tickets folder, 
with a name that starts with the ticket number and a dash, followed by a short 
description of the ticket. For example, 001-setup-project.md. Put the result in 
the ./doc/tickets folder.
Add all decisions to the file doc/idea-v1-decisions.md
```

The result is 22 markdown tickets files in the [tickets folder](doc/tickets) folder.

**Prompt**
```
Review the doc/idea-v1-spec.md and the tickets in the ./doc/tickets folder with the Agency Agents
backend-architect, security-engineer, and product-manager. Have each agent ask
clarifying questions where context is missing before giving their concerns.
Return each agent's concerns and recommendations so I can fold them back into
the spec and tickets. write the concerns and recommendations in the file doc/idea-v1-spec-review.md
Add all decisions to the file doc/idea-v1-decisions.md
```

Solving the main concerns from the review resulted in the following changes to the spec and tickets:

**Prompt**
```
I will not go public with the 0.1 and 0.2 release and only test that with friends and family. This will make it okay to just start with a clean history at 0.3. 
Please work it throug and update the idea-v1-spec-review.md to remove the findings that are now solved with this change or make updates if things have changed.
```

Solving some of the other review issues:

**Prompt**
```
As a reaction on the review, i would likce to process the following changes to the idea-v1.md, idea-v1-spec.md, idea-v1-decisions.md and tickets
- A user will get 2 elo ratings. 1 for games against the computer and 1 against real opponents.
- All 20 computer opponents will be implemented from the start so that they can all be callibrated.
- For games against a computer opponent all processing including validation will be on the users device only. Also the rating for that is only visible on the device itself.
- A user needs to buy an app store subscription for unlocking the feature to play against real opponents. That subscription will be a price per year. It could also be purchased for just 1 year without renewal.
- A user will have an option to configure if it wants a chat in every game, only friends games or never. On the start a game flow this can be changed for that specific game.
```

Cleanup of historical document so we can start another round of reviews.

**Prompt**
```
i would like to move the documents that are only a record and which do not contribure to the implemantation into a doc/history folder.  I think that's the case for idea-v1-brainstorming.md, idea-v1-spec-review.md and the original idea-v0.md please evaluate before moving.
```

Ask for another review that would also update the spec and tickets with the new information.

**Prompt**
```
Start a new review of the doc/idea-v1-spec.md and the tickets in the ./doc/tickets folder and 
also evaluate if averything in idea-v1.md is covered. Ask clarifying questions before proposing
changes if anything is unclear. 
Then use the Agency Agents backend-architect, security-engineer, and product-manager and evaluate 
each agent's concerns and recommendations and ask clarifying questions before you fold 
them back into the spec and tickets. 
Add all decisions to the file doc/idea-v1-decisions.md
```

Found an existing game called Qubic that is similar to Quadrim and has a known first move wins strategy.
Ask for an evaluation if that strategy can be used to create a perfect computer player and if so, add that information to the spec.

**Prompt**
```
I just found out that the game existed earlier and was called Qubic. 
There is even a known first move wins strategy. Documentation including the strategy can be found at https://en.wikipedia.org/wiki/3D_tic-tac-toe 
The complete strategy can be found at https://ranger.uta.edu/~weems/NOTES6319/PAPERSONE/patashnik.pdf
Could that help for creating the perfect computer player? If so, can you add information about that to the specs?
```

Now I went to https://claude.ai/design and asked for a design for the game. The result is in the [design](doc/design.md) document.

**Prompt**
```
Based on the doc/idea-v1.md , the doc/idea-v1-spec.md and the tickets in the doc/tickets folder,
I create a first run experience for the game using Claude Design. 
I put the results in de doc folder. See the DesignHandof.md file for the handoff.

If you need more details about what was done in Claude Design, then you can use the 
claude_design MCP (https://api.anthropic.com/v1/design/mcp, auth via /design-login) to import this project:
https://claude.ai/design/p/b1cfa4c8-147f-43ac-aa79-fc7318d8bfd4?file=First-Run+Experience.dc.html

use the skills design-consultation and design-review to reevaluate the design and flow of the first run experience. 
Make sure that the choices made in the design are consistent with the spec and tickets.
Ask clarifying questions about the design and flow if anything is unclear before finalizing the first run experience.
Add the decissions to the file doc/idea-v1-decisions.md

Then use the skill design:design-handoff to create a design handoff document for the first run experience.
```

Start implementation.

**Prompt**
```
Now that the spec and tickets are finalized, start implementing the game according to the tickets in the ./doc/tickets folder.
The goal is to have a working v0.1 version of the game that can be tested by friends and family.
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-v1-decisions.md
After each ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
```

After it stoped half way (5 times): Continue with other tickets until all tickets are completed and the v0.1 version is ready for testing.

**Prompt**
```
Continue implementing the game according to the tickets in the ./doc/tickets folder.
The goal is to have all tickets implemented so that there is a complete testable version..
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-v1-decisions.md
After each ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
Then open the new app in the simulator.
```

After being notified obout problems with the implementation of the computer player, 
I asked for a reevaluation with updated specs.

**Prompt**
```
do an evaluation rewrite of thicket 026. On a device a move should be done within 20 seconds. 
I don't want to ship more than 50MB of data with the app. While the computer player is thinking 
the player should see a clear indication that it is thinking so that it is clear what the player 
is waiting for.
```

Found the perfect play data.

**Prompt**
```
I found the Patashnic data plus an okay to use it. See the data plus sample code 
at https://github.com/kogorman/qubic start the implementation of the perfect play and then us it 
to fix the other tiers.
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-v1-decisions.md
After each ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
```

Requested some small UI tweaks.

After the UI tweaks were implemented, I reevaluated the design and flow of the first run experience.
I got new idease and recorded them in the [idea-v2-additions.md](doc/idea-v2-additions.md) document.
We will now brainstorm that idea first and then update the spec and tickets with the new information.

**Prompt**
```
After reviewing the current result I had some new ideas and recorded them in doc/idea-v2-additions.md. 
These should be treated as modifications and additions to the idea-v2.md
Restate the goal, list the assumptions and unknowns, and don't write any code yet. Ask me
any clarifying questions you need until the goal and constraints are
unambiguous before you summarize. The goal is to have a clear and unambiguous understanding of the game and its requirements before starting to write code.
Put all decisions in the file doc/idea-v3-decisions.md and put the result in the file doc/idea-v3.md
```

Improving on the idea-v3.md with a brainstorm session

**Prompt**
```
Use the Superpowers brainstorming skill on the created file doc/idea-v3.md. 
Take into consideration what is already implemented.
Propose several approaches. Ask clarifying questions about the setup, functionality, design and
constraints before proposing options if anything is unclear.
Put the results in the file doc/idea-v3-brainstorming.md
Add all decisions to the file doc/idea-v3-decisions.md
```

Create a fresh specification document.

**Prompt**
```
Use the Matt Skills to-spec skill to turn the doc/idea-v3.md plus the doc/idea-v3-brainstorming.md
into a spec for the game: goal, scope, non-goals, exposed endpoints, data and
acceptance criteria. Ask clarifying questions and don't finalize the spec until
any ambiguities are resolved. Follow recomended strategy A from the brainstorming document.
Use the sugested bots Pebble, Mote, Bramble, Kestrel, Marlin and Onyx.
Put the result in the file doc/idea-v3-spec.md
Add all decisions to the file doc/idea-v3-decisions.md
```

Now crete the new tickets

**Prompt**
```
Use the Matt Skills to-tickets skill to break what not yet implemented indoc/idea-v3-spec.md 
into small, independently shippable tickets with dependencies and acceptance
criteria, ordered so each can be built, tested, and merged on its own. Ask
clarifying questions about scope or dependencies before finalizing the
breakdown. Store all tickets as a markdown file in the ./doc/tickets folder, 
with a name that starts with the ticket number and a dash, followed by a short 
description of the ticket. For example, 001-setup-project.md. Put the result in 
the ./doc/tickets folder.
Add all decisions to the file doc/idea-v3-decisions.md
```

And start the implementation again

**Prompt**
```
Continue implementing the game according to the tickets in the ./doc/tickets folder.
The goal is to have all tickets implemented so that there is a complete testable version..
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-v3-decisions.md
After each ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
Then open the new app in the simulator.
```
