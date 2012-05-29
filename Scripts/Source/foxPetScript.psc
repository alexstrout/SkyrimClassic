Scriptname foxPetScript extends ObjectReference
{Derivative of WEDogFollowerScript}

DialogueFollowerScript Property DialogueFollower Auto
GlobalVariable Property PlayerAnimalCount Auto
Message Property foxPetScriptGetNewAnimalMessage Auto
Message Property foxPetScriptHasAnimalMessage Auto
;Actor property dog auto

auto state Waiting
event onActivate(objectReference AkActivator)
	;if player does not have an animal, make this animal player's animal
	If PlayerAnimalCount.GetValueInt() == 0
		(DialogueFollower as DialogueFollowerScript).SetAnimal(self)
		foxPetScriptGetNewAnimalMessage.Show()
		;gotostate ("done") ;Allow script to repeat ~fox

	;Otherwise show message if player already has pet ~fox
	ElseIf !((DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().IsInDialogueWithPlayer() || (DialogueFollower as DialogueFollowerScript).pAnimalAlias.GetActorRef().IsBleedingOut()) ;I have no idea what I'm doing ~fox
		foxPetScriptHasAnimalMessage.Show()
		(DialogueFollower as DialogueFollowerScript).DismissAnimal()

		(DialogueFollower as DialogueFollowerScript).SetAnimal(self)
		foxPetScriptGetNewAnimalMessage.Show()
		;gotostate ("done") ;Allow script to repeat ~fox
	EndIF
endEvent
endState

state done
endstate
