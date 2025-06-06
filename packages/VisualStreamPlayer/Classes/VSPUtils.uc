//=============================================================================
// VSPUtils.
// Description: Useful static functions.
//=============================================================================
class VSPUtils extends Info;


// JSON functions.

/*
	Return a JSON string representing an int array.
	Example: [1,2,...]

	@param	length		The array length.
	@param	arr			The int array (length: 255).
*/
static function String buildJsonIntArray(int length, int arr[255]) {
	local String content;
	local int i;
	
	for (i = 0; i < length; i++) {
		if (i > 0)
			content = content$",";
		content = content$arr[i];
	}
	
	return "[" $ content $ "]";
}


/*
	Return a JSON string representing an object array where objects
	are JSON strings.
	Example: [{...},{...},...]

	@param	length		The array length.
	@param	jsonObjs	The object array (length: 255).
*/
static function String buildJsonObjArray(int length, String jsonObjs[255]) {
	local String content;
	local int i;
	
	for (i = 0; i < length; i++) {
		if (i > 0)
			content = content$",";
		content = content$jsonObjs[i];
	}
	
	return "[" $ content $ "]";
}


/*
	Return a json object keypair string.
	Example 1: "key":"stringValue"
	Example 2: "key":nonStringValue

	@param	k			Key.
	@param	v			Value.
	@param	bStrVal		True if @v is a string.
*/
static function String buildJsonKeypair(coerce String k, coerce String v, bool bStrVal) {
	local String dQuot;
	
	dQuot = chr(34);
	if (bStrVal)
		v = dQuot$ v $dQuot;
	
	return dQuot$ k $dQuot$ ":" $ v;
}


/*
	Return a JSON string for an array of JSON keypair strings.
	Example: {"key":value,"key":value,...}

	@param	keypairs		JSON keypair string array (length: 255).
*/
static function String buildJsonObj(String keypairs[255]) {
	local String content;
	local int i;
	
	for (i = 0; i < arrayCount(keypairs); i++)
		if (keypairs[i] == "")
			// We assume the last keypair is the one before the
			// first empty string occurrence in the array.
			break;
		else {
			if (i > 0)
				content = content$",";
			content = content$keypairs[i];
		}
		
	return "{"$ content $"}";
}


// Media functions.

/*
	Get the video wall (display grid) rows and columns counts.

	@param	searcher		Actor which foreach will be called from.
	@param	rows			Rows count (out parameter).
	@param	columns			Columns count (out parameter).
	@param	group			If not an empty string, only the video wall
							belonging to this group will be considered.
*/
static function getVideoWallShape(Actor searcher, out int rows, out int columns, optional String group) {
	local VSPDisplayManager dispMan;
	
	// If non-zero values were provided reinitialize them.
	rows = 0;
	columns = 0;
	
	// Get the highest values for the row and column positions among
	// the displays belonging to the specified group.
	foreach searcher.allActors(class'VSPDisplayManager', dispMan) {
		if (dispMan.wallGroup == group) {
			rows = max(rows, dispMan.posRow);
			columns = max(columns, dispMan.posCol);
		}
	}
	
	// As we calculated them by checking the positions and they start
	// with 0,0 we add 1 for the count.
	rows += 1;
	columns += 1;
}


/*
	Get the streamer's IP address.

	@param	streamerHost		Streamer host. If provided it stays
								as is, otherwise the server's IP
								address will be assigned to it.
	@param	level				Level, used for calling
								getAddressURL().
*/
static function procStreamerHost(out String streamerHost, LevelInfo level) {
	if (streamerHost == "") {
		streamerHost = level.getAddressURL();
		streamerHost = left(streamerHost, inStr(streamerHost, ":"));
		if (streamerHost == "0.0.0.0")
			// We are the server.
			streamerHost = "";
		// else we are the client.
	}
	if (streamerHost == "")
		// Only the server may reach here.
		streamerHost = "127.0.0.1";
}