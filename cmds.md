A command is called like this: !name arguments -flag -flag  
Flags can come in any order but arguments must be ordered.  
Arguments in italics are optional. All flags are optional.  

## User Commands
`pmh`  
Print medic history  
Include flag `-me` to only print your immunity status.  

`v` player  
Volunteer to be medic in place of `player`  
`v` team  
Volunteer to be medic for team `team`

`deaf`
`undeaf`  
Server deafen or undeafen.

`purgstatus` How many medic games do I have left to play, if I'm in purgatory?  

`flip` Heads or tails?

`rng` num1 num2  
Returns a random number in the range provided.

## Mod commands:  
Glossary:  
Pug pool - A pug pool (called a namespace in the code) is the parent room containing add up, chill room, and the pug servers for a pool. There are two pug pools, normal pugs and junior pugs (Pug Pools 1 and 2).  
Pug Pool Conscious Commands operate within a pug pool, so you must be sure to call the commands correctly. These commands **DEFAULT** to Pug Pool 1 (normal pugs). In order to use them for junior pugs you must include the flag **-newb**
##### Pug Pool Conscious Commands 
`roll` *number*   
Roll for medics.   
**Args**:  
`number` - the number of medics to roll. If omitted, the command will determine how many medics you need and provide that amount.  
**Flags**:   
`-b` Bottom up: fill the bottom pug first.  

`link` server  
Link the red/blu channels to each other and addup in `server`

`unlink` server  
Unlink the red/blu channels from each other and addup in `server`

`dc` server  
Dump the players from the red/blu channels from `server` into addup.

`cull`  
Move deafened players from addup to chill room.

`afkcheck` *player*  
If no argument: Move all afk players from addup to chill room.  
If `player` provided: Check if player is AFK. If they are, move them.

`mund`  
If anyone is server deafened through the bot, undeafen them.

`draftlock` *bool*  
If `bool` is included, set draftlock to that bool (true/false). If not included, toggle draftlock to whatever it isn't.

`mute`  
Mute everyone in addup, unlink chill room from addup.

`unmute`  
Unmute everyone in addup, link chill room to addup.

##### Pug Pool Irrelevant

`clearmh`  
Clears medic history.

`strike` player  
Removes medic immunity from `player`

`ami` player  
Gives medic immunity to `player`

`massadd` player anotherplayer onemoreplayer ...  
Give medic immunity to all players provided

`setmotd` your message  
Set a message of the day

`readout` variable  
Get the value of a global variable within the bot. Can also print out tables like warrants, purgatory, etc. Can readout keys from tables if you write like this: `!readout players User medicImmunity` (equiv to writing print(players["User"]["medicImmunity"] in the interpreter). Case sensitive.

`pmute` player  
Toggle server muting of `player` that persists through multiple sessions.

`dpr` player  
Remove player from "prison" (Prison prevents a person from changing channels - it is enacted after they volunteer for medic and removed when their game is done)

`append` table value  
Add value to a global table.  
Potential uses:  
`!append warrants person` Place a warrant on person, who will be banned on next connect.  

`remove` table value  
Remove value from table.

`sync` thing  
`thing` can be `channels` or `admins`.
Synchronize channels - use this if you add or remove a pug server.
Synchronize admins - use this if you give mod powers to someone.

`toggle` val  
`val` can be **motd** or **dle** or **q**. dle is draftlock's oversight. If dle is toggled off, draftlock will never happen. If q (quarantine) is toggled on, unregistered users will be forced to stay in root until registered.  
**Flags:**  
`-f` If used, val can be any global variable. Be very careful!

`purg` player *num*  
Assign/unassign medic purgatory.  
**Args:**  
`player` - the player to change.  
`num` - defaults to 3 - can be any number. 0 will clear purgatory.
