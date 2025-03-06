# misc scripts for Windows, Linux, SteamOS

### Steam Deck screenshots

##### appName-dirs-ln.sh

Creates links to the installed games' screenshots folder for easy retrieval
Supports non-Steam games by creating associations in a JSON file
Also creates links based on hardcoded values in the JSON file

This will use various methods to get the app name based on appID : API snapshot, API, Web, JSON file

##### getSteamGamesFromAPI.sh

Creates an offline snapshot of the games list from the Steam API

##### list\_all\_screenshots.sh

Displays all screenshots located in the userdata folder

##### removeLinks.sh

Basically removes all links from a folder