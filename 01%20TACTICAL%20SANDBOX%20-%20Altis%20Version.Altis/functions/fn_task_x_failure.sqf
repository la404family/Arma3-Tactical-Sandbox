/*
    ====================================================================================================
    FONCTION : MISSION_fnc_task_x_failure
    ====================================================================================================
    Description : 
        Séquence de fin de mission (échec).
        Affiche une séquence cinématique avec musique et messages d'échec,
        puis termine la mission sur un échec.
    
    Séquence :
        1. Musique "00outro"
        2. "MISSION_FAILURE" (couleur #ffbb00ff) + 10 sec
        3. Pause (10 sec)
        4. "De nouvelles missions vous seront confiées prochainement...." (5 sec)
        5. "À bientôt sur..." (5 sec)
        6. Titre du jeu STR_INTRO_TITLE (10 sec)
        7. Fade noir (2 sec)
        8. Fin de mission (échec "LOSER")
    ====================================================================================================
*/

// Exécution uniquement sur les machines avec interface (joueurs)
if (hasInterface) then {
    [] spawn {
        // ==============================================================================================
        // MUSIQUE D'OUTRO
        // ==============================================================================================
        playMusic "00outro";
        sleep 10;
        
        // ==============================================================================================
        // MESSAGE 1 : MISSION ÉCHOUÉE (10 secondes)
        // ==============================================================================================
        titleText [
            format [
                "<t size='3.0' color='#ffbb00ff' font='PuristaBold' shadow='2'>%1</t><br/><br/>",
                localize "STR_FINISH_MISSION_FAILURE"
            ],
            "PLAIN", 3, true, true
        ];
        titleFadeOut 3;
        
        sleep 4;
        titleText ["", "PLAIN", 1];
        sleep 4;
        
        // ==============================================================================================
        // PAUSE (2 secondes)
        // ==============================================================================================
        sleep 4;
        
        // ==============================================================================================
        // MESSAGE 2 : NOUVELLES MISSIONS
        // ==============================================================================================
        titleText [
            format [
                "<t size='1.6' color='#ffffff' font='PuristaLight'>%1</t>",
                localize "STR_FINISH_NEW_MISSIONS"
            ],
            "PLAIN", 3, true, true
        ];
        
        sleep 4;
        titleText ["", "PLAIN", 1];
        sleep 4;
        
        // ==============================================================================================
        // MESSAGE 3 : À BIENTÔT SUR...
        // ==============================================================================================
        titleText [
            format [
                "<t size='1.6' color='#bbbbbb' font='PuristaLight'>%1</t>",
                localize "STR_FINISH_SEE_YOU"
            ],
            "PLAIN", 3, true, true
        ];
        
        sleep 4;
        titleText ["", "PLAIN", 1];
        sleep 4;
        
        // ==============================================================================================
        // MESSAGE 4 : TITRE DU JEU 
        // ==============================================================================================
        titleText [
            format [
                "<t size='3.5' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
                localize "STR_INTRO_TITLE"
            ],
            "PLAIN", 3, true, true
        ];
        
        sleep 4;
        titleText ["", "PLAIN", 2];
        sleep 4;
        
        // ==============================================================================================
        // FADE NOIR ET FIN
        // ==============================================================================================
        
        cutText ["", "BLACK FADED", 2];
        sleep 4;
        
        disableUserInput false;
        showCinemaBorder false;
        
        // ==============================================================================================
        // TERMINER LA MISSION SUR UN ÉCHEC
        // ==============================================================================================
        // "LOSER" = Debriefing d'échec
        ["LOSER", false] call BIS_fnc_endMission;
    };
};
