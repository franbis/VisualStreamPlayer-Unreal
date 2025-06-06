//=============================================================================
// VSPDisplay469e.
// Description: A version of VSPDisplay which uses a workaround to replace
//              the bg tex without the constant flickering on 469e.
//=============================================================================
class VSPDisplay469e extends VSPDisplay;


function setup() {
    super.setup();

    // Force scrTex to turn into bgTex once and make the latter send
    // renderTexture() events, so we don't have to call replaceTexture()
    // at all. This means bgTex must be a ScriptedTexture.
	if ((dispMan.scrTex != None) && (dispMan.bgTex != None)) {
        dispMan.scrTex.notifyActor = None;
        ScriptedTexture(dispMan.bgTex).notifyActor = self;
		dispMan.bgTex.palette = dispMan.palTex.palette;

        dispMan.scrTex.animNext = dispMan.bgTex;
        dispMan.bgTex.animNext = dispMan.bgTex;
    }
}


function drawBackground(ScriptedTexture tex) {}