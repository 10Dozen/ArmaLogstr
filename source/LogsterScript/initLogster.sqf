// Functions
#define PARAMS_LIST_STR ["_param1",""],["_param2",""],["_param3",""],["_param4",""],["_param5",""],["_param6",""],["_param7",""],["_param8",""],["_param9",""],["_param10",""]
#define PARAMS_LIST _param1, _param2, _param3, _param4, _param5, _param6, _param7, _param8, _param9, _param10

dzn_Logster_fnc_init = {
	LogsterThreads = call CBA_fnc_createNamespace;
	LogsterSettings = call CBA_fnc_createNamespace;
	
	LogsterSettings setVariable ["default_outputs", "diary,sideChat"];
	LogsterSettings setVariable ["L", "[LOG]"];
	LogsterSettings setVariable ["I", "[INF]"];
	LogsterSettings setVariable ["W", "[WARN]"];
	LogsterSettings setVariable ["E", "[ERR]"];
	
	LogsterSettings setVariable ["ST_L", "[<t color='#8ac5d1'>LOG</t>]"];
	LogsterSettings setVariable ["ST_I", "[<t color='#a4d194'>INF</t>]"];
	LogsterSettings setVariable ["ST_W", "[<t color='#fc6f03'>WARN</t>]"];
	LogsterSettings setVariable ["ST_E", "[<t color='#ff4545'>ERR</t>]"];
	
	LogsterSettings setVariable ["T_L", "[<font color='#8ac5d1'>LOG</font>]"];
	LogsterSettings setVariable ["T_I", "[<font color='#a4d194'>INF</font>]"];
	LogsterSettings setVariable ["T_W", "[<font color='#fc6f03'>WARN</font>]"];
	LogsterSettings setVariable ["T_E", "[<font color='#ff4545'>ERR</font>]"];
	
	player createDiarySubject ["Logster", "Logster"];
};

dzn_Logster_fnc_createThread = {
	params ["_threadName","_threadOutputOptions"];

	private _options = toLower _threadOutputOptions splitString ",";
	LogsterThreads setVariable [_threadName, ["Init"]];
	LogsterThreads setVariable [format ["%1_options", _threadName], _options];
	if (_options findIf { "diary" == _x } > -1) then {
		player createDiaryRecord  ["Logster", [
			_threadName,
			"Init   <br/><execute expression='[" + str _threadName + "] call dzn_Logster_fnc_copyThreadFromDiary'>Copy All</t>"
		]];
	};
};

dzn_Logster_fnc_doLog = {
	params [
		"_threadName", "_entryType", "_entryValue"
		, PARAMS_LIST_STR
	];

	private _thread = LogsterThreads getVariable ["_threadName", []];
	if (_thread isEqualTo []) then {
		[_threadName, LogsterSettings getVariable "default_outputs"] call dzn_Logster_fnc_createThread;
		_thread = LogsterThreads getVariable _threadName;
	};

	private _logEntry = format [_entryValue, PARAMS_LIST];
	private _time = CBA_missionTime;
	private _index = count _thread;

	_thread pushBack [_index, _time, _entryType, _logEntry];
	LogsterThreads setVariable ["_threadName", _thread];

	[_threadName, _index, _time, _entryType, _logEntry] call dzn_Logster_fnc_writeLog;
};

dzn_Logster_fnc_writeLog = {
	params ["_threadName", "_logIndex", "_logTime", "_logLevel", "_logEntry"];
	private _options = LogsterThreads getVariable format ["%1_options", _threadName];
	private _time = [_logTime, "HH:MM:SS.MS"] call BIS_fnc_secondsToString;
	private _text = "";

	{
		switch _x do {
			case "hint": {
				hintSilent parseText (["structured", _this] call dzn_Logster_fnc_formatText);
			};
			case "diary": {
				player createDiaryRecord  ["Logster", [_threadName,
					"<execute expression='[" + str _threadName + ", " + str _logIndex + "] call dzn_Logster_fnc_copyFromDiary'>Copy</execute> "
					+ (["diary", _this] call dzn_Logster_fnc_formatText)
				]];
			};
			case "sidechat": {
				if (_text == "") then { _text = ["text", _this] call dzn_Logster_fnc_formatText; };
				[side player, "Base"] sideChat _text;
			};
			case "rpt": {
				if (_text == "") then { _text = ["text", _this] call dzn_Logster_fnc_formatText; };
				diag_log parseText _text;
			};
		};
	} forEach _options;
};

dzn_Logster_fnc_getLogByIndex = {
	params ["_threadName","_index"];
	private _textData = [_threadName];
	_textData append ((LogsterThreads getVariable _threadName) # _index);
	["text", _textData] call dzn_Logster_fnc_formatText
};

dzn_Logster_fnc_copyFromDiary = {
	params ["_threadName","_index"];
	private _text = [_threadName, _index] call dzn_Logster_fnc_getLogByIndex;
	copyToClipboard _text;
	hint "Log entry copied!";
};

dzn_Logster_fnc_copyThreadFromDiary = {
	params ["_threadName"];
	private _outputText = [];
	
	for "_i" from 1 to (count (LogsterThreads getVariable _threadName)) - 1 do {
		_outputText pushBack ([_threadName, _i] call dzn_Logster_fnc_getLogByIndex);
	};
	copyToClipboard (_outputText joinString toString [10]);
	hint "Thread log copied!";
};

dzn_Logster_fnc_formatText = {
	params ["_formatMode", "_textData"];
	_textData params ["_threadName","_logIndex", "_logTime", "_logLevel", "_logEntry"];
	private _result = "";
	private _time = [_logTime, "HH:MM:SS.MS"] call BIS_fnc_secondsToString;

	switch toLower(_formatMode) do {
		case "text": {
			_logLevel = LogsterSettings getVariable [_logLevel, "[" + _logLevel + "]"];
			_result = _time + " [" + _threadName + "][" + str _logIndex + "]" + _logLevel + " " + _logEntry;
		};
		case "diary": {
			_logLevel = LogsterSettings getVariable ["T_" + _logLevel, "[" + _logLevel + "]"];
			_result = _time + " [" + _threadName + "][" + str _logIndex + "]" + _logLevel + " " + _logEntry;
		};
		case "structured": {
			_logLevel = LogsterSettings getVariable ["ST_" + _logLevel, "[" + _logLevel + "]"];
			_result = "<t size='2'>" + _threadName + "</t><br/>"
				+ "<t size='1.1'>" + _time + "  |  #" +  str _logIndex + "</t><br/>"
				+ _logLevel + "<br/>"
				+ _logEntry;
		};
	};
	
	_result
};


// Shortcuts
AddLogThread = dzn_Logster_fnc_createThread;
Infostr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "I", _entryValue, PARAMS_LIST] call dzn_Logster_fnc_doLog
};
Logstr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "L", _entryValue, PARAMS_LIST] call dzn_Logster_fnc_doLog
};
Warnstr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "W", _entryValue, PARAMS_LIST] call dzn_Logster_fnc_doLog
};
Errstr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "E", _entryValue, PARAMS_LIST] call dzn_Logster_fnc_doLog
};


// Init
[] call dzn_Logster_fnc_init;

