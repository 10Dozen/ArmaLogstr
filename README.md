# ArmaLogstr
Small in-game log tool for Arma 3

### Installation
Put `initLogstr.sqf` to mission folder and execute file via (e.g. at the first line of `init.sqf`):
```sqf
call compile preProcessFileLineNumbers "initLogstr.sqf";
```

### Usage
By default Logstr provide output Diary and sideChat. To configure output you need to manually create log thread before logging:
```sqf
["MyLog", "diary,sidechat,hint,rpt"] call AddLogThread;
// diary    - log entry is added to Diary record (Logstr -> MyLog topic); logged lines may be copied to clipboard via diary buttons
// sidechat - log entry is displayed via sideChat 
// hint     - log entry is displayed via hintSilent (as formatted structued text)
// rpt      - log entry is dumped to RPT file (via diag_log, as structured text)
```

To log something you need just use any of the function below:
```sqf
["MyLog", "My message"] call Logstr;        // 00:00:04.953 [MyLog][1][LOG] My message
["MyLog", "My info message"] call Infostr;  // 00:00:05.353 [MyLog][2][INFO] My info message
["MyLog", "My warn message"] call Warnstr;  // 00:00:06.353 [MyLog][3][WARN] My warn message
["MyLog", "My error message"] call Errstr;  // 00:00:07.153 [MyLog][4][ERR] My error message
// all log entries are formatted as:
//   <time from mission start> [<log name>][<log entity number>][<log type>] <log message>
```

You can also pass up to 10 parameters to your log message:
```sqf
["MyLog", "My logged message with %1 and %2 params", _myParam1, _myParam2] call Logstr;
// 00:00:10.823 [MyLog][6][LOG] My logged message with 123 and [1,2,3] params
```

### Customization 

#### Custom log function
To customize log function, just make a wrapper for `dzn_Logstr_fnc_doLog` function:
```sqf
#define PARAMS_LIST_STR ["_param1",""],["_param2",""],["_param3",""],["_param4",""],["_param5",""],["_param6",""],["_param7",""],["_param8",""],["_param9",""],["_param10",""]
#define PARAMS_LIST _param1, _param2, _param3, _param4, _param5, _param6, _param7, _param8, _param9, _param10

DoLog = {
    params ["_msg", PARAMS_LIST_STR];
    [
        "MySingleLog"
        , "MSG"
        , _msg
        , PARAMS_LIST
    ] call dzn_Logstr_fnc_doLog;
};

["My custom log message"] call DoLog;
// 00:00:10.823 [MySingleLog][1][MSG] My custom log message
```

#### Default outputs
To change default outputs use:
```sqf
LogstrSettings setVariable ["default_outputs", "diary,sideChat"];
```

#### Update outputs for thread
To change outputs for specific log thread use:
```sqf
["MyLog", "outputs: diary"] call dzn_Logstr_fnc_applyOptions; 
// Change output options for MyLog thread to Diary only
```

#### Log type formatting
To update formatting of log types (`log`, `info`, `warn` and `err`) :
```sqf
// Default shortcuts values
LogstrSettings setVariable ["L", "[LOG]"];
LogstrSettings setVariable ["I", "[INF]"];
LogstrSettings setVariable ["W", "[WARN]"];
LogstrSettings setVariable ["E", "[ERR]"];

// Default types as structured text
LogstrSettings setVariable ["ST_L", "[<t color='#8ac5d1'>LOG</t>]"];
LogstrSettings setVariable ["ST_I", "[<t color='#a4d194'>INF</t>]"];
LogstrSettings setVariable ["ST_W", "[<t color='#fc6f03'>WARN</t>]"];
LogstrSettings setVariable ["ST_E", "[<t color='#ff4545'>ERR</t>]"];

// Default types as diary record text
LogstrSettings setVariable ["T_L", "[<font color='#8ac5d1'>LOG</font>]"];
LogstrSettings setVariable ["T_I", "[<font color='#a4d194'>INF</font>]"];
LogstrSettings setVariable ["T_W", "[<font color='#fc6f03'>WARN</font>]"];
LogstrSettings setVariable ["T_E", "[<font color='#ff4545'>ERR</font>]"];
```
or add custom types:
```sqf
LogstrSettings setVariable ["MSG", "[MSG]"];
// Styling for hint
LogstrSettings setVariable ["ST_MSG", "[<t color='#00aabb'>MSG</t>]"];
// Styling for diary
LogstrSettings setVariable ["T_MSG", "[<font color='#00aabb'>MSG</font>]"];
```
