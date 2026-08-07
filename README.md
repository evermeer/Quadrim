# Quadrim
4 in a row game in a 4 by 4 cube

This document will show how this game was constructed using vibe coding folowing [the workflow described here](https://github.com/evermeer/CodingAgentOrchestration/blob/main/docs/part-1-why-use-an-ai-coding-agent-cli.md#your-workflow)

Here is what i wrote as the initial [Idea](doc/history/IDEA.md) for the game.

**Prompt**
```
Here's a rough idea for a game in the file doc/idea.md. Restate the
goal, list the assumptions and unknowns, and don't write any code yet. Ask me
any clarifying questions you need until the goal and constraints are
unambiguous before you summarize. The goal is to have a clear and unambiguous understanding of the game and its requirements before starting to write code.
Put all decisions in the file doc/idea-decisions.md and put the result in the file doc/Idea-final.md
```

The result of that prompt was a [decisions](doc/idea-decisions.md) document and a [final idea](doc/Idea-final.md) document.

**Prompt**
```	
Use the Superpowers brainstorming skill on the created file doc/Idea-final.md. 
Propose several approaches. Ask clarifying questions about the setup, functionality, design and
constraints before proposing options if anything is unclear.
Put the results in the file doc/Idea-final-brainstorming.md
Add all decisions to the file doc/idea-decisions.md
```	

The result of that prompt was a [brainstorming](doc/history/Idea-final-brainstorming.md) document.

This next prompt overrides the write to tickets instructiions of the to-spec skill and instead 
asks to write a spec document. It also answers 2 questions from the brainstorming document.

**Prompt**
```
Use the Matt Skills to-spec skill to turn the doc/Idea-final.md plus the doc/Idea-final-brainstorming.md
into a spec for the game: goal, scope, non-goals, exposed endpoints, data and
acceptance criteria. Ask clarifying questions and don't finalize the spec until
any ambiguities are resolved. Follow recomended strategy A from the brainstorming document.
Use the sugested bots Pebble, Mote, Bramble, Ember, Basalt and Onyx.
Put the result in the file doc/Idea-final-spec.md
Add all decisions to the file doc/idea-decisions.md
```

The result of that prompt was a [spec](doc/Idea-final-spec.md) document.

Again overriding the instructions of the to-tickets skill, this next prompt asks to 
break the spec into tickets as markdown files in the .doc/tickets folder.

**Prompt**
```
Use the Matt Skills to-tickets skill to break the doc/Idea-final-spec.md into
small, independently shippable tickets with dependencies and acceptance
criteria, ordered so each can be built, tested, and merged on its own. Ask
clarifying questions about scope or dependencies before finalizing the
breakdown. Store all tickets as a markdown file in the ./doc/tickets folder, 
with a name that starts with the ticket number and a dash, followed by a short 
description of the ticket. For example, 001-setup-project.md. Put the result in 
the ./doc/tickets folder.
Add all decisions to the file doc/idea-decisions.md
```

The result is 22 markdown tickets files in the [tickets folder](doc/tickets) folder.

**Prompt**
```
Review the doc/Idea-final-spec.md and the tickets in the ./doc/tickets folder with the Agency Agents
backend-architect, security-engineer, and product-manager. Have each agent ask
clarifying questions where context is missing before giving their concerns.
Return each agent's concerns and recommendations so I can fold them back into
the spec and tickets. write the concerns and recommendations in the file doc/Idea-final-spec-review.md
Add all decisions to the file doc/idea-decisions.md
```

Solving the main concerns from the review resulted in the following changes to the spec and tickets:

**Prompt**
```
I will not go public with the 0.1 and 0.2 release and only test that with friends and family. This will make it okay to just start with a clean history at 0.3. 
Please work it throug and update the Idea-final-spec-review.md to remove the findings that are now solved with this change or make updates if things have changed.
```

Solving some of the other review issues:

**Prompt**
```
As a reaction on the review, i would likce to process the following changes to the idea-final.md, idea-final-spec.md, idea-decisions.md and tickets
- A user will get 2 elo ratings. 1 for games against the computer and 1 against real opponents.
- All 20 computer opponents will be implemented from the start so that they can all be callibrated.
- For games against a computer opponent all processing including validation will be on the users device only. Also the rating for that is only visible on the device itself.
- A user needs to buy an app store subscription for unlocking the feature to play against real opponents. That subscription will be a price per year. It could also be purchased for just 1 year without renewal.
- A user will have an option to configure if it wants a chat in every game, only friends games or never. On the start a game flow this can be changed for that specific game.
```

Cleanup of historical document so we can start another round of reviews.

**Prompt**
```
i would like to move the documents that are only a record and which do not contribure to the implemantation into a doc/history folder.  I think that's the case for idea-final-brainstorming.md, idea-final-spec-review.md and the original idea.md please evaluate before moving.
```

Ask for another review that would also update the spec and tickets with the new information.

**Prompt**
```
Start a new review of the doc/Idea-final-spec.md and the tickets in the ./doc/tickets folder and 
also evaluate if averything in idea-final.md is covered. Ask clarifying questions before proposing
changes if anything is unclear. 
Then use the Agency Agents backend-architect, security-engineer, and product-manager and evaluate 
each agent's concerns and recommendations and ask clarifying questions before you fold 
them back into the spec and tickets. 
Add all decisions to the file doc/idea-decisions.md
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
Based on the doc/Idea-final.md , the doc/Idea-final-spec.md and the tickets in the doc/tickets folder,
I create a first run experience for the game using Claude Design. 
I put the results in de doc folder. See the DesignHandof.md file for the handoff.

If you need more details about what was done in Claude Design, then you can use the 
claude_design MCP (https://api.anthropic.com/v1/design/mcp, auth via /design-login) to import this project:
https://claude.ai/design/p/b1cfa4c8-147f-43ac-aa79-fc7318d8bfd4?file=First-Run+Experience.dc.html

use the skills design-consultation and design-review to reevaluate the design and flow of the first run experience. 
Make sure that the choices made in the design are consistent with the spec and tickets.
Ask clarifying questions about the design and flow if anything is unclear before finalizing the first run experience.
Add the decissions to the file doc/idea-decisions.md

Then use the skill design:design-handoff to create a design handoff document for the first run experience.
```

Start implementation.
**Prompt**
```
Now that the spec and tickets are finalized, start implementing the game according to the tickets in the ./doc/tickets folder.
The goal is to have a working v0.1 version of the game that can be tested by friends and family.
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-decisions.md
After each ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
```
