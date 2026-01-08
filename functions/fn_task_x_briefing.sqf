/*
    Copright 2026 - la404family
    
    Fonction: MISSION_fnc_task_x_briefing
    Description: 
    - Gère le système de briefing interactif dans la salle de conférence.
    - Ajoute une action au joueur via le trigger 'briefing_request'.
    - Permet aux joueurs de s'asseoir sur chaïse_0...chaïse_13.
    - Ordonne aux IA de s'asseoir sur les chaises libres.
    
    Paramètres: Aucun (appelé au démarrage)
*/

// On attend que le jeu soit chargé
waitUntil { !isNull player };

// ============================================================================
// 1. SETUP DES CHAISES (ACTIONS JOUEURS)
// ============================================================================
// On récupère toutes les chaises et on ajoute l'action "S'asseoir"
// Cette boucle doit s'exécuter sur chaque client.

for "_i" from 0 to 13 do {
    private _chair = missionNamespace getVariable [format ["chaise_%1", _i], objNull];
    
    if (!isNull _chair) then {
        // ACTION : S'ASSEOIR (Sur la chaise)
        _chair addAction [
            format ["<t color='#00FF00'>%1</t>", localize "STR_ACTION_SIT"],
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                
                // 1. Vérifier si quelqu'un est déjà dessus (joueur ou IA)
                private _nearUnits = (_target nearEntities ["Man", 0.5]) select { alive _x && _x != _caller };
                if (count _nearUnits > 0) exitWith { hint "Cette chaise est déjà occupée !"; };
                
                // 2. Animation s'asseoir
                _caller setDir (getDir _target - 180);
                _caller setPosATL (getPosATL _target);
                
                private _anims = ["HubSittingChairA_idle1", "HubSittingChairB_idle1", "HubSittingChairC_idle1"];
                [_caller, selectRandom _anims] remoteExec ["switchMove", 0];
                
                // 3. Variables d'état
                _caller setVariable ["isSitting", true, true];
                _target setVariable ["isOccupied", true, true]; // Marqueur pour les IA
                
                // 4. Ajouter l'action SE LEVER au JOUEUR lui-même (et non à la chaise)
                // Cela garantit qu'il peut toujours l'utiliser peu importe où il regarde
                private _idStand = _caller addAction [
                    format ["<t color='#FFFF00'>%1</t>", localize "STR_ACTION_STAND"],
                    {
                        params ["_target", "_caller", "_actionId", "_arguments"];
                        _arguments params ["_chair"]; // On récupère la chaise passée en argument
                        
                        // Reset anim
                        [_caller, ""] remoteExec ["switchMove", 0];
                        
                        // Position debout un peu devant
                        _caller setPosATL ((getPosATL _chair) vectorAdd [0, 0.5, 0]); 
                        
                        // Reset variables
                        _caller setVariable ["isSitting", false, true];
                        _chair setVariable ["isOccupied", false, true];
                        
                        // Supprimer l'action "Se lever" du joueur
                        _caller removeAction _actionId;
                    },
                    [_target], // Arguments: La chaise sur laquelle on est assis
                    10,
                    true,
                    true,
                    "",
                    "true" // Toujours visible pour le joueur tant qu'il a l'action
                ];
            },
            nil,
            1.5,
            true,
            true,
            "",
            "(!(_this getVariable ['isSitting', false])) && (_this distance _target < 2) && (isNull (objectParent _this))" // Condition: Pas assis, proche
        ];
    };
};


// ============================================================================
// 2. GESTION DU BRIEFING (TRIGGER & IA)
// ============================================================================

// Trigger objet
private _trigger = missionNamespace getVariable ["briefing_request", objNull];

// Sécurité : Si le trigger n'existe pas, on arrête
if (isNull _trigger) exitWith {
    diag_log "ERREUR: Trigger 'briefing_request' introuvable pour MISSION_fnc_task_x_briefing";
};

// Variable locale pour suivre l'état du briefing
player setVariable ["isBriefingActive", false];

// Fonction locale pour faire asseoir les IA
MISSION_fnc_sitDownAI = {
    // 1. Trouver les chaises disponibles
    private _chairs = [];
    for "_i" from 0 to 13 do {
        private _chair = missionNamespace getVariable [format ["chaise_%1", _i], objNull];
        if (!isNull _chair) then {
            _chairs pushBack _chair;
        };
    };
    
    // Le tableau des tâches (pour regarder)
    private _tableau = missionNamespace getVariable ["tableau_des_taches", objNull];
    
    // 2. Sélectionner les unités du groupe du joueur (IA seulement)
    private _groupUnits = units group player;
    private _aiUnits = _groupUnits select { !isPlayer _x && alive _x };
    
    if (count _aiUnits == 0) exitWith { hint (localize "STR_BRIEFING_NO_AI"); };
    
    // 3. Assigner les positions
    {
        private _unit = _x;
        
        // Pause pour éviter que tout le monde bouge en même temps (embouteillage)
        sleep 0.5;
        
        // Configuration comportementale pour qu'ils obéissent
        _unit setBehaviour "SAFE";
        _unit setCombatMode "BLUE";
        _unit disableAI "AUTOTARGET";
        _unit disableAI "TARGET";
        _unit disableAI "WEAPONAIM";
        _unit disableAI "SUPPRESSION";
        
        // Trouver une chaise LIBRE
        private _assignedChair = objNull;
        
        // On cherche la première chaise NON occupée par un joueur ou une IA
        {
            private _c = _x;
            // Check via variable (fiable si setVariable utilisé) OU via proximité (sécurité)
            private _isOccupiedVar = _c getVariable ["isOccupied", false];
            private _isOccupiedPhys = (count ((getPosATL _c) nearEntities ["Man", 0.5]) > 0);
            
            if (!_isOccupiedVar && !_isOccupiedPhys) then {
                _assignedChair = _c;
                // On la marque occupée tout de suite pour que la prochaine IA ne la prenne pas
                _assignedChair setVariable ["isOccupied", true, true]; 
                break; // On sort de la boucle chaises
            };
        } forEach _chairs;
        
        
        if (!isNull _assignedChair) then {
            // -- TENTATIVE D'ASSEOIR SUR CHAISE --
            
            // On ordonne le mouvement vers la chaise
            _unit doMove (getPosATL _assignedChair);
            
            // Thread de surveillance individuel
            [_unit, _assignedChair, _tableau] spawn {
                params ["_unit", "_chair", "_tableau"];
                
                private _timeout = time + 20; // 20 secondes pour atteindre la chaise
                private _seated = false;
                
                waitUntil {
                    sleep 1;
                    // Condition de succès : proche de la chaise (< 1.8m)
                    if (_unit distance2D _chair < 1.8) then {
                        // On affine la position pour l'anim
                        _unit setDir (getDir _chair - 180);
                        _unit setPosATL (getPosATL _chair);
                        
                        private _anims = ["HubSittingChairA_idle1", "HubSittingChairB_idle1", "HubSittingChairC_idle1"];
                        _unit switchMove (selectRandom _anims);
                        
                        _unit disableAI "ANIM";
                        _unit disableAI "MOVE";
                        _seated = true;
                    };
                    
                    (_seated) || (time > _timeout) || (!alive _unit)
                };
                
                // Si ECHEC (Timeout & pas assis) -> Direction Tableau
                if (!_seated && alive _unit && !isNull _tableau) then {
                    // Libérer la chaise si on n'a pas pu s'asseoir
                    _chair setVariable ["isOccupied", false, true];
                    
                    _unit doWatch _tableau;
                    sleep 1;
                    if (alive _unit) then { _unit setDir (_unit getDir _tableau); };
                };
            };
            
        } else {
            // -- PAS DE CHAISE DISPO -> RESTE DEBOUT ET REGARDE LE TABLEAU --
            if (!isNull _tableau) then {
                _unit doWatch _tableau;
                sleep 0.5;
                if (alive _unit) then { _unit setDir (_unit getDir _tableau); };
            };
        };
        
    } forEach _aiUnits;
    
    hint (localize "STR_ACTION_ORGANIZE_BRIEFING");
};

// Fonction locale pour terminer le briefing (se lever)
MISSION_fnc_standUpAI = {
    private _groupUnits = units group player;
    private _aiUnits = _groupUnits select { !isPlayer _x };
    
    // Reset de toutes les chaises occupées par des IA (clean global)
    // On pourrait être plus précis, mais un reset global des chaises IA est safe.
    for "_i" from 0 to 13 do {
        private _c = missionNamespace getVariable [format ["chaise_%1", _i], objNull];
        // On ne reset PAS si un joueur est dessus (distance check)
        if (!isNull _c) then {
            private _playerOnIt = (count ((getPosATL _c) nearEntities ["Man", 0.5] select {isPlayer _x}) > 0);
            if (!_playerOnIt) then {
               _c setVariable ["isOccupied", false, true];
            };
        };
    };

    {
        if (alive _x) then {
            _x enableAI "ANIM";
            _x enableAI "MOVE";
            _x switchMove ""; // Reset anim (se lève)
            
            sleep 0.5;
            
            _x enableAI "AUTOTARGET";
            _x enableAI "TARGET";
            _x enableAI "WEAPONAIM";
            _x setBehaviour "AWARE";
            _x setCombatMode "YELLOW";
            
            _x doFollow player; // Revenir en formation
        };
    } forEach _aiUnits;
    
    hint (localize "STR_ACTION_END_BRIEFING");
};

// ============================================================================
// AJOUT DE L'ACTION AU JOUEUR VIA TRIGGER
// ============================================================================
// L'action n'est visible que si le joueur est DANS la zone du trigger
// et s'il est CHEF DE GROUPE.

private _condition = "player inArea briefing_request && (leader group player == player)";

// Action: Organiser le briefing
player addAction [
    format ["<t color='#FFFF00'>%1</t>", localize "STR_ACTION_ORGANIZE_BRIEFING"], 
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        
        // Vérification redondante Leader (pour message erreur)
        if (leader group player != player) exitWith {
            hint (localize "STR_ONLY_GROUP_LEADER");
        };
        
        // Marquer le briefing comme actif
        player setVariable ["isBriefingActive", true];
        
        // Exécuter la logique
        call MISSION_fnc_sitDownAI;
    },
    [],
    10, 
    true, 
    true, 
    "",
    "player inArea briefing_request && (leader group player == player) && !(player getVariable ['isBriefingActive', false])"
];

// Action: Terminer le briefing (visible seulement si actif)
player addAction [
    format ["<t color='#FF0000'>%1</t>", localize "STR_ACTION_END_BRIEFING"], 
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        
        player setVariable ["isBriefingActive", false];
        call MISSION_fnc_standUpAI;
    },
    [],
    10, 
    true, 
    true, 
    "",
    "player inArea briefing_request && (player getVariable ['isBriefingActive', false])"
];

// Message pour non-leaders dans la zone (optionnel, pour feedback)
player addAction [
    format ["<t color='#AAAAAA'>%1</t>", localize "STR_ACTION_ORGANIZE_BRIEFING"], 
    { hint (localize "STR_ONLY_GROUP_LEADER"); },
    [],
    9, 
    false, 
    true, 
    "",
    "player inArea briefing_request && (leader group player != player)"
];
