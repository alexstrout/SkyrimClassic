Scriptname foxFollowFollowerAliasScript extends ReferenceAlias
{Rewrite of FollowerAliasScript with rad new stuff - see DialogueFollowerScript too, which had to stay the same name}

;Begin Vanilla FollowerAliasScript Members
DialogueFollowerScript Property DialogueFollower Auto
;GlobalVariable Property PlayerFollowerCount  Auto
;Faction Property CurrentHirelingFaction Auto
;End Vanilla FollowerAliasScript Members

Actor Property PlayerRef Auto
FormList Property LearnedSpellBookList Auto

float Property CombatWaitUpdateTime = 12.0 AutoReadOnly
float Property FollowUpdateTime = 4.5 AutoReadOnly
float Property DialogWaitTime = 6.0 AutoReadOnly

event OnUpdateGameTime()
	Actor ThisActor = Self.GetActorRef()

	;Per Vanilla - "kill the update if the follower isn't waiting anymore"
	;Not needed as we use RegisterForSingleUpdateGameTime instead
	;UnRegisterForUpdateGameTime()
	if (ThisActor.GetAV("WaitingforPlayer") == 1)
		DialogueFollower.DismissMultiFollower(Self, DialogueFollower.IsFollower(ThisActor), 5)
	endif
endEvent

event OnUnload()
	Actor ThisActor = Self.GetActorRef()

	;Per Vanilla - "if follower unloads while waiting for the player, wait three days then dismiss him"
	if (ThisActor.GetAV("WaitingforPlayer") == 1)
		DialogueFollower.FollowerMultiFollowWait(Self, DialogueFollower.IsFollower(ThisActor), 1)
	endif
endEvent

event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	if (akTarget == PlayerRef)
		DialogueFollower.DismissMultiFollower(Self, DialogueFollower.IsFollower(Self.GetActorRef()), 0, 0)
	endif

	;HACK Begin registering combat check to fix getting stuck in combat (bug in bleedouts for animals)
	;This should be bloat-friendly as it will never fire more than once at a time, even if OnActivate is called multiple times in this time frame
	if (aeCombatState == 1)
		SetSpeedup(false)
		RegisterForSingleUpdate(CombatWaitUpdateTime)
	endif
endEvent

event OnDeath(Actor akKiller)
	DialogueFollower.DismissMultiFollower(Self, DialogueFollower.IsFollower(Self.GetActorRef()))
	;DialogueFollower.pPlayerFollowerCount.SetValue(0)
	;DialogueFollower.pPlayerAnimalCount.SetValue(0)
	;Self.GetActorRef().RemoveFromFaction(DialogueFollower.pCurrentHireling)
	;Self.Clear()
endEvent

event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	Book SomeBook = akBaseItem as Book
	if (SomeBook)
		AddBookSpell(SomeBook)
	endif
endEvent
function AddBookSpell(Book SomeBook, bool ShowMessage = true)
	Spell BookSpell = SomeBook.GetSpell()
	if (BookSpell)
		Actor ThisActor = Self.GetActorRef()
		if (!ThisActor.HasSpell(BookSpell))
			LearnedSpellBookList.AddForm(SomeBook)
			ThisActor.AddSpell(BookSpell)
			;Debug.Trace(ThisActor + " learning " + BookSpell + BookSpell.GetName())
			if (ShowMessage)
				;Debug.MessageBox("Follower learning " + BookSpell.GetName()) ;Temp until make message durr
				DialogueFollower.FollowerLearnSpellMessage.Show()
				DialogueFollower.FollowerLearnSpellSound.Play(ThisActor)
			endif
		;else
		;	Debug.MessageBox("Follower already knows " + BookSpell.GetName() + "!")
		endif
	endif
endFunction

event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	Book SomeBook = akBaseItem as Book
	if (SomeBook)
		RemoveBookSpell(SomeBook, RemoveCondition = LearnedSpellBookList.HasForm(SomeBook) && Self.GetActorRef().GetItemCount(akBaseItem) == 0)
	endif
endEvent
function RemoveBookSpell(Book SomeBook, bool ShowMessage = true, bool RemoveCondition = true)
	Spell BookSpell = SomeBook.GetSpell()
	if (BookSpell)
		Actor ThisActor = Self.GetActorRef()
		if (RemoveCondition && ThisActor.HasSpell(BookSpell))
			LearnedSpellBookList.RemoveAddedForm(SomeBook)
			ThisActor.RemoveSpell(BookSpell)
			;Debug.Trace(ThisActor + " forgetting " + BookSpell + BookSpell.GetName())
			if (ShowMessage)
				;Debug.MessageBox("Follower forgetting " + BookSpell.GetName()) ;Temp until make message durr
				DialogueFollower.FollowerForgetSpellMessage.Show()
				DialogueFollower.FollowerForgetSpellSound.Play(ThisActor)
			endif
		endif
	endif
endFunction

function AddAllBookSpells()
	;RemoveAllBookSpells first just in case we got out of sync somehow (should never happen! But doesn't hurt)
	;This isn't run often, so we can afford to be extra-cautious here
	RemoveAllBookSpells()

	Actor ThisActor = Self.GetActorRef()
	int i = ThisActor.GetNumItems()
	Book SomeBook = None
	while i
		i -= 1
		SomeBook = ThisActor.GetNthForm(i) as Book
		if (SomeBook)
			AddBookSpell(SomeBook, false)
		endif
	endWhile
endFunction

function RemoveAllBookSpells()
	int i = LearnedSpellBookList.GetSize()
	Book SomeBook = None
	while i
		i -= 1
		SomeBook = LearnedSpellBookList.GetAt(i) as Book
		if (SomeBook)
			RemoveBookSpell(SomeBook, false)
		endif
	endWhile

	;Fully revert just in case we missed any (we shouldn't!)
	LearnedSpellBookList.Revert()
endFunction

;Track last follower activated so we have something to fall back on later
event OnActivate(ObjectReference akActivator)
	;Debug.Trace("foxFollowActor - activated! :|")
	if (akActivator == PlayerRef)
		;Debug.Trace("foxFollowActor - activated by Player! :D")
		DialogueFollower.CheckForModUpdate()
		Actor ThisActor = Self.GetActorRef()
		DialogueFollower.SetPreferredFollowerAlias(ThisActor)
		while (DialogueFollower.MeetsPreferredFollowerAliasConditions(ThisActor))
			Utility.Wait(DialogWaitTime)
		endwhile
		Utility.Wait(DialogWaitTime)
		DialogueFollower.ClearPreferredFollowerAlias(ThisActor)
		;Debug.Trace("foxFollowActor - finished being activated by Player :(")
	endif
endEvent

event OnUpdate()
	Actor ThisActor = Self.GetActorRef()
	if (!ThisActor)
		RegisterForSingleUpdate(CombatWaitUpdateTime)
		return
	endif

	;Register for longer-interval update as long as we're in combat
	;Otherwise use a shorter-interval update to handle catchup
	if (ThisActor.IsInCombat())
		;If we've exited combat then actually stop combat - this fixes perma-bleedout issues
		if (!PlayerRef.IsInCombat())
			ThisActor.StopCombat()
		endif
	elseif (ThisActor.GetAV("WaitingForPlayer") == 0)
	   	float maxDist = 2048.0
	   	if (ThisActor.IsInInterior())
	   		maxDist * 0.75
	   	endif
		float dist = ThisActor.GetDistance(PlayerRef)
		if (dist > maxDist && !PlayerRef.IsOnMount())
			float AngleZ = PlayerRef.GetAngleZ()
			ThisActor.MoveTo(PlayerRef, -128.0 * Math.Sin(AngleZ), -128.0 * Math.Cos(AngleZ), 64.0, true)
			;Debug.Trace("foxFollowActor - initiating hyperjump!")
		else
			SetSpeedup(dist > maxDist * 0.5)
		endif

		RegisterForSingleUpdate(FollowUpdateTime)
		return
	endif

	RegisterForSingleUpdate(CombatWaitUpdateTime)
endEvent

function SetSpeedup(bool punchIt)
	Actor ThisActor = Self.GetActorRef()
	float SpeedMult = ThisActor.GetAV("SpeedMult")
	if (punchIt)
		;This will compound over time until we actually catch up - 2x, 3x, 4x... 88x. lols
		if (SpeedMult > 8800)
			return
		endif
		ThisActor.ModAV("SpeedMult", 100)
		ThisActor.ModAV("CarryWeight", 1) ;CarryWeight must be adjusted for SpeedMult to apply
		;Debug.Trace("foxFollowActor - initiating warp speed... Mach " + ThisActor.GetAV("SpeedMult"))
	elseif (SpeedMult > 100)
		;Using ModAV and ForceAV doesn't change BaseAV, so we can safely look those up to reset to previous values - appears to work across saves
		ThisActor.ForceAV("SpeedMult", ThisActor.GetBaseAV("SpeedMult"))
		ThisActor.ForceAV("CarryWeight", ThisActor.GetBaseAV("CarryWeight"))
		;Debug.Trace("foxFollowActor - dropping to impulse power")
	endif
endFunction
