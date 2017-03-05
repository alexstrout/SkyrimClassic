;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname foxPetDialDismiss Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;Variable04 is tampered with in DismissAnimal by vanilla scripts, so store it to be fixed later
;It already be 0 if pet was hired in previous versions, so check BaseAV too if that happens
;I'm not sure what Variable04 does, but it may be important to Stray Dog, so we'll only do it for foxPet
float tempAV = akSpeaker.GetAV("Variable04")
if (tempAV == 0)
	tempAV = akSpeaker.GetBaseAV("Variable04")
endif

(pDialogueFollower as DialogueFollowerScript).DismissAnimal()
akSpeaker.SetPlayerTeammate(false)
akSpeaker.SetAV("WaitingForPlayer", 0)

;Revert Variable04 to whatever it was before SetAnimal tampered with it
akSpeaker.SetAV("Variable04", tempAV)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property pDialogueFollower  Auto  
