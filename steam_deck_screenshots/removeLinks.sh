#!/bin/bash

# Répertoire cible (par défaut : répertoire courant)
TARGET_DIR=${1:-.}

# Vérifier si le répertoire existe
if [ ! -d "$TARGET_DIR" ]; then
  echo "Erreur : Le répertoire spécifié '$TARGET_DIR' n'existe pas."
  exit 1
fi

# Parcourir tous les fichiers et supprimer les liens symboliques
echo "Suppression des liens symboliques dans le répertoire : $TARGET_DIR"
for item in "$TARGET_DIR"/*; do
  if [ -L "$item" ]; then
    echo "Suppression du lien symbolique : $item"
    rm "$item"
  fi
done

echo "Tous les liens symboliques ont été supprimés."
