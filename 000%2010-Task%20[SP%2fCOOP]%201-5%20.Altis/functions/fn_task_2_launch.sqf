if (!isServer) exitWith {};

// Wait for enemy initialization
waitUntil { !isNil "MISSION_var_enemies" && !isNil "MISSION_var_officers" };
if (count MISSION_var_enemies == 0 || count MISSION_var_officers == 0) exitWith {
    systemChat "ERROR: No memory enemies/officers found for Task 2.";
};

// 1. Get Physical Document Object from Editor
private _document = missionNamespace getVariable ["task_2_document", objNull];
if (isNull _document) exitWith {
    systemChat "ERROR: task_2_document not found in editor.";
};

// Hide document initially
_document hideObjectGlobal true;
_document enableSimulationGlobal false;

// 2. Spawn Selection
private _spawnMarkers = [
    "task_2_spawn_01", "task_2_spawn_02", "task_2_spawn_03", 
    "task_2_spawn_04", "task_2_spawn_05", "task_2_spawn_06"
];

private _selectedMarker = selectRandom _spawnMarkers;
private _spawnObj = missionNamespace getVariable [_selectedMarker, objNull];
private _spawnPos = if (!isNull _spawnObj) then { getPosATL _spawnObj } else { [0,0,0] };
_spawnPos set [2, 0]; 

if (_spawnPos isEqualTo [0,0,0]) exitWith { systemChat "ERROR: Task 2 Spawn Point not found."; };

// 3. Spawn Officer
private _officerTemplate = selectRandom MISSION_var_officers;
_officerTemplate params ["_oVar", "_oType", "", "", "_oSide", "_oLoadout"];

private _grpEnemies = createGroup [east, true];
_grpEnemies setBehaviour "AWARE";
_grpEnemies setCombatMode "RED";

private _officer = _grpEnemies createUnit [_oType, _spawnPos, [], 5, "NONE"];
_officer setUnitLoadout _oLoadout;
_officer setRank "COLONEL";
_officer setSkill 0.8;
_officer disableAI "PATH"; 

// 4. Spawn Guards (5 soldiers)
private _guards = [];
for "_i" from 1 to 5 do {
    private _eTemplate = selectRandom MISSION_var_enemies;
    _eTemplate params ["_eVar", "_eType", "", "", "_eSide", "_eLoadout"];
    
    private _guard = _grpEnemies createUnit [_eType, _spawnPos, [], 5, "NONE"];
    _guard setUnitLoadout _eLoadout;
    _guards pushBack _guard;
};

// 5. Position and Behavior
{
    private _relPos = _officer getPos [2 + random 5, random 360];
    _x setPos _relPos;
    _x setUnitPos "AUTO";
} forEach _guards;

// Dynamic repositioning loop
[_grpEnemies, _officer, _guards] spawn {
    params ["_grp", "_officer", "_guards"];
    
    while {alive _officer} do {
        sleep 45;
        if (!alive _officer) exitWith {};
        {
            if (alive _x) then {
                private _newPos = _officer getPos [2 + random 5, random 360];
                _x doMove _newPos;
                _x setUnitPos "AUTO";
            };
        } forEach _guards;
    };
};

// 6. Task Creation
private _taskID = "task_2_assassination";
[
    true,
    [_taskID],
    [
        localize "STR_TASK_2_DESC",
        localize "STR_TASK_2_TITLE",
        ""
    ],
    getPosWorld _officer,
    "CREATED",
    1,
    true,
    "kill"
] call BIS_fnc_taskCreate;

// 7. Conditions Monitoring - Physical Object Pickup
MISSION_var_task2_completed = false;
publicVariable "MISSION_var_task2_completed";

[_taskID, _officer, _document] spawn {
    params ["_taskID", "_officer", "_document"];
    
    private _markerCreated = false;
    private _documentRevealed = false;
    
    while {true} do {
        sleep 1;
        
        // Officer Death - Reveal document near body
        if (!alive _officer && !_documentRevealed) then {
            _documentRevealed = true;
            
            private _bodyPos = getPosATL _officer;
            _bodyPos set [2, 0];
            
            // Move document to body and reveal
            _document setPosATL _bodyPos;
            _document hideObjectGlobal false;
            _document enableSimulationGlobal true;
            
            // Create marker
            private _mkrName = createMarker ["mkr_task_2_doc", _bodyPos];
            _mkrName setMarkerType "mil_objective";
            _mkrName setMarkerColor "ColorWhite";
            _mkrName setMarkerText (localize "STR_MARKER_DOCUMENT");
            _markerCreated = true;
            
            [_taskID, _bodyPos] call BIS_fnc_taskSetDestination;
            
            // Add pickup action to document (executed on all clients)
            [[_document], {
                params ["_doc"];
                _doc addAction [
                    localize "STR_MARKER_DOCUMENT",
                    {
                        params ["_target", "_caller", "_actionId"];
                        MISSION_var_task2_completed = true;
                        publicVariable "MISSION_var_task2_completed";
                        _target hideObjectGlobal true;
                        _target enableSimulationGlobal false;
                        hint (localize "STR_MARKER_DOCUMENT" + " - OK");
                    },
                    nil,
                    6,
                    true,
                    true,
                    "",
                    "_this distance _target < 3"
                ];
            }] remoteExec ["call", 0, true];
        };
        
        // Task Success - Document picked up
        if (MISSION_var_task2_completed) exitWith {
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
            if (_markerCreated) then { deleteMarker "mkr_task_2_doc"; };
        };
    };
};

