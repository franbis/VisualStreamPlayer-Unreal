//=============================================================================
// VSPMutExample.
// Description: A mutator to let players send commands to a streamer.
//				If the command is "stream" the font texture path is
//				autofilled.
//				NOTE: The player must escape any quotation mark.
//=============================================================================
class VSPMutExample extends Mutator;


var class<VSPDisplayServerLink> serverLinkClass;


function mutate(string mutateString, PlayerPawn sender) {
	local VSPDisplayServerLink serverLink;
	local int firstSpaceIdx;
	local String cmd, args;
	local String palFontPath;

	super.mutate(mutateString, sender);
	
	palFontPath = "../examples/media/indexed_color/palette_tex_color_1.bmp";

	//if (sender.bAdmin && sender.playerReplicationInfo.bAdmin)
	
	serverLink = serverLinkClass.static.getOrCreateInstance(self);
	
	firstSpaceIdx = inStr(mutateString, " ");
	if (firstSpaceIdx == -1) firstSpaceIdx = len(mutateString);
	cmd = left(mutateString, firstSpaceIdx);

	if (cmd == "stream")
		args = palFontPath$" ";

	args $= mid(mutateString, firstSpaceIdx + 1, len(mutateString));
	serverLink.sendCmd(cmd, args);
}


defaultproperties {
	serverLinkClass=class'VSPDisplayServerLink'
}