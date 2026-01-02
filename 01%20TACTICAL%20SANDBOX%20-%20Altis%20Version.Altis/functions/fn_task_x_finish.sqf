/*
    ====================================================================================================
    FONCTION : MISSION_fnc_task_x_finish
    ====================================================================================================
    Description : 
        Séquence de fin de mission (succès).
        Affiche une séquence cinématique avec musique et messages de félicitations,
        puis termine la mission sur un succès.
    
    Séquence :
        1. Musique "00outro"
        2. "MISSION ACCOMPLIE." + sous-titre (10 sec)
        3. Pause (10 sec)
        4. "De nouvelles missions vous seront confiées prochainement...." (5 sec)
        5. "À bientôt sur..." (5 sec)
        6. Titre du jeu STR_INTRO_TITLE (10 sec)
        7. Fade noir (2 sec)
        8. Fin de mission (succès)
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
        // MESSAGE 1 : MISSION ACCOMPLIE 
        // ==============================================================================================
        // Utilisation de titleText avec PLAIN pour un simple fade (pas de défilement)
        titleText [
            format [
                "<t size='3.0' color='#00ff00' font='PuristaBold' shadow='2'>%1</t><br/><br/>" +
                "<t size='1.3' color='#cccccc' font='PuristaLight'>%2</t>",
                localize "STR_FINISH_MISSION_SUCCESS",
                localize "STR_FINISH_CONGRATULATIONS"
            ],
            "PLAIN", 3, true, true // PLAIN = fade simple, 1 = fade rapide, true = afficher le texte, true = afficher le texte
        ];
        titleFadeOut 3;  // Prépare le fade out
        
        sleep 4;
        titleText ["", "PLAIN", 1];  // Estompe le texte
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
        titleText ["", "PLAIN", 2];  // Fade out plus long
        sleep 4;
        
        // ==============================================================================================
        // FADE NOIR ET FIN
        // ==============================================================================================
        
        // Fondu vers le noir
        cutText ["", "BLACK FADED", 2];
        sleep 4;
        
        // Restaurer les contrôles avant la fin
        disableUserInput false;
        showCinemaBorder false;
        
        // ==============================================================================================
        // TERMINER LA MISSION SUR UN SUCCÈS
        // ==============================================================================================
        // "END1" est l'identifiant de fin, true = succès (débriefing positif)
        ["END1", true] call BIS_fnc_endMission;
    };
};
