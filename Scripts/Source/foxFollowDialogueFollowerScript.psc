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
; 		DismissFollower()
; 	elseif (control == "Jump")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 		DismissAnimal()
; 	elseif (control == "Sneak")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 		string stuff = ""
; 		int i = 0
; 		while (i < Followers.Length)
; 			stuff += Followers[i] + "\n"
; 			i += 1
; 		endwhile
; 		Debug.Messagebox(stuff)
; 		stuff = ""
; 		i = 0
; 		while (i < Followers.Length)
; 			if (Followers[i].GetActorRef())
; 				stuff += Followers[i].GetActorRef()
; 			else
; 				stuff += "None"
; 			endif
; 			stuff += "\n"
; 			i += 1
; 		endwhile
; 		Debug.Messagebox(stuff)
; 	endif
; endEvent
; event OnControlUp(string control, float HoldTime)
; 	if (control == "Activate")
; 		UnregisterForAllControls()
; 		RegisterForControl("Activate")
; 	endif
; endEvent

;On the off chance we're actually running this on a new game (DialogueFollower is ever-present!), init stuff!
event OnInit()
	CheckForModUpdate(false)
endEvent

;See if we need to update from an old save (or first run from vanilla save)
;Currently checked on OnInit, SetMultiFollower, and any current followers' OnActivate
function CheckForModUpdate(bool ShowUpdateMessage = true)
	if (foxFollowVer < foxFollowScriptVer)
		if (foxFollowVer < 1)
			ModUpdate1()
		endif

		;Ready to rock!
		if (ShowUpdateMessage)
			Debug.MessageBox("foxFollow ready to roll!\nPrevious Version: " + foxFollowVer + "\nNew Version: " + foxFollowScriptVer + "\n\nIf uninstalling mod later, please remember\nto dismiss all followers first. Thanks!")
		endif
		foxFollowVer = foxFollowScriptVer
	endif

	;Useful debug hotkeys
	;RegisterForControl("Activate")
endFunction
function ModUpdate1()
	;Init our stuff, grabbing existing refs from vanilla save
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

	;Also add existing follower follower (as opposed to animal follower) to "info" faction
	;Also retroactively learn spells from any spell tomes we might have?
	Actor FollowerActor = DialogueFollower.pFollowerAlias.GetActorRef()
	if (FollowerActor)
		FollowerActor.AddToFaction(FollowerInfoFaction)
		FollowerAlias0.ForceRefTo(FollowerActor)
		(FollowerAlias0 as foxFollowFollowerAliasScript).AddAllBookSpells()
	endif
	FollowerActor = DialogueFollower.pAnimalAlias.GetActorRef()
	if (FollowerActor)
		FollowerAlias1.ForceRefTo(FollowerActor)
		(FollowerAlias1 as foxFollowFollowerAliasScript).AddAllBookSpells()
	endif
endFunction

;Attempt to add follower by ref - returns alias if successful
ReferenceAlias function AddFollowerAlias(ObjectReference FollowerRef)
	int i = 0
	while (i < Followers.Length)
		if (Followers[i].ForceRefIfEmpty(FollowerRef))
			;Add back all our book-learned spells again - no real way to keep track of these when not following
			;This has the added bonus of retroactively applying to previously dismissed vanilla followers carrying spell tomes
			(Followers[i] as foxFollowFollowerAliasScript).AddAllBookSpells()

			;Finally, register us for an update so we start doing nifty catchup stuff
			Followers[i].RegisterForSingleUpdate(InitialUpdateTime)

			return Followers[i]
		endif
		i += 1
	endwhile
	return None
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
	if (FollowerActor)
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

;Clear our preferred follower, and set to first available (so we have something for commands to use - also nice to have vanilla aliases filled for any third party scripts)
function ResetPreferredFollowerAlias(bool isFollower)
	;Debug.Trace("foxFollow ResetPreferredFollowerAlias - IsFollower: " + isFollower)
	if (isFollower)
		DialogueFollower.pFollowerAlias.UnRegisterForUpdateGameTime()
		DialogueFollower.pFollowerAlias.UnRegisterForUpdate()
		DialogueFollower.pFollowerAlias.Clear()
	else
		DialogueFollower.pAnimalAlias.UnRegisterForUpdateGameTime()
		DialogueFollower.pAnimalAlias.UnRegisterForUpdate()
		DialogueFollower.pAnimalAlias.Clear()
	endif

	ReferenceAlias FollowerAlias = GetAnyFollowerAliasByType(isFollower)
	if (FollowerAlias)
		Actor FollowerActor = FollowerAlias.GetActorRef()
		if (FollowerActor)
			SetPreferredFollowerAlias(FollowerActor)
		endif
	endif
endFunction

;Clear our preferred follower if it's set to FollowerActor - called from current followers' OnActivate
function ClearPreferredFollowerAlias(Actor FollowerActor)
	ReferenceAlias PreferredFollower = GetPreferredFollowerAlias(IsFollower(FollowerActor))
	if (PreferredFollower && PreferredFollower.GetActorRef() == FollowerActor && !MeetsPreferredFollowerAliasConditions(FollowerActor))
		;Debug.Trace("foxFollow ClearPreferredFollowerAlias! - IsFollower: " + IsFollower(FollowerActor))
		CommandMode = 0
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

;Version of SetFollower that handles multiple followers
function SetMultiFollower(ObjectReference FollowerRef, bool isFollower)
	;Make sure our Follower array is good to go!
	CheckForModUpdate()

	;There's a chance some follow scripts might get confused and attempt to add us twice
	;e.g. foxPet when activated while favors active (oops!)
	;This will be difficult to recover from later, so try to catch this here
	ReferenceAlias FollowerAlias = GetFollowerAliasByRef(FollowerRef)
	if (FollowerAlias)
		;Debug.Trace("foxFollow attempted to add follower that already existed! Oops... - IsFollower: " + isFollower)
		DismissMultiFollower(FollowerAlias, isFollower)
	endif

	;Fairly standard DialogueFollowerScript.SetFollower code
	Actor FollowerActor = FollowerRef as Actor
	if (!FollowerActor)
		return
	endif
	FollowerActor.RemoveFromFaction(DialogueFollower.pDismissedFollower)
	if (FollowerActor.GetRelationshipRank(PlayerRef) < 3 && FollowerActor.GetRelationshipRank(PlayerRef) >= 0)
		FollowerActor.SetRelationshipRank(PlayerRef, 3)
	endif

	;Per Vanilla - "don't allow lockpicking"
	;However, we'll allow this as we're too lazy to restore it after, and besides, who cares?
	;if (!isFollower)
	;	FollowerActor.SetAV("Lockpicking", 0)
	;endif

	;However, only allow favors if we aren't recruiting an animal (animals themselves are of course free to override this after SetAnimal(), e.g. foxPet)
	FollowerActor.SetPlayerTeammate(abCanDoFavor = isFollower)

	;Attempt to assign the appropriate reference appropriately
	FollowerAlias = AddFollowerAlias(FollowerActor)
	if (!FollowerAlias)
		Debug.MessageBox("Added too many followers! Oops\nIsFollower: " + isFollower)
		return
	endif

	;Check to see if we're at capacity - if so, set both follower counts to 1
	;This prevents taking on any more followers of either kind until a reference is freed up
	if (GetNumFollowers() >= Followers.Length)
		DialogueFollower.pPlayerFollowerCount.SetValue(1)
		DialogueFollower.pPlayerAnimalCount.SetValue(1)
	endif

	;If we're a follower and not an animal, add to "info" faction so we know what type we are later
	;Also set our preferred follower while we're here, since we did just interact with this follower
	if (isFollower)
		FollowerActor.AddToFaction(FollowerInfoFaction)
		SetPreferredFollowerAlias(FollowerActor)
	endif
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

	FollowerAlias.GetActorRef().SetAV("WaitingForPlayer", mode)
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

	Actor FollowerActor = FollowerAlias.GetActorRef()
	if (!FollowerActor || FollowerActor.IsDead())
		;Express dismissal! Hiyaa1
		;Fairly standard FollowerAliasScript.OnDeath / TrainedAnimalScript.OnDeath... More or less
		if (FollowerActor)
			FollowerActor.RemoveFromFaction(DialogueFollower.pCurrentHireling)
		elseif (iMessage != -1)
			Debug.MessageBox("Can't dismiss None Actor! Oops\nClearing follower alias anyway...\nIsFollower: " + isFollower)
		endif
		DismissMultiFollowerClearAlias(FollowerAlias, FollowerActor, iMessage)
		return
	endif

	;Make sure we're actually a follower (might have gotten mixed up somehow - could happen if we try to trick the script by quickly talking to the wrong type)
	if (IsFollower(FollowerActor) != isFollower)
		;Debug.Trace("Follower type didn't match! - IsFollower: " + isFollower)
		isFollower = IsFollower(FollowerActor)
	endif
	FollowerActor.RemoveFromFaction(FollowerInfoFaction)

	;These things from DialogueFollowerScript.DismissFollower we would like to run on both followers and animals
	FollowerActor.StopCombatAlarm()
	FollowerActor.SetPlayerTeammate(false)
	FollowerActor.SetAV("WaitingForPlayer", 0)

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
			Utility.Wait(2)
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
	;Per Vanilla - "don't set count to 0 if Companions have replaced follower" (this actually makes sense here)
	if (iMessage != 2)
		DialogueFollower.pPlayerFollowerCount.SetValue(0)
		DialogueFollower.pPlayerAnimalCount.SetValue(0)
	endif

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

	;Finally, now that all that's done, if we're the preferred follower of our type, try to set someone else
	bool isFollower = IsFollower(FollowerActor)
	FollowerAlias = GetPreferredFollowerAlias(isFollower)
	if (FollowerAlias.GetActorRef() == FollowerActor)
		ResetPreferredFollowerAlias(isFollower)
	endif
endFunction
