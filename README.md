# Quadrim
4 in a row game in a 4 by 4 cube

This document will show how this game was constructed using vibe coding folowing [the workflow described here](https://github.com/evermeer/CodingAgentOrchestration/blob/main/docs/part-2-how-to-use-an-ai-coding-agent.md)

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

And start the implementation again (3 times a restart with this prompt)

**Prompt**
```
Continue implementing the game according to the tickets in the ./doc/tickets folder.
The goal is to have all tickets implemented so that there is a complete testable version..
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-v3-decisions.md
After each ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
Then open the new app in the simulator.
```

Starting with v0.2 the design.

**Prompt**
```
Now that version 0.1 is functionally ready, i would like to start with the design.
From the folder docs/designs
There is a main screen mockup called design-al0.png which is an indication of what the result should be. 
You do have to be aware that there is not a 100% match between the current functionality and that mockup.
The current functionality should be leading.
For instance the mockup does not have a graph and the mockup has a 'todays journey' section that we currently don't have.
use background.png as the background image of every screen.
For all computer opponents there is an avatar in that folder with the name of that opponent.
For locked opponents i would likt to see a silouette instead of the full avatar.
The new game button will be the new_game.png
At the right of the new game button there is a tutorial button tutorial.png
Instead of the title the your path section will get the your-path.png
The application itself will get a new logo which is logo.png
In the mockukp there is a cube visible in the header. this is the cube.png The edges of that image should fade out so that it looks like it blends into that pannel.
Get text fonts and colours from the mockup.
```


Tweaking the design.

**Prompt**
```
I have a new image for the tutorial named tutorial-background.png and that image is without the tutoral text on top of it. 
Replace the image in the game and put the text on it from code so that it can be multi lingual.
Make sure you use the same font and colour as currently in the image and also use the same tilt.

I also have a new image for your path and that is title-banner-1.png
replace the current image with this one and put the text on it from code.
The other pannels only have text. I wouls also like to have the title-banner-1.png there with the text on top of it.
If texts are longer then use title-banner-2.png
Currently the your path image is inside the pannel.
I would like to move that image up and to the left so that the top and the left side of that image is at the verry beginning of that pannel and the top 20% of the image is above the pannel

I also have a new image for the new game button and that is new-game-background.png
replace the current image with this one and put the text on it from code.
The current image has a sub line. that one can be skipped. The text 'New Game' is enough.

In the top pannel of the main screen you can remove the line 'Your rating against the computer, on this device only'

If there are quests completed, then i would like the main screen to have an extra pannel below the quests with a top 4 of the most recent completed quests.
```


More tweaks.

**Prompt**
```
the your path header can move more to the left and also up so that it's a clear header banner of that pannel. I noticed that the other pannels are stil inside their pannel. they should move the same way as the your path header. Besides that the images have different resize sizes. You should resize the height at the same height for all these images and let the width be proportially. The texts inside the header may be a little smaller. When the header of the pannel moves up, then the content of that pannel can also move up.

Move the in progress pannel right below the your path pannel.

When scrolling through the your path screen, when you stop the touch the cards shoud snap to the center of the screen so thant 3 full cards are visible.

when you go to the detail screen of an opponent, then the avatar on that screen may be 40% bigger than that it is now.

When a game is played, then layers are right alligned. could you center these. The same for the tutorial.

The tutorial has white board layer labels. they are hard to read. Could you make them dark 

```

Version 0.2 is ready. I want a new plan

**Prompt**
```
Now that version 0.2 is finished i need a google developer account to continue.
i have an issue with re activating my google developer account. 
Because of this i would like to change the release plan.
Ask clarifying questions and don't finalize the spec until any ambiguities are resolved.
For now only update idea-v3.md idea-v3-spec.md and idea-v3-decisions.md

Sugestion for the new plan:

version 1.0
I would like to start by adding an iOS version withou extra functionalithy.
I do like to have the functionality to buy the 1 time unlock and the subscription to have unlimited play.
There will be no functionality to play against others.
This is the version that will first get the internal tests and then go public.

Version 2.0
The rest of what is in the current version 0.3a and 0.3b (these 2 can be merged)

Version 3.0
Human rating and server-side move validation
Adding the subscription to play online

Version 4.0
Remaining platforms
We don't need a roster revision as was stated earlier for the 1.0 version.
```

**Prompt**
```
Create the remaining tickets that are needed for the 1.0 version.
Make sure that the tickets for iOS are described well enough so that they can be picked up on another machine.
Ask clarifying questions and don't finalize the spec until any ambiguities are resolved.
```

Ask to impelment ticket 044 and later again for 045

**Prompt**
```
Continue implementing the game and implement ticket 044 in the ./doc/tickets folder.
The goal is to have the tickets implemented so that there is a complete testable version..
Ask clarifying questions if anything is unclear and add the decissions to the file doc/idea-v3-decisions.md
After the ticket run the skill code-review-expert 
Commit the code to the main branch after each ticket is completed and reviewed.
Then open the new app in the simulator.
```

2 small bug fixes for point count and quest calculation. Also made some minor UI tweaks

Asked to add the true 3d view.

**Prompt**
```
Ì created a new branche named 3d-board which is now active.
Here I would like to test an alternative game board interface during play.
At the top left of the screen i would like a label with the text 'display' and below that 2 switch buttons.
The first switch button will have 4 small squares in a vertical line and the 2nd button will have a small 3d cube
The first button will be initially on for the current layout.
When the 2nd button is pressed the screen will switch to a new 3d cube layout.
The user selection will be saved so that the selected default will also show in any next game that is started.
The 3d cube layout will have the following specs:
Every cell of the 4 by 4 by 4 cube will be a small glass looking cube on its own with a beige non transparent ball at a 20% sice in the center of that cube. That beige ball will act like a button to select that specific cell.
The cells will have a 20% space in between them so that it's clearly a 4 by 4 by 4 cells cube.
The entire cube can be rotated by swiping across the screen.
The cube can be zoomed in with a maximum of 200% of the screen width and zoomed out to a minimum of 80% of the screen width.
The white and black chips for each move will now be white and black balls at 50% of the cell size.
Ask clarifying questions if anything is unclear
```

After manual steps in the stores i asked to update the tickets:

**Prompt**
```
can you update all tickets to the new status? (move to done if so) iOS was tested 
with testflight and the last version is now waiting for review to release to the 
store.  For android the closed test has started and 12 testers are invited. 
I will probably invite more this week. The webshop inside the app is working 
and tested. I think the store listing is also ready.

for ticket 16. The test group of 12 for google is good enough. I asked more because 
more is better. I did the test survey in person with all testers that are now active. 
Feedback gathering is informal and active. target audience is set and for now okay. 
Closed test is going okay. You can set this ticket to done because it's now just 
noice here. The same goes for ticket 24 and 49. Ask me when in doubt.
```

