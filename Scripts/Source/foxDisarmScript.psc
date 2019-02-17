Scriptname foxDisarmScript extends ActiveMagicEffect
{Cool script that replaces disarms with just unequipping stuff yo}

event OnEffectStart(Actor akTarget, Actor akCaster)
	if (!akTarget)
		;Debug.MessageBox("No target!\n" + akTarget)
		return
	endif

	Form SomeObject = akTarget.GetEquippedObject(1)
	if (SomeObject)
		akTarget.UnequipItem(SomeObject)
	endif

	SomeObject = akTarget.GetEquippedObject(0)
	if (SomeObject)
		akTarget.UnequipItem(SomeObject)
	endif
endEvent
