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

This next prompt overrides the write to tickets instructiions of the to-spec skill and instead asks to write a spec document.
It also answers 2 questions from the brainstorming document.

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
