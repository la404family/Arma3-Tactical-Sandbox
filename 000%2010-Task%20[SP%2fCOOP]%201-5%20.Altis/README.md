# 🛠️ Guide de Conception de Mission Arma 3 : Randomisation & Standards

Ce document détaille les instructions pour créer une mission immersive, rejouable et compatible à la fois en Singleplayer (SP) et en Coopératif (COOP).

---

## 1. Conception de Mission : Randomisation & Dynamisme

Pour maximiser la rejouabilité, il est crucial d'intégrer des éléments aléatoires et une vie autonome dans la mission.

### 🎲 Probabilité et Placement des Ennemis
*   **Probabilité de présence** : Fixez à **20 %** la chance d'apparition pour les éléments aléatoires.
*   **Groupes d'ennemis** : Placez environ **de nombreux groupes potentiels**, mais leurs apparitions seront régies par la probabilité définie.
*   **Marqueurs d'objectifs** : Privilégiez des **zones de recherche** (ex: 1 km de diamètre) plutôt que des points précis, forçant le joueur à explorer.

### Types d’objectifs de mission

- Extraction de VIP : Escorter un officier, scientifique ou informateur jusqu’à la base alliée.
    - Offre : une caisses de ravitaillement.
- Récupération de personnel isolé : Secourir un prisonnier de guerre derrière les lignes ennemies.
    - Offre : ???
- Assassinat et récupération de documents : Éliminer un officier ennemi de haut rang. + récuperation de documents dans son inventaire.
    - Offre : Révélation de positions ennemies sur la carte (bases, patrouilles).
- Chasse à l’homme (HVT) : Traquer un commandant ennemi mobile entre plusieurs bases ou convois.
    - Offre : ???
- Suppression de défenses : Neutraliser un radar anti-aérien pour permettre un soutien aérien allié.
    - Offre : survole rapide de la zone par un hélicoptère allié. (éviter officier ennemis)
- Destruction de convoi : Détruire un convoi de ravitaillement ou des véhicules ennemis lourds.
    - Offre : ???
- Reconquête : Reprendre une base alliée (QG ennemie) tombée aux mains de l’ennemi.
    - Offre : ???
- Récupération de renseignements : Infiltrer un QG ennemi pour pirater un ordinateur.
    - Offre : ???
- Enquête mystérieuse : Explorer un laboratoire secret pour comprendre une anomalie.
    - Offre : ???

**Besoins :** 
 - Officier allié
 - Officier ennemi avec documents
 - Officier ennemi mobile
 - QG ennemi (avec ordinateur à pirater)
 - QG allié
 - Radar anti-aérien
 - Convoie ennemie
 - laboratoire secret


### 🌍 Dynamisme Général
*   **Monde vivant** : Intégrez des événements indépendants des actions du joueur (ex: convois, combats entre IA, trafic civil).
*   **Tâches variées** : Mélangez les types de missions (Sauvetage, Destruction, Capture, Recupération).

---

## 2. Bonnes Pratiques de Codage (SP/COOP)

> **La Règle d'Or** : Codez toujours pour le **COOP**. Si cela fonctionne en multijoueur, cela fonctionnera automatiquement en solo.

### Gestion Serveur vs Client
En SP, votre machine est à la fois serveur et client. En COOP, ces rôles sont séparés.
*   `isServer` : Vrai sur la machine locale en SP, vrai uniquement sur le serveur dédié/hôte en MP.

### 🚫 Erreurs Courantes
*   **NE JAMAIS UTILISER** : `player` dans des scripts globaux (car `player` est différent sur chaque machine ou inexistant sur un serveur dédié).
*   **UTILISER PLUTÔT** : 
    *   `playableUnits` : Retourne toutes les unités jouables (y compris IA si slots non utilisés).

### Création de Tâches (Task Framework)
Utilisez toujours les fonctions BIS pour créer des tâches côté serveur. Elles gèrent automatiquement la synchronisation.

```sqf
[
    west,                   // Équipe concernée
    "task_obj1",            // ID de la tâche
    ["STR_TASK_DESC", "STR_TASK_TITLE", ""], // Textes (clés stringtable)
    getMarkerPos "obj_1",   // Position
    "ASSIGNED",             // État initial
    1,                      // Priorité
    true                    // Notification à l'écran
] call BIS_fnc_taskCreate;
```

---

## 3. Support Multilingue (Internationalisation)

> **Règle Principale** : **ZÉRO texte en dur** dans les scripts (.sqf). Utilisez obligatoirement `stringtable.xml`.

Cela permet une traduction automatique selon la langue du jeu du client.

### Structure `stringtable.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<Project name="MyMission">
    <Package name="General">
        <Key ID="STR_MISSION_NAME">
            <English>Silent Dawn</English>
            <French>Aube Silencieuse</French>
            <German>Stille Morgenröte</German>
            <Spanish>Amanecer Silencioso</Spanish>
            <Italian>Alba Silenziosa</Italian>
            <Russian>Тихий Рассвет</Russian>
            <Polish>Cichy Świt</Polish>
            <Czech>Tiché Svítání</Czech>
            <Turkish>Sessiz Şafak</Turkish>
            <Chinese>寂静黎明</Chinese>
            <Chinesesimp>寂静黎明</Chinesesimp>
        </Key>

        <Key ID="STR_TASK_TITLE">
            <English>Secure the area</English>
            <French>Sécuriser la zone</French>
            <German>Gebiet sichern</German>
            <Spanish>Asegurar el área</Spanish>
            <Italian>Mettere in sicurezza l'area</Italian>
            <Russian>Обезопасить территорию</Russian>
            <Polish>Zabezpieczyć obszar</Polish>
            <Czech>Zabezpečit oblast</Czech>
            <Turkish>Bölgeyi güvene alın</Turkish>
            <Chinese>確保該地區安全</Chinese>
            <Chinesesimp>确保该地区安全</Chinesesimp>
        </Key>

        <Key ID="STR_TASK_DESC">
            <English>Eliminate enemy presence.</English>
            <French>Éliminez toute présence ennemie.</French>
            <German>Beseitigen Sie die feindliche Präsenz.</German>
            <Spanish>Elimine la presencia enemiga.</Spanish>
            <Italian>Eliminare la presenza nemica.</Italian>
            <Russian>Уничтожьте присутствие противника.</Russian>
            <Polish>Wyeliminuj obecność wroga.</Polish>
            <Czech>Eliminujte nepřátelskou přítomnost.</Czech>
            <Turkish>Düşman varlığını yok edin.</Turkish>
            <Chinese>消滅敵人的存在</Chinese>
            <Chinesesimp>消灭敌人的存在</Chinesesimp>
        </Key>
    </Package>
</Project>
```

---

## 4. Structure des Fichiers

Une organisation rigoureuse est essentielle pour la maintenance.

```text
maMission/
├── mission.sqm          # Fichier éditeur principal (placement objets/unités)
├── description.ext      # Configuration générale (Respawn, Paramètres, Sounds)
├── stringtable.xml      # Base de données des traductions
├── init.sqf             # Script d'initialisation global (exécuté partout)
└── scripts/             # Dossier stockage des scripts
    ├── fn_xxx.sqf         # Logique xxx
    ├── fn_yyy.sqf         # Logique yyy
    └── fn_zzz.sqf         # Logique zzz
```

---

## 5. Checklist de Compatibilité SP/COOP

Avant de publier, vérifiez que votre code respecte ces points :

- [ ] J'utilise `isServer` pour toute logique critique (Spawn, Création Tâches, Score).
- [ ] J'utilise `hasInterface` pour tout ce qui est visuel/sonore local.
- [ ] J'utilise `remoteExec` pour exécuter du code sur une autre machine si nécessaire.
- [ ] J'utilise `publicVariable` pour synchroniser des variables importantes entre serveur et clients.
- [ ] J'utilise `addEventHandler` pour les événements liés aux unités (compatible MP).
- [ ] Je privilégie les fonctions `BIS_fnc_*` qui sont généralement optimisées pour le réseau.
