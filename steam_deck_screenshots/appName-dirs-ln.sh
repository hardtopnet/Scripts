#!/bin/bash

# fichier json récupéré depuis https://api.steampowered.com/ISteamApps/GetAppList/v2/

sanitize_name() {
    local input="$1"
	local sanitized_name

    # Appliquer les transformations
    sanitized_name=$(echo "$input" | sed 's/[^a-zA-Z0-9._-]/_/g; s/[™®]//g')
    sanitized_name=$(echo "$sanitized_name" | sed 's/ /_/g; s/__/_/g')

    # Retourner le résultat
    echo "$sanitized_name"
}

# Répertoire cible (par défaut : /home/deck/.local/share/Steam/userdata/**USER_ID**/760/remote)
TARGET_DIR=${1:-/home/deck/.local/share/Steam/userdata/**USER_ID**/760/remote}
# TARGET_DIR=${1:-/home/deck/temp}
 
# URL de l'API Steam
API_URL="https://api.steampowered.com/ISteamApps/GetAppList/v2/"

# Vérifier si le répertoire existe
if [ ! -d "$TARGET_DIR" ]; then
  echo "Erreur : Le répertoire spécifié '$TARGET_DIR' n'existe pas."
  exit 1
fi

# Vérifier que jq est installé
if ! command -v jq &> /dev/null; then
  echo "Erreur : 'jq' est requis pour exécuter ce script. Installez-le avec 'sudo apt install jq' ou équivalent."
  exit 1
fi

# suppression des anciens liens
~/scripts/removeLinks.sh

# Récupérer la liste complète des applications une seule fois
echo "Récupération des données depuis Steam..."
response=$(curl -s "$API_URL")
if [ -z "$response" ]; then
  echo "Erreur : impossible de récupérer les données depuis l'API Steam."
  exit 1
fi

# Parcourir les sous-répertoires
for dir in "$TARGET_DIR"/*; do
  # Retirer le slash final pour obtenir le nom du répertoire
  appid=$(basename "$dir")
  echo -e "\nTraitement du répertoire : $appid"

  # Vérifier si le nom est un nombre
  if [[ "$appid" =~ ^[0-9]+$ && "$appid" -ne 7 ]]; then
  
# recherche dans liens non-steam hardcodés
	app_name=$(jq -r --argjson appid "$appid" '.applist.apps[] | select(.appid == $appid) | .name' ~/scripts/non-steam-games.json | head -n 1)

	if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
		echo "    [JSN] $app_name"
		sanitized_name=$(sanitize_name "$app_name")
	else
# recherche dans snapshot API sur disque
		app_name=$(jq -r --argjson appid "$appid" '.applist.apps[] | select(.appid == $appid) | .name' ~/scripts/steam-api.json | head -n 1)

		if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
			echo "    [JSA] $app_name"
			sanitized_name=$(sanitize_name "$app_name")
		else
# recherche dans API
			app_info=$(echo "$response" | jq -r ".applist.apps[] | select(.appid == $appid)")
			app_name=$(echo "$response" | jq -r "first(.applist.apps[] | select(.appid == $appid)) | .name")

			if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
				echo "    [API] $app_name"
				sanitized_name=$(sanitize_name "$app_name")
			else 
# recherche sur la page HTML du Steam Store pour l'AppID
				steam_store_url="https://store.steampowered.com/app/$appid"
				page_content=$(curl -s -L "$steam_store_url" | tr -d '\0')

				# Extraire le titre du jeu depuis la balise <title>
				app_name=$(echo "$page_content" | grep -oP '(?<=<title>).*?(?= on Steam</title>)')
				# Nettoyer pour ne garder que le nom du jeu
				app_name=$(echo "$app_name" | sed -E 's/^Save [0-9]+%? on (.+)/\1/' | sed 's/[™®]//g')

				if [ -n "$app_name" ]; then
					echo "    [WEB] $app_name"
					sanitized_name=$(sanitize_name "$app_name")
				else
					echo "    [ID ] $appid"
					sanitized_name=$appid
				fi
			fi
		fi
	fi
    
	# Créer un lien symbolique avec le nom de l'application
    ln -sfn "$dir/screenshots" "$sanitized_name"
    echo "- Lien symbolique créé : $sanitized_name -> $dir"
  else
    echo "Ignoré : $dir n'est pas un appid valide."
  fi
done

# # ajout liens hardcodés

ln -sfn "/home/deck/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/users/steamuser/Documents/My Games/Outlaws/Photos" Star_Wars_Outlaws_photo
ln -sfn "/home/deck/.local/share/Steam/steamapps/compatdata/NonSteamLaunchers/pfx/drive_c/users/steamuser/Documents/Assassin's Creed Mirage/photos" Assassins_Creed_Mirage_photo

echo -e "\n\nTraitement terminé."
