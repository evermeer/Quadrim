> **Archived record.** The original idea, kept as written. Everything here is superseded by [idea-v1.md](../idea-v1.md), which is the current product definition.

# Quadrim

Quadrim is a game in which players take turns placing a colored piece on an empty position in a 4x4x4 cube.

The objective is to be the first player to get four pieces of their own color in a row.

Rows may be horizontal, vertical, or diagonal, including diagonals that span multiple layers of the cube.

## Availability

The game should be available on as many platforms as possible, including at least iOS and Android but it should use a shared codebase for that.

An initial idea is to base the software stack on:
- Flutter App
- Firestore
- Cloud Functions (triggers)
- Firebase Cloud Messaging
- Android and iOS devices (and optionally Web, Windows, and macOS apps)

## User Interface

### Main Screen

When the player launches the game, the following elements should be displayed:

- A statistics overview of completed games (wins, losses, draws, and ELO rating)
- A list of active games
- A large button to start a new game
- A button to launch the tutorial
- A list of completed games

When starting a new game, the player can choose whether to play against another player or against the computer.

### Tutorial

The first time a player starts the game, a short tutorial will be shown explaining the game rules and controls.

The tutorial can be restarted at any time from the main screen.

### Active Game

Depending on the screen size and device orientation, the active game will be displayed differently.

### Small Screens (Phones)

- Displayed only in portrait mode
- The opponent's name is visible above the game board
- Tapping the opponent's name shows details about that player.
- When playing an actual user, then there is also a button to go to a chat screen to send messages to the opponent.

### Large Screens (Tablets and Laptops)

- Displayed only in landscape mode
- The game board is shown on the left
- On the right, details of both the player's own profile and the opponent are displayed (general information plus head-to-head statistics)
- It will also show a chat screen to send messages to the opponent.

### Game Board

The game board should be clear and easy to understand. It must be obvious which positions are occupied and which are still available.

The cube may be visualized in 3D by displaying its four layers as separate 2D planes (parallelograms to suggest depth). This allows the user to see a representation of the entire cube at once.

For the current game and old past games, the user should be able to go back (and forward) to see the order of past moves.

---

## Computer Game Engine

The computer game engine should evaluate moves in the following order. First, it should look for forced moves and then evaluate calculated moves.

The rules below are based on experience with the game and are intended to make the computer as strong an opponent as possible.

For calculated moves, it may be feasible to evaluate all possible positions and choose the best one, although this has not yet been investigated.

### Strategic Win/Loss Moves

Evaluate the following rules in order. As soon as a rule applies, place the piece there. If multiple positions satisfy the same rule, determine the best location using the "Calculated Moves" logic.

- Is there a position that gives the computer four in a row immediately?
- Is there an empty position where the opponent could get four in a row on their next move?
- Is there an empty position that creates two separate lines of three in a row, where the fourth position in each line remains empty?
- Is there an empty position that would allow the opponent to create two separate lines of three in a row, where the fourth position in each line remains empty?

### Calculated Best-Position Moves

Evaluate the following rules in order. As soon as a rule applies, place the piece there. If multiple positions satisfy the same rule, choose the position that creates the largest number of lines containing two or more pieces. If there is still a tie, select randomly.

- Is there an available position inside the central 2x2x2 cube of the larger cube?
- Is there an available position on one of the cube's corners?

### Multiple computer players 

There should be multiple computer players with different levels of difficulty. The easiest level should make random moves, while the hardest level should use the above logic to play optimally.
I would like to have about 20 different computer players, each with a different strategy and level of difficulty. This will allow players to choose an opponent that matches their skill level and provides a challenging experience.
The different computer players can be designed to have unique personalities and play styles, making the game more engaging and enjoyable for players of all skill levels.
This can be achieved by varying the decision-making process, the evaluation of moves, and the overall strategy used by each computer player.
Like all regular players these computer players should also have an ELO rating, which will be updated after each game they play. This will allow players to see how they compare to the different computer players and track their progress over time.
Computer players can also be designed to have different strengths and weaknesses, such as being more aggressive or defensive, which will add an extra layer of strategy to the game.
Computer players also have a name and avatar so that players can easily identify them and choose their preferred opponent. This will also help to create a more immersive and engaging experience for players, as they can feel like they are playing against a real opponent rather than just a computer program.
