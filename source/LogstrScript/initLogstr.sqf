// Functions
#define PARAMS_LIST_STR ["_param1",""],["_param2",""],["_param3",""],["_param4",""],["_param5",""],["_param6",""],["_param7",""],["_param8",""],["_param9",""],["_param10",""]
#define PARAMS_LIST _param1, _param2, _param3, _param4, _param5, _param6, _param7, _param8, _param9, _param10

dzn_Logstr_fnc_init = {
	LogstrThreads = call CBA_fnc_createNamespace;
	LogstrSettings = call CBA_fnc_createNamespace;
	
	LogstrSettings setVariable ["default_outputs", "diary,sideChat,hint"];
	LogstrSettings setVariable ["L", "[LOG]"];
	LogstrSettings setVariable ["I", "[INF]"];
	LogstrSettings setVariable ["W", "[WARN]"];
	LogstrSettings setVariable ["E", "[ERR]"];
	
	LogstrSettings setVariable ["ST_L", "[<t color='#8ac5d1'>LOG</t>]"];
	LogstrSettings setVariable ["ST_I", "[<t color='#a4d194'>INF</t>]"];
	LogstrSettings setVariable ["ST_W", "[<t color='#fc6f03'>WARN</t>]"];
	LogstrSettings setVariable ["ST_E", "[<t color='#ff4545'>ERR</t>]"];
	
	LogstrSettings setVariable ["T_L", "[<font color='#8ac5d1'>LOG</font>]"];
	LogstrSettings setVariable ["T_I", "[<font color='#a4d194'>INF</font>]"];
	LogstrSettings setVariable ["T_W", "[<font color='#fc6f03'>WARN</font>]"];
	LogstrSettings setVariable ["T_E", "[<font color='#ff4545'>ERR</font>]"];
	
	player createDiarySubject ["Logstr", "Logstr"];
};

dzn_Logstr_fnc_createThread = {
	params ["_threadName","_threadOutputOptions"];

	private _options = (toLower _threadOutputOptions) splitString " " joinString "" splitString ",";
	LogstrThreads setVariable [_threadName, ["Init"]];
	LogstrThreads setVariable [format ["%1.outputs", _threadName], _options];
	if (_options findIf { "diary" == _x } > -1) then {
		player createDiaryRecord  ["Logstr", [
			_threadName,
			"Init   <br/><execute expression='[" + str _threadName + "] call dzn_Logstr_fnc_copyThreadFromDiary'>Copy All</t>"
		]];
	};
};

dzn_Logstr_fnc_doLog = {
	params [
		"_threadName", "_entryType", "_entryValue"
		, PARAMS_LIST_STR
	];

	private _thread = LogstrThreads getVariable [_threadName, []];
	if (_thread isEqualTo []) then {
		[_threadName, LogstrSettings getVariable "default_outputs"] call dzn_Logstr_fnc_createThread;
		_thread = LogstrThreads getVariable _threadName;
	};

	private _logEntry = format [_entryValue, PARAMS_LIST];
	private _time = CBA_missionTime;
	private _index = count _thread;

	_thread pushBack [_index, _time, _entryType, _logEntry];
	// LogstrThreads setVariable [_threadName, _thread];

	[_threadName, _index, _time, _entryType, _logEntry] call dzn_Logstr_fnc_writeLog;
};

dzn_Logstr_fnc_writeLog = {
	params ["_threadName", "_logIndex", "_logTime", "_logLevel", "_logEntry"];
	private _options = LogstrThreads getVariable format ["%1.outputs", _threadName];
	private _time = [_logTime, "HH:MM:SS.MS"] call BIS_fnc_secondsToString;
	private _text = "";

	{
		switch _x do {
			case "hint": {
				hintSilent parseText (["structured", _this] call dzn_Logstr_fnc_formatText);
			};
			case "diary": {
				player createDiaryRecord  ["Logstr", [_threadName,
					"<execute expression='[" + str _threadName + ", " + str _logIndex + "] call dzn_Logstr_fnc_copyFromDiary'>Copy</execute> "
					+ (["diary", _this] call dzn_Logstr_fnc_formatText)
				]];
			};
			case "sidechat": {
				if (_text == "") then { _text = ["text", _this] call dzn_Logstr_fnc_formatText; };
				[side player, "Base"] sideChat _text;
			};
			case "rpt": {
				if (_text == "") then { _text = ["text", _this] call dzn_Logstr_fnc_formatText; };
				diag_log parseText _text;
			};
		};
	} forEach _options;
};

dzn_Logstr_fnc_getLogByIndex = {
	params ["_threadName","_index"];
	private _textData = [_threadName];
	_textData append ((LogstrThreads getVariable _threadName) # _index);
	["text", _textData] call dzn_Logstr_fnc_formatText
};

dzn_Logstr_fnc_copyFromDiary = {
	params ["_threadName","_index"];
	private _text = [_threadName, _index] call dzn_Logstr_fnc_getLogByIndex;
	copyToClipboard _text;
	hint "Log entry copied!";
};

dzn_Logstr_fnc_copyThreadFromDiary = {
	params ["_threadName"];
	private _outputText = [];
	
	for "_i" from 1 to (count (LogstrThreads getVariable _threadName)) - 1 do {
		_outputText pushBack ([_threadName, _i] call dzn_Logstr_fnc_getLogByIndex);
	};
	copyToClipboard (_outputText joinString toString [10]);
	hint "Thread log copied!";
};

dzn_Logstr_fnc_formatText = {
	params ["_formatMode", "_textData"];
	_textData params ["_threadName","_logIndex", "_logTime", "_logLevel", "_logEntry"];
	private _result = "";
	private _time = [_logTime, "HH:MM:SS.MS"] call BIS_fnc_secondsToString;

	switch toLower(_formatMode) do {
		case "text": {
			_logLevel = LogstrSettings getVariable [_logLevel, "[" + _logLevel + "]"];
			_result = format ["%1 [%2][%3]%4 ", _time, _threadName, _logIndex, _logLevel] + _logEntry;
		};
		case "diary": {
			_logLevel = LogstrSettings getVariable ["T_" + _logLevel, "[" + _logLevel + "]"];
			_result = format ["<font size='10' face='EtelkaMonospacePro'>%1 [%2]%3 ", _time, _logIndex, _logLevel] + _logEntry + "</font>";
		};
		case "structured": {
			_logLevel = LogstrSettings getVariable ["ST_" + _logLevel, "[" + _logLevel + "]"];
			_result = format [
				"<t size='2'>%1</t><br/><t size='1.1'>%2  |  #%3</t><br/>%4<br/>"
				, _threadName, _time, _logIndex, _logLevel
			] + _logEntry;
		};
	};
	
	_result
};

dzn_Logstr_fnc_applyOptions = {
	params ["_threadName", "_optionsString"];

	private _options = ((toLower _optionsString) splitString " " joinString "" splitString ";") apply { _x splitString ":" };
	if (_options isEqualTo []) exitWith {};
	
	{
		_x params ["_option","_value"];
		
		switch _option do {
			case "outputs";
			case "output": {
				LogstrThreads setVariable [format ["%1.outputs", _threadName], _value splitString ","];
			};
		};
	} forEach _options;
};

// Shortcuts
AddLogThread = dzn_Logstr_fnc_createThread;
Infostr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "I", _entryValue, PARAMS_LIST] call dzn_Logstr_fnc_doLog
};
Logstr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "L", _entryValue, PARAMS_LIST] call dzn_Logstr_fnc_doLog
};
Warnstr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "W", _entryValue, PARAMS_LIST] call dzn_Logstr_fnc_doLog
};
Errstr = {
	params ["_threadName", "_entryValue", PARAMS_LIST_STR];
	[_threadName, "E", _entryValue, PARAMS_LIST] call dzn_Logstr_fnc_doLog
};


// Init
[] call dzn_Logstr_fnc_init;
