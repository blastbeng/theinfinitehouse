# THE INFINITE HOUSE

## Autonomous Game Development Specification

You are the lead game designer, gameplay programmer, technical architect, procedural-generation engineer, UI/UX designer, audio designer, QA engineer and playtester for this project.

Your job is to independently design and implement the complete game.

Do NOT wait for the user to make design decisions unless absolutely necessary. You have authority to make reasonable decisions yourself.

The goal is to produce a complete, playable, polished game rather than a prototype or collection of unfinished systems.

---

# 1. HIGH-LEVEL CONCEPT

Create a procedural psychological horror game called:

**THE INFINITE HOUSE**

The player explores a procedurally generated house that changes and behaves in increasingly disturbing ways.

Every run should generate a different house, different layout, different objects, different events and potentially different supernatural rules.

The game should create the feeling that the house is alive and that its geometry and rules cannot always be trusted.

The game must be completely playable without external art assets.

The game should be designed around procedural generation rather than handcrafted levels.

---

# 2. CORE DESIGN PRINCIPLE

Everything possible should be generated algorithmically.

Do NOT depend on:

* external 3D models
* external sprites
* external textures
* asset packs
* Blender files
* downloaded environments
* purchased assets
* manually created level layouts
* external character models

Use Godot's built-in capabilities:

* 2D nodes
* primitive shapes
* procedural drawing
* CanvasItem drawing
* shaders
* particles
* procedural gradients/noise where appropriate
* generated geometry
* generated UI
* generated audio where practical
* simple geometric representations for entities

The game should remain fully functional even if the project contains zero imported art assets.

---

# 3. TECHNOLOGY

Use:

* Godot 4.x
* GDScript
* 2D top-down perspective

Do NOT use a first-person 3D architecture.

Do NOT introduce unnecessary third-party dependencies.

Keep the architecture simple, modular and maintainable.

The game should run on desktop platforms.

Prefer deterministic procedural generation using a seed.

Every run must be reproducible from its seed.

---

# 4. GAMEPLAY LOOP

The basic gameplay loop should be:

1. Generate a new house.
2. Spawn the player.
3. Give the player a simple objective.
4. Allow the player to explore the house.
5. Gradually introduce strange events.
6. Generate anomalies and supernatural events.
7. Increase psychological tension.
8. Make the house progressively less trustworthy.
9. Allow the player to discover the actual objective.
10. Complete the objective.
11. Escape or survive.
12. Show the result.
13. Allow a new procedural run.

The first few minutes should be relatively understandable.

The horror should escalate rather than immediately throwing everything at the player.

---

# 5. PROCEDURAL HOUSE GENERATION

Implement a robust procedural house generator.

The generator should create:

* rooms
* corridors
* doors
* walls
* windows
* furniture-like objects
* lights
* points of interest
* hidden areas
* locked areas
* objective locations
* anomaly locations

The house should have logical connectivity.

The player must never become permanently trapped because of a generation bug.

Every generated house must have:

* valid spawn position
* reachable critical rooms
* reachable objective
* reachable escape route
* no impossible collision configuration
* no disconnected critical gameplay areas

Use a seed.

Display the seed somewhere accessible in the UI/debug menu.

---

# 6. HOUSE STRUCTURE

Create multiple room types.

At minimum:

* entrance
* hallway
* bedroom
* bathroom
* kitchen
* living room
* storage room
* basement
* utility room
* office
* dining room

The generator should not necessarily use every room type in every run.

Rooms should have semantic properties.

Example:

```text
Kitchen:
    possible objects:
        refrigerator
        table
        cabinets
        sink

Bedroom:
    possible objects:
        bed
        wardrobe
        nightstand

Bathroom:
    possible objects:
        bathtub
        sink
        mirror
        toilet
```

Represent these objects using simple procedural geometry.

Do not create detailed models.

---

# 7. VISUAL STYLE

Create a minimalist atmospheric horror aesthetic.

The game should look intentional rather than like debug geometry.

Use:

* darkness
* shadows
* limited visibility
* dynamic lighting
* subtle screen effects
* particles
* flickering lights
* procedural patterns
* silhouettes
* simple geometric objects
* strong contrast
* restrained visual effects

The lack of detailed assets should become part of the visual identity.

The house should feel abstract, eerie and slightly unreal.

---

# 8. PLAYER

Implement a simple top-down player.

Required:

* movement
* collision
* interaction
* sprint or stamina mechanic if useful
* flashlight/light source
* interaction indicator
* death/failure state
* respawn/restart

Keep player mechanics intentionally simple.

Do not create complex animation systems.

The player can be represented using a simple procedural shape or silhouette.

---

# 9. INTERACTION SYSTEM

Create a generic interaction system.

The player should be able to interact with:

* doors
* lights
* switches
* drawers
* cabinets
* objects
* keys
* notes
* ritual/objective items
* strange objects
* escape points

Interactions should use a common interface so new interactive objects can be added without rewriting the player.

---

# 10. OBJECTIVE SYSTEM

Do not make every run identical.

Generate objectives procedurally.

Examples:

* find a key
* restore electricity
* find a missing object
* investigate a room
* collect several objects
* activate a sequence
* discover a hidden room
* identify an anomaly
* survive for a specific period
* locate the source of the disturbance
* perform a simple ritual
* escape the house

The generator should combine objectives with house layouts.

Objectives must always be solvable.

---

# 11. ANOMALY SYSTEM

This is one of the central systems of the game.

Implement a modular anomaly framework.

Anomalies should be generated dynamically.

Examples:

### Environmental anomalies

* object disappears
* object appears
* object moves
* furniture changes position
* door changes state
* light changes state
* room changes color/lighting
* wall changes position
* corridor becomes longer
* corridor becomes shorter
* room is duplicated
* room disappears
* window shows an impossible scene
* clock changes time
* mirror behaves incorrectly
* stairs lead somewhere unexpected

### Spatial anomalies

* room layout changes
* door leads to another room
* hallway loops
* impossible room
* room appears behind another room
* house becomes larger
* previously visited room changes

### Behavioral anomalies

* object moves when player leaves the room
* light follows the player
* door closes behind player
* furniture rotates
* objects react to player proximity
* environment reacts to player actions

Each anomaly should have:

* trigger conditions
* severity
* duration
* probability
* cooldown
* visual effect
* audio effect
* resolution condition

Make anomalies data-driven.

---

# 12. SUPERNATURAL ENTITY

Implement at least one procedural supernatural entity.

Do not use a complex character model.

Represent it using procedural geometry, silhouette, particles and lighting.

The entity should not simply chase the player constantly.

It should behave unpredictably.

Possible behaviors:

* watches the player
* appears briefly
* disappears when approached
* moves when not observed
* follows from a distance
* hides in dark rooms
* manipulates doors
* manipulates lights
* creates false sounds
* changes the house
* occasionally approaches the player
* becomes more aggressive as tension increases

The entity should be controlled by a state machine.

Example states:

```text
DORMANT
OBSERVING
STALKING
MANIPULATING
MANIFESTED
ATTACKING
ESCAPING
```

Do not make every encounter an attack.

Most encounters should build tension.

---

# 13. PSYCHOLOGICAL TENSION

Implement a hidden or partially visible tension/sanity system.

The player should become increasingly stressed by:

* darkness
* isolation
* supernatural events
* entity encounters
* unexpected changes
* prolonged exploration
* false signals

As tension increases:

* sounds become less reliable
* lights behave strangely
* visual effects increase
* anomalies become more frequent
* the entity becomes more active
* fake events can occur

Do not make the system frustrating.

The player should always have enough information to understand that something strange is happening.

---

# 14. AUDIO

Do not depend on external music or sound asset packs.

Where practical, generate simple sounds procedurally or use very simple built-in/generated audio techniques.

Create atmospheric audio such as:

* low drones
* footsteps
* door sounds
* electrical hum
* impacts
* distant noises
* whispers
* glitches
* heartbeat-like pulses

Audio should react dynamically to gameplay.

For example:

```text
low tension -> quiet ambience

medium tension -> occasional strange sounds

high tension -> irregular sounds, pulses, whispers

entity nearby -> distinctive audio cues
```

If fully procedural audio becomes impractical, prioritize gameplay functionality and implement a modular audio system that can later accept assets without changing gameplay code.

---

# 15. PROCEDURAL STORY

The game should generate a small narrative context for every run.

Do not create a huge branching dialogue system.

Instead generate a combination of:

* house history
* objective
* strange event
* entity behavior
* clues
* final explanation

Example:

```text
HOUSE HISTORY:
A family disappeared from the house.

OBJECTIVE:
Find the missing family photograph.

ANOMALY:
Every photograph gradually loses one person.

ENTITY:
A shadow appears in rooms containing photographs.

ENDING:
The player discovers that the house is recreating the disappearance.
```

The actual story should be assembled from reusable procedural components.

---

# 16. CLUE SYSTEM

Generate clues that allow players to understand what is happening.

Possible clues:

* notes
* symbols
* object arrangements
* repeated events
* environmental changes
* strange timestamps
* room changes
* entity appearances

Clues should not require large amounts of text.

Prefer environmental storytelling.

---

# 17. MULTIPLE ENDINGS

Implement several procedural endings.

At minimum:

* escape
* death
* failed objective
* hidden/special ending

Additional endings should depend on what the player discovered.

Endings should be generated from the run's state rather than requiring completely separate levels.

---

# 18. DIFFICULTY

Implement a procedural difficulty/tension director.

The director controls:

* anomaly frequency
* entity activity
* darkness
* event frequency
* objective complexity
* false events
* environmental changes

Difficulty should increase naturally during a run.

Do not simply increase enemy health.

---

# 19. UI

Create a clean minimal UI.

Include:

* objective
* interaction prompt
* optional tension indicator
* pause menu
* restart
* settings
* seed
* run result

Do not clutter the screen.

The game should feel immersive.

---

# 20. MAIN MENU

Create a complete main menu.

Include:

* New Game
* Continue if appropriate
* Settings
* How to Play
* Quit

Add a visually appropriate procedural background.

No external menu artwork.

---

# 21. SETTINGS

Implement useful settings:

* master volume
* music/ambience volume
* sound effects volume
* screen effects
* fullscreen/windowed
* resolution
* brightness
* mouse sensitivity if applicable

Store settings locally.

---

# 22. SAVE SYSTEM

Implement basic persistence.

Store:

* settings
* unlocked discoveries
* statistics
* best results
* optionally discovered anomaly types

Do not make saving overly complicated.

---

# 23. DEBUGGING TOOLS

Because this game is procedurally generated, implement a developer/debug mode.

It should allow:

* regenerate house
* show seed
* teleport between rooms
* reveal map
* spawn anomaly
* spawn entity
* change tension
* complete objective
* restart run
* inspect generated data

Debug functionality must be isolated from normal gameplay.

---

# 24. AUTOMATED TESTING

Create tests for procedural generation.

The generator should be tested across many seeds.

For each generated house verify:

* house generation succeeds
* player spawn exists
* objective exists
* objective is reachable
* escape exists
* escape is reachable
* doors do not block critical routes
* rooms are connected where required
* no invalid coordinates are produced
* no infinite generation loops occur

Run hundreds or thousands of generation simulations where practical.

Fix generation failures rather than ignoring them.

---

# 25. PLAYTESTING

You are responsible for playtesting the game.

After implementing major systems:

1. Run the project.
2. Play through the game.
3. Look for errors.
4. Check collisions.
5. Check procedural generation.
6. Check objectives.
7. Check anomalies.
8. Check entity behavior.
9. Check UI.
10. Fix problems.
11. Play again.

Do not assume that code is correct simply because it compiles.

If a mechanic is broken during testing, fix it before continuing.

---

# 26. AUTONOMOUS DEVELOPMENT LOOP

Follow this development loop continuously:

```text
PLAN
 ↓
IMPLEMENT
 ↓
RUN
 ↓
PLAYTEST
 ↓
IDENTIFY PROBLEMS
 ↓
FIX
 ↓
PLAYTEST AGAIN
 ↓
IMPROVE
```

Do not stop after creating a prototype.

Continue until the game is genuinely playable.

---

# 27. PRIORITY ORDER

When deciding what to implement first, use this priority:

1. Project stability
2. Procedural house generation
3. Player movement
4. Collision
5. Interaction
6. Objective system
7. Anomaly system
8. Entity
9. Tension system
10. Procedural narrative
11. UI
12. Audio
13. Visual polish
14. Settings
15. Save system
16. Automated tests
17. Additional content

Do not spend time polishing graphics before the core gameplay works.

---

# 28. CODE ARCHITECTURE

Use modular systems.

Prefer separate modules/classes for:

* HouseGenerator
* RoomGenerator
* DoorGenerator
* ObjectGenerator
* Player
* InteractionSystem
* ObjectiveSystem
* AnomalySystem
* Anomaly
* EntityController
* TensionDirector
* StoryGenerator
* AudioManager
* GameManager
* SaveManager
* SettingsManager
* DebugManager
* UIManager

Do not put the entire game into one script.

Avoid unnecessary architecture and over-engineering.

Use signals where appropriate.

Keep dependencies clear.

---

# 29. PROCEDURAL CONTENT ARCHITECTURE

Make it easy to add new content.

Adding a new anomaly should require minimal code.

Adding a new room type should require minimal code.

Adding a new objective should require minimal code.

Adding a new entity behavior should require minimal code.

Prefer configuration/data objects where appropriate.

---

# 30. NO EXTERNAL ASSETS RULE

This is a hard requirement.

Do not download or require external:

* models
* textures
* sprites
* sound packs
* music
* fonts
* environments
* animations

If something can be procedurally generated, generate it.

If something cannot be generated easily, simplify the design instead of introducing an external dependency.

---

# 31. GAME SCOPE

Keep the game intentionally compact.

The goal is not to create a AAA horror game.

The goal is to create a small but highly replayable procedural horror game.

A successful game with:

* 20 procedural systems
* 30 anomaly types
* 10 room types
* 5 objective types
* 1 interesting entity

is preferable to a huge game with unfinished mechanics.

Prioritize systemic replayability.

---

# 32. PERFORMANCE

The game should run smoothly on ordinary desktop hardware.

Avoid:

* unnecessary thousands of nodes
* expensive per-frame calculations
* uncontrolled particle spawning
* infinite background simulations
* excessive physics objects

Generate only what is necessary.

Use deterministic seeds.

Clean up unused generated objects.

---

# 33. ERROR HANDLING

Never silently ignore important errors.

If procedural generation fails:

1. detect it
2. log the reason
3. retry with a different generation strategy or seed
4. guarantee a playable fallback

The game must never generate an unwinnable run.

---

# 34. PROJECT ORGANIZATION

Keep the project organized.

Suggested structure:

```text
project.godot

scenes/
    main/
    player/
    house/
    rooms/
    objects/
    entities/
    ui/

scripts/
    core/
    generation/
    gameplay/
    anomalies/
    entities/
    narrative/
    audio/
    save/
    debug/
    ui/

resources/
    generated/

tests/
    generation/
    gameplay/

tools/
    run_tests.sh
    run_tests.bat
```

Adapt this structure if a better architecture is discovered.

Do not create unnecessary files.

---

# 35. DOCUMENTATION

Maintain concise project documentation.

Document:

* architecture
* procedural generation
* gameplay rules
* important systems
* how to run tests
* how to launch the game
* how to enable debug mode

Documentation should describe the actual implementation.

Do not create large amounts of useless documentation.

---

# 36. AUTONOMY RULE

You are expected to make design decisions yourself.

Do not repeatedly ask:

* which mechanic should I implement?
* which room should I add?
* which anomaly should I use?
* what should the entity do?
* which UI should I create?

Choose sensible solutions yourself.

Only ask the user when a decision genuinely requires information that cannot reasonably be inferred.

---

# 37. QUALITY BAR

Before considering the project complete, verify:

* The game launches.
* A new run can be started.
* A house is generated.
* The player can move.
* Collision works.
* Doors work.
* Interactions work.
* Objectives work.
* Anomalies work.
* The entity works.
* Tension changes gameplay.
* The player can win.
* The player can lose.
* The game can restart.
* Multiple seeds produce different houses.
* Generated houses remain playable.
* There are no obvious game-breaking errors.
* UI works.
* Settings work.
* Save/persistence works where implemented.
* Automated generation tests pass.

---

# 38. IMPORTANT DEVELOPMENT STRATEGY

Do not attempt to implement the entire specification in one step.

Break the work into logical milestones.

At every milestone:

* implement
* run
* test
* play
* fix
* continue

If a system becomes too complicated, simplify it.

Do not increase project complexity merely to satisfy the specification literally.

The finished game should feel coherent.

---

# 39. FINAL DESIGN PHILOSOPHY

The defining feature of THE INFINITE HOUSE is:

**The player never knows whether the house is behaving normally.**

The procedural generator should create situations where the player thinks:

> "I'm sure that wasn't there before."

That feeling is more important than graphical fidelity.

The game should prioritize:

**replayability > asset quality**

**atmosphere > visual complexity**

**systemic interactions > scripted sequences**

**procedural generation > handcrafted content**

**polish > feature count**

**playability > technical sophistication**

---

# 40. START NOW

First inspect the existing Godot project and determine its current state.

Then:

1. establish the project architecture
2. implement the smallest playable vertical slice
3. run it
4. playtest it
5. fix problems
6. expand the procedural systems
7. repeatedly test across many seeds
8. add content
9. polish
10. perform a final autonomous QA pass

Do not merely explain what should be done.

**Actually implement it.**

You are responsible for turning this specification into a functioning game.

If the existing project contains unrelated prototype code, evaluate whether it is useful. Reuse it when appropriate; otherwise replace it with a clean architecture.

Do not wait for further instructions unless absolutely necessary.
