params [["_mode", ""]];

// Variables globales pour stocker les données par catégorie
if (isNil "MISSION_var_officers") then { MISSION_var_officers = []; };
if (isNil "MISSION_var_enemies") then { MISSION_var_enemies = []; };
if (isNil "MISSION_var_vehicles") then { MISSION_var_vehicles = []; };
if (isNil "MISSION_var_tanks") then { MISSION_var_tanks = []; };

if (_mode == "SAVE") exitWith {
    
    // ---- Officiers ----
    private _officerNames = ["task_x_officer_1", "task_x_officer_2", "task_x_officer_3"];
    {
        private _unit = missionNamespace getVariable [_x, objNull];
        if (!isNull _unit) then {
            MISSION_var_officers pushBack [_x, typeOf _unit, getPosWorld _unit, getDir _unit, side group _unit, getUnitLoadout _unit];
            deleteVehicle _unit;
        };
    } forEach _officerNames;

    // ---- Ennemis (infanterie) ----
    for "_i" from 0 to 15 do {
        private _numStr = if (_i < 10) then { format ["0%1", _i] } else { str _i };
        private _varName = format ["task_x_enemy_%1", _numStr];
        private _unit = missionNamespace getVariable [_varName, objNull];
        if (!isNull _unit) then {
            MISSION_var_enemies pushBack [_varName, typeOf _unit, getPosWorld _unit, getDir _unit, side group _unit, getUnitLoadout _unit];
            deleteVehicle _unit;
        };
    };

    // ---- Véhicules (pas de tanks) ----
    private _vehicleNames = ["task_x_vehicle_1", "task_x_vehicle_2"];
    {
        private _veh = missionNamespace getVariable [_x, objNull];
        if (!isNull _veh) then {
            MISSION_var_vehicles pushBack [_x, typeOf _veh, getPosWorld _veh, getDir _veh, east, []];
            deleteVehicle _veh;
        };
    } forEach _vehicleNames;

    // ---- Tanks ----
    private _tankNames = ["task_x_tank_1"];
    {
        private _tank = missionNamespace getVariable [_x, objNull];
        if (!isNull _tank) then {
            MISSION_var_tanks pushBack [_x, typeOf _tank, getPosWorld _tank, getDir _tank, east, []];
            deleteVehicle _tank;
        };
    } forEach _tankNames;

    // Debug (désactivé)
    // systemChat format ["Memory: Officers=%1, Enemies=%2, Vehicles=%3, Tanks=%4", 
    //     count MISSION_var_officers, 
    //     count MISSION_var_enemies, 
    //     count MISSION_var_vehicles, 
    //     count MISSION_var_tanks
    // ];
};

if (_mode == "SPAWN") exitWith {
    // Respawn tout (si besoin à l'avenir)
    // À implémenter selon les besoins
};
