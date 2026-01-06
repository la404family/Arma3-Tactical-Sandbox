/*
    Function: MISSION_fnc_ajust_change_team_leader
    Description:
        Checks if the current group leader is an AI.
        If so, attempts to transfer leadership to an available human player in the group.
    
    Usage:
        Call this function periodically or on specific events (TeamSwitch, Respawn).
        [] call MISSION_fnc_ajust_change_team_leader;
*/

if (!hasInterface) exitWith {}; // Executes only on player clients

private _group = group player;
private _leader = leader _group;

// Check if the current leader is an AI
if (!isPlayer _leader) then {
    
    // Find a suitable human player
    private _newLeader = objNull;
    
    {
        if (isPlayer _x && alive _x) exitWith {
            _newLeader = _x;
        };
    } forEach (units _group);
    
    // If a human player is found, transfer leadership
    if (!isNull _newLeader) then {
        _group selectLeader _newLeader;
        
        // Optional: Notify players
        // systemChat format ["Leadership transferred to %1", name _newLeader];
    };
};
