// ============================================================================
// Dialog de Sélection des Ennemis
// ID: 7777
// ============================================================================

class Refour_Enemies_Dialog
{
    idd = 7777;
    movingEnable = false;
    enableSimulation = true;

    class controlsBackground
    {
        class MainBackground: RscText
        {
            idc = -1;
            x = 0.25 * safezoneW + safezoneX;
            y = 0.15 * safezoneH + safezoneY;
            w = 0.50 * safezoneW;
            h = 0.70 * safezoneH;
            colorBackground[] = {0,0,0,0.8};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_ENEMIES_MENU_TITLE";
            x = 0.25 * safezoneW + safezoneX;
            y = 0.15 * safezoneH + safezoneY;
            w = 0.50 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.6,0.1,0.1,1};
            style = ST_CENTER;
        };
    };

    class controls
    {
        // Label: Sélection Officiers
        class LabelOfficers: RscText
        {
            idc = 3001;
            text = "$STR_SELECT_OFFICERS";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.4,0.2,0,0.8};
            style = ST_CENTER;
        };
        
        // Compteur Officiers
        class CounterOfficers: RscText
        {
            idc = 3002;
            text = "0 / 3";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {1,0.8,0,1};
            style = ST_CENTER;
        };
        
        // Liste Officiers Sélectionnés
        class OfficersList: RscListBox
        {
            idc = 3003;
            x = 0.26 * safezoneW + safezoneX;
            y = 0.26 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.15 * safezoneH;
        };
        
        // Label: Sélection Soldats
        class LabelSoldiers: RscText
        {
            idc = 3004;
            text = "$STR_SELECT_SOLDIERS";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.2,0.3,0,0.8};
            style = ST_CENTER;
        };
        
        // Compteur Soldats
        class CounterSoldiers: RscText
        {
            idc = 3005;
            text = "0 / 12";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.45 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.03 * safezoneH;
            colorText[] = {0.6,1,0.2,1};
            style = ST_CENTER;
        };
        
        // Liste Soldats Sélectionnés
        class SoldiersList: RscListBox
        {
            idc = 3006;
            x = 0.26 * safezoneW + safezoneX;
            y = 0.48 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.24 * safezoneH;
        };
        
        // Liste OPFOR disponibles (droite)
        class LabelAvailable: RscText
        {
            idc = -1;
            text = "$STR_AVAILABLE_UNITS";
            x = 0.51 * safezoneW + safezoneX;
            y = 0.20 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.03 * safezoneH;
            colorBackground[] = {0.3,0.3,0.3,0.8};
            style = ST_CENTER;
        };
        
        class AvailableList: RscListBox
        {
            idc = 3007;
            x = 0.51 * safezoneW + safezoneX;
            y = 0.23 * safezoneH + safezoneY;
            w = 0.23 * safezoneW;
            h = 0.49 * safezoneH;
        };
        
        // Bouton: Ajouter comme Officier
        class BtnAddOfficer: RscButton
        {
            idc = 3010;
            text = "$STR_BTN_ADD_OFFICER";
            x = 0.51 * safezoneW + safezoneX;
            y = 0.73 * safezoneH + safezoneY;
            w = 0.11 * safezoneW;
            h = 0.035 * safezoneH;
            colorBackground[] = {0.5,0.3,0,1};
            colorBackgroundActive[] = {0.7,0.4,0,1};
            action = "['ADD_OFFICER'] call MISSION_fnc_spawn_ennemies;";
        };
        
        // Bouton: Ajouter comme Soldat
        class BtnAddSoldier: RscButton
        {
            idc = 3011;
            text = "$STR_BTN_ADD_SOLDIER";
            x = 0.63 * safezoneW + safezoneX;
            y = 0.73 * safezoneH + safezoneY;
            w = 0.11 * safezoneW;
            h = 0.035 * safezoneH;
            colorBackground[] = {0.2,0.4,0,1};
            colorBackgroundActive[] = {0.3,0.6,0,1};
            action = "['ADD_SOLDIER'] call MISSION_fnc_spawn_ennemies;";
        };
        
        // Bouton: Valider
        class BtnValidate: RscButton
        {
            idc = 3020;
            text = "$STR_BTN_VALIDATE";
            x = 0.26 * safezoneW + safezoneX;
            y = 0.78 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0,0.5,0,1};
            colorBackgroundActive[] = {0,0.7,0,1};
            action = "['VALIDATE'] call MISSION_fnc_spawn_ennemies;";
        };
        
        // Bouton: Réinitialiser
        class BtnReset: RscButton
        {
            idc = 3021;
            text = "$STR_BTN_RESET";
            x = 0.40 * safezoneW + safezoneX;
            y = 0.78 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0.7,0,0,1};
            colorBackgroundActive[] = {1,0,0,1};
            action = "['RESET'] call MISSION_fnc_spawn_ennemies;";
        };
        
        // Bouton: Quitter
        class BtnClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.62 * safezoneW + safezoneX;
            y = 0.78 * safezoneH + safezoneY;
            w = 0.12 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};
