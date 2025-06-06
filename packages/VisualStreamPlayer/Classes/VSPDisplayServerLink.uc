//=============================================================================
// VSPDisplayServerLink.
// Description: Communicates with a streamer through JSON strings.
//				After the initial setup it is not dependent on
//				a particular display manager.
//=============================================================================
class VSPDisplayServerLink extends UdpLink;


// Singleton.
var VSPDisplayServerLink instance;
var bool bSetup;

var VSPDisplayManager dispMan;

var IpAddr streamerIpAddr;


static function VSPDisplayServerLink getOrCreateInstance(Actor spawner) {
	if (default.instance == None)
		default.instance = spawner.spawn(default.class);
		
	return default.instance;
}


function setup() {
	// To avoid affecting the original streamerHost as a different value may
	// then be replicated to new clients.
	local String streamerHost;

	if (bSetup) return;
	
	// Resolve the host IP address.
	streamerHost = dispMan.streamerHost;
	class'VSPUtils'.static.procStreamerHost(streamerHost, level);
	stringToIpAddr(streamerHost, streamerIpAddr);
	streamerIpAddr.port = dispMan.streamerPort;
	
	// Open to connections.
	dispMan.boundPort = bindPort();
	if (dispMan.bDebug) log("Socket bound port:"@dispMan.boundPort);
	
	bSetup = true;
}


/*
	Return true if a display manager belonging to a group is in
	a list.

	@param	group		Video wall group.
	@param	list		Array of display managers (length: 255).
*/
static function bool isInWallList(String group, VSPDisplayManager list[255]) {
	local int i;
	
	for (i = 0; i < ArrayCount(list); i++)
		if (list[i] != None) {
			if (list[i].wallGroup == group)
				return true;
		} else
			// We assume the last display manager is the one before the
			// first empty slot occurrence in the array.
			break;
			
	return false;
}


/*
	Send the video walls data to the streamer.
*/
function sendInit() {
	local int wallShape[255];
	local int res[255];
	local String wallDataKeypairs[255], dataKeypairs[255];
	local String wallList[255];
	local String jsonStr;
	// dm is the current DisplayManager when iterating through all of them.
	// dms is the list of DisplayManagers we populate when iterating through
	// all of them to avoid sending a group's data more than once.
	// (Passed to isInWallList()).
	local VSPDisplayManager dm, dms[255];
	local int i;
	
	// Prepare the role and type data.
	dataKeypairs[0] = class'VSPUtils'.static.buildJsonKeypair("role", "SERVER", true);
	dataKeypairs[1] = class'VSPUtils'.static.buildJsonKeypair("type", "INIT", true);
	
	// Prepare the data for each wall group.
	// We want to send the data for each group but groups are not objects,
	// so find the first display manager occurrence for each group and get
	// its group-related data, as it is is the same for each display
	// manager in the same group.
	i = 0;
	foreach allActors(class'VSPDisplayManager', dm) {
		if (!isInWallList(dm.wallGroup, dms)) {
			// This is the first display manager occurrence for its
			// group.
		
			// Prepare the group data.
			wallDataKeypairs[0] = class'VSPUtils'.static.buildJsonKeypair("group", dm.wallGroup, true);
			
			// Prepare the wall's shape data.
			class'VSPUtils'.static.getVideoWallShape(level, wallShape[0], wallShape[1], dm.wallGroup);
			wallDataKeypairs[1] = class'VSPUtils'.static.buildJsonKeypair(
				"shape",
				class'VSPUtils'.static.buildJsonIntArray(2, wallShape),
				false
			);
			
			// Prepare the display/tile's resolution data.
			res[0] = dm.pixRows;
			res[1] = dm.pixCols;
			wallDataKeypairs[2] = class'VSPUtils'.static.buildJsonKeypair(
				"display_res",
				class'VSPUtils'.static.buildJsonIntArray(2, res),
				false
			);
			
			// Add dm to dms to avoid sending this group's data more than once.
			dms[i] = dm;
			// Add the wall group's data to the wall list to prepare the array
			// data to send later on.
			wallList[i++] = class'VSPUtils'.static.buildJsonObj(wallDataKeypairs);
		}
	}
	// Prepare the wall group list's data.
	dataKeypairs[2] = class'VSPUtils'.static.buildJsonKeypair(
		"walls",
		class'VSPUtils'.static.buildJsonObjArray(i, wallList),
		false
	);
	
	// Convert the prepared data to a JSON string and send it.
	jsonStr = class'VSPUtils'.static.buildJsonObj(dataKeypairs);
	sendText(streamerIpAddr, jsonStr);
	if (dispMan.bDebug) log("Socket sent data:"@jsonStr);
	
	// NOTE: Apparently GetLastError() is less informative on 469.
	if (dispMan.bDebug)	log("Socket last error:"@GetLastError());
}


/*
	Send a command to the streamer.
*/
function sendCmd(String cmd, optional String args) {
	local String dataKeypairs[255];
	local String jsonStr;
	
	// Prepare the role and type data.
	dataKeypairs[0] = class'VSPUtils'.static.buildJsonKeypair("role", "SERVER", true);
	dataKeypairs[1] = class'VSPUtils'.static.buildJsonKeypair("type", "CMD", true);
	
	// Prepare the cmd and args data.
	dataKeypairs[2] = class'VSPUtils'.static.buildJsonKeypair("cmd", cmd, true);
	dataKeypairs[3] = class'VSPUtils'.static.buildJsonKeypair("args", args, true);
	
	// Convert the prepared data to JSON and send it.
	jsonStr = class'VSPUtils'.static.buildJsonObj(dataKeypairs);
	sendText(streamerIpAddr, jsonStr);
}