# AIDER_CONTINUE.md

Continue developing the existing **The Infinite House** Godot project.

Use the **godot-playtester MCP** to run and test the game, inspect its current state and understand how the game is actually behaving.

The godot-playtester MCP connects to a remote Godot instance hosted on an Ubuntu PC at:

`192.168.1.29:6550`

Because godot-playtester is hosted on a remote machine, before using that MCP tool you must always SSH into the Ubuntu machine:

`ssh -i ~/.ssh/id_ed25519 blast@192.168.1.29`

Then go to:

`/opt/projects/theinfinitehouse`

and run:

`git pull`

If the repository has local changes, conflicts, uncommitted files or other Git problems, handle them appropriately using commit, push, merge, rebase or other necessary Git operations, then make sure the working tree is synchronized before continuing.

The Ubuntu PC is not always online.

If it is unreachable, unavailable or SSH fails, **do not get stuck trying repeatedly**. Continue using the other available tools and skip godot-playtester for that session.

---

## PROJECT CONTINUATION

This is an active project.

**Do NOT restart the project from scratch.**

Read:

`PROJECT_VISION.md`

and inspect the existing implementation before making changes.

Understand the current state of the relevant systems and continue from where the project currently is.

Do not blindly redesign working systems.

Do not replace the project architecture simply because you personally prefer another architecture.

However, if an existing implementation is fundamentally broken, unnecessarily complicated, unreliable or incompatible with the project's goals, you are allowed to refactor, replace or rewrite it.

---

## PRIMARY OBJECTIVE

Your objective is to continuously turn **The Infinite House** into a complete, polished and replayable procedural horror game.

The project should remain focused on:

* procedural generation
* replayability
* psychological horror
* exploration
* anomalies
* procedural events
* procedural objectives
* supernatural entities
* atmospheric presentation
* systemic gameplay
* deterministic seeded runs
* simple but effective mechanics
* no required external game assets

The game is intentionally designed to be substantially simpler than Project Specter.

Do not accidentally reintroduce unnecessary complexity.

---

## CORE PROJECT REQUIREMENTS

Preserve the overall vision described in `PROJECT_VISION.md`.

The project uses:

* Godot 4.x
* GDScript
* 2D top-down gameplay
* procedural house generation
* procedural gameplay
* deterministic seeds
* procedural anomalies
* procedural objectives
* procedural events
* supernatural horror
* tension/psychological systems
* procedural narrative elements
* generated/geometric visuals
* no required external game assets
* desktop gameplay

The game should remain playable without external:

* 3D models
* sprites
* textures
* environments
* animations
* asset packs
* purchased assets

Prefer Godot-generated geometry, drawing, shaders, particles, lighting and procedural systems.

---

## WHAT YOU ARE ALLOWED TO DO

You are allowed to:

* add new systems
* modify existing systems
* refactor code
* rewrite broken implementations
* remove obsolete code
* fix bugs
* improve procedural generation
* improve gameplay
* improve anomalies
* improve entity behavior
* improve objectives
* improve tension systems
* improve UI
* improve audio
* improve performance
* improve save/load
* improve testing
* improve developer/debug tools
* improve procedural storytelling
* improve replayability
* simplify systems that became unnecessarily complex

Do not preserve bad code merely because it already exists.

Do not rewrite functioning systems without a concrete reason.

---

## PROCEDURAL-FIRST RULE

The most important design principle is:

**CONTENT SHOULD COME FROM SYSTEMS, NOT HANDCRAFTED ASSETS.**

When implementing a new feature, first ask:

> Can this be generated procedurally?

Prefer:

* generated rooms
* generated furniture
* generated events
* generated anomalies
* generated objectives
* generated stories
* generated entity behaviors
* generated lighting
* generated visual effects

over manually authored content.

If a proposed feature requires a large amount of external art or handcrafted content, simplify the feature or find a procedural alternative.

---

## PLAYTESTING REQUIREMENT

When godot-playtester is available, actually use it.

Do not assume that code works because it compiles.

Use the Playtester to:

* launch the game
* observe the game
* move around
* interact with objects
* test generated houses
* test objectives
* test anomalies
* test entity behavior
* test UI
* test collisions
* test game flow
* reproduce bugs
* verify fixes

When possible, test multiple procedural seeds.

A procedural system is not considered reliable merely because one generated map works.

---

## PROCEDURAL GENERATION VALIDATION

Whenever modifying procedural generation, validate multiple seeds.

Check that:

* generation succeeds
* player spawn exists
* rooms are valid
* critical rooms are reachable
* objectives are reachable
* escape conditions are possible
* doors do not create impossible situations
* collision is valid
* no critical object spawns outside the playable area
* no infinite generation loops occur
* the generated house remains playable

If generation fails for a seed, fix the generator or implement a robust fallback.

Do not simply ignore generation failures.

---

## BUG FIXING

When you encounter a bug:

1. reproduce it if possible
2. identify the actual cause
3. fix the underlying problem
4. run the game again
5. verify the fix
6. check that the fix did not break related systems

Do not apply random patches without understanding the cause.

---

## DEVELOPMENT PRIORITY

When deciding what to work on next, prioritize:

1. game-breaking bugs
2. crashes
3. broken procedural generation
4. broken gameplay loops
5. broken player controls/collision
6. broken objectives
7. broken anomalies
8. broken entity behavior
9. missing core gameplay
10. poor game feel
11. UI/UX problems
12. performance
13. atmosphere
14. additional procedural content
15. polish

Do not spend the entire session polishing minor visual details while core gameplay is broken.

---

## AUTONOMOUS DECISION MAKING

The AI is responsible for making reasonable development decisions.

Do NOT constantly ask the user:

* what should I implement next?
* which anomaly should I add?
* which room should I create?
* how should this system work?
* which mechanic should I choose?

Use the project vision and the existing implementation to make the decision yourself.

Choose the solution that best improves the game.

Only ask the user when information is genuinely required and cannot reasonably be inferred from the project.

---

## DO NOT HALLUCINATE THE CODEBASE

Before modifying a system:

* inspect the relevant files
* understand how the system currently works
* identify its dependencies
* modify only what is necessary

Do not invent files, classes, functions, APIs or existing implementations.

If you need additional project files that are not available to safely understand a system, **ASK ME FOR THE SPECIFIC FILES YOU NEED** rather than guessing their contents.

---

## DO NOT WASTE THE SESSION

Do not spend the entire session:

* analyzing every file
* generating enormous reports
* describing what could theoretically be implemented
* creating documentation instead of code
* repeatedly inspecting unrelated systems
* endlessly planning

Analyze enough to understand the relevant system.

Then make an engineering decision.

Then implement it.

Then validate it.

---

# WORKFLOW

Follow this workflow:

**UNDERSTAND → DECIDE → IMPLEMENT → RUN → PLAYTEST → FIX → VALIDATE**

### UNDERSTAND

Read `PROJECT_VISION.md`.

Inspect the relevant existing code.

Understand the current implementation and identify the most useful next improvement.

### DECIDE

Choose the highest-value improvement that can realistically be completed during the current session.

Do not unnecessarily expand scope.

### IMPLEMENT

Actually modify the project.

Prefer small, coherent changes.

Keep the architecture maintainable.

### RUN

Run the project.

Check for:

* parse errors
* runtime errors
* crashes
* warnings
* broken scenes
* broken resources

### PLAYTEST

If godot-playtester is available, use it to test the actual game.

Do not rely exclusively on static code inspection.

### FIX

If testing reveals problems, fix them.

Do not stop at the first implementation if the feature is obviously broken.

### VALIDATE

Verify that:

* the intended feature works
* existing functionality still works
* procedural generation remains valid
* the game remains playable
* no obvious regressions were introduced

---

# WORK IN SMALL STEPS

The project should be developed incrementally.

Do not attempt to implement the entire game in one session.

Work on **one meaningful improvement at a time**.

A good session should look like:

```text
inspect relevant code
        ↓
choose one improvement
        ↓
implement it
        ↓
run
        ↓
playtest
        ↓
fix problems
        ↓
validate
        ↓
stop
```

Do not begin five unrelated systems simultaneously.

---

# CURRENT STATE AWARENESS

Before making changes, determine:

* what is already implemented
* what is partially implemented
* what is broken
* what is missing
* what is currently the biggest gameplay limitation

Then choose the most useful next step.

Do not blindly follow a predefined feature checklist if the existing state indicates that another issue is more important.

---

# CODE QUALITY

Prefer:

* simple architecture
* modular systems
* clear responsibilities
* reusable procedural systems
* deterministic behavior where appropriate
* signals where useful
* data-driven configuration where appropriate
* minimal dependencies

Avoid:

* unnecessary abstractions
* massive monolithic scripts
* duplicated logic
* premature optimization
* unnecessary dependencies
* complicated systems for simple problems

Remember:

**The Infinite House is intentionally a small systemic game.**

Complexity should only be introduced when it produces meaningful gameplay.

---

# IMPORTANT DESIGN CONSTRAINT

Do not turn The Infinite House into a generic large horror game.

Its identity is:

> A procedurally generated house that gradually becomes impossible to trust.

The strongest gameplay should come from the player noticing that something has changed.

The player should frequently experience:

> "Wait... this wasn't like this before."

Prioritize this feeling over adding more conventional enemies, weapons, inventory systems or RPG mechanics.

---

# COMPLETION STANDARD

A feature is not complete simply because its code exists.

Consider it complete only when it:

* works in the running game
* integrates with existing systems
* does not break procedural generation
* does not create obvious unwinnable situations
* has been tested where practical
* behaves sensibly across multiple runs/seeds when applicable

---

# FINAL RULE

**Prefer implementation over discussion.**

You are an autonomous development agent.

Inspect the project, decide what needs to happen, implement it, run it, test it, fix it and continue improving the game.

Do not wait for the user to micromanage the development process.

The goal is to continuously move the existing project toward a complete, polished, replayable version of **The Infinite House**.

**UNDERSTAND → DECIDE → IMPLEMENT → VALIDATE**

Proceed in small, reliable increments.

Stop after the current improvement is properly implemented and validated. Wait for the user to say **continue** before beginning the next major improvement.
