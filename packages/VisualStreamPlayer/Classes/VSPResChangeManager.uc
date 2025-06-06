//=============================================================================
// VSPResChangeManager.
// Description: A HUD mutator to detect a change in the window resolution
//				and notify all the displays in the level.
//=============================================================================
class VSPResChangeManager extends Mutator;


// Singleton.
var VSPResChangeManager instance;

// Last resolution.
var float lastClipX, lastClipY;


static function VSPResChangeManager getOrCreateInstance(Actor spawner) {
	if (default.instance == None)
		default.instance = spawner.spawn(default.class);
		
	return default.instance;
}


event tick(float delta) {
	super.tick(delta);
	
	if (!bHUDMutator)
		registerHUDMutator();
}


event postRender(Canvas canvas) {
	local VSPDisplay disp;

	// Detect a change in the resolution and notify all the displays
	// in the level.
	if ((canvas.clipX != lastClipX) || (canvas.clipY != lastClipY))
		foreach allActors(class'VSPDisplay', disp)
			disp.bShouldRefresh = true;
	
	// Remember the new resolution.
	lastClipX = canvas.clipX;
	lastClipY = canvas.clipY;
	
	if (nextHUDMutator != None)
		nextHUDMutator.postRender(canvas);
}