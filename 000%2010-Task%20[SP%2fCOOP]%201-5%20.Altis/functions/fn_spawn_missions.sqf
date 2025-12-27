params [["_mode", ""], ["_args", []]];

// Variable globale pour stocker les tâches sélectionnées
if (isNil "MISSION_var_selected_tasks") then { MISSION_var_selected_tasks = []; };
if (isNil "MISSION_var_current_task_index") then { MISSION_var_current_task_index = 0; };

// ============================================================================
// INIT - Ajouter l'action au joueur quand il entre dans la zone
// ============================================================================
if (_mode == "INIT") exitWith {
    [] spawn {
        waitUntil {time > 0};
        
        player addAction [
            localize "STR_ACTION_MISSIONS",
            { ["OPEN"] call MISSION_fnc_spawn_missions; },
            [],
            1.5,
            true,
            true,
            "",
            "player inArea missions_request"
        ];
    };
};

// ============================================================================
// OPEN - Ouvrir le menu et remplir la liste
// ============================================================================
if (_mode == "OPEN") exitWith {
    createDialog "Refour_Missions_Dialog";
    
    private _listCtrl = (findDisplay 7777) displayCtrl 2200;
    
    // Remplir la liste avec 20 tâches
    for "_i" from 1 to 20 do {
        private _taskName = "";
        if (_i == 1) then {
            _taskName = format ["%1 - %2", localize "STR_MISSIONS_LIST_LABEL" select [0, 5], localize "STR_TASK_1_TITLE"];
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_1_TITLE"];
        } else {
            _taskName = format ["Tâche %1 - %2", _i, localize "STR_TASK_X_TITLE"];
        };
        
        private _index = _listCtrl lbAdd _taskName;
        _listCtrl lbSetData [_index, str _i];
        
        // Si déjà sélectionné, mettre en vert
        if (_i in MISSION_var_selected_tasks) then {
            _listCtrl lbSetColor [_index, [0.2, 0.8, 0.2, 1]];
        };
    };
    
    _listCtrl lbSetCurSel 0;
};

// ============================================================================
// SELECT - Quand on sélectionne une tâche dans la liste
// ============================================================================
if (_mode == "SELECT") exitWith {
    _args params ["_ctrl", "_selIndex"];
    
    private _taskNum = parseNumber (_ctrl lbData _selIndex);
    MISSION_var_current_task_index = _taskNum;
    
    private _titleCtrl = (findDisplay 7777) displayCtrl 2202;
    private _descCtrl = (findDisplay 7777) displayCtrl 2203;
    private _checkCtrl = (findDisplay 7777) displayCtrl 2201;
    
    // Afficher titre et description
    if (_taskNum == 1) then {
        _titleCtrl ctrlSetText (localize "STR_TASK_1_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_1_DESC");
    } else {
        _titleCtrl ctrlSetText (localize "STR_TASK_X_TITLE");
        _descCtrl ctrlSetText (localize "STR_TASK_X_DESC");
    };
    
    // Mettre à jour le bouton (couleur et texte selon sélection)
    if (_taskNum in MISSION_var_selected_tasks) then {
        _checkCtrl ctrlSetBackgroundColor [0.2, 0.6, 0.2, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_DESELECT");
    } else {
        _checkCtrl ctrlSetBackgroundColor [0.3, 0.3, 0.3, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_SELECT");
    };
};

// ============================================================================
// TOGGLE - Quand on clique sur la checkbox
// ============================================================================
if (_mode == "TOGGLE") exitWith {
    private _taskNum = MISSION_var_current_task_index;
    if (_taskNum == 0) exitWith {};
    
    private _checkCtrl = (findDisplay 7777) displayCtrl 2201;
    private _listCtrl = (findDisplay 7777) displayCtrl 2200;
    
    if (_taskNum in MISSION_var_selected_tasks) then {
        // Désélectionner
        MISSION_var_selected_tasks = MISSION_var_selected_tasks - [_taskNum];
        _checkCtrl ctrlSetBackgroundColor [0.3, 0.3, 0.3, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_SELECT");
        _listCtrl lbSetColor [_taskNum - 1, [1, 1, 1, 1]];
    } else {
        // Sélectionner
        MISSION_var_selected_tasks pushBack _taskNum;
        _checkCtrl ctrlSetBackgroundColor [0.2, 0.6, 0.2, 1];
        _checkCtrl ctrlSetText (localize "STR_BTN_DESELECT");
        _listCtrl lbSetColor [_taskNum - 1, [0.2, 0.8, 0.2, 1]];
    };
};

// ============================================================================
// LAUNCH - Lancer les missions sélectionnées
// ============================================================================
if (_mode == "LAUNCH") exitWith {
    closeDialog 0;
    
    if (count MISSION_var_selected_tasks == 0) exitWith {};
    
    // Lancer chaque tâche sélectionnée
    {
        switch (_x) do {
            case 1: {
                // Tâche 1 - Défense du QG
                [] call MISSION_fnc_task_1_launch;
            };
            // Tâches 2-20 : à implémenter plus tard
            default {};
        };
    } forEach MISSION_var_selected_tasks;
    
    // Réinitialiser les sélections
    MISSION_var_selected_tasks = [];
};
