//=============================================================================
// VSPDisplay.
// Description: Draws frames on a ScriptedTexture. Uses a font where
//				each glyph is a pixel with a unique color, the streamer
//				must be aware of the order of the glyphs and stream each
//				pixel as a glyph.
//				To make the streamer aware of the order of the glyphs,
//				they should have the same order of colors in its
//				original texture's palette.
//=============================================================================
class VSPDisplay extends Info;


var VSPDisplayManager dispMan;

var bool bShouldRefresh;


function setup() {
	if (dispMan.scrTex != None) {
		dispMan.scrTex.notifyActor = self;
			
		// Set the ScriptedTexture palette to the font palette to
		// prevent the miscolorization of the text we're going to draw.
		dispMan.scrTex.palette = dispMan.palTex.palette;
	}
}


function drawBackground(ScriptedTexture tex) {
	tex.replaceTexture(dispMan.bgTex);
}


function drawFrame(ScriptedTexture tex) {
	local int i;

	// Draw each frame line.
	for (i = 0; i < dispMan.pixRows; i++)
		// We assume each font's glyph is a single pixel.
		tex.drawText(0, i, dispMan.frameLines[i], dispMan.palFont);
}


event renderTexture(ScriptedTexture tex) {
	super.renderTexture(tex);
	
	if (bShouldRefresh) {
		// The texture needs to be updated (e.g. when there's a change
		// in res). To let it update we just need to skip painting for
		// one frame.
		bShouldRefresh = false;
		return;
	}
	
	// NOTE: Calling replaceTexture() and drawText() in the same
	//			renderTexture() call causes an issue with the rendering
	//			on 469e.
	if (dispMan.bgTex != None)
		// This is a draw operation, therefore it has to be done for each render.
		drawBackground(tex);
	drawFrame(tex);
}


event destroyed() {
	super.destroyed();

	if ((level.netMode == NM_Standalone) || (role != ROLE_Authority))
		if (dispMan.scrTex != None)
			dispMan.scrTex.notifyActor = None;
}


defaultproperties
{
	bStatic=False
	bNoDelete=False
}