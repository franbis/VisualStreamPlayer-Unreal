//=============================================================================
// VSPDisplayClientLink.
// Description: Communicates with a streamer through JSON strings and
//				handle received frames.
//=============================================================================
class VSPDisplayClientLink extends UdpLink;


var bool bSetup;

var VSPDisplayManager dispMan;

var IpAddr streamerIpAddr;


function setup() {
	// Till here, streamerHost has retained the original value as we
	// made sure not to change it in the server.
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
	Send the display's initial data to the streamer.
*/
function sendInit() {
	local int pos[255];
	local String dataKeypairs[255];
	local String jsonStr;
	
	// Prepare the role, type and wall group data.
	dataKeypairs[0] = class'VSPUtils'.static.buildJsonKeypair("role", "CLIENT", true);
	dataKeypairs[1] = class'VSPUtils'.static.buildJsonKeypair("type", "INIT", true);
	
	dataKeypairs[2] = class'VSPUtils'.static.buildJsonKeypair("group", dispMan.wallGroup, true);
	
	// Prepare the data for the position of the display in the wall group [Row, Column].
	pos[0] = dispMan.posRow;
	pos[1] = dispMan.posCol;
	dataKeypairs[3] = class'VSPUtils'.static.buildJsonKeypair(
		"position",
		class'VSPUtils'.static.buildJsonIntArray(2, pos),
		false
	);
	
	// Convert the prepared data to a JSON string and send it.
	jsonStr = class'VSPUtils'.static.buildJsonObj(dataKeypairs);
	sendText(streamerIpAddr, jsonStr);
	if (dispMan.bDebug) log("Socket sent data:"@jsonStr);
	
	if (dispMan.bDebug)	log("Socket last error:"@GetLastError());
	
	// Start heartbeat.
	setTimer(5, true);
}


/*
	Inform the streamer the display is still active.
*/
function sendHeartbeat() {
	local String dataKeypairs[255];
	local String jsonStr;
	
	// Prepare the role and type data.
	dataKeypairs[0] = class'VSPUtils'.static.buildJsonKeypair("role", "CLIENT", true);
	dataKeypairs[1] = class'VSPUtils'.static.buildJsonKeypair("type", "HEARTBEAT", true);
	
	// Convert the prepared data to JSON and send it.
	jsonStr = class'VSPUtils'.static.buildJsonObj(dataKeypairs);
	sendText(streamerIpAddr, jsonStr);
}


event timer() {
	super.timer();
	sendHeartbeat();
}


event receivedText(IpAddr addr, String text) {
	super.receivedText(addr, text);
	
	if (addr == streamerIpAddr)
		// We received a frame from the streamer, pass it to the
		// display.
		dispMan.setFrame(text);
}