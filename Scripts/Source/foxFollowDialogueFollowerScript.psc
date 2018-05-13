ScriptName foxFollowDialogueFollowerScript extends Quest
{Rewrite of DialogueFollowerScript with cool new stuff - see DialogueFollowerScript too, which had to stay the same name, and simply forwards its calls to us}

;Begin Vanilla DialogueFollowerScript Members
; GlobalVariable Property pPlayerFollowerCount Auto
; GlobalVariable Property pPlayerAnimalCount Auto
; ReferenceAlias Property pFollowerAlias Auto
; ReferenceAlias property pAnimalAlias Auto
; Faction Property pDismissedFollower Auto
; Faction Property pCurrentHireling Auto
; Message Property	FollowerDismissMessage Auto
; Message Property AnimalDismissMessage Auto
; Message Property	FollowerDismissMessageWedding Auto
; Message Property	FollowerDismissMessageCompanions Auto
; Message Property	FollowerDismissMessageCompanionsMale Auto
; Message Property	FollowerDismissMessageCompanionsFemale Auto
; Message Property	FollowerDismissMessageWait Auto
; SetHirelingRehire Property HirelingRehireScript Auto
;
; ;Property to tell follower to say dismissal line
; Int Property iFollowerDismiss Auto Conditional
;
; ; PATCH 1.9: 77615: remove unplayable hunting bow when follower is dismissed
; Weapon Property FollowerHuntingBow Auto
; Ammo Property FollowerIronArrow Auto
;End Vanilla DialogueFollowerScript Members

DialogueFollowerScript Property DialogueFollower Auto

Actor Property PlayerRef Auto
Faction Property FollowerInfoFaction Auto
ReferenceAlias Property FollowerAlias0 Auto
ReferenceAlias Property FollowerAlias1 Auto
ReferenceAlias Property FollowerAlias2 Auto
ReferenceAlias Property FollowerAlias3 Auto
ReferenceAlias Property FollowerAlias4 Auto
ReferenceAlias Property FollowerAlias5 Auto
ReferenceAlias Property FollowerAlias6 Auto
ReferenceAlias Property FollowerAlias7 Auto
ReferenceAlias Property FollowerAlias8 Auto
ReferenceAlias Property FollowerAlias9 Auto

Sound Property FollowerLearnSpellSound Auto
Sound Property FollowerForgetSpellSound Auto
Message Property FollowerLearnSpellMessage Auto
Message Property FollowerForgetSpellMessage Auto
Message Property FollowerCommandModeMessage Auto

Spell Property FollowerSpeedAbility Auto

int Property foxFollowVer Auto
int Property foxFollowScriptVer = 1 AutoReadOnly

float Property WaitAroundForPlayerGameTime = 72.0 AutoReadOnly
float Property InitialUpdateTime = 2.0 AutoReadOnly

ReferenceAlias[] Followers
int CommandMode

;Useful debug hotkeys
; event OnControlDown(string control)
; 	if (control == "Activate")
; 		RegisterForControl("Sprint")
; 		RegisterForControl("Jump")
; 		RegisterForControl("Sneak")
; 	elseif (control == "Sprint")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 		DialogueFollower.DismissFollower()
; 	elseif (control == "Jump")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 		DialogueFollower.DismissAnimal()
; 	elseif (control == "Sneak")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 		string stuff = ""
; 		int i = 0
; 		while (i < Followers.Length)
; 			if (i > 0)
; 				stuff += "\n"
; 			endif
; 			stuff += Followers[i]
; 			i += 1
; 		endwhile
; 		Debug.Messagebox(stuff)
; 		stuff = ""
; 		i = 0
; 		while (i < Followers.Length)
; 			if (i > 0)
; 				stuff += "\n"
; 			endif
; 			if (Followers[i].GetActorRef())
; 				stuff += Followers[i].GetActorRef()
; 			else
; 				stuff += "None"
; 			endif
; 			i += 1
; 		endwhile
; 		Debug.Messagebox(stuff)
; 		stuff = DialogueFollower.pFollowerAlias + "\n" + DialogueFollower.pAnimalAlias
; 		if (DialogueFollower.pFollowerAlias.GetActorRef())
; 			stuff += "\n" + DialogueFollower.pFollowerAlias.GetActorRef()
; 		else
; 			stuff += "\nNone"
; 		endif
; 		if (DialogueFollower.pAnimalAlias.GetActorRef())
; 			stuff += "\n" + DialogueFollower.pAnimalAlias.GetActorRef()
; 		else
; 			stuff += "\nNone"
; 		endif
; 		Debug.Messagebox(stuff)
; 	endif
; endEvent
; event OnControlUp(string control, float HoldTime)
; 	if (control == "Activate")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 	endif
; endEvent

;Init our stuff - hey since we're a separate script now this will actually always run on first load, hooray!
event OnInit()
	RegisterForSingleUpdate(2.0)
endEvent

;See if we need to update from an old save (or first run from vanilla save)
;Currently checked on OnInit, SetMultiFollower, and any current followers' OnActivate
function CheckForModUpdate()
	;Set foxFollowVer ASAP to avoid mod updates being run twice from two threads
	int ver = foxFollowVer
	foxFollowVer = foxFollowScriptVer
	if (ver < foxFollowScriptVer)
		if (ver < 1)
			ModUpdate1()
		endif

		;Ready to rock!
		;Possibly display update message - will only be displayed on existing saves, foxFollowVer set to -1 on new game from DialogueFollowerScript
		if (ver != -1)
			Debug.MessageBox("foxFollow ready to roll!\nPrevious Version: " + ver + "\nNew Version: " + foxFollowScriptVer + "\n\nIf uninstalling mod later, please remember\nto dismiss all followers first. Thanks!")
		endif
	endif

	;Useful debug hotkeys
	;RegisterForControl("Activate")
endFunction
event OnUpdate()
	CheckForModUpdate()
endEvent
function ModUpdate1()
	;Telling our modified DialogueFollower to point to us, if it's somehow None (existing saves should pull the CK value, but PlayerRef somehow ended up None in foxPet)
	if (!DialogueFollower.foxFollowDialogueFollower)
		DialogueFollower.foxFollowDialogueFollower = Self
	endif

	;Init our stuff!
	Followers = new ReferenceAlias[10]
	Followers[0] = FollowerAlias0
	Followers[1] = FollowerAlias1
	Followers[2] = FollowerAlias2
	Followers[3] = FollowerAlias3
	Followers[4] = FollowerAlias4
	Followers[5] = FollowerAlias5
	Followers[6] = FollowerAlias6
	Followers[7] = FollowerAlias7
	Followers[8] = FollowerAlias8
	Followers[9] = FollowerAlias9
	CommandMode = 0

	;Grab our existing follower/animal followers from vanilla save
	;Just use SetMultiFollower with a ForcedDestAlias to accomplish this - will safely ignore CheckForModUpdate
	Actor FollowerActor = DialogueFollower.pFollowerAlias.GetActorRef()
	if (FollowerActor)
		SetMultiFollower(FollowerActor, true, FollowerAlias0)
	endif
	FollowerActor = DialogueFollower.pAnimalAlias.GetActorRef()
	if (FollowerActor)
		SetMultiFollower(FollowerActor, false, FollowerAlias1)
	endif

	;Finally clean up our any registered updates on vanilla aliases, as those won't be needed anymore
	DialogueFollower.pFollowerAlias.UnRegisterForUpdateGameTime()
	DialogueFollower.pFollowerAlias.UnRegisterForUpdate()
	DialogueFollower.pAnimalAlias.UnRegisterForUpdateGameTime()
	DialogueFollower.pAnimalAlias.UnRegisterForUpdate()
endFunction

;Attempt to add follower by ref - returns alias if successful
ReferenceAlias function AddFollowerAlias(ObjectReference FollowerRef)
	int i = 0
	while (i < Followers.Length)
		if (SetFollowerAlias(Followers[i], FollowerRef))
			return Followers[i]
		endif
		i += 1
	endwhile
	return None
endFunction

;Set follower alias by ref - returns true if successful
bool function SetFollowerAlias(ReferenceAlias FollowerAlias, ObjectReference FollowerRef)
	if (FollowerAlias.ForceRefIfEmpty(FollowerRef))
		;Add back all our book-learned spells again - no real way to keep track of these when not following
		;This has the added bonus of retroactively applying to previously dismissed vanilla followers carrying spell tomes
		(FollowerAlias as foxFollowFollowerAliasScript).AddAllBookSpells()

		;Finally, register us for an update so we start doing nifty catchup stuff
		FollowerAlias.RegisterForSingleUpdate(InitialUpdateTime)
		return true
	endif
	return false
endFunction

;Remove follower by alias
function RemoveFollowerAlias(ReferenceAlias FollowerAlias)
	;First, cancel any pending update
	FollowerAlias.UnRegisterForUpdateGameTime()
	FollowerAlias.UnRegisterForUpdate()

	;Also remove all our book-learned spells - no real way to keep track of these when not following
	(FollowerAlias as foxFollowFollowerAliasScript).RemoveAllBookSpells()

	;Clear!
	FollowerAlias.Clear()

	;Make sure our preferred followers are filled with something
	CheckPreferredFollowerAlias(true)
	CheckPreferredFollowerAlias(false)
endFunction

;Get follower at index
ReferenceAlias function GetFollowerAlias(int i)
	return Followers[i]
endFunction

;Find follower by ref
ReferenceAlias function GetFollowerAliasByRef(ObjectReference FollowerRef)
	int i = 0
	while (i < Followers.Length)
		if (Followers[i].GetRef() == FollowerRef)
			return Followers[i]
		endif
		i += 1
	endwhile
	return None
endFunction

;Find follower by follower type (Follower / Animal)
ReferenceAlias function GetAnyFollowerAliasByType(bool isFollower)
	Actor FollowerActor = None
	int i = 0
	while (i < Followers.Length)
		FollowerActor = Followers[i].GetActorRef()
		if (FollowerActor && IsFollower(FollowerActor) == isFollower)
			return Followers[i]
		endif
		i += 1
	endwhile
	return None
endFunction

;Find any follower
ReferenceAlias function GetAnyFollowerAlias()
	int i = 0
	while (i < Followers.Length)
		if (Followers[i].GetRef())
			return Followers[i]
		endif
		i += 1
	endwhile
	return None
endFunction

;Attempt to untangle which follower we're talking about
ReferenceAlias function GetPreferredFollowerAlias(bool isFollower)
	Actor FollowerActor = None
	if (isFollower)
		FollowerActor = DialogueFollower.pFollowerAlias.GetActorRef()
	else
		FollowerActor = DialogueFollower.pAnimalAlias.GetActorRef()
	endif
	if (FollowerActor && IsFollower(FollowerActor) == isFollower)
		;Debug.Trace("foxFollow got single preffered alias - IsFollower: " + isFollower)
		return GetFollowerAliasByRef(FollowerActor)
	endif
	;Debug.Trace("foxFollow got no alias :( - IsFollower: " + isFollower)
	return None
endFunction

;Set our preferred follower (will use for ambiguous situations where possible) - called generally from current followers' OnActivate
function SetPreferredFollowerAlias(Actor FollowerActor, int newCommandMode = 0)
	;Debug.Trace("foxFollow SetPreferredFollowerAlias - IsFollower: " + IsFollower(FollowerActor))
	if (IsFollower(FollowerActor))
		DialogueFollower.pFollowerAlias.ForceRefTo(FollowerActor)
	else
		DialogueFollower.pAnimalAlias.ForceRefTo(FollowerActor)
	endif

	;Also handle CommandMode here - for now, CommandMode > 0 means command all followers
	;Assign a negative value to indicate CommandMode is waiting to be consumed by a supported command
	CommandMode = -newCommandMode
endFunction

;Check our preferred follower, setting to first available if empty (so we have something for commands to use - also nice to have vanilla aliases filled for any third party scripts)
function CheckPreferredFollowerAlias(bool isFollower)
	ObjectReference FollowerRef = None
	if (isFollower)
		FollowerRef = DialogueFollower.pFollowerAlias.GetRef()
	else
		FollowerRef = DialogueFollower.pAnimalAlias.GetRef()
	endif
	if (GetFollowerAliasByRef(FollowerRef))
		return
	endif

	ReferenceAlias FollowerAlias = GetAnyFollowerAliasByType(isFollower)
	if (FollowerAlias)
		;Debug.Trace("foxFollow CheckPreferredFollowerAlias set new alias - IsFollower: " + isFollower)
		if (isFollower)
			DialogueFollower.pFollowerAlias.ForceRefTo(FollowerAlias.GetRef())
		else
			DialogueFollower.pAnimalAlias.ForceRefTo(FollowerAlias.GetRef())
		endif
	else
		;Debug.Trace("foxFollow CheckPreferredFollowerAlias cleared - IsFollower: " + isFollower)
		if (isFollower)
			DialogueFollower.pFollowerAlias.Clear()
		else
			DialogueFollower.pAnimalAlias.Clear()
		endif
	endif
endFunction

;Clear our preferred follower if it's set to FollowerActor - called from current followers' OnActivate
;Note: This currently just clears CommandMode since we now keep preferred follower populated at all times - but could be used for actually clearing again at some point...
function ClearPreferredFollowerAlias(Actor FollowerActor)
	ReferenceAlias PreferredFollower = GetPreferredFollowerAlias(IsFollower(FollowerActor))
	if (PreferredFollower && PreferredFollower.GetActorRef() == FollowerActor && !MeetsPreferredFollowerAliasConditions(FollowerActor))
		;Debug.Trace("foxFollow ClearPreferredFollowerAlias! - IsFollower: " + IsFollower(FollowerActor))

		;Only clear CommandMode if the other preferred follower also isn't gabbing
		PreferredFollower = GetPreferredFollowerAlias(!IsFollower(FollowerActor))
		if (PreferredFollower)
			FollowerActor = PreferredFollower.GetActorRef()
		endif
		if (!FollowerActor || !MeetsPreferredFollowerAliasConditions(FollowerActor))
			;Debug.Trace("foxFollow ClearPreferredFollowerAlias clearing CommandMode!")
			CommandMode = 0
		endif
	endif
endFunction

;Are we the probable target for follow / wait / dismiss? (e.g. recently in dialogue with player, recently interacted with... any clues)
bool function MeetsPreferredFollowerAliasConditions(Actor FollowerActor)
	return FollowerActor.IsInDialogueWithPlayer() || FollowerActor.IsDoingFavor()
endFunction

;Figure out if we're a follower follower or animal follower
bool function IsFollower(Actor FollowerActor)
	return FollowerActor.IsInFaction(FollowerInfoFaction)
endFunction

;Get how many followers we actually have - also return breakdown by follower type (Follower / Animal) in out variables
int outNumFollowers
int outNumAnimals
int function GetNumFollowers()
	outNumFollowers = 0
	outNumAnimals = 0
	Actor FollowerActor = None
	int i = 0
	while (i < Followers.Length)
		FollowerActor = Followers[i].GetActorRef()
		if (FollowerActor)
			if (IsFollower(FollowerActor))
				outNumFollowers += 1
			else
				outNumAnimals += 1
			endif
		endif
		i += 1
	endwhile
	return outNumFollowers + outNumAnimals
endFunction

;Update follower count (whether we can recruit new followers) based on how many followers we actually have - returns true if at capacity
;Currently checked on SetMultiFollower, DismissMultiFollowerClearAlias, and any current followers' OnActivate
bool function UpdateFollowerCount()
	if (GetNumFollowers() >= Followers.Length)
		DialogueFollower.pPlayerFollowerCount.SetValue(1)
		DialogueFollower.pPlayerAnimalCount.SetValue(1)
		return true
	endif
	DialogueFollower.pPlayerFollowerCount.SetValue(0)
	DialogueFollower.pPlayerAnimalCount.SetValue(0)
	return false
endFunction

;Version of SetFollower that handles multiple followers
function SetMultiFollower(ObjectReference FollowerRef, bool isFollower, ReferenceAlias ForcedDestAlias = None)
	;Make sure our Follower array is good to go!
	;If we have a ForcedDestAlias, we're probably coming from CheckForModUpdate
	if (!ForcedDestAlias)
		CheckForModUpdate()
	endif

	;There's a chance some follow scripts might get confused and attempt to add us twice
	;e.g. foxPet when activated while favors active (oops!)
	;This will be difficult to recover from later, so try to catch this here
	;Note that this will also clear any other conflicts if they somehow exist, thanks to DismissMultiFollowerClearAlias
	ReferenceAlias FollowerAlias = GetFollowerAliasByRef(FollowerRef)
	if (FollowerAlias)
		;Debug.Trace("foxFollow attempted to add follower that already existed! Oops... - IsFollower: " + isFollower)
		DismissMultiFollower(FollowerAlias, isFollower)
	endif

	;Do we exist?
	Actor FollowerActor = FollowerRef as Actor
	if (!FollowerActor)
		return
	endif

	;Attempt to assign the appropriate reference appropriately - do this first so we can safely bail if something goes wrong
	if (ForcedDestAlias && SetFollowerAlias(ForcedDestAlias, FollowerActor))
		FollowerAlias = ForcedDestAlias
	else
		if (ForcedDestAlias)
			Debug.MessageBox("Couldn't set ForcedDestAlias! Oops\nUsing first available instead...\nIsFollower: " + isFollower)
		endif
		FollowerAlias = AddFollowerAlias(FollowerActor)
	endif
	if (!FollowerAlias)
		Debug.MessageBox("Added too many followers! Oops\nNo available slots. Skipping...\nIsFollower: " + isFollower)
		return
	endif

	;Fairly standard DialogueFollowerScript.SetFollower code follows
	FollowerActor.RemoveFromFaction(DialogueFollower.pDismissedFollower)
	if (FollowerActor.GetRelationshipRank(PlayerRef) < 3 && FollowerActor.GetRelationshipRank(PlayerRef) >= 0)
		FollowerActor.SetRelationshipRank(PlayerRef, 3)
	endif

	;Per Vanilla - "don't allow lockpicking"
	;However, we'll allow this as we're too lazy to restore it after, and besides, who cares?
	;if (!isFollower)
	;	FollowerActor.SetActorValue("Lockpicking", 0)
	;endif

	;However, only allow favors if we aren't recruiting an animal (animals themselves are of course free to override this after SetAnimal(), e.g. foxPet)
	FollowerActor.SetPlayerTeammate(abCanDoFavor = isFollower)

	;Check to see if we're at capacity - if so, set both follower counts to 1
	;This prevents taking on any more followers of either kind until a reference is freed up
	UpdateFollowerCount()

	;If we're a follower and not an animal, add to "info" faction so we know what type we are later
	;Also set our preferred follower while we're here, since we did just interact with this follower
	if (isFollower)
		FollowerActor.AddToFaction(FollowerInfoFaction)
	endif
	SetPreferredFollowerAlias(FollowerActor)
endFunction

;Version of FollowerWait / FollowerFollow that handles multiple followers
;Note: isFollower only matters if FollowerAlias is None
function FollowerMultiFollowWait(ReferenceAlias FollowerAlias, bool isFollower, int mode)
	;This gets tricky because we very well may have no idea who we're actually telling to follow / wait
	;However, if we're commanding multiple followers, this is fine and we'll actually force a None FollowerAlias...
	if (CommandMode < 0)
		CommandMode *= -1 ;Negate CommandMode again to indicate we've consumed it, so it's not again handled by recursive calls
		FollowerAlias = None
	elseif (!FollowerAlias)
		FollowerAlias = GetPreferredFollowerAlias(isFollower)
	endif

	;If we can't figure out a specific follower, make everyone wait / follow - either we're in CommandMode, or we've been called from a quest or something
	;This should actually never happen now (unless we're in CommandMode of course), since we make sure our preferred follower is always filled
	if (!FollowerAlias)
		int i = 0
		while (i < Followers.Length)
			if (Followers[i].GetRef())
				FollowerMultiFollowWait(Followers[i], isFollower, mode)
			endif
			i += 1
		endwhile
		CommandMode = 0
		return
	endif

	FollowerAlias.GetActorRef().SetActorValue("WaitingForPlayer", mode)
	if (mode > 0)
		;SetObjectiveDisplayed(10, abforce = true)
		FollowerAlias.RegisterForSingleUpdateGameTime(WaitAroundForPlayerGameTime)
	else
		;SetObjectiveDisplayed(10, abdisplayed = false)
		FollowerAlias.RegisterForSingleUpdate(InitialUpdateTime)
	endif
endFunction

;Version of DismissFollower that handles multiple followers
function DismissMultiFollower(ReferenceAlias FollowerAlias, bool isFollower, int iMessage = 0, int iSayLine = 1)
	;This gets tricky because we very well may have no idea who we're actually dismissing
	;However, if we're commanding multiple followers, this is fine and we'll actually force a None FollowerAlias...
	if (CommandMode < 0)
		CommandMode *= -1 ;Negate CommandMode again to indicate we've consumed it, so it's not again handled by recursive calls
		FollowerAlias = None

		;Just pass in iSayLine 0 because we don't really need to hear the whole party blab
		;We'll keep iMessage though because rapid notifications aren't necessarily spammed and some of the info might be useful
		;But! iMessage 2 is companions dismissal that doesn't reset PlayerFollowerCount / PlayerAnimalCount
		;Double-But! If this ever happens (e.g. we're talking to a follower in CommandMode when triggered) we know our followers are getting replaced, so we'll trust it
		;Besides, PlayerFollowerCount / AnimalFollowerCount is apparently messed with all over the place - so we'll need to sanitize those later anyway
		iSayLine = 0
	elseif (!FollowerAlias)
		;Debug.Trace("foxFollow attempting to dismiss None... - IsFollower: " + isFollower)
		FollowerAlias = GetPreferredFollowerAlias(isFollower)
	endif

	;If we can't figure out a specific follower, just dismiss everyone of our follow type - either we're in CommandMode, or we've been called from a quest or something
	;This should actually never happen now (unless we're in CommandMode of course), since we make sure our preferred follower is always filled
	if (!FollowerAlias)
		int i = 0
		while (i < Followers.Length)
			Actor MultiActor = Followers[i].GetActorRef()
			if (!MultiActor)
				;Just purge the slot anyways - iMessage -1 tells DismissMultiFollower to skip None Actor warning
				DismissMultiFollower(Followers[i], true, -1, 0)
			elseif (CommandMode || IsFollower(MultiActor) == isFollower)
				DismissMultiFollower(Followers[i], isFollower, iMessage, iSayLine)
			endif
			i += 1
		endwhile
		CommandMode = 0
		return
	endif

	;If we don't exist or we're dead, time for express dismissal! Hiyaa1
	Actor FollowerActor = FollowerAlias.GetActorRef()
	if (!FollowerActor || FollowerActor.IsDead())
		;Fairly standard FollowerAliasScript.OnDeath / TrainedAnimalScript.OnDeath... More or less
		if (FollowerActor)
			FollowerActor.RemoveFromFaction(DialogueFollower.pCurrentHireling)
		elseif (iMessage != -1)
			Debug.MessageBox("Can't dismiss None Actor! Oops\nClearing follower alias anyway...\nIsFollower: " + isFollower)
		endif
		DismissMultiFollowerClearAlias(FollowerAlias, FollowerActor, iMessage)
		return
	endif

	;Oops we should probably reset SpeedMult hehe
	(FollowerAlias as foxFollowFollowerAliasScript).SetSpeedup(FollowerActor, false)

	;Make sure we're actually a follower (might have gotten mixed up somehow - could happen if we try to trick the script by quickly talking to the wrong type)
	if (IsFollower(FollowerActor) != isFollower)
		;Debug.Trace("Follower type didn't match! - IsFollower: " + isFollower)
		isFollower = IsFollower(FollowerActor)
	endif
	FollowerActor.RemoveFromFaction(FollowerInfoFaction)

	;TODO Tell our alias script whether we're a follower or not so we don't have to keep calling IsFollower
	;Could likely replace FollowerInfoFaction with this? Might be cleaner and would require no Actor loaded
	;(FollowerAlias as foxFollowFollowerAliasScript).IsFollower = isFollower

	;These things from DialogueFollowerScript.DismissFollower we would like to run on both followers and animals
	FollowerActor.StopCombatAlarm()
	FollowerActor.SetPlayerTeammate(false)
	FollowerActor.SetActorValue("WaitingForPlayer", 0)

	;Per Vanilla - "PATCH 1.9: 77615: remove unplayable hunting bow when follower is dismissed"
	;Added in additional safety checks - may not be set on old scripts
	if (DialogueFollower.FollowerHuntingBow && DialogueFollower.FollowerIronArrow)
		int itemCount = FollowerActor.GetItemCount(DialogueFollower.FollowerHuntingBow)
		if (itemCount > 0)
			FollowerActor.RemoveItem(DialogueFollower.FollowerHuntingBow, itemCount, true)
		endif
		itemCount = FollowerActor.GetItemCount(DialogueFollower.FollowerIronArrow)
		if (itemCount > 0)
			FollowerActor.RemoveItem(DialogueFollower.FollowerIronArrow, itemCount, true)
		endif
	endif

	if (isFollower)
		;Fairly standard DialogueFollowerScript.DismissFollower code
		if (iMessage == 0)
			DialogueFollower.FollowerDismissMessage.Show()
		elseif (iMessage == 1)
			DialogueFollower.FollowerDismissMessageWedding.Show()
		elseif (iMessage == 2)
			DialogueFollower.FollowerDismissMessageCompanions.Show()
		elseif (iMessage == 3)
			DialogueFollower.FollowerDismissMessageCompanionsMale.Show()
		elseif (iMessage == 4)
			DialogueFollower.FollowerDismissMessageCompanionsFemale.Show()
		elseif (iMessage == 5)
			DialogueFollower.FollowerDismissMessageWait.Show()
		elseif (iMessage != -1)
			DialogueFollower.FollowerDismissMessage.Show()
		endif
		FollowerActor.AddToFaction(DialogueFollower.pDismissedFollower)
		FollowerActor.RemoveFromFaction(DialogueFollower.pCurrentHireling)

		;Per Vanilla - "hireling rehire function"
		DialogueFollower.HirelingRehireScript.DismissHireling(FollowerActor.GetActorBase())
		if (iSayLine == 1)
			DialogueFollower.iFollowerDismiss = 1
			FollowerActor.EvaluatePackage()
			;Per Vanilla - "Wait for follower to say line"
			;We don't need to wait 2 seconds though
			Utility.Wait(0.5)
		endif
		DialogueFollower.iFollowerDismiss = 0
	elseif (iMessage != -1)
		;Fairly standard DialogueFollowerScript.DismissAnimal code
		;Note: Variable04 would be set to 1 in AnimalTrainerSystemScript, but it looks like that was commented out, so let's not tamper with it
		;FollowerActor.SetActorValue("Variable04", 0)
		DialogueFollower.AnimalDismissMessage.Show()
	endif

	;Ready to roll!
	DismissMultiFollowerClearAlias(FollowerAlias, FollowerActor, iMessage)
endFunction
function DismissMultiFollowerClearAlias(ReferenceAlias FollowerAlias, Actor FollowerActor, int iMessage)
	;Remove that alias!
	RemoveFollowerAlias(FollowerAlias)

	;Set both counts to 0 so we're ready to accept either follower type again
	UpdateFollowerCount()

	;Finally, there's a chance we ended up with multiple followers pointing to the same ref
	;This should never happen, but we should try to unwrangle it just in case
	;We'll only need to clear these out - we've already cleaned up the ref itself in DismissMultiFollower
	;Of course this is moot on None Actor anyways - d'oh!
	if (!FollowerActor)
		return
	endif
	FollowerAlias = GetFollowerAliasByRef(FollowerActor)
	while (FollowerAlias)
		;Debug.Trace("foxFollow cleaning up duplicate followers... - IsFollower: " + IsFollower(FollowerActor))
		RemoveFollowerAlias(FollowerAlias)
		FollowerAlias = GetFollowerAliasByRef(FollowerActor)
	endwhile
endFunction
