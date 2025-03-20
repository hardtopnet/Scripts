# misc scripts for Windows, Linux, SteamOS

### Steam Deck screenshots

##### appName-dirs-ln.sh

Creates links to the installed games' screenshots folder for easy retrieval
Supports non-Steam games by creating associations in a JSON file
Also creates links based on hardcoded values in the JSON file

This will use various methods to get the app name based on appID : API snapshot, API, Web, JSON file

###### constants & parameters

you can adjust the following constants in the script :
`USER_ID` : indicates your own UserID
`API_URL` : the API from which the Steam app list is retrieved
`LINK_DIR` : the directory where the links will be created
`NON_STEAM_GAMES` : the name of the JSON file containing hardcoded values
`STEAM_API` : the name of the JSON file with a snapshot of the Steam API GetAppList return value

##### getSteamGamesFromAPI.sh

Creates an offline snapshot of the games list from the Steam API

###### constants & parameters

you can adjust the following constants in the script :
`STEAM_API` : the name of the JSON file with a snapshot of the Steam API GetAppList return value

##### list\_all\_screenshots.sh

Displays all screenshots located in the userdata folder

###### constants & parameters

command line parameters :
`$1` : directory to check (default `~/Pictures`)
`$2` : file filter (default `*.??g`)

##### removeLinks.sh

Basically removes all links from a folder

###### constants & parameters

you can adjust the following constants in the script :
`TARGET_DIR` : the directory where to remove all links