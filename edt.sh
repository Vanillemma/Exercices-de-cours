#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Couleurs ANSI
# ============================================================

GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[34m"
YELL="\033[33m"
CYAN="\033[36m"
PLAIN="\033[m"
BOLD="\033[1m"
UNDL="\033[4m"
BLIK="\033[5m"

# Chaque option -7 ajoute un caractère à cette variable.
# Sa longueur permet donc de compter le nombre de semaines.
semaine=""

# ============================================================
# Détection des commandes GNU
# ============================================================

if command -v gdate >/dev/null 2>&1; then
    DATE_CMD="gdate"
elif command -v date >/dev/null 2>&1; then
    DATE_CMD="date"
else
    echo "Erreur : commande date/gdate introuvable." >&2
    exit 1
fi

if command -v gsed >/dev/null 2>&1; then
    SED_CMD="gsed"
elif command -v sed >/dev/null 2>&1; then
    SED_CMD="sed"
else
    echo "Erreur : commande sed/gsed introuvable." >&2
    exit 1
fi

command -v curl >/dev/null 2>&1 || {
    echo "Erreur : curl est nécessaire." >&2
    exit 1
}

command -v awk >/dev/null 2>&1 || {
    echo "Erreur : awk est nécessaire." >&2
    exit 1
}

# ============================================================
# Aide
# ============================================================

synop() {
    cat <<EOF
Usage : ${0##*/} [-7 [-7 ...]] [M1|M2|SRI|STR|DU]

Exemples :
  ${0##*/} M1
  ${0##*/} -7 SRI
  ${0##*/} -7 -7 M2

Sans promotion, l'emploi du temps par défaut est utilisé.
Chaque option -7 ajoute 7 jours à la période affichée.
EOF
    exit 2
}

# ============================================================
# Fonctions de date / heure
# ============================================================

MJ() {
    "$DATE_CMD" --date="@$1" +%x
}

HM() {
    "$DATE_CMD" --date="@$1" +%H:%M
}

J() {
    "$DATE_CMD" --date="@$1" +%A
}

# ============================================================
# Affichage d'un cours
# ============================================================

FormatCours() {
    while read -r D F R; do
        if [[ -z "${D:-}" || -z "${F:-}" || -z "${R:-}" ]]; then
            echo "...vide?"
            return 1
        fi

        printf -v Jour '% 10s' "$(J "$D")"

        echo -en "${BLUE}${Jour}${PLAIN} - ${YELL}$(HM "$D") - $(HM "$F")${PLAIN}"

        printf '%s\n' "$R" | awk -F ':' '
            BEGIN { RS="," }
            $1 ~ /"summary"/  { Cours=$2 }
            $1 ~ /"location"/ { Salle=$2 }
            END {
                gsub(/"/, "", Salle)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", Salle)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", Cours)
                printf("\033[31m%10s\033[m - %s\n", Salle, Cours)
            }
        '
    done
}

# ============================================================
# Gestion des options
# ============================================================

while getopts "7" OPT; do
    case "$OPT" in
        7)
            semaine="y${semaine}"
            ;;
        \?)
            synop
            ;;
    esac
done

shift $((OPTIND - 1))

# ============================================================
# Choix de l'URL selon la promotion
# ============================================================

if (( $# == 0 )); then
    URL='http://edt.jordan-martin.fr/AAJ?refresh'
else
    ARG1=$(printf '%s' "$1" | awk '{ print toupper($0) }')

    case "$ARG1" in
        M1)
            URL='http://edt.jordan-martin.fr/AAH?refresh'
            ;;
        M2)
            URL='http://edt.jordan-martin.fr/AAG?refresh'
            ;;
        STR)
            URL='http://edt.jordan-martin.fr/AAI?refresh'
            ;;
        SRI)
            URL='http://edt.jordan-martin.fr/AAE?refresh'
            ;;
        DU)
            URL='https://edt.jordan-martin.fr/ebu#?refresh'
            ;;
        *)
            synop
            ;;
    esac
fi

# ============================================================
# Calcul du prochain jour de cours
# ============================================================

Ajout=""

HeureDuJour=$("$DATE_CMD" +%H)
JourSemaine=$("$DATE_CMD" +%u)

# Si la journée est terminée, on part du lendemain.
if (( 10#$HeureDuJour >= 20 )); then
    Ajout="+1 day"
fi

# On calcule une date de référence, puis on vérifie si elle tombe
# pendant le week-end.
if [[ -n "$Ajout" ]]; then
    DateReference=$("$DATE_CMD" --date="$Ajout" +%F)
else
    DateReference=$("$DATE_CMD" +%F)
fi

JourReference=$("$DATE_CMD" --date="$DateReference" +%u)

case "$JourReference" in
    6)
        DateReference=$("$DATE_CMD" --date="$DateReference +2 days" +%F)
        ;;
    7)
        DateReference=$("$DATE_CMD" --date="$DateReference +1 day" +%F)
        ;;
esac

# ============================================================
# Fenêtre temporelle
# ============================================================

Debut=$("$DATE_CMD" --date="$DateReference 08:00" +%s)

if [[ -z "$semaine" ]]; then
    Fin=$("$DATE_CMD" --date="$DateReference 20:00" +%s)

    echo -e "EDT du ${YELL}${BOLD}$(MJ "$Debut")${PLAIN}"
else
    NbJours=$((7 * ${#semaine}))
    DateFin=$("$DATE_CMD" --date="$DateReference +${NbJours} days" +%F)
    Fin=$("$DATE_CMD" --date="$DateFin 20:00" +%s)

    echo -e \
        "EDT du ${YELL}${BOLD}$(MJ "$Debut")${PLAIN}" \
        "au ${BLIK}${YELL}${BOLD}$(MJ "$Fin")${PLAIN}"
fi

# ============================================================
# Téléchargement et extraction des événements
# ============================================================

curl -L --fail --silent --show-error "$URL" |
    grep 'var eventsArray' |
    "$SED_CMD" -e 's/^[[:space:]]*var eventsArray = \[//' |
    "$SED_CMD" -e 's/},/}\n/g' |
    "$SED_CMD" -e 's/[{}]//g;s/,/ /;s/,/ /;s/^[^:]*://;s/"dtend"://' |
    awk -v debut="$Debut" -v fin="$Fin" '
        {
            # On garde tout événement qui intersecte la fenêtre :
            # début événement <= fin fenêtre ET fin événement >= début fenêtre.
            if ($1 <= fin && $2 >= debut)
                print $0
        }
    ' |
    FormatCours
