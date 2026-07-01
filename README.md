# dungeon_master_game
AI-assisted hobby project, an idle game / 2d fantasy dungeon ant farm esque simulator about running an adventurer's guild

## core gameplay

You are the dungeon master of an adventurer's guild.  You can see a 2d cross section of the town and the dungeon beneath it.  At the top of the screen is the town.  beneath it are many different levels and rooms of the dungeon.  The dungeon is procedurally generated from a list of template rooms and arranged semi-randomly, and monsters will spawn when appropriate.

When the dungeon is open for exploration, adventurers from your guild will head down into the dungeon to explore it.  They will wander around, reveal new unexplored rooms, fight monsters, find treasure, etc. autonomously;  you cannot control the adventurers, only manage them as a guild master.  The dungeon will change and evolve, and you must balance nurturing your adventurers, completing requests, and exploring deeper into the dungeon through management decisions.  non adventurer NPCS will also exist such as in-dungeon shopkeepers.

## VERSION 1

Placeholder graphics only.  Your only management choice is "hire an adventurer" which spawns an adventurer in the town who immediately goes into the dungeon.  Adventurers will wander randomly and endlessly, killing monsters and gathering treasure.  they have a health bar and will die when the health goes to zero.  Monsters will spawn, stronger the deeper in the dungeon they are.  The dungeon is procedurally generated, has fixed left and right width, and goes down indefinitely.  It is divided into "layers" and each layer is generated the first time an adventurer goes down there.  Layers are some number of tiles high and extend all the way to the left and right.   The dungeon is made of premade rectangular blocks of various sizes.  There will be multiple entrances and exits to each layer from above and below, with the exception of the first layer which only has one entrance from the top at the very center of the town.  When an adventurer meets a monster, they will engage in a very simple "battle" system, where they stand next to each other and trade attacks back and forth, the animation simply being them bumping into the other and moving back, damaging each others' health based on their attack power until ones' health is depleted, at which point they die and the battle ends.  each "block" is made up of "tiles", each monster and adventurer is the size of a single tile.  let's say like a 16x16 sprite.  monsters and adventurers can only walk on floors, it's purely a sidescroller so they have to either walk on the ground or climb ladders to go up or down.  Monsters will spawn regularly from spawner tiles on the edges of each layer.  Blocks are hidden until an adventurer enters them for the first time at which point they are revealed.  Hidden blocks or yet-ungenerated layers look pure black.  Blocks can contain ladders which go up or down and ground-level passageways to blocks to the left/right.

## VERSION 2

version 2 will make significant improvements: more indepth adventurers and some rudimentary management decisions.

Adventurers will have personalized stats, experience, levels, names, ranks, gear.  They also have a bravery and happiness stat.

Adventurers will have stats:  health, attack, defense, speed, which affect combat.  These have base starting values and can increase with level.  instead of a number these are ranks:  F-, F, F+, E-, E, E+, D-, ... , A+, S, SS, SSS.  At each level up, the adventurer chooses one of these to rank up.  Each adventurer has a bias which is a stat they like leveling up over others.  remember, you are the guildmaster, you can't control things yourself.

Adventurers gain experience and gold when they kill monsters.  with enough exp they get levelups.  stronger monsters mean more exp.

Adventurers have random names.  We'll need a name generator.

Adventurers will have ranks, which will be a number of ☆s.  Let's say ☆☆☆☆☆ is the highest rank for now.  Higher rank adventurers have better
starting stats, start at a higher level, and gain more stats on level up.  the limitation is that they are rarer to recruit and have more finicky
happiness requirements (more on that later)

bravery affects how deep they want to go, how long they stay in the dungeon before going back up, and how much health they will need to lose before turning back and trying to get out of the dungeon.  This means we will need improvements to adventurer AI that take this into account.

Adventurers will refuse to go into the dungeon if they are too unhappy.  Unhappy adventurers will also lower your guild's reputation which affects
the rank of adventurers you can recruit.  Happiness is affected by the fatality rate, taxes (which are determined by management
decisions), and alcohol.  Happy adventurers will increase your guild's reputation.

Adventurers with enough extra money will sometimes spend it on gear.  Gear has ranks just like any other stat but instead of increasing by leveling up it's a method of relieving adventurers of their excess money (and making them stronger).  gear is abstracted as a single stat and is a rank just like other stats, F-, F, F+, all the way to SSS, but increases in cost exponentially per rank.

As for management decisions:  you can control taxes (percent of dungeon earnings you get), which affects happiness and income.  Your guild earns 
money it saves up you can use to do upgrades and stuff.

You spend this money on various town upgrades:  for example, you can build an ale hall or a gear shop in town.  Adventurers will spend money there;  for ale, they will gain happiness, for gear, they will increase gear.  You don't own the ale or gear shops, you just pay for the shop being built in the first place.  Later maybe we can change this.  Maybe we can upgrade the shops in some way;  for example, you can spend some money on better gear shops which sell higher ranked gear, or better ale halls which sell better kinds of alcohol.  Adventurers will phyiscally walk to the ale hall or the gear store while in town when doing their thing.

Another management decisions are access rules.  You can set rank, and level restrictions on access to certain floors.  each floor you will be able to add a rank, level, or both filter for it and adventurers won't be able to go to that floor or deeper.

you can build a recruitment office, which increases the rank of adventurers you can recruit.

recruitment: quality of available adventurers is a function of reputation (which is a function of happiness) and the level of your recruitment office.  Basically, you will have a rotating list of prospective randomly generated visiting adventurers who want to join your guild.  You can select them and they join your guild.  This is the other management decision you make.  You can kick out adventurers you don't want in your guild anymore (though this will hurt your reputation).

We will need user interfaces for all of these features.

We will also make whatever improvements to the dungeon and monsters make sense and are commensurate with the improvements to adventurers.  for example monsters will probably have stats too same as adventurers.  We will probably make the dungeon deeper and add more kinds of monsters.

Possibly some UI like a sort of quick view of the dungeon -- a vertical bar always visible on one side of the screen representing the dungeon from top to bottom, with a bunch of adventurer icons on it marking what depth they're at, whether they're in combat, how weak they are, etc.  click on the icon to quick zoom to that adventurer in the actual view.

## VERSION 3

TODO. quest management, guild employees such as in-dungeon shopkeepers, rescuing fallen adventurers?  maybe building infrastructure (modifying the dungeon, e.g. building ladders or shortcuts...?)  we'll see once v2 starts and I figure out what's really important and missing

## VERSION ???

better graphics
any kind of sound effects or music
Start menu, settings menu, credits page
Tutorial?
Dungeon/town events (cave-ins, earthquakes that shuffle rooms, infestations, weather effects)
Legendary/famous adventurers?
Adventuring parties, classes?
Day/night cycle
Themed dungeon zones (ice cavern, lava level, haunted level etc.) with zone-specific monsters and hazards
Secret rooms requiring specific conditions to unlock?
Artifacts and rare items found in the dungeon?
Dungeon economy (item prices fluctuate based on supply/demand, quest rewards tied to market)
Graveyard/hall of fame for fallen adventurers?
