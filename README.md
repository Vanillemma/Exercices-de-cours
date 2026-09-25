# Exercice Bash — Emploi du temps

Ce projet contient un script Bash permettant de récupérer un emploi du temps depuis une page web et de l'afficher dans le terminal.

## Objectifs

Le script :

1. choisit une URL selon une promotion ;
2. calcule une fenêtre temporelle en secondes UNIX ;
3. télécharge la page avec `curl` ;
4. extrait le tableau JavaScript `eventsArray` ;
5. filtre les événements selon la période choisie ;
6. affiche les cours dans un format lisible avec des couleurs ANSI.

## Structure du projet

```text
exercices-shell/
├── .gitignore
├── README.md
└── emploi-du-temps/
    ├── edt.sh
    ├── README.md
    └── exemple-sortie.txt
```

## Utilisation

Rendre le script exécutable :

```bash
chmod +x edt.sh
```

Puis lancer :

```bash
./edt.sh
```

Pour sélectionner une promotion :

```bash
./edt.sh M1
./edt.sh M2
./edt.sh SRI
./edt.sh STR
./edt.sh DU
```

## Option `-7`

Chaque option `-7` ajoute 7 jours à la période d'affichage.

Exemple :

```bash
./edt.sh -7 M1
```

affiche environ une semaine supplémentaire.

Deux options :

```bash
./edt.sh -7 -7 M1
```

ajoutent 14 jours.

## Dépendances

Le script utilise :

- Bash ;
- `curl` ;
- `awk` ;
- GNU `date` ou `gdate` ;
- GNU `sed` ou `gsed`.

### macOS

Sur macOS, les commandes GNU peuvent être installées avec Homebrew :

```bash
brew install coreutils gnu-sed
```

### Linux

Sous Linux, `date` et `sed` sont généralement déjà disponibles.

## Fonctions principales

### `MJ(epoch)`

Convertit une date UNIX en date locale.

### `HM(epoch)`

Affiche l'heure au format `HH:MM`.

### `J(epoch)`

Affiche le nom du jour.

### `FormatCours()`

Lit des lignes au format :

```text
DEBUT FIN RESTE
```

avec :

- `DEBUT` : timestamp de début ;
- `FIN` : timestamp de fin ;
- `RESTE` : données contenant notamment `summary` et `location`.

Exemple de sortie :

```text
    Monday - 10:15 - 12:00      B203 - UNIX
```

## Couleurs ANSI

Le script définit plusieurs codes ANSI :

```bash
GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[34m"
YELL="\033[33m"
CYAN="\033[36m"
PLAIN="\033[m"
BOLD="\033[1m"
UNDL="\033[4m"
BLIK="\033[5m"
```

Cela permet notamment d'afficher :

- le jour en bleu ;
- les heures en jaune ;
- la salle en rouge.

## Gestion des promotions

Les promotions actuellement reconnues sont :

| Promotion | Code URL |
|---|---|
| défaut | AAJ |
| M1 | AAH |
| M2 | AAG |
| STR | AAI |
| SRI | AAE |
| DU | ebu |

L'argument est converti en majuscules avant le `case`, ce qui permet par exemple d'utiliser :

```bash
./edt.sh m1
```

ou :

```bash
./edt.sh M1
```

## Calcul de la période

Le script cherche le prochain jour de cours.

Par défaut :

- début : 08:00 ;
- fin : 20:00.

Après 20 h, le script passe au lendemain.

Pour éviter les problèmes de langue du système, le week-end est détecté avec :

```bash
date +%u
```

où :

- `6` = samedi ;
- `7` = dimanche.

## Extraction des événements

La page est téléchargée avec :

```bash
curl -L --fail --silent --show-error
```

Le script recherche ensuite la ligne contenant :

```javascript
var eventsArray
```

Puis plusieurs transformations `sed` permettent de transformer les données en lignes exploitables avec `awk`.

## Améliorations apportées

Par rapport à la version initiale :

### Vérification des champs vides

Au lieu d'enchaîner `&&` et `||`, le script utilise une condition claire :

```bash
if [[ -z "${D:-}" || -z "${F:-}" || -z "${R:-}" ]]; then
    echo "...vide?"
    return 1
fi
```

### Gestion du week-end indépendante de la langue

Le script utilise `%u` au lieu de tester les noms `Samedi` ou `Dimanche`.

### Heure

Le script utilise `%H` plutôt que `%_H`.

### Filtrage des événements

Le script vérifie si l'événement intersecte la fenêtre temporelle :

```text
début événement <= fin fenêtre
ET
fin événement >= début fenêtre
```

Cela permet de conserver un cours qui aurait commencé légèrement avant 08:00 mais qui continuerait après 08:00.

### Dépendances

Le script vérifie la présence de `curl`, `awk`, `date/gdate` et `sed/gsed`.

### Mode Bash strict

Le script utilise :

```bash
set -euo pipefail
```

afin de détecter plus facilement les erreurs.

## Limites

Le parsing reste volontairement basé sur `sed` et `awk`.

Cette solution peut devenir fragile si :

- la structure JavaScript change ;
- l'ordre des propriétés change ;
- certains champs contiennent des virgules ;
- des caractères échappés apparaissent dans les valeurs.

Une amélioration future serait d'extraire correctement le tableau JSON puis d'utiliser `jq`.

## Lancement rapide

```bash
git clone URL_DU_DEPOT
cd exercices-shell/emploi-du-temps
chmod +x edt.sh
./edt.sh M1
```

## Conclusion

Cet exercice permet de travailler plusieurs notions Unix et Bash :

- les variables ;
- les fonctions ;
- les options avec `getopts` ;
- les timestamps UNIX ;
- `curl` ;
- `sed` ;
- `awk` ;
- les pipes ;
- les couleurs ANSI ;
- le filtrage et la transformation de données.
