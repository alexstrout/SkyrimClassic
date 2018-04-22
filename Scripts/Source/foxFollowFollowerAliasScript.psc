Scriptname foxFollowFollowerAliasScript extends ReferenceAlias
{Rewrite of FollowerAliasScript with rad new stuff - see DialogueFollowerScript too, which had to stay the same name}

;Begin Vanilla FollowerAliasScript Members
DialogueFollowerScript Property DialogueFollower Auto
;GlobalVariable Property PlayerFollowerCount  Auto
;Faction Property CurrentHirelingFaction Auto
;End Vanilla FollowerAliasScript Members

Actor Property PlayerRef Auto

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
		Spell BookSpell = SomeBook.GetSpell()
		if (BookSpell)
			Actor ThisActor = Self.GetActorRef()
			if (!ThisActor.HasSpell(BookSpell))
				ThisActor.AddSpell(BookSpell)
				Debug.Trace(ThisActor + " learning " + BookSpell)
			else
				ThisActor.RemoveItem(akBaseItem, 8888, true, PlayerRef)
				Debug.MessageBox("Follower already knows this spell!") ;Temp until make message durr
			endif
		endif
	endif
endEvent

event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	;Check to see if we're removing a "duplicate" spell - in which case, don't unlearn the spell! D'oh
	;I suppose someone COULD remove 8888 spell tomes - but that would probably be too heavy for the follower to carry in the first place :)
	;And if they really were carrying that many spell tomes they deserve to permanently keep the spell
	if (aiItemCount == 8888)
		return
	endif
	Book SomeBook = akBaseItem as Book
	if (SomeBook)
		Spell BookSpell = SomeBook.GetSpell()
		Actor ThisActor = Self.GetActorRef()
		if (BookSpell && ThisActor.HasSpell(BookSpell))
			ThisActor.RemoveSpell(BookSpell)
			Debug.Trace(ThisActor + " forgetting " + BookSpell)
		endif
	endif
endEvent

;Track last follower activated so we have something to fall back on later
event OnActivate(ObjectReference akActivator)
	Debug.Trace("foxFollowActor - activated! :|")
	if (akActivator == PlayerRef)
		Debug.Trace("foxFollowActor - activated by Player! :D")
		DialogueFollower.CheckUpdate()
		Actor ThisActor = Self.GetActorRef()
		DialogueFollower.SetPreferredFollowerAlias(ThisActor)
		while (DialogueFollower.MeetsPreferredFollowerAliasConditions(ThisActor))
			Utility.Wait(DialogWaitTime)
		endwhile
		Utility.Wait(DialogWaitTime)
		DialogueFollower.ClearPreferredFollowerAlias(ThisActor)
		Debug.Trace("foxFollowActor - finished being activated by Player :(")
	endif
endEvent

event OnUpdate()
	Actor ThisActor = Self.GetActorRef()
	if (!ThisActor)
		RegisterForSingleUpdate(CombatWaitUpdateTime)
		return
	endif

	;Register for another update as long as we're in combat
	;Otherwise do nifty catchup stuff
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
			Debug.Trace("foxFollowActor - initiating hyperjump!")
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
		Debug.Trace("foxFollowActor - initiating warp speed... Mach " + ThisActor.GetAV("SpeedMult"))
	elseif (SpeedMult > 100)
		;Using ModAV and ForceAV doesn't change BaseAV, so we can safely look those up to reset to previous values - appears to work across saves
		ThisActor.ForceAV("SpeedMult", ThisActor.GetBaseAV("SpeedMult"))
		ThisActor.ForceAV("CarryWeight", ThisActor.GetBaseAV("CarryWeight"))
		Debug.Trace("foxFollowActor - dropping to impulse power")
	endif
endFunction
