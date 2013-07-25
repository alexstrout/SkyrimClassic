Scriptname foxPetScript extends ObjectReference
{Derivative of WEDogFollowerScript}

DialogueFollowerScript Property DialogueFollower Auto
GlobalVariable Property PlayerAnimalCount Auto
Message Property foxPetScriptGetNewAnimalMessage Auto
Message Property foxPetScriptHasAnimalMessage Auto
;Actor property dog auto

Function foxPetAddPet()
	(DialogueFollower as DialogueFollowerScript).SetAnimal(self)
	(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetPlayerTeammate(true, true)
	(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetNoBleedoutRecovery(false)
	foxPetScriptGetNewAnimalMessage.Show()
EndFunction

Function foxPetRemovePet()
	foxPetScriptHasAnimalMessage.Show()
	(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetPlayerTeammate(false)
	(DialogueFollower as DialogueFollowerScript).DismissAnimal()
EndFunction

event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	Actor ThisActor = (self as ObjectReference) as Actor

	if (aeCombatState == 0 && ThisActor.IsBleedingOut())
		ThisActor.Disable()
		ThisActor.Enable()
		Utility.Wait(1)
		ThisActor.Disable()
		ThisActor.Enable()
	endif
endEvent

auto state Waiting
event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	Actor ThisActor = (self as ObjectReference) as Actor
	ObjectReference DroppedItem = ThisActor.DropObject(akBaseItem, 9999)

	;Immediately drop it and release ownership (don't let your pets manage your cupboard!) ~fox
	if DroppedItem.GetActorOwner() == ThisActor.GetActorBase()
		DroppedItem.SetActorOwner(None)
	endif
endEvent

event onActivate(objectReference AkActivator)
	Actor ThisActor = (self as ObjectReference) as Actor

	;if player does not have an animal, make this animal player's animal
	if PlayerAnimalCount.GetValueInt() == 0
		foxPetAddPet()

	;Otherwise show message if player already has pet ~fox
	elseif !ThisActor.IsPlayerTeammate()
		foxPetRemovePet()
		foxPetAddPet()
	endif
endEvent
endState
