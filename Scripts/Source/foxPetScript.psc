Scriptname foxPetScript extends ObjectReference
{Derivative of WEDogFollowerScript}

DialogueFollowerScript Property DialogueFollower Auto
GlobalVariable Property PlayerAnimalCount Auto
Message Property foxPetScriptGetNewAnimalMessage Auto
Message Property foxPetScriptHasAnimalMessage Auto
;Actor property dog auto

Function foxPetAddPet()
	(DialogueFollower as DialogueFollowerScript).SetAnimal(self)
	;(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetPlayerTeammate(abCanDoFavor = true) ;Allow favors once they're fixed up
	foxPetScriptGetNewAnimalMessage.Show()
	;gotostate ("done") ;Allow script to repeat ~fox
EndFunction

Function foxPetRemovePet()
	foxPetScriptHasAnimalMessage.Show()
	(DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().SetPlayerTeammate(false)
	(DialogueFollower as DialogueFollowerScript).DismissAnimal()
EndFunction

auto state Waiting
event onActivate(objectReference AkActivator)
	Actor ThisActor = (self as ObjectReference) as Actor

	;if player does not have an animal, make this animal player's animal
	If PlayerAnimalCount.GetValueInt() == 0
		foxPetAddPet()

	;Otherwise show message if player already has pet ~fox
	ElseIf !ThisActor.IsPlayerTeammate()
		foxPetRemovePet()
		foxPetAddPet()

	;Finally, attempt to fix a broken bleedout ~fox
	ElseIf !(ThisActor.IsInDialogueWithPlayer() || ThisActor.IsBleedingOut())
		ThisActor.Disable()
		ThisActor.Enable()
		Utility.Wait(1)
		ThisActor.Disable()
		ThisActor.Enable()
	EndIF
endEvent
endState

state done
endstate
