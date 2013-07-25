Scriptname foxPetScript extends ObjectReference
{Derivative of WEDogFollowerScript}

DialogueFollowerScript Property DialogueFollower Auto
GlobalVariable Property PlayerAnimalCount Auto
Message Property foxPetScriptGetNewAnimalMessage Auto
Message Property foxPetScriptHasAnimalMessage Auto
;Actor property dog auto

Function foxPetAddPet()
	Actor ThisActor = (self as ObjectReference) as Actor

	ThisActor.SetPlayerTeammate(true, true)
	ThisActor.SetNoBleedoutRecovery(false)
	(DialogueFollower as DialogueFollowerScript).SetAnimal(self)
	foxPetScriptGetNewAnimalMessage.Show()
EndFunction

Function foxPetRemovePet()
	foxPetScriptHasAnimalMessage.Show()
	(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetPlayerTeammate(false)
	(DialogueFollower as DialogueFollowerScript).DismissAnimal()
EndFunction

auto state Waiting
event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	Actor ThisActor = (self as ObjectReference) as Actor
	ObjectReference DroppedItem = ThisActor.DropObject(akBaseItem, 9999)

	;Immediately drop it and release ownership (don't let your pets manage your cupboard!) ~fox
	If DroppedItem.GetActorOwner() == ThisActor.GetActorBase()
		DroppedItem.SetActorOwner(None)
	EndIf
endEvent

event onActivate(objectReference AkActivator)
	Actor ThisActor = (self as ObjectReference) as Actor

	;if player does not have an animal, make this animal player's animal
	If PlayerAnimalCount.GetValueInt() == 0
		foxPetAddPet()

	;Otherwise show message if player already has pet ~fox
	ElseIf !ThisActor.IsPlayerTeammate()
		foxPetRemovePet()
		foxPetAddPet()
	EndIF
endEvent
endState
