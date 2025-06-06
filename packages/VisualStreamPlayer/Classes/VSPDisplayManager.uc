//=============================================================================
// VSPDisplayManager.
// Description: Manages the display components.
//=============================================================================
class VSPDisplayManager extends Info
	config(VisualStreamPlayer);


//const MAX_FRAME_BYTES_PER_SOCK = 4095;

var() bool bDebug;

var config String streamerHost;
var config int streamerPort;
var int boundPort;

// Video wall (display grid) vars.
// String instead of name so we can send an empty string with the socket.
var() String wallGroup;
// Display position on video wall.
var() byte posRow;
var() byte posCol;

// The ScriptedTexture the display will draw on.
var() ScriptedTexture scrTex;

// A background texture that replaces scrTex's texture. (Optional)
// It should use the same palette of palTex to prevent miscolorization.
var() Texture bgTex;

// Display's resolution.
// UT Version | Max UDP receieving bytes | Maximum display resolution:
// 451			1023						31x31
// 469			4095						63x63
// NOTE: Even if we were able to receive one more byte, there is,
//			apparently, a bug that makes ScriptedTexture.drawText()
//			fail to draw on the texture's bottom and right borders.
var() byte pixRows;
var() byte pixCols;

// The colors of the characters in the font must be in the same order of
// the colors in the original texture's palette.
// We can't access a font's original texture but we still want to access
// its palette, hence why we need palTex.
var() Font palFont;
var() Texture palTex;

// The last received frame.
// Configurable to allow a placeholder frame.
var() String frameLines[255];

// Configurable classes.
var() class<VSPDisplayServerLink> serverLinkClass;
var() class<VSPDisplayClientLink> clientLinkClass;
var() class<VSPDisplay> displayClass;
var() class<VSPResChangeManager> resChangeManClass;

var VSPDisplayClientLink clientLink;
var VSPDisplay display;


replication {
	reliable if ((role == ROLE_Authority) && bNetInitial)
		bDebug,
		streamerHost, streamerPort,
		clientLinkClass, displayClass, resChangeManClass,
		wallGroup, posRow, posCol,
		scrTex, bgTex, pixRows, pixCols, palFont, palTex,
		// bNetInitial to allow a placeholder frame sent by the server.
		// It then gets handled entirely by the client.
		frameLines;
}


simulated function setup() {
	local VSPDisplayServerLink serverLink;
	
	if (role == ROLE_Authority) {
		// Spawn the server link on the server.
		serverLink = serverLinkClass.static.getOrCreateInstance(self);
		// There should be only 1 server link, don't spawn another if one was
		// already setup.
		if (!serverLink.bSetup) {
			serverLink.dispMan = self;
			serverLink.setup();
			serverLink.sendInit();
		}
	}
		
	if ((level.netMode == NM_Standalone) || (role != ROLE_Authority)) {
		// Spawn the display and client link on the client.
		display = spawn(displayClass);
		display.dispMan = self;
		display.setup();
		
		clientLink = spawn(clientLinkClass);
		clientLink.dispMan = self;
		clientLink.setup();
		// Inform the streamer of this display.
		clientLink.sendInit();
		
		// Spawn a res-change detector.
		resChangeManClass.static.getOrCreateInstance(self);
	}
}


event preBeginPlay() {
	super.preBeginPlay();
	// Setup on server.
	setup();
}


simulated event postNetBeginPlay() {
	super.postNetBeginPlay();
	// Setup on client in MP.
	setup();
}


simulated function setFrame(String frame) {
	local int i;
	
	// Chop the frame string and populate the frame lines.
	for (i = 0; i < pixRows; i++) {
		frameLines[i] = left(frame, pixCols);
		// Discard the processed row.
		frame = mid(frame, pixCols);
	}
}


defaultproperties {
	remoteRole=ROLE_DumbProxy
	bAlwaysRelevant=True
	bDebug=False
	pixRows=63
	pixCols=63
	streamerPort=6789
	serverLinkClass=class'VSPDisplayServerLink'
	clientLinkClass=class'VSPDisplayClientLink'
	displayClass=class'VSPDisplay'
	resChangeManClass=class'VSPResChangeManager'
}