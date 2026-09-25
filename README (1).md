# Exercices Shell / Bash

Ce dépôt regroupe mes exercices de programmation Shell et Bash.

## Exercices

### Emploi du temps

Le dossier [`emploi-du-temps`](emploi-du-temps/) contient un script permettant de récupérer et d'afficher un emploi du temps dans le terminal.

Concepts utilisés :

- Bash ;
- fonctions ;
- `getopts` ;
- `curl` ;
- `sed` ;
- `awk` ;
- pipes Unix ;
- timestamps UNIX ;
- couleurs ANSI.

## Organisation

Chaque exercice possède son propre dossier afin de pouvoir ajouter facilement de nouveaux travaux :

```text
exercices-shell/
├── emploi-du-temps/
├── exercice-awk/
├── exercice-sed/
└── ...
```

## Git

Après modification d'un exercice :

```bash
git status
git add .
git commit -m "Description des modifications"
git push
```
