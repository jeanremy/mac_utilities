#########################################
# Written by: me
# Widely based on Robin PARISI's great work
#########################################

# TAF
# Demander une version de Drupal à installer




###############################################################################
#		        Coloration des echo                                   #
###############################################################################
function cecho {
    while [ "$1" ]; do
        case "$1" in 
            -red)           color="\033[31;01m" ;;
            -green)         color="\033[32;01m" ;;
            -yellow)        color="\033[33;01m" ;;
            -blue)          color="\033[34;01m" ;;
            -n)             one_line=1;   shift ; continue ;;
            *)              echo -n "$1"; shift ; continue ;;
        esac

        shift
        echo "$color"
        echo "$1"
        echo "\033[00m"
        shift

    done
    if [ ! $one_line ]; then
        echo
    fi
}

# Define
#-----------------------------------------------------------------------------

# edit user here
USER="JR"

# configuration files
CONF_FILE="/Users/"$USER"/Sites/httpd-vhosts.conf"
SITES_FOLDER="/Users/"$USER"/Sites" 
HOSTS_FILE="/private/etc/hosts"


# Functions
#-----------------------------------------------------------------------------

last_command() {
	EXIT_V="$?"
	case $EXIT_V in
		0) 
		cecho -green "réussi"		
		;;
		1)
		cecho -red "échoué"
		exit		
		;;
	esac	
}

display_ban() {
 echo 
 cecho -green "################################################################################"
 cecho -green "#                             DRUPAL INSTALL                                   #"
 cecho -green "################################################################################"
 echo 
}

display_separator() {
 echo	
 echo "################################################################################"
 echo
}

ask_for_action() {
 echo "$*"
 echo -n "(o) pour continuer, (n) pour annuler : "
 read key
 if [ $key != "o" ]
  then
 echo "exit..."
 exit 1
 fi
}

test_root() {
 if [ $EUID -ne 0 ]; then
  cecho -red "Le script doit être lancé en root" 1>&2
  exit 1
 fi
}

# Start script
#-----------------------------------------------------------------------------

#test_root
display_ban


read -p "Nom du site (ex: site.local) : " site_name

read -p "Nom du le repertoire drupal  : " folder_name
 
read -p "Nom de la base de données  : " database_name

read -p "Utilisateur de la base de données (root) : " mysql_user_name
mysql_user_name=${mysql_user_name:-root}

echo "Mot de passe utilisateur de la base de données (vide) : "
mysql_user_name=${mysql_user_name:-}

read -p "Utilisateur Drupal (admin)  : " drupal_user_name
drupal_user_name=${drupal_user_name:-admin}

read -p "Mot de passe utilisateur Drupal (admin)  : " drupal_user_password
drupal_user_password=${drupal_user_password:-admin}

echo
cecho -blue "Le site sera configuré tel quel : "
echo "Site    : " $site_name
echo "Repertoire : " /Users/$USER/Sites/$folder_name
echo "Base de données : " $database_name
echo "Utilisateur Mysql : " $mysql_user_name
echo "Mot de passe Mysql : " $mysql_user_password
echo "Utilisateur Drupal : " $drupal_user_password
echo "Mot de passe Drupal : " $drupal_user_password
echo

ask_for_action "Voulez-vous continuer ?"

display_separator



# Database creation
# -------------------------------------------------
echo 'Création de la base de données :'
echo "CREATE DATABASE IF NOT EXISTS $database_name" | mysql -u $mysql_user_name -p
last_command
display_separator



# Launch Drupal download
# -------------------------------------------------
if [ -d SITES_FOLDER/$site_name ]; then
    cecho -yellow "Le repertoire $site_name existe déjà"
else
    drush dl drupal --drupal-project-rename=$folder_name
    last_command
fi


# Launch Drupal Install
# ---------------------------------------------------
echo "Téléchargement de la version FR  : "
bash -c "curl http://ftp.drupal.org/files/translations/7.x/drupal/drupal-7.8.fr.po > /Users/$USER/Sites/$folder_name/profiles/standard/translations/drupal-7.8.fr.po"
last_command

echo "Installation de Drupal  : "
cd $folder_name
drush site-install minimal --account-name=$drupal_user_name --account-pass=$drupal_user_password --db-url=mysql://$mysql_user_name:$mysql_user_password@127.0.0.1/$database_name --site-name=$site_name --locale="fr"
last_command
display_separator


# Change permissisons on files/folders
# ----------------------------------------------------
echo "Changement des permissions sur le répertoire files :"
chmod g+w sites/default/files
last_command
display_separator



# Install modules
# ----------------------------------------------------

## would be good to make a list to check
echo "Liste des modules à installer (séparés par des espaces)        : "
echo "Ex: ckeditor adminimal_theme ctools date devel entity field_collection field_group image_url_formatter imce libraries menu_admin_per_menu metatag node_clone pathauto references token views webform"
read modules
echo "Téléchargement des modules en cours "

drush dl $modules
drush en field_ui node_reference taxonomy toolbar views_ui $modules

last_command
display_separator



# Remove modules
# ----------------------------------------------------
echo "Liste des modules à désinstaller (séparés par des espaces) : "
echo "Ex: overlay"
read disabled

drush dis $disabled

last_command
display_separator


# Edit Hosts file
# ---------------------------------------------------

echo "Ajout d'un host dans $HOSTS_FILE :"
sudo -- sh -c "echo  \ \ >> $HOSTS_FILE";sudo -- sh -c "echo 127.0.0.1  $site_name >> $HOSTS_FILE"
dscacheutil -flushcache
last_command
display_separator


# Write vhosts
# ---------------------------------------------------
echo "Création d'un virtual host :"
echo "
<VirtualHost $site_name>
    DocumentRoot \"/Users/$USER/Sites/$folder_name\"
    ServerName $site_name
    <Directory \"/Users/$USER/Sites/$folder_name\">
        Order allow,deny
        Allow from all
        AllowOverride All
    </Directory>
</VirtualHost>
" >> $CONF_FILE
last_command
display_separator


# Restart Apache
# ---------------------------------------------------
echo "Redémarrage d'Apache :"
sudo apachectl graceful
last_command
display_separator



# End
# ----------------------------------------------------

