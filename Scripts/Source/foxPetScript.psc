Scriptname foxPetScript extends ObjectReference
{Derivative of WEDogFollowerScript}

DialogueFollowerScript Property DialogueFollower Auto
GlobalVariable Property PlayerAnimalCount Auto
Message Property foxPetScriptGetNewAnimalMessage Auto
Message Property foxPetScriptHasAnimalMessage Auto
Actor Property PlayerRef Auto

function foxPetAddPet()
	Actor ThisActor = (self as ObjectReference) as Actor

	;Lockpicking is tampered with in SetAnimal by vanilla scripts, so store it to be fixed later
	;It could already be 0 if pet was hired in previous versions, so check BaseAV too if that happens
	float tempAV = ThisActor.GetAV("Lockpicking")
	if (tempAV == 0)
		tempAV = ThisActor.GetBaseAV("Lockpicking")
	endif

	DialogueFollower.SetAnimal(self)
	ThisActor.SetPlayerTeammate(true, true)
	ThisActor.SetNoBleedoutRecovery(false)
	foxPetScriptGetNewAnimalMessage.Show()

	;Revert Lockpicking to whatever it was before SetAnimal tampered with it
	ThisActor.SetAV("Lockpicking", tempAV)
endFunction

function foxPetRemovePet()
	foxPetScriptHasAnimalMessage.Show()
	DialogueFollower.pAnimalAlias.GetActorRef().SetPlayerTeammate(false)
	DialogueFollower.DismissAnimal()
endFunction

event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	;HACK Begin registering combat check to fix getting stuck in combat (bug in bleedouts)
	;This should be bloat-friendly as it will never fire more than once at a time, even if OnActivate is called multiple times in this time frame
	if (aeCombatState == 1)
		RegisterForSingleUpdate(12.0)
	endif
endEvent

event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	Actor ThisActor = (self as ObjectReference) as Actor
	ObjectReference DroppedItem = ThisActor.DropObject(akBaseItem, 9999)

	;Immediately drop it and release ownership (don't let your pets manage your cupboard!)
	if DroppedItem.GetActorOwner() == ThisActor.GetActorBase()
		DroppedItem.SetActorOwner(None)
	endif
endEvent

event OnActivate(ObjectReference akActivator)
	Actor ThisActor = (self as ObjectReference) as Actor

	;Normally, we don't show a trade dialogue, so make sure we grab any stray arrows etc. that may be in pet's inventory
	;This should be unnecessary as we immediately drop any added item - but we'll still do this just in case it's a really old save etc.
	ThisActor.RemoveAllItems(Game.GetPlayer(), false, true)

	;Add ourself as a pet - unless there is an old pet, in which case we will just kick it and add ourself anyway
	if (PlayerAnimalCount.GetValueInt() == 0)
		foxPetAddPet()
	elseif (!ThisActor.IsPlayerTeammate())
		foxPetRemovePet()
		foxPetAddPet()
	endif
endEvent

event OnUpdate()
	Actor ThisActor = (self as ObjectReference) as Actor

	;If we've exited combat then actually stop combat - this fixes perma-bleedout issues
	if (!PlayerRef.IsInCombat())
		ThisActor.StopCombat()
	endif

	;Register for another update as long as we're in combat
	if (ThisActor.IsInCombat())
		RegisterForSingleUpdate(12.0)
	endif
endEvent
