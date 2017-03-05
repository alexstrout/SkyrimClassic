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
	;It already be 0 if pet was hired in previous versions, so check BaseAV too if that happens
	float tempAV = ThisActor.GetAV("Lockpicking")
	if (tempAV == 0)
		tempAV = ThisActor.GetBaseAV("Lockpicking")
	endif

	(DialogueFollower as DialogueFollowerScript).SetAnimal(self)
	ThisActor.SetPlayerTeammate(true, true)
	ThisActor.SetNoBleedoutRecovery(false)
	foxPetScriptGetNewAnimalMessage.Show()

	;Revert Lockpicking to whatever it was before SetAnimal tampered with it
	ThisActor.SetAV("Lockpicking", tempAV)
endFunction

function foxPetRemovePet()
	foxPetScriptHasAnimalMessage.Show()
	(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetPlayerTeammate(false)
	(DialogueFollower as DialogueFollowerScript).DismissAnimal()
endFunction

event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	;Hack - begin registering combat check to fix getting stuck in combat (bug in bleedouts)
	;bloat-friendly as it will never fire more than once at a time, even if OnActivate is called multiple times in this time-frame
	if (aeCombatState == 1)
		RegisterForSingleUpdate(12.0)
	endif
endEvent

event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	Actor ThisActor = (self as ObjectReference) as Actor
	ObjectReference DroppedItem = ThisActor.DropObject(akBaseItem, 9999)

	;Immediately drop it and release ownership (don't let your pets manage your cupboard!) ~fox
	if DroppedItem.GetActorOwner() == ThisActor.GetActorBase()
		DroppedItem.SetActorOwner(None)
	endif
endEvent

event OnActivate(ObjectReference akActivator)
	Actor ThisActor = (self as ObjectReference) as Actor

	;if player does not have an animal, make this animal player's animal
	if (PlayerAnimalCount.GetValueInt() == 0)
		foxPetAddPet()

	;Otherwise show message if player already has pet ~fox
	elseif (!ThisActor.IsPlayerTeammate())
		foxPetRemovePet()
		foxPetAddPet()
	endif
endEvent

event OnUpdate()
	Actor ThisActor = (self as ObjectReference) as Actor

	;If we've exited combat then actually stop combat
	if (!PlayerREF.IsInCombat())
		ThisActor.StopCombat()
	endif

	;Register for another update as long as we're in combat
	if (ThisActor.IsInCombat())
		RegisterForSingleUpdate(12.0)
	endif
endEvent
