/*
    Author: Antigravity (Enhanced)
    Description:
    Cinematic Introduction V2 - Advanced Camera System
    - Robust Input Handling (Failsafe included)
    - Dynamic Shots: HQ -> City Travel -> Heli Interior -> Orbital Exterior -> Ground Landing
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
        
        // TEXT: Presents (Tailles augmentées)
        [
            format [
                "<t size='1.6' color='#bbbbbb' font='PuristaMedium'>%1</t><br />" + 
                "<t size='1.2' color='#a0a0a0' font='PuristaLight'>%2</t>",
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
        
        // TEXT: Title (Taille augmentée)
        [
            format [
                "<t size='3.0' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
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

        // --- SHOT 3: HELICOPTER INTERIOR VIEW (15s) ---
        // Cinematic interior with smooth movement
        waitUntil { vehicle player != player };
        private _heli = vehicle player;

        // Detach camera from previous position
        detach _cam;
        
        // Transition fade
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;

        // TEXT: Subtitle (Taille augmentée)
        [
            format [
                "<t size='1.4' color='#dddddd' font='PuristaLight'>%1</t>",
                localize "STR_INTRO_SUBTITLE"
            ],
            -1, 
            safeZoneY + safeZoneH - 0.2, 
            6, 
            1, 
            0, 
            791
        ] spawn BIS_fnc_dynamicText;

        cutText ["", "BLACK IN", 1];
        
        // Interior camera with progressive movement
        private _intStartTime = time;
        private _intDuration = 15;
        
        while { time < _intStartTime + _intDuration } do {
            private _progress = (time - _intStartTime) / _intDuration;
            
            // Progressive movement forward
            private _yOffset = 1.7 + (_progress * 1.2); // From 1.7m to 2.9m forward
            private _xOffset = 0 - (_progress * 0.2); // Slight left drift
            private _zOffset = -0.5 + (sin(_progress * 180) * 0.08); // Subtle vertical oscillation
            
            private _relPos = [_xOffset, _yOffset, _zOffset];
            _cam attachTo [_heli, _relPos];
            _cam setVectorDirAndUp [[0, 1, 0.05], [0, 0, 1]];
            _cam camSetFov (0.85 - (_progress * 0.1)); // Slight zoom in
            
            sleep 0.05;
        };

        // --- SHOT 4: ORBITAL EXTERIOR VIEW (14s) ---
        // Dynamic orbital camera around helicopter
        detach _cam;
        
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        cutText ["", "BLACK IN", 1];
        
        private _orbStartTime = time;
        private _orbDuration = 14;
        private _orbitAngle = -90; // Start from left side
        
        while { time < _orbStartTime + _orbDuration } do {
            private _progress = (time - _orbStartTime) / _orbDuration;
            
            // Progressive rotation around helicopter (-90° to +45°)
            _orbitAngle = -90 + (_progress * 135);
            
            // Dynamic distance and height
            private _distance = 35 - (_progress * 10); // 35m to 25m (approaching)
            private _height = 12 + (sin(_progress * 180) * 3); // 9m to 15m (oscillating)
            
            // Calculate camera position in orbit
            private _heliPos = getPosATL _heli;
            private _heliDir = getDir _heli;
            private _finalAngle = _heliDir + _orbitAngle;
            
            private _camX = (_heliPos select 0) + (sin _finalAngle * _distance);
            private _camY = (_heliPos select 1) + (cos _finalAngle * _distance);
            private _camZ = (_heliPos select 2) + _height;
            
            // Target slightly ahead of helicopter for motion effect
            private _targetOffset = _heli modelToWorld [0, 3, 0];
            
            _cam camSetPos [_camX, _camY, _camZ];
            _cam camSetTarget _targetOffset;
            _cam camSetFov 0.75;
            _cam camCommit 0.4;
            
            sleep 0.05;
        };

        // --- SHOT 5: GROUND LANDING VIEW (Until touchdown) ---
        // Fixed ground camera watching helicopter land
        detach _cam;
        
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        
        // Position camera on ground near LZ
        private _destPos = getPosATL vehicles_spawner;
        private _groundCamPos = [
            (_destPos select 0) + 20,  // 20m to the side
            (_destPos select 1) - 15,  // 15m back
            (_destPos select 2) + 1.8  // 1.8m height (eye level)
        ];
        
        _cam camSetPos _groundCamPos;
        _cam camSetTarget _heli;
        _cam camSetFov 0.7;
        _cam camCommit 0;
        
        cutText ["", "BLACK IN", 1];
        
        // Follow helicopter until landing
        while { !isTouchingGround _heli && (getPos _heli select 2) > 1 } do {
            _cam camSetTarget (getPosASL _heli);
            _cam camCommit 0.3;
            sleep 0.1;
        };
        
        // Keep watching during disembark
        sleep 2;
        
        // Wait for player to exit
        waitUntil { vehicle player == player };
        
        sleep 2;

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

        // 100% UNLOCK INPUT
        disableUserInput false;
        disableUserInput true;
        disableUserInput false;

        cutText ["", "BLACK IN", 2];

        // Final Mission Start Text (Tailles augmentées)
        [
            format [
                "<t size='2.0' color='#ffffff' font='PuristaBold'>%1</t><br/>" +
                "<t size='1.3' color='#cccccc' font='PuristaLight'>%2</t>",
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

// --- SERVER SIDE ---
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

        // Fast Approach (SHOT 1+2: 14s)
        _heli doMove _destPos;
        _heli flyInHeight 150;
        _heli limitspeed 200;

        sleep 14; // Wait for HQ + City shots

        // Continue flight (SHOT 3: Interior 15s)
        sleep 15;

        // Approach for landing (SHOT 4: Orbital 14s)
        _heli limitspeed 120;
        
        sleep 14;

        // Final approach (SHOT 5: Ground view)
        waitUntil { (_heli distance2D _destPos) < 250 };
        
        _heli land "GET OUT";
        
        waitUntil { (getPos _heli) select 2 < 2 };
        
        sleep 1;
        _heli lock false; 
        _heli lockCargo false;
        
        // Eject players safely
        {
            if (isPlayer _x) then {
                moveOut _x;
                unassignVehicle _x;
                private _dir = getDir _heli;
                private _dist = 6;
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