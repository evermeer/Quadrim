# Quadrim
4 in a row game in a 4 by 4 cube

This document will show how this game was constructed using vibe coding folowing [the workflow described here](https://github.com/evermeer/CodingAgentOrchestration/blob/main/docs/part-1-why-use-an-ai-coding-agent-cli.md#your-workflow)

Here is what i wrote as the initial [Idea](doc/IDEA.md) for the game.

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
```	

The result of that prompt was a [brainstorming](doc/Idea-final-brainstorming.md) document.

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
```

The result is 22 markdown tickets files in the [tickets folder](doc/tickets) folder.

**Prompt**
```
Review the doc/Idea-final-spec.md and the tickets in the ./doc/tickets folder with the Agency Agents
backend-architect, security-engineer, and product-manager. Have each agent ask
clarifying questions where context is missing before giving their concerns.
Return each agent's concerns and recommendations so I can fold them back into
the spec and tickets. write the concerns and recommendations in the file doc/Idea-final-spec-review.md
```
