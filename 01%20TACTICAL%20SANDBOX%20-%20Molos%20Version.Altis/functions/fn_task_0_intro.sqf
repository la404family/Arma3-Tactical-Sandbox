/*
    Author: Antigravity (Refined)
    Description:
    Cinematic Introduction V2.
    - Robust Input Handling (Failsafe included)
    - Dynamic Shots: HQ -> City Travel -> Heli -> Landing
    - Targets: batiment_officer, task_5_spawn_15, task_1_spawn_06
*/

if (hasInterface) then {
    [] spawn {
        // --- 1. SETUP & SECURITY ---
        disableSerialization;
        
        // Failsafe: Ensure input is back after 90s no matter what crashes
        [] spawn {
            sleep 90;
            disableUserInput false;
            disableUserInput true;
            disableUserInput false;
            player allowDamage true;
            showCinemaBorder false;
        };

        // Initial State
        cutText ["", "BLACK FADED", 999];
        0 fadeSound 0;
        showCinemaBorder true;
        disableUserInput true;
        
        // Wait for player
        waitUntil { !isNull player };
        player allowDamage false;

        // Visuals
        private _ppColor = ppEffectCreate ["ColorCorrections", 1500];
        _ppColor ppEffectEnable true;
        _ppColor ppEffectAdjust [1, 1.0, -0.05, [0.2, 0.2, 0.2, 0.0], [0.8, 0.8, 0.9, 0.7], [0.1, 0.1, 0.2, 0]]; 
        _ppColor ppEffectCommit 0;

        // Define Targets (Check existence to avoid errors)
        private _targetHQ = if (!isNil "batiment_officer") then { batiment_officer } else { player };
        private _targetCityMid = if (!isNil "task_5_spawn_15") then { task_5_spawn_15 } else { _targetHQ };
        private _targetCityEnd = if (!isNil "task_1_spawn_06") then { task_1_spawn_06 } else { _targetHQ };

        // Play Music
        playMusic "00intro";
        3 fadeSound 1;

        // --- SHOT 1: ALLIED HQ (Wake up / Prepare) ---
        // High angle, slow pan over HQ
        private _posHQ = getPos _targetHQ;
        private _cam = "camera" camCreate [_posHQ select 0, _posHQ select 1, 100];
        _cam cameraEffect ["INTERNAL", "BACK"];
        _cam camSetPos [(_posHQ select 0) + 80, (_posHQ select 1) - 80, 60];
        _cam camSetTarget _targetHQ;
        _cam camCommit 0;

        // Move cam
        _cam camSetPos [(_posHQ select 0) - 40, (_posHQ select 1) + 40, 40];
        _cam camCommit 8;

        cutText ["", "BLACK IN", 3];
        
        // TEXT: Presents
        [
            format [
                "<t size='1.2' color='#bbbbbb' font='PuristaMedium'>%1</t><br />" + 
                "<t size='0.8' color='#a0a0a0' font='PuristaLight'>%2</t>",
                localize "STR_INTRO_AUTHOR",
                localize "STR_INTRO_PRESENTS"
            ],
            safeZoneX + 0.1, 
            safeZoneY + safeZoneH - 0.3, 
            6, 
            1, 
            0, 
            789
        ] spawn BIS_fnc_dynamicText;

        sleep 6;

        // --- SHOT 2: THE CITY (Mission Area) ---
        // Fast low flight through the city streets (simulated)
        private _posCityStart = getPos _targetCityMid;
        private _posCityEnd = getPos _targetCityEnd;

        _cam camSetPos [(_posCityStart select 0), (_posCityStart select 1), 20];
        _cam camSetTarget _targetCityMid;
        _cam camCommit 0; // Cut to this position

        // Movement: Fly towards end of city
        _cam camSetPos [(_posCityEnd select 0), (_posCityEnd select 1), 30];
        _cam camSetTarget _targetCityEnd;
        _cam camCommit 7; // Fast movement through city

        sleep 2;
        
        // TEXT: Title
        [
            format [
                "<t size='2.5' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
                localize "STR_INTRO_TITLE"
            ],
            -1, 
            -1, 
            5, 
            1, 
            0, 
            790
        ] spawn BIS_fnc_dynamicText;

        sleep 5;

        // --- SHOT 3: HELICOPTER INSERTION ---
        // Attach camera to heli
        waitUntil { vehicle player != player };
        private _heli = vehicle player;

        // Internal View - Adjusted per user request
        // [0, 1.7, -0.5]
        _cam attachTo [_heli, [0, 1.7, -0.5]]; 
        _cam setVectorDirAndUp [[0, 1, 0], [0, 0, 1]];
        _cam camSetFov 0.85;

        // Blur transition
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        cutText ["", "BLACK IN", 1];

        // TEXT: Subtitle
        sleep 2;
        [
            format [
                "<t size='1.0' color='#dddddd' font='PuristaLight'>%1</t>",
                localize "STR_INTRO_SUBTITLE"
            ],
            -1, 
            safeZoneY + safeZoneH - 0.2, 
            6, 
            1, 
            0, 
            791
        ] spawn BIS_fnc_dynamicText;

        sleep 8; // Enjoy the flight

        // --- SHOT 4: LANDING (Dynamic External) ---
        // Switch to cinematic external view for landing
        if ((getPos _heli select 2) < 50) then {
            detach _cam;
            // Position relative: Side view
            _cam attachTo [_heli, [-15, 5, 2]]; 
            _cam setVectorDirAndUp [[0.8, -0.2, -0.1], [0, 0, 1]];
            
            // Wait for landing
            waitUntil { isTouchingGround _heli || (getPos _heli select 2) < 1 };
        };
        
        // Wait for player to be out of vehicle (Server handles ejection)
        waitUntil { vehicle player == player };
        
        sleep 1;

        // --- FINISH ---
        cutText ["", "BLACK FADED", 1];
        sleep 1;

        // Cleanup
        _cam cameraEffect ["TERMINATE", "BACK"];
        camDestroy _cam;
        ppEffectDestroy _ppColor;
        
        // Restore Player
        player switchCamera "INTERNAL";
        showCinemaBorder false;
        player allowDamage true;

        // 100% UNLOCK INPUT - ONLY NOW
        disableUserInput false;
        disableUserInput true;
        disableUserInput false;

        cutText ["", "BLACK IN", 2];

        // Final Mission Start Text
        [
            format [
                "<t size='1.5' color='#ffffff' font='PuristaBold'>%1</t><br/>" +
                "<t size='1.0' color='#cccccc' font='PuristaLight'>%2</t>",
                localize "STR_MISSION_START",
                localize "STR_MISSION_START_SUBTITLE"
            ],
            -1, 
            -1, 
            5, 
            1, 
            0, 
            793
        ] spawn BIS_fnc_dynamicText;
        
        missionNamespace setVariable ["MISSION_intro_finished", true, true];
    };
};

if (isServer) then {
    [] spawn {
        waitUntil {!isNil "MISSION_var_helicopters" };
        waitUntil {!isNil "MISSION_var_model_player" };

        private _heliData = [];
        { if ((_x select 0) == "task_x_helicoptere") exitWith { _heliData = _x; }; } forEach MISSION_var_helicopters;
        
        if (count _heliData == 0) exitWith { 
            missionNamespace setVariable ["MISSION_intro_finished", true, true];
        };

        private _destPos = getPosATL vehicles_spawner; 
        private _startDist = 2000; 
        private _startDir = random 360;
        private _startPos = vehicles_spawner getPos [_startDist, _startDir];
        _startPos set [2, 200];

        private _heliClass = _heliData select 1;
        private _heli = createVehicle [_heliClass, _startPos, [], 0, "FLY"];
        _heli setPos _startPos;
        _heli setDir (_heli getDir _destPos);
        _heli flyInHeight 150;
        _heli lock true; 
        _heli lockCargo true;
        _heli allowDamage false;

        createVehicleCrew _heli;
        private _crew = crew _heli;
        { _x allowDamage false; } forEach _crew;
        
        private _modelPlayerData = [];
        { if ((_x select 0) == "model_player") exitWith { _modelPlayerData = _x; }; } forEach MISSION_var_model_player;
        
        if (count _modelPlayerData > 0) then {
            { _x setUnitLoadout (_modelPlayerData select 5); } forEach _crew;
        };
        
        private _grpHeli = group driver _heli;
        _grpHeli setBehaviour "CARELESS";
        _grpHeli setCombatMode "BLUE";

        private _players = playableUnits;
        if (count _players == 0 && hasInterface) then { _players = [player]; };

        {
            if (isPlayer _x) then {
                if (count _modelPlayerData > 0) then { _x setUnitLoadout (_modelPlayerData select 5); };
                _x moveInCargo _heli;
                if (vehicle _x == _x) then { _x moveInAny _heli; };
                _x assignAsCargo _heli;
            };
        } forEach _players;

        sleep 1; 

        // Fast Approach
        _heli doMove _destPos;
        _heli flyInHeight 150;
        _heli limitspeed 200;

        // Arrival logic - Wait until close
        waitUntil { (_heli distance2D _destPos) < 250 };
        
        _heli land "GET OUT";
        
        waitUntil { (getPos _heli) select 2 < 2 };
        
        sleep 1;
        _heli lock false; 
        _heli lockCargo false;
        
        {
            if (isPlayer _x) then {
                moveOut _x;
                unassignVehicle _x;
                // Eject to safe side
                private _dir = getDir _heli;
                private _dist = 5;
                private _pos = _heli getPos [_dist, _dir + 90]; 
                _pos set [2,0];
                _x setPos _pos;
                _x setDir _dir;
            };
        } forEach _players;
        
        sleep 5;
        
        // Departure
        _heli land "NONE";
        private _exitPos = _destPos getPos [3000, _startDir];
        _heli doMove _exitPos;
        _heli flyInHeight 200;
        _heli limitspeed 300;
        
        sleep 60;
        { deleteVehicle _x } forEach _crew;
        deleteVehicle _heli;
    };
};