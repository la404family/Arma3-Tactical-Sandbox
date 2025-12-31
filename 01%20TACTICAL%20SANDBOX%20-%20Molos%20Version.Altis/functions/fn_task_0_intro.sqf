/*
    ====================================================================================================
    FONCTION : MISSION_fnc_task_0_intro
    ====================================================================================================
    Description : 
        Introduction Cinématique V2 - Système de Caméra Avancé
        Cette fonction gère l'introduction immersive de la mission avec une séquence cinématique
        complète composée de 5 plans différents, synchronisée avec le vol d'un hélicoptère
        transportant les joueurs vers la zone de mission.
    
    Caractéristiques :
        - Gestion robuste des entrées utilisateur (avec sécurité anti-blocage)
        - Plans dynamiques : QG -> Survol Ville -> Intérieur Hélico -> Vue Orbitale -> Atterrissage
        - Points de référence : batiment_officer, task_5_spawn_15, task_1_spawn_06
        - Améliorations : Transitions fluides, animations FOV subtiles, post-processing par plan,
          boucles raffinées pour un mouvement fluide, léger balancement de caméra pour réalisme
    
    Structure :
        - Partie CLIENT (hasInterface) : Gère la caméra cinématique, les effets visuels et textes
        - Partie SERVEUR (isServer) : Gère le spawn et le vol de l'hélicoptère
    ====================================================================================================
*/

// ==================================================================================================
// PARTIE CLIENT - Exécution uniquement sur les machines avec interface graphique (joueurs)
// ==================================================================================================
if (hasInterface) then {
    [] spawn {
        // ==============================================================================================
        // SECTION 1 : INITIALISATION ET SECURITE
        // ==============================================================================================
        
        // Nécessaire pour manipuler les éléments d'interface utilisateur (UI)
        disableSerialization;
        
        // ----------------------------------------------------------------------------------------------
        // SECURITE ANTI-BLOCAGE (Failsafe)
        // ----------------------------------------------------------------------------------------------
        // Ce thread parallèle garantit que les contrôles du joueur seront TOUJOURS restaurés
        // après 90 secondes, même si le script principal plante ou se bloque.
        // C'est une protection essentielle pour éviter que le joueur reste bloqué.
        [] spawn {
            sleep 90;  // Durée maximale de la cinématique
            
            // Triple appel pour forcer la réinitialisation des contrôles
            // (technique Arma 3 pour garantir le déblocage)
            disableUserInput false;
            disableUserInput true;
            disableUserInput false;
            
            // Restauration de l'état normal du joueur
            player allowDamage true;       // Le joueur peut à nouveau subir des dégâts
            showCinemaBorder false;        // Masque les bandes noires cinématiques
        };

        // ----------------------------------------------------------------------------------------------
        // ÉTAT INITIAL DE LA CINEMATIQUE
        // ----------------------------------------------------------------------------------------------
        cutText ["", "BLACK FADED", 999];  // Écran noir total (fondu instantané)
        0 fadeSound 0;                      // Coupe le son immédiatement (volume à 0 en 0 sec)
        showCinemaBorder true;              // Affiche les bandes noires cinématiques (style film)
        disableUserInput true;              // Bloque tous les contrôles du joueur
        
        // Attendre que l'objet joueur soit initialisé (sécurité multijoueur)
        waitUntil { !isNull player };
        player allowDamage false;           // Rend le joueur invulnérable pendant l'intro

        // ==============================================================================================
        // SECTION 2 : EFFETS DE POST-PROCESSING (PP)
        // ==============================================================================================
        // Les effets PP modifient le rendu final de l'image pour créer une atmosphère cinématique
        
        // ----------------------------------------------------------------------------------------------
        // EFFET DE CORRECTION COULEUR (ColorCorrections)
        // ----------------------------------------------------------------------------------------------
        // Paramètres : [intensité, luminosité, contraste, [mélange couleur ombres], 
        //              [mélange couleur hauts], [mélange couleur moyens]]
        private _ppColor = ppEffectCreate ["ColorCorrections", 1500];  // Priorité 1500
        _ppColor ppEffectEnable true;
        _ppColor ppEffectAdjust [
            1,                    // Intensité globale (1 = 100%)
            1.0,                  // Luminosité
            -0.05,                // Contraste (légèrement réduit pour un look cinéma)
            [0.2, 0.2, 0.2, 0.0], // Teinte des ombres (gris neutre)
            [0.8, 0.8, 0.9, 0.7], // Teinte des hautes lumières (léger bleu)
            [0.1, 0.1, 0.2, 0]    // Teinte des tons moyens
        ]; 
        _ppColor ppEffectCommit 0;  // Application immédiate (0 seconde de transition)

        // ----------------------------------------------------------------------------------------------
        // EFFET DE GRAIN DE FILM (FilmGrain)
        // ----------------------------------------------------------------------------------------------
        // Ajoute un grain subtil à l'image pour simuler une caméra de cinéma
        // Paramètres : [intensité, netteté, tailleGrain, intensitéRGB, monochromatique]
        private _ppGrain = ppEffectCreate ["FilmGrain", 2005];  // Priorité 2005
        _ppGrain ppEffectEnable true;
        _ppGrain ppEffectAdjust [0.1, 1, 1, 0.1, 1, false];  // Grain léger, couleur
        _ppGrain ppEffectCommit 0;

        // ==============================================================================================
        // SECTION 3 : DEFINITION DES CIBLES DE CAMERA
        // ==============================================================================================
        // Ces objets servent de points de référence pour les mouvements de caméra.
        // Si un objet n'existe pas, on utilise un fallback (joueur ou autre cible)
        
        // Cible 1 : Quartier Général Allié (pour le Plan 1)
        private _targetHQ = if (!isNil "batiment_officer") then { batiment_officer } else { player };
        
        // Cible 2 : Centre de la ville (pour le Plan 2 - départ)
        private _targetCityMid = if (!isNil "task_3_spawn_12") then { task_3_spawn_12 } else { _targetHQ };
        
        // Cible 3 : Fin de la ville (pour le Plan 2 - arrivée)
        private _targetCityEnd = if (!isNil "task_2_spawn_17") then { task_2_spawn_17 } else { _targetHQ };

        // ==============================================================================================
        // SECTION 4 : MUSIQUE D'INTRODUCTION
        // ==============================================================================================
        playMusic "00intro";   // Démarre la musique d'intro (définie dans description.ext)
        3 fadeSound 1;         // Remonte le volume à 100% en 3 secondes (fondu audio progressif)

        // ##############################################################################################
        // PLAN 1 : VUE AERIENNE DU QG ALLIE (8 secondes)
        // ##############################################################################################
        // Description : Vue plongeante avec panoramique lent au-dessus du quartier général.
        //               Effet de dézoom progressif pour une sensation épique.
        
        private _posHQ = getPos _targetHQ;  // Position 3D du QG
        
        // Création de la caméra cinématique
        // camCreate [type, position] - Crée une caméra à la position spécifiée
        private _cam = "camera" camCreate [_posHQ select 0, _posHQ select 1, 100];
        
        // Active la caméra et la lie au rendu principal
        // "INTERNAL" = vue première personne de la caméra, "BACK" = canal de rendu principal
        _cam cameraEffect ["INTERNAL", "BACK"];
        
        // Position initiale : décalée de 80m sur X, -80m sur Y, à 60m de hauteur
        _cam camSetPos [(_posHQ select 0) + 80, (_posHQ select 1) - 80, 60];
        _cam camSetTarget _targetHQ;  // La caméra vise le QG
        _cam camSetFov 0.6;           // Champ de vision réduit (zoom avant) - valeur normale = 0.74
        _cam camCommit 0;             // Application immédiate des paramètres
        
        // ----------------------------------------------------------------------------------------------
        // TEXTE : AUTEUR ET "PRÉSENTE"
        // ----------------------------------------------------------------------------------------------
        // BIS_fnc_dynamicText affiche du texte formaté avec des effets de fondu
        // Paramètres : [texte, posX, posY, durée, fonduIn, fonduOut, calque]
        [
            format [
                "<t size='1.6' color='#bbbbbb' font='PuristaMedium'>%1</t><br />" +  // Nom auteur
                "<t size='1.2' color='#a0a0a0' font='PuristaLight'>%2</t>",          // "Présente"
                localize "STR_INTRO_AUTHOR",    // Texte localisé depuis stringtable.xml
                localize "STR_INTRO_PRESENTS"
            ],
            safeZoneX + 0.1,                    // Position X : coin gauche + marge
            safeZoneY + safeZoneH - 0.3,        // Position Y : bas de l'écran
            6,                                   // Durée d'affichage : 6 secondes
            1,                                   // Durée du fondu d'entrée : 1 seconde
            0,                                   // Durée du fondu de sortie : 0 seconde
            789                                  // ID du calque (pour éviter les conflits)
        ] spawn BIS_fnc_dynamicText;

        sleep 6;  // Attendre la fin du Plan 1

        // ----------------------------------------------------------------------------------------------
        // TRANSITION ENTRE PLANS 1 ET 2
        // ----------------------------------------------------------------------------------------------
        cutText ["", "BLACK FADED", 0.5];  // Fondu vers le noir en 0.5s
        sleep 0.8;
        cutText ["", "BLACK IN", 1];       // Fondu depuis le noir en 1s

        [
            format [
                "<t size='3.0' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
                localize "STR_INTRO_TITLE"  // Titre principal de la mission
            ],
            -1,      // Position X centrée (-1 = auto-centrage)
            -1,      // Position Y centrée
            5,       // Durée : 5 secondes
            1,       // Fondu entrée : 1 seconde
            0,       // Fondu sortie : 0 seconde
            790      // ID calque
        ] spawn BIS_fnc_dynamicText;

        sleep 5;

        // ##############################################################################################
        // PLAN 3 : VUE INTERIEURE DE L'HELICOPTERE (15 secondes)
        // ##############################################################################################
        cutText ["", "BLACK FADED", 0.5];  // Fondu vers le noir en 0.5s
        sleep 0.8;
        cutText ["", "BLACK IN", 1];       // Fondu depuis le noir en 1s
        // Description : Caméra à l'intérieur de l'hélicoptère regardant vers l'arrière (cargo).
        //               Mouvement progressif avec balancement subtil pour le réalisme.
        
        // Attendre que le joueur soit bien à bord de l'hélicoptère
        waitUntil { vehicle player != player };
        private _heli = vehicle player;  // Référence à l'hélicoptère

        // Détacher la caméra de toute attache précédente
        detach _cam;
        
        // Transition visuelle
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;

        // ----------------------------------------------------------------------------------------------
        // TEXTE : SOUS-TITRE
        // ----------------------------------------------------------------------------------------------
        [
            format [
                "<t size='1.4' color='#dddddd' font='PuristaLight'>%1</t>",
                localize "STR_INTRO_SUBTITLE"
            ],
            -1, 
            safeZoneY + safeZoneH - 0.2,  // Bas de l'écran
            6, 
            1, 
            0, 
            791
        ] spawn BIS_fnc_dynamicText;

        cutText ["", "BLACK IN", 1];
        
        // ----------------------------------------------------------------------------------------------
        // AJUSTEMENT PP POUR L'INTERIEUR : Plus sombre, plus contrasté
        // ----------------------------------------------------------------------------------------------
        _ppColor ppEffectAdjust [0.9, 1.2, -0.1, [0.3, 0.3, 0.3, 0.1], [0.7, 0.7, 0.8, 0.6], [0.2, 0.2, 0.3, 0.1]]; 
        _ppColor ppEffectCommit 1;
        // Augmentation du grain pour une atmosphère plus immersive
        _ppGrain ppEffectAdjust [0.15, 1.2, 1.2, 0.15, 1.2, false];
        _ppGrain ppEffectCommit 1;

        // ----------------------------------------------------------------------------------------------
        // CAMERA FIXE INTERIEURE
        // ----------------------------------------------------------------------------------------------
        // Position fixe au fond de l'hélicoptère (cargo arrière), regardant vers l'avant (cockpit)
        // Pour le CH-67 Huron (B_Heli_Transport_03_F), ces valeurs placent la caméra au fond du cargo
        
        // Position relative par rapport au centre de l'hélicoptère :
        // X = 0 : centré latéralement
        // Y = -3 : 3 mètres vers l'arrière (fond du cargo)
        // Z = -0.5 : légèrement sous le niveau des sièges pour une vue immersive
        private _fixedPos = [0, -3, -0.5];
        
        // Attacher la caméra à l'hélicoptère (elle suivra ses mouvements automatiquement)
        _cam attachTo [_heli, _fixedPos];
        
        // Orientation : regarder vers l'AVANT de l'hélicoptère (vers le cockpit)
        // [0, 1, 0] = Direction positive sur l'axe Y (avant de l'hélico)
        // [0, 0, 1] = Vecteur "haut" standard (axe Z vers le haut)
        _cam setVectorDirAndUp [[0, 1, 0], [0, 0, 1]];
        
        // Champ de vision légèrement large pour voir l'intérieur du cargo
        _cam camSetFov 0.9;
        _cam camCommit 0;
        
        // Attendre la durée du plan (15 secondes)
        sleep 15;

        // ##############################################################################################
        // PLAN 4 : VUE ORBITALE EXTERIEURE (14 secondes)
        // ##############################################################################################
        // Description : La caméra orbite autour de l'hélicoptère en vol, offrant une vue 
        //               spectaculaire de l'appareil et du paysage. Rotation fluide avec easing.
        
        detach _cam;  // Détacher la caméra de l'hélicoptère
        
        // Transition visuelle
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        cutText ["", "BLACK IN", 1];
        
        // ----------------------------------------------------------------------------------------------
        // REINITIALISATION PP POUR L'EXTERIEUR : Plus lumineux, moins de grain
        // ----------------------------------------------------------------------------------------------
        _ppColor ppEffectAdjust [1, 1.0, -0.05, [0.2, 0.2, 0.2, 0.0], [0.8, 0.8, 0.9, 0.7], [0.1, 0.1, 0.2, 0]]; 
        _ppColor ppEffectCommit 1;
        _ppGrain ppEffectAdjust [0.05, 0.8, 0.8, 0.05, 0.8, false];
        _ppGrain ppEffectCommit 1;
        
        // Variables de timing pour l'orbite
        private _orbStartTime = time;
        private _orbDuration = 14;
        private _orbitAngle = -90;  // Angle initial : côté gauche de l'hélico
        
        while { time < _orbStartTime + _orbDuration } do {
            private _progress = (time - _orbStartTime) / _orbDuration;
            
            // -----------------------------------------------------------------------------------------
            // CALCUL DE L'ANGLE D'ORBITE AVEC EASING
            // -----------------------------------------------------------------------------------------
            // Rotation de -90° à +45° (total 135°) avec fonction sinus pour un mouvement fluide
            // sin(_progress * 90) crée une accélération douce au début et décélération à la fin
            _orbitAngle = -90 + (sin(_progress * 90) * 135);
            
            // -----------------------------------------------------------------------------------------
            // DISTANCE ET HAUTEUR DYNAMIQUES
            // -----------------------------------------------------------------------------------------
            // Distance : de 35m à 25m (rapprochement progressif avec easing)
            private _distance = 35 - (sin(_progress * 90) * 10);
            
            // Hauteur : oscillation entre 9m et 15m (mouvement de vague)
            private _height = 12 + (sin(_progress * 180) * 3);
            
            // -----------------------------------------------------------------------------------------
            // CALCUL DE LA POSITION ORBITALE
            // -----------------------------------------------------------------------------------------
            private _heliPos = getPosATL _heli;       // Position actuelle de l'hélico
            private _heliDir = getDir _heli;           // Direction de l'hélico (cap)
            private _finalAngle = _heliDir + _orbitAngle;  // Angle absolu de la caméra
            
            // Conversion polaire -> cartésienne pour la position de la caméra
            private _camX = (_heliPos select 0) + (sin _finalAngle * _distance);
            private _camY = (_heliPos select 1) + (cos _finalAngle * _distance);
            private _camZ = (_heliPos select 2) + _height;
            
            // -----------------------------------------------------------------------------------------
            // CIBLE DECALEE POUR EFFET DE MOUVEMENT
            // -----------------------------------------------------------------------------------------
            // La caméra vise légèrement devant l'hélico pour donner une sensation de vitesse
            // modelToWorld convertit des coordonnées locales (relatives à l'hélico) en coordonnées monde
            private _targetOffset = _heli modelToWorld [0, 3, 0];  // 3m devant l'hélico
            
            // Application de la position et de la cible
            _cam camSetPos [_camX, _camY, _camZ];
            _cam camSetTarget _targetOffset;
            _cam camSetFov 0.75;
            _cam camCommit 0.2;  // Commit court pour fluidité
            
            sleep 0.03;  // Haute fréquence de mise à jour
        };

        // ##############################################################################################
        // PLAN 5 : VUE AERIENNE PLONGEANTE SUR LE QG (durée variable)
        // ##############################################################################################
        // Description : Caméra fixe haute dans les airs, regardant vers le bas sur QG_Center.
        //               On voit l'hélicoptère arriver et atterrir dans le champ de vision.
        //               Ouverture de la rampe pendant l'approche finale.
        //               Fondu au noir jusqu'à ce que le joueur reprenne le contrôle.
        
        detach _cam;
        
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        
        // ----------------------------------------------------------------------------------------------
        // POSITIONNEMENT DE LA CAMERA - VUE PLONGEANTE SUR QG_CENTER
        // ----------------------------------------------------------------------------------------------
        
        // Récupération de la position du QG (variable de l'éditeur)
        private _qgPos = if (!isNil "QG_Center") then { getPos QG_Center } else { getPos vehicles_spawner };
        
        // Position de la caméra : DIRECTEMENT au-dessus du QG, haute altitude
        // On se décale légèrement pour avoir un angle plus cinématique
        private _aerialCamPos = [
            (_qgPos select 0),        // Centré sur le QG (axe X)
            (_qgPos select 1) - 30,   // 30m en arrière pour voir l'arrivée
            (_qgPos select 2) + 60    // 60m de hauteur (vue plongeante)
        ];
        
        _cam camSetPos _aerialCamPos;
        
        // CIBLER LE QG (pas l'hélicoptère) - Vue fixe sur le QG
        _cam camSetTarget _qgPos;
        _cam camSetFov 0.55;  // FOV large pour voir toute la zone
        _cam camCommit 0;
        
        // Forcer une mise à jour immédiate
        waitUntil { camCommitted _cam };
        
        cutText ["", "BLACK IN", 1];
        
        // Variable pour tracker si la rampe a été ouverte
        private _rampOpened = false;
        
        // ----------------------------------------------------------------------------------------------
        // BOUCLE D'ATTENTE AVEC OUVERTURE DE RAMPE
        // ----------------------------------------------------------------------------------------------
        // La caméra reste fixe sur le QG, on attend juste l'atterrissage
        // L'hélicoptère entre dans le champ de vision naturellement
        
        while { !isTouchingGround _heli && (getPos _heli select 2) > 1 } do {
            
            // La caméra reste fixe - pas besoin de mise à jour de cible
            // Elle vise toujours QG_Center
            
            // -----------------------------------------------------------------------------------------
            // OUVERTURE DE LA RAMPE ARRIERE
            // -----------------------------------------------------------------------------------------
            if (!_rampOpened && (getPos _heli select 2) < 30) then {
                // Animation de la rampe arrière (plusieurs noms selon le type d'hélico)
                _heli animateDoor ["door_back", 1];
                _heli animateDoor ["door_back_ramp", 1];
                _heli animateDoor ["ramp", 1];
                _heli animateDoor ["ramp_door", 1];
                _heli animateDoor ["CargoRamp_Open", 1];  // Nom pour certains hélicos
                
                _rampOpened = true;
            };
            
            sleep 0.2;  // Pas besoin d'update fréquent car caméra fixe
        };
        
        // Courte pause pour voir l'atterrissage complet
        sleep 2;
        
        // ----------------------------------------------------------------------------------------------
        // FONDU FINAL ET ATTENTE DU JOUEUR
        // ----------------------------------------------------------------------------------------------
        cutText ["", "BLACK FADED", 1.5];
        
        // Attendre que le joueur sorte de l'hélicoptère
        waitUntil { vehicle player == player };
        
        sleep 1;

        // ##############################################################################################
        // FIN DE LA CINEMATIQUE : NETTOYAGE ET RESTAURATION
        // ##############################################################################################
        
        // Fondu final vers le noir
        cutText ["", "BLACK FADED", 1];
        sleep 1;

        // ----------------------------------------------------------------------------------------------
        // NETTOYAGE DES OBJETS CINEMATIQUES
        // ----------------------------------------------------------------------------------------------
        _cam cameraEffect ["TERMINATE", "BACK"];  // Désactive l'effet caméra
        camDestroy _cam;                          // Détruit l'objet caméra
        ppEffectDestroy _ppColor;                 // Supprime l'effet de correction couleur
        ppEffectDestroy _ppGrain;                 // Supprime l'effet de grain
        
        // ----------------------------------------------------------------------------------------------
        // RESTAURATION DU JOUEUR
        // ----------------------------------------------------------------------------------------------
        player switchCamera "INTERNAL";  // Retour à la vue première personne
        showCinemaBorder false;          // Masque les bandes noires
        player allowDamage true;         // Le joueur peut à nouveau subir des dégâts

        // DEBLOCAGE COMPLET DES CONTROLES
        // Triple appel pour garantir le déblocage (technique Arma 3)
        disableUserInput false;
        disableUserInput true;
        disableUserInput false;

        // Fondu depuis le noir vers le jeu normal
        cutText ["", "BLACK IN", 2];

        // ----------------------------------------------------------------------------------------------
        // TEXTE FINAL : DEBUT DE MISSION
        // ----------------------------------------------------------------------------------------------
        [
            format [
                "<t size='2.0' color='#ffffff' font='PuristaBold'>%1</t><br/>" +
                "<t size='1.3' color='#cccccc' font='PuristaLight'>%2</t>",
                localize "STR_MISSION_START",          // "Mission commencée" ou équivalent
                localize "STR_MISSION_START_SUBTITLE"  // Sous-titre
            ],
            -1,   // Centré X
            -1,   // Centré Y
            5,    // Durée : 5 secondes
            1,    // Fondu entrée
            0,    // Fondu sortie
            793   // ID calque
        ] spawn BIS_fnc_dynamicText;
        
        // Signale à tous les clients et au serveur que l'intro est terminée
        missionNamespace setVariable ["MISSION_intro_finished", true, true];
    };
};

// ==================================================================================================
// PARTIE SERVEUR - Gestion du vol de l'hélicoptère d'introduction
// ==================================================================================================
// Cette partie ne s'exécute QUE sur le serveur. Elle gère :
// - La création de l'hélicoptère et de son équipage
// - Le chargement des joueurs à bord
// - Le pilotage automatique vers la zone de mission
// - L'atterrissage et le débarquement des joueurs
// - Le départ et la suppression de l'hélicoptère

if (isServer) then {
    [] spawn {
        // Attendre que les données de configuration soient chargées
        waitUntil {!isNil "MISSION_var_helicopters" };   // Liste des hélicoptères disponibles
        waitUntil {!isNil "MISSION_var_model_player" };   // Modèle du joueur (pour les équipements)

        // ----------------------------------------------------------------------------------------------
        // RECUPERATION DES DONNEES DE L'HELICOPTERE
        // ----------------------------------------------------------------------------------------------
        // Recherche de l'hélicoptère marqué "task_x_helicoptere" dans la liste des hélicoptères
        private _heliData = [];
        { 
            if ((_x select 0) == "task_x_helicoptere") exitWith { _heliData = _x; }; 
        } forEach MISSION_var_helicopters;
        
        // Si aucun hélicoptère configuré, on skip l'intro et on marque comme terminée
        if (count _heliData == 0) exitWith { 
            missionNamespace setVariable ["MISSION_intro_finished", true, true];
        };

        // ----------------------------------------------------------------------------------------------
        // CALCUL DES POSITIONS DE DEPART ET D'ARRIVEE
        // ----------------------------------------------------------------------------------------------
        private _destPos = getPosATL vehicles_spawner;  // Position de la zone d'atterrissage
        
        // Position de départ : 1500m de distance, direction aléatoire, à 200m d'altitude
        private _startDist = 1500; 
        private _startDir = random 360;  // Direction aléatoire (pour varier les entrées)
        private _startPos = vehicles_spawner getPos [_startDist, _startDir];
        _startPos set [2, 200];  // Force l'altitude à 200m

        // ----------------------------------------------------------------------------------------------
        // CREATION DE L'HELICOPTERE
        // ----------------------------------------------------------------------------------------------
        private _heliClass = _heliData select 1;  // Classe de l'hélicoptère (ex: "B_Heli_Transport_01_F")
        
        // Création en mode vol
        private _heli = createVehicle [_heliClass, _startPos, [], 0, "FLY"];
        _heli setPos _startPos;
        _heli setDir (_heli getDir _destPos);  // Orienter vers la destination
        _heli flyInHeight 150;                  // Altitude de croisière
        _heli lock true;                        // Véhicule verrouillé (pas d'entrée/sortie libre)
        _heli lockCargo true;                   // Cargo verrouillé également
        _heli allowDamage false;                // Invulnérable pendant l'intro

        // ----------------------------------------------------------------------------------------------
        // CREATION ET CONFIGURATION DE L'EQUIPAGE
        // ----------------------------------------------------------------------------------------------
        createVehicleCrew _heli;  // Crée automatiquement pilote et copilote
        private _crew = crew _heli;
        { _x allowDamage false; } forEach _crew;  // Équipage invulnérable
        
        // Application de l'équipement du modèle joueur à l'équipage (pour cohérence visuelle)
        private _modelPlayerData = [];
        { if ((_x select 0) == "model_player") exitWith { _modelPlayerData = _x; }; } forEach MISSION_var_model_player;
        
        if (count _modelPlayerData > 0) then {
            { _x setUnitLoadout (_modelPlayerData select 5); } forEach _crew;
        };
        
        // Configuration du comportement du groupe hélico
        private _grpHeli = group driver _heli;
        _grpHeli setBehaviour "CARELESS";  // Ignore les menaces (pas d'esquive)
        _grpHeli setCombatMode "BLUE";     // Ne jamais engager (mode passif total)

        // ----------------------------------------------------------------------------------------------
        // EMBARQUEMENT DES JOUEURS
        // ----------------------------------------------------------------------------------------------
        private _players = playableUnits;
        // En solo, playableUnits peut être vide, donc on ajoute le joueur local
        if (count _players == 0 && hasInterface) then { _players = [player]; };

        {
            if (isPlayer _x) then {
                // Application de l'équipement si disponible
                if (count _modelPlayerData > 0) then { _x setUnitLoadout (_modelPlayerData select 5); };
                
                // Placement dans l'hélicoptère
                _x moveInCargo _heli;
                // Fallback si le cargo est plein : essayer n'importe quel siège
                if (vehicle _x == _x) then { _x moveInAny _heli; };
                _x assignAsCargo _heli;
            };
        } forEach _players;

        sleep 1;  // Petit délai pour stabilisation

        // ##############################################################################################
        // PHASES DE VOL SYNCHRONISEES AVEC LES PLANS CAMERA
        // ##############################################################################################
        
        // ----------------------------------------------------------------------------------------------
        // PHASE 1 : Approche rapide (Plans 1+2 de la caméra = 14 secondes)
        // ----------------------------------------------------------------------------------------------
        _heli doMove _destPos;     // Ordre de déplacement vers la destination
        _heli flyInHeight 150;     // Maintenir 150m d'altitude
        _heli limitspeed 200;      // Vitesse élevée pour l'approche

        sleep 14;  // Durée des Plans 1+2

        // ----------------------------------------------------------------------------------------------
        // PHASE 2 : Vol intermédiaire (Plan 3 = 15 secondes)
        // ----------------------------------------------------------------------------------------------
        // L'hélico continue vers la destination pendant la vue intérieure
        sleep 15;

        // ----------------------------------------------------------------------------------------------
        // PHASE 3 : Approche finale (Plan 4 = 14 secondes)
        // ----------------------------------------------------------------------------------------------
        _heli limitspeed 120;  // Ralentissement pour l'approche finale
        
        sleep 14;

        // ----------------------------------------------------------------------------------------------
        // PHASE 4 : Atterrissage (Plan 5)
        // ----------------------------------------------------------------------------------------------
        // Attendre d'être proche de la LZ
        waitUntil { (_heli distance2D _destPos) < 250 };
        
        // Ordre d'atterrissage avec débarquement automatique
        _heli land "GET OUT";
        
        // Attendre le poser (altitude < 2m)
        waitUntil { (getPos _heli) select 2 < 2 };
        
        sleep 1;
        
        // Débloquer les portes pour permettre la sortie
        _heli lock false; 
        _heli lockCargo false;
        
        // ----------------------------------------------------------------------------------------------
        // DEBARQUEMENT SECURISE DES JOUEURS
        // ----------------------------------------------------------------------------------------------
        // Éjecter chaque joueur manuellement et le positionner à côté de l'hélico
        {
            if (isPlayer _x) then {
                moveOut _x;              // Forcer la sortie du véhicule
                unassignVehicle _x;      // Désassigner du véhicule
                
                // Positionner le joueur 6m sur le côté droit de l'hélico
                private _dir = getDir _heli;
                private _dist = 6;
                private _pos = _heli getPos [_dist, _dir + 90];  // 90° = droite
                _pos set [2, 0];  // Forcer au niveau du sol
                _x setPos _pos;
                _x setDir _dir;   // Orienter dans la même direction que l'hélico
            };
        } forEach _players;
        
        sleep 5;  // Pause pour permettre au joueur de s'orienter
        
        // ----------------------------------------------------------------------------------------------
        // DEPART DE L'HELICOPTERE
        // ----------------------------------------------------------------------------------------------
        _heli land "NONE";  // Annuler l'ordre d'atterrissage
        
        // Définir une position de sortie à 3km dans la direction d'origine
        private _exitPos = _destPos getPos [3000, _startDir];
        _heli doMove _exitPos;
        _heli flyInHeight 200;
        _heli limitspeed 300;  // Vitesse maximale pour le départ
        
        // ----------------------------------------------------------------------------------------------
        // NETTOYAGE FINAL
        // ----------------------------------------------------------------------------------------------
        sleep 60;  // Attendre que l'hélico soit hors de vue
        
        // Supprimer l'équipage et l'hélicoptère pour libérer les ressources
        { deleteVehicle _x } forEach _crew;
        deleteVehicle _heli;
    };
};