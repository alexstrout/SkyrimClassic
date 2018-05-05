ScriptName DialogueFollowerScript extends Quest Conditional
{Rewrite of DialogueFollowerScript with cool new stuff - this could not be a new script due to use in other scripts}

;Begin Vanilla DialogueFollowerScript Members
GlobalVariable Property pPlayerFollowerCount Auto
GlobalVariable Property pPlayerAnimalCount Auto
ReferenceAlias Property pFollowerAlias Auto
ReferenceAlias property pAnimalAlias Auto
Faction Property pDismissedFollower Auto
Faction Property pCurrentHireling Auto
Message Property  FollowerDismissMessage Auto
Message Property AnimalDismissMessage Auto
Message Property  FollowerDismissMessageWedding Auto
Message Property  FollowerDismissMessageCompanions Auto
Message Property  FollowerDismissMessageCompanionsMale Auto
Message Property  FollowerDismissMessageCompanionsFemale Auto
Message Property  FollowerDismissMessageWait Auto
SetHirelingRehire Property HirelingRehireScript Auto

;Property to tell follower to say dismissal line
Int Property iFollowerDismiss Auto Conditional

; PATCH 1.9: 77615: remove unplayable hunting bow when follower is dismissed
Weapon Property FollowerHuntingBow Auto
Ammo Property FollowerIronArrow Auto
;End Vanilla DialogueFollowerScript Members

Actor Property PlayerRef Auto
Faction Property FollowerInfoFaction Auto
ReferenceAlias Property pExtraAlias1 Auto
ReferenceAlias Property pExtraAlias2 Auto
ReferenceAlias Property pExtraAlias3 Auto
ReferenceAlias Property pExtraAlias4 Auto
ReferenceAlias Property pExtraAlias5 Auto
ReferenceAlias Property pExtraAlias6 Auto
ReferenceAlias Property pExtraAlias7 Auto
ReferenceAlias Property pExtraAlias8 Auto
ReferenceAlias[] Property Followers Auto

Sound Property FollowerLearnSpellSound Auto
Sound Property FollowerForgetSpellSound Auto
Message Property FollowerLearnSpellMessage Auto
Message Property FollowerForgetSpellMessage Auto
Message Property FollowerCommandModeMessage Auto

int Property foxFollowVer Auto
int Property foxFollowScriptVer = 1 AutoReadOnly

float Property WaitAroundForPlayerGameTime = 72.0 AutoReadOnly
float Property InitialUpdateTime = 2.0 AutoReadOnly

ReferenceAlias PreferredFollowerAlias
ReferenceAlias LastFollowerActivatedAlias
int CommandMode

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
endFunction
function ModUpdate1()
	;Init our stuff, grabbing existing refs from vanilla save
	Followers = new ReferenceAlias[10]
	Followers[0] = pFollowerAlias
	Followers[1] = pAnimalAlias
	Followers[2] = pExtraAlias1
	Followers[3] = pExtraAlias2
	Followers[4] = pExtraAlias3
	Followers[5] = pExtraAlias4
	Followers[6] = pExtraAlias5
	Followers[7] = pExtraAlias6
	Followers[8] = pExtraAlias7
	Followers[9] = pExtraAlias8

	PreferredFollowerAlias = None
	LastFollowerActivatedAlias = None
	CommandMode = 0

	;Also add existing follower follower (as opposed to animal follower) to "info" faction
	;Also retroactively learn spells from any spell tomes we might have?
	Actor FollowerActor = pFollowerAlias.GetActorRef()
	if (FollowerActor)
		FollowerActor.AddToFaction(FollowerInfoFaction)
		(pFollowerAlias as foxFollowFollowerAliasScript).AddAllBookSpells()
	endif
	if (pAnimalAlias.GetActorRef())
		(pAnimalAlias as foxFollowFollowerAliasScript).AddAllBookSpells()
	endif
endFunction

;Attempt to add follower by ref - returns alias if successful
ReferenceAlias function AddFollowerAlias(ObjectReference FollowerRef)
	int i = 0
	while (i < Followers.Length)
		if (Followers[i].ForceRefIfEmpty(FollowerRef))
			return Followers[i]
		endif
		i += 1
	endwhile
	return None
endFunction

;Attempt to untangle which follower we're talking about
ReferenceAlias function GetPreferredFollowerAlias(bool isFollower)
	;Check to see if we have only one follower first - or if we're the only one of our Follower/Animal type (both are Vanilla cases we can solve)
	;This is slower to do first, but safest as we can solve this with 99% certainty ;)
	if (GetNumFollowers() == 1)
		;Debug.Trace("foxFollow got single alias")
		return GetAnyFollowerAlias()
	elseif ((isFollower && outNumFollowers == 1) || (!isFollower && outNumAnimals == 1))
		;Debug.Trace("foxFollow got single alias for follow/animal type - IsFollower: " + isFollower)
		return GetAnyFollowerAliasByType(isFollower)
	endif

	;Do we have a PreferredFollowerAlias set?
	if (PreferredFollowerAlias)
		;Debug.Trace("foxFollow got single preffered alias - IsFollower: " + isFollower)
		return PreferredFollowerAlias
	endif

	;Otherwise, do our normal MeetsPreferredFollowerAliasConditions picking (we probably won't get here)
	Actor FollowerActor = None
	int i = 0
	while (i < Followers.Length)
		FollowerActor = Followers[i].GetActorRef()
		if (FollowerActor && MeetsPreferredFollowerAliasConditions(FollowerActor))
			;Debug.Trace("foxFollow got first preferred-conditions-met alias - IsFollower: " + isFollower)
			return Followers[i]
		endif
		i += 1
	endwhile
	;Debug.Trace("foxFollow got no alias :( - IsFollower: " + isFollower)
	return None
endFunction

;Attempt to find follower by ref - shouldn't be needed often (we usually know our alias)
ReferenceAlias function GetFollowerAlias(ObjectReference FollowerRef)
	int i = 0
	while (i < Followers.Length)
		if (Followers[i].GetRef() == FollowerRef)
			return Followers[i]
		endif
		i += 1
	endwhile
	return None
endFunction

;Attempt to find follower by follower type (Follower / Animal)
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

;Attempt to just find any follower
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

;Set our preferred follower (will use for ambiguous situations where possible) - called generally from current followers' OnActivate
function SetPreferredFollowerAlias(Actor FollowerActor, int newCommandMode = 0)
	;Debug.Trace("foxFollow SetPreferredFollowerAlias - IsFollower: " + IsFollower(FollowerActor))
	PreferredFollowerAlias = GetFollowerAlias(FollowerActor)
	LastFollowerActivatedAlias = PreferredFollowerAlias

	;Also handle CommandMode here - for now, CommandMode > 0 means command all followers
	;Assign a negative value to indicate CommandMode is waiting to be consumed by a supported command
	CommandMode = -newCommandMode
endFunction

;Clear our preferred follower if it's set to FollowerActor - called from current followers' OnUpdate
function ClearPreferredFollowerAlias(Actor FollowerActor)
	if (PreferredFollowerAlias != None && PreferredFollowerAlias.GetActorRef() == FollowerActor)
		;Debug.Trace("foxFollow ClearPreferredFollowerAlias cleared! - IsFollower: " + IsFollower(FollowerActor))
		PreferredFollowerAlias = None
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
	ReferenceAlias FollowerAlias = GetFollowerAlias(FollowerRef)
	if (FollowerAlias)
		;Debug.Trace("foxFollow attempted to add follower that already existed! Oops... - IsFollower: " + isFollower)
		DismissMultiFollower(FollowerAlias, isFollower)
	endif

	;Fairly standard DialogueFollowerScript.SetFollower code
	Actor FollowerActor = FollowerRef as Actor
	if (!FollowerActor)
		return
	endif
	FollowerActor.RemoveFromFaction(pDismissedFollower)
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

	;Add back all our book-learned spells again - no real way to keep track of these when not following
	;This has the added bonus of retroactively applying to previously dismissed vanilla followers carrying spell tomes
	(FollowerAlias as foxFollowFollowerAliasScript).AddAllBookSpells()

	;Check to see if we're at capacity - if so, set both follower counts to 1
	;This prevents taking on any more followers of either kind until a reference is freed up
	if (GetNumFollowers() >= Followers.Length)
		pPlayerFollowerCount.SetValue(1)
		pPlayerAnimalCount.SetValue(1)
	endif

	;If we're a follower and not an animal, add to "info" faction so we know what type we are later
	if (isFollower)
		FollowerActor.AddToFaction(FollowerInfoFaction)
	endif

	;Finally, register us for an update so we start doing nifty catchup stuff
	FollowerAlias.RegisterForSingleUpdate(InitialUpdateTime)
endFunction
function SetFollower(ObjectReference FollowerRef)
	SetMultiFollower(FollowerRef, true)
endFunction
function SetAnimal(ObjectReference AnimalRef)
	SetMultiFollower(AnimalRef, false)
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
function FollowerWait()
	FollowerMultiFollowWait(None, true, 1)
endFunction
function AnimalWait()
	FollowerMultiFollowWait(None, false, 1)
endFunction
function FollowerFollow()
	FollowerMultiFollowWait(None, true, 0)
endFunction
function AnimalFollow()
	FollowerMultiFollowWait(None, false, 0)
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
		if (FollowerActor && isFollower)
			FollowerActor.RemoveFromFaction(pCurrentHireling)
		elseif (iMessage != -1)
			Debug.MessageBox("Can't dismiss None Actor! Oops\nClearing follower alias anyway...\nIsFollower: " + isFollower)
		endif
		DismissMultiFollowerClearAlias(FollowerAlias, FollowerActor, iMessage)
		return
	endif

	;Make sure we're actually a follower (might have gotten mixed up somehow - don't think this should ever happen, but it doesn't hurt)
	if (FollowerActor.IsInFaction(FollowerInfoFaction))
		isFollower = true
		FollowerActor.RemoveFromFaction(FollowerInfoFaction)
	endif

	;These things from DialogueFollowerScript.DismissFollower we would like to run on both followers and animals
	FollowerActor.StopCombatAlarm()
	FollowerActor.SetPlayerTeammate(false)
	FollowerActor.SetAV("WaitingForPlayer", 0)

	;Per Vanilla - "PATCH 1.9: 77615: remove unplayable hunting bow when follower is dismissed"
	;Added in additional safety checks - may not be set on old scripts
	if (FollowerHuntingBow && FollowerIronArrow)
		int itemCount = FollowerActor.GetItemCount(FollowerHuntingBow)
		if (itemCount > 0)
			FollowerActor.RemoveItem(FollowerHuntingBow, itemCount, true)
		endif
		itemCount = FollowerActor.GetItemCount(FollowerIronArrow)
		if (itemCount > 0)
			FollowerActor.RemoveItem(FollowerIronArrow, itemCount, true)
		endif
	endif

	if (isFollower)
		;Fairly standard DialogueFollowerScript.DismissFollower code
		if (iMessage == 0)
			FollowerDismissMessage.Show()
		elseif (iMessage == 1)
			FollowerDismissMessageWedding.Show()
		elseif (iMessage == 2)
			FollowerDismissMessageCompanions.Show()
		elseif (iMessage == 3)
			FollowerDismissMessageCompanionsMale.Show()
		elseif (iMessage == 4)
			FollowerDismissMessageCompanionsFemale.Show()
		elseif (iMessage == 5)
			FollowerDismissMessageWait.Show()
		elseif (iMessage != -1)
			FollowerDismissMessage.Show()
		endif
		FollowerActor.AddToFaction(pDismissedFollower)
		FollowerActor.RemoveFromFaction(pCurrentHireling)

		;Per Vanilla - "hireling rehire function"
		HirelingRehireScript.DismissHireling(FollowerActor.GetActorBase())
		if (iSayLine == 1)
			iFollowerDismiss = 1
			FollowerActor.EvaluatePackage()
			;Per Vanilla - "Wait for follower to say line"
			Utility.Wait(2)
		endif
		iFollowerDismiss = 0
	elseif (iMessage != -1)
		;Fairly standard DialogueFollowerScript.DismissAnimal code
		;Note: Variable04 would be set to 1 in AnimalTrainerSystemScript, but it looks like that was commented out, so let's not tamper with it
		;FollowerActor.SetActorValue("Variable04", 0)
		AnimalDismissMessage.Show()
	endif

	;Ready to roll!
	DismissMultiFollowerClearAlias(FollowerAlias, FollowerActor, iMessage)
endFunction
function DismissMultiFollowerClearAlias(ReferenceAlias FollowerAlias, Actor FollowerActor, int iMessage)
	;First, cancel any pending update
	FollowerAlias.UnRegisterForUpdateGameTime()
	FollowerAlias.UnRegisterForUpdate()

	;Also remove all our book-learned spells - no real way to keep track of these when not following
	(FollowerAlias as foxFollowFollowerAliasScript).RemoveAllBookSpells()

	;Clear!
	FollowerAlias.Clear()

	;Set both counts to 0 so we're ready to accept either follower type again
	;Per Vanilla - "don't set count to 0 if Companions have replaced follower" (this actually makes sense here)
	if (iMessage != 2)
		pPlayerFollowerCount.SetValue(0)
		pPlayerAnimalCount.SetValue(0)
	endif

	;Finally, there's a chance we ended up with multiple followers pointing to the same ref
	;This should never happen, but we should try to unwrangle it just in case
	;We'll only need to clear these out - we've already cleaned up the ref itself in DismissMultiFollower
	;Of course this is moot on None Actor anyways - d'oh!
	if (!FollowerActor)
		return
	endif
	FollowerAlias = GetFollowerAlias(FollowerActor)
	while (FollowerAlias)
		;Debug.Trace("foxFollow cleaning up duplicate followers... - IsFollower: " + isFollower)
		FollowerAlias.Clear()
		FollowerAlias = GetFollowerAlias(FollowerActor)
	endwhile
endFunction
function DismissFollower(int iMessage = 0, int iSayLine = 1)
	DismissMultiFollower(None, true, iMessage, iSayLine)
endFunction
function DismissAnimal()
	DismissMultiFollower(None, false)
endFunction
