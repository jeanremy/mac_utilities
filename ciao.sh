######################################
# BACKUP DES BDD
######################################

#--------------------------------------------------
#		        Coloration des echo             
#--------------------------------------------------
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


#--------------------------------------------------
#               DEFINE             
#--------------------------------------------------

BACKUPS_FOLDER="/PATHTOBACKUPFOLDER/"
now=$(date +"%d_%m_%Y")
FILE_NAME="$BACKUPS_FOLDER/backup_sql_$now.sql"

#--------------------------------------------------
#               FUNCTIONS           
#--------------------------------------------------


test_root() {
 if [ $EUID -ne 0 ]; then
  cecho -red "Le script doit être lancé en root" 1>&2
  exit 1
 fi
}

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


echo '==================================================='
echo '           BACKUP DES BASES DE DONNEES             '
echo '==================================================='

test_root




if [ -f "$FILE_NAME" ];
then
    cecho -yellow "Le fichier existe existe déjà"
    read -p "Ecraser le fichier (N/o) ?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[o]$ ]];
    then
        mysqldump -u root --all-databases > $FILE_NAME
    else
        cecho -red "abandon"
        exit
    fi
else
    mysqldump -u root --all-databases > $FILE_NAME
fi




last_command


echo '==================================================='
if [ "$(date +"%l")" = "friday" ]; 
then
  echo '               BON WEEK END ;)                '
else 
    echo '               A DEMAIN !                '
fi

echo '==================================================='

#shutdown -r now
osascript -e 'tell app "loginwindow" to «event aevtrsdn»'

exit
