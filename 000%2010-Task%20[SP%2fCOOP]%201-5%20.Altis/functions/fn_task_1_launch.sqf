/*
    Function: MISSION_fnc_task_1_launch
    Description: Spawns enemies targeting the officer.
    - Every 3 seconds: spawn 1 infantry
    - After max infantry, spawn 1-2 vehicles (NO tanks)
    - Stops after 10 total spawns
*/

if (!isServer) exitWith {};

waitUntil { !isNil "MISSION_var_enemies" };
if (count MISSION_var_enemies == 0) exitWith {};

private _spawnMarkers = [
    "task_1_spawn_01", "task_1_spawn_02", "task_1_spawn_03", 
    "task_1_spawn_04", "task_1_spawn_05", "task_1_spawn_06"
];

// ============================================================================
// Créer la tâche Arma 3
// ============================================================================
private _taskID = "task_1_hq_defense";

[
    true,                                           // Exécuter globalement
    [_taskID],                                      // ID de la tâche
    [
        localize "STR_TASK_1_DESC",                 // Description
        localize "STR_TASK_1_TITLE",                // Titre
        ""                                          // Marqueur (optionnel)
    ],
    getPosWorld officier_task_giver,                // Position de la tâche
    "CREATED",                                      // État initial
    1,                                              // Priorité
    true,                                           // Afficher notification
    "defend"                                        // Type de tâche
] call BIS_fnc_taskCreate;

// Variable globale pour suivre les ennemis spawnés
MISSION_var_task1_spawned_enemies = [];

[_spawnMarkers] spawn {
    params ["_spawnMarkers"];
    
    private _maxInfantry = 5 + floor (random 6);
    private _spawnedInfantry = 0;
    private _vehiclesSpawned = false;
    private _totalSpawns = 0;
    private _maxTotalSpawns = 10;
    
    private _grpInf = createGroup [east, true];
    _grpInf setBehaviour "AWARE";
    _grpInf setCombatMode "RED";
    _grpInf enableAttack true;
    
    while {_totalSpawns < _maxTotalSpawns} do {
        sleep 3;
        
        private _spawnMarker = selectRandom _spawnMarkers;
        private _spawnObj = missionNamespace getVariable [_spawnMarker, objNull];
        private _spawnPos = if (!isNull _spawnObj) then { getPos _spawnObj } else { [0,0,0] };
        
        if (_spawnPos isEqualTo [0,0,0]) then { continue; };
        
        // Spawn 1 Infanterie par loop
        if (_spawnedInfantry < _maxInfantry && _totalSpawns < _maxTotalSpawns) then {
            if (count MISSION_var_enemies > 0) then {
                private _template = selectRandom MISSION_var_enemies;
                _template params ["_tVar", "_tType", "_tPos", "_tDir", "_tSide", "_tLoadout"];
                
                private _unit = _grpInf createUnit [_tType, _spawnPos, [], 5, "NONE"];
                _unit setUnitLoadout _tLoadout;
                
                // Révéler la cible à l'unité pour qu'elle la traque
                _unit reveal [officier_task_giver, 4];
                
                // Donner l'ordre d'attaquer directement la cible
                _unit doTarget officier_task_giver;
                _unit doFire officier_task_giver;
                
                _spawnedInfantry = _spawnedInfantry + 1;
                _totalSpawns = _totalSpawns + 1;
                
                // Donner un nom unique à l'unité pour le suivi
                private _unitName = format ["task1_enemy_%1", _totalSpawns];
                _unit setVehicleVarName _unitName;
                missionNamespace setVariable [_unitName, _unit, true];
                
                // Ajouter à la liste de suivi
                MISSION_var_task1_spawned_enemies pushBack _unit;
                
                // Après le premier spawn, configurer le comportement du groupe
                if (_spawnedInfantry == 1) then {
                    // Mode AWARE pour éviter que l'IA se couche (problème dans les bâtiments)
                    _grpInf setBehaviour "AWARE";
                    _grpInf setCombatMode "RED";
                    _grpInf setSpeedMode "FULL";
                    
                    private _wp = _grpInf addWaypoint [getPosWorld officier_task_giver, 5];
                    _wp setWaypointType "SAD";
                    _wp setWaypointBehaviour "AWARE";
                    _wp setWaypointCombatMode "RED";
                    _wp setWaypointCompletionRadius 3;
                };
                
                // Thread individuel pour la fouille du bâtiment
                [_unit] spawn {
                    params ["_unit"];
                    
                    // Attendre que l'unité soit proche du bâtiment (30m)
                    waitUntil { sleep 1; (!alive _unit) || (_unit distance batiment_officer < 30) };
                    if (!alive _unit) exitWith {};
                    
                    // Récupérer les positions intérieures du bâtiment
                    private _positions = batiment_officer buildingPos -1;
                    if (count _positions == 0) exitWith {};
                    
                    // Forcer le mode debout pour entrer dans le bâtiment
                    _unit setUnitPos "UP";
                    (group _unit) setBehaviour "AWARE";
                    
                    // Parcourir les positions du bâtiment
                    {
                        if (!alive _unit) exitWith {};
                        if (!alive officier_task_giver) exitWith {};
                        
                        _unit doMove _x;
                        
                        // Attendre max 10s pour atteindre la position
                        private _timeout = time + 10;
                        waitUntil { sleep 0.5; (!alive _unit) || (_unit distance _x < 2) || (time > _timeout) };
                        
                        // Vérifier si l'officier est visible et tirer
                        if (alive _unit && alive officier_task_giver) then {
                            _unit reveal [officier_task_giver, 4];
                            _unit doTarget officier_task_giver;
                            _unit doFire officier_task_giver;
                        };
                        
                        sleep 0.5;
                    } forEach _positions;
                    
                    // Revenir au mode normal après la fouille
                    _unit setUnitPos "AUTO";
                };
            };
        };
        
        // Spawn Véhicules une fois l'infanterie atteinte
        if (_spawnedInfantry >= _maxInfantry && !_vehiclesSpawned && _totalSpawns < _maxTotalSpawns) then {
            _vehiclesSpawned = true;
            
            private _nbVeh = 1 + floor (random 2);
            
            for "_v" from 1 to _nbVeh do {
                if (count MISSION_var_vehicles > 0 && _totalSpawns < _maxTotalSpawns) then {
                    private _vTemplate = selectRandom MISSION_var_vehicles;
                    _vTemplate params ["_vVar", "_vType", "_vPos", "_vDir", "_vSide", "_vLoadout"];
                    
                    private _veh = createVehicle [_vType, _spawnPos, [], 15, "NONE"];
                    _veh setDir (getDir _spawnObj);
                    
                    private _grpVeh = createGroup [east, true];
                    _grpVeh setBehaviour "CARELESS";
                    _grpVeh setCombatMode "RED";
                    
                    if (count MISSION_var_enemies > 0) then {
                        private _dTemplate = selectRandom MISSION_var_enemies;
                        _dTemplate params ["_dVar", "_dType", "", "", "", "_dLoadout"];
                        private _driver = _grpVeh createUnit [_dType, [0,0,0], [], 0, "NONE"];
                        _driver moveInDriver _veh;
                        _driver setUnitLoadout _dLoadout;
                    };
                    
                    if (count MISSION_var_enemies > 0) then {
                        private _cTemplate = selectRandom MISSION_var_enemies;
                        _cTemplate params ["_cVar", "_cType", "", "", "", "_cLoadout"];
                        private _crew = _grpVeh createUnit [_cType, [0,0,0], [], 0, "NONE"];
                        if (_veh emptyPositions "Gunner" > 0) then { _crew moveInGunner _veh; }
                        else { if (_veh emptyPositions "Commander" > 0) then { _crew moveInCommander _veh; }
                        else { _crew moveInCargo _veh; };};
                        _crew setUnitLoadout _cLoadout;
                    };
                    
                    _grpVeh move (getPosWorld officier_task_giver);
                    
                    [_veh, _grpVeh] spawn {
                        params ["_veh", "_grp"];
                        waitUntil { sleep 1; (!alive _veh) || (_veh distance officier_task_giver < 20) };
                        
                        if (alive _veh) then {
                            { unassignVehicle _x; } forEach (units _grp);
                            units _grp allowGetIn false;
                            _grp leaveVehicle _veh;
                            _veh lock false;
                            _grp setBehaviour "COMBAT";
                            // Révéler et attaquer la cible
                            { _x reveal [officier_task_giver, 4]; _x doTarget officier_task_giver; } forEach (units _grp);
                            private _wp = _grp addWaypoint [getPosWorld officier_task_giver, 5];
                            _wp setWaypointType "SAD";
                            _wp setWaypointBehaviour "COMBAT";
                        };
                    };
                    
                    _totalSpawns = _totalSpawns + 1;
                };
            };
        };
    };
};

// ============================================================================
// Thread de surveillance des conditions de victoire/défaite
// ============================================================================
[] spawn {
    private _taskID = "task_1_hq_defense";
    private _spawnComplete = false;
    
    // Attendre que le spawn commence (au moins 1 ennemi)
    waitUntil { sleep 3; count MISSION_var_task1_spawned_enemies > 0 };
    
    // Attendre que le spawn soit terminé (10 spawns max) ou timeout 60s
    private _startTime = time;
    waitUntil { 
        sleep 3; 
        _spawnComplete = (count MISSION_var_task1_spawned_enemies >= 10) || (time - _startTime > 60);
        _spawnComplete || !alive officier_task_giver || !alive player 
    };
    
    // Boucle de vérification toutes les 5 secondes
    while {true} do {
        sleep 5;
        
        // Condition d'échec : officier ou joueur mort
        if (!alive officier_task_giver || !alive player) exitWith {
            [_taskID, "FAILED"] call BIS_fnc_taskSetState;
        };
        
        // Compter les ennemis vivants (uniquement infanterie, pas véhicules)
        private _aliveEnemies = 0;
        {
            if (alive _x) then {
                if (_x isKindOf "Man") then {
                    _aliveEnemies = _aliveEnemies + 1;
                };
            };
        } forEach MISSION_var_task1_spawned_enemies;
        
        // Debug - décommenter pour tester
        //systemChat format ["Task1: %1 ennemis vivants sur %2", _aliveEnemies, count MISSION_var_task1_spawned_enemies];
        
        // Condition de succès : tous les ennemis (Man) éliminés et spawn terminé
        if (_aliveEnemies == 0 && _spawnComplete) exitWith {
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
            //systemChat "Task1: MISSION ACCOMPLIE!";
        };
    };
};
