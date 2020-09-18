#!/usr/bin/env bash

###########################################################
### Script:         laralara.sh
### Author:         Kevin Jackson <laidbackwebsage@gmail.com>
### Description:    Sets up a local laradock project.
###########################################################
### Fail at the first error
set -e

### =================================================== ###
### Functions
### =================================================== ###
verbose() {
    if [[ ${VERBOSE} == 1 ]]; then
        echo "$1"
        echo ""
    fi
}

usage() {
    cat <<EOB
This project can be download/clones from: 
https://github.com/laidbackwebsage/laralara

Usage for $0
===========================================================
-a, --app-name (required)
    This value will be appended to your "--project-dir"
    (q.v., below) to create the fully-qualified path to where 
    your project will reside. If this path alreay exists,
    this script will fail with an error.

--mysql-version (optional)
    Set the mysql version to use; defaults to "latest".
    Valid values are: 8.0.21, 8.0, 8, latest, 5.7.31, 
    5.7, 5, 5.6.49, 5.6

--php-version (optional)
    Set the php version to use; defaults to 7.4.
    Valid values are: 7.4, 7.3, 7.2, 7.1, 7.0, 5.6

-p, --project-dir (required)
    Fully-qualified path to your projects directory.
    Defaults to $HOME/Projects. If this path does not exist,
    it will be created.

-v, --verbose (optional)
    If passed on the cammand line, this script will output
    meaningful updates regarding what the script is doing.
    Otherwise, it will remain silent, except for errors.

-w, --web-root-path (optional)
    Path to Laravel code in the workspace container, defaults
    '/var/www/<app-name>'
    
-h, -?, --help (optional)
    Displays this usage message and exits 


EOB
}

### =================================================== ###
### Set our Initial Paths
### =================================================== ###
# shellcheck disable=SC2086
BIN_DIR="$( dirname $0 )"

# shellcheck disable=SC2006
BIN_DIR="` ( cd \"$BIN_DIR\" && pwd )`"
if [ -z "$BIN_DIR" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  echo "ERROR: Unable to determine current directory; exiting." 
  exit 3  # fail
fi
verbose "BIN_DIR: ${BIN_DIR}" 

# shellcheck disable=SC2086
BASE_DIR="$(realpath ${BIN_DIR}/../)"
verbose "BASE_DIR: $BASE_DIR"

### =================================================== ###
### Set our defaults
### =================================================== ###
APP_NAME=
ENV_NAME="local"
MYSQL_VERSION=latest
PHP_VERSION=7.4
PROJECT_DIR=
VERBOSE=0
WEB_ROOT_PATH=

### =================================================== ###
### Parse the command line arguments
### --------------------------------------------------- ###
### Unabashedly stolen from:
### https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
### =================================================== ###
PARAMS=""

# shellcheck disable=SC2221
# shellcheck disable=SC2222
while (("$#")); do
    case "$1" in
    -a | --app-name)
        APP_NAME=$2
        shift 2
        ;;
    -e | --env)
        ENV_NAME=$2
        shift 2
        ;;
    --mysql-version)
        MYSQL_VERSION=$2
        shift 2
        ;;
    --php-version)
        PHP_VERSION=$2
        shift 2
        ;;
    -p | --project-dir)
        PROJECT_DIR=$2
        shift 2
        ;;
    -v | --verbose)
        VERBOSE=1
        shift
        ;;
    -w | --web-root-path)
        WEB_ROOT_PATH=$2
        shift 2
        ;;
    -h | -\? | --help)
        usage
        exit 0
        ;;
    -* | --*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        exit 1
        ;;
    *) # preserve positional arguments
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

### =================================================== ###
### Validate our arguments
### =================================================== ###
if [[ -z "${APP_NAME}" ]]; then
    usage
    echo
    echo "ERROR: --app-name is required."
    exit 2
fi

if [[ -z "${PROJECT_DIR}" ]]; then
    PROJECT_DIR="${HOME}"/Projects
fi

if [[ ! -d "${PROJECT_DIR}" ]]; then
    mkdir -p "${PROJECT_DIR}" || { 
        usage
        echo
        echo "ERROR: Unable to create project directory, ${PROJECT_DIR}: $?"
        exit
    }
fi

LOCAL_APP_PATH="${PROJECT_DIR}/${APP_NAME}"

if [[ -d "${LOCAL_APP_PATH}" ]]; then
    echo "ERROR: Your intended app path, ${LOCAL_APP_PATH}, already exists."
    exit 2
else
    verbose "Attempting to create ${LOCAL_APP_PATH}"
    mkdir -p "${LOCAL_APP_PATH}" || { 
        usage
        echo
        echo "ERROR: Unable to create ${LOCAL_APP_PATH}: $?"
        exit
    }
fi

if [[ -z "${WEB_ROOT_PATH}" ]]; then
    WEB_ROOT_PATH="/var/www/$APP_NAME"
    verbose "Assigned WEB_ROOT_PATH to default: ${WEB_ROOT_PATH}"
fi
verbose "WEB_ROOT_PATH: ${WEB_ROOT_PATH}"

### =================================================== ###
### Validate PHP Version here
### =================================================== ###
if  [[ ! "${PHP_VERSION}" =~ ^(7.4|7.3|7.2|7.1|7.0|5.6)$ ]]; then
    usage
    echo
    echo "ERROR: INVALID PHP_VERSION: ${PHP_VERSION}."
    echo "MUST BE ONE OF: 7.4 - 7.3 - 7.2 - 7.1 - 7.0 - 5.6"
    exit 2
fi

### =================================================== ###
### Validate MySQL Version here
### =================================================== ###
if  [[ ! "${MYSQL_VERSION}" =~ ^(latest|8.0.21|8.0|8|5.7.31|5.7|5|5.6.49|5.6)$ ]]; then
    usage
    echo
    echo "ERROR: INVALID MYSQL_VERSION: ${MYSQL_VERSION}."
    echo "MUST BE ONE OF: 8.0.21, 8.0, 8, latest, 5.7.31, 5.7, 5, 5.6.49, 5.6"
    exit 2
fi

### =================================================== ###
### This script requires curl to be installed. If 
### it is not available, notify the user and exit
### gracefully.
### =================================================== ###
if [[ -z $(which curl) ]]; then
    echo "This script requires \"curl\" to work. You can get it by running:"
    echo "\tsudo apt update && sudo apt install -y curl"
fi

### =================================================== ###
### This script requires html2text to be installed. If 
### it is not available, notify the user and exit
### gracefully.
### =================================================== ###
if [[ -z $(which html2text) ]]; then
    echo "This script requires \"html2text\" to work. You can get it by running:"
    echo "\tsudo apt update && sudo apt install -y html2text"
fi

### =================================================== ###
### Create and define the rest of our paths
### =================================================== ###
SRC_PATH="${LOCAL_APP_PATH}"/app_src
mkdir -p "${SRC_PATH}" || { 
    usage
    echo
    echo "ERROR: Unable to create ${SRC_PATH}: $?"
    exit
}
verbose "SRC_PATH: ${SRC_PATH}"

BIN_PATH="${LOCAL_APP_PATH}"/bin
mkdir -p "${BIN_PATH}" || { 
    usage
    echo
    echo "ERROR: Unable to create ${BIN_PATH}: $?"
    exit
}
verbose "BIN_PATH: ${BIN_PATH}"

CONFIGS_PATH="${LOCAL_APP_PATH}"/configs/local
mkdir -p "${CONFIGS_PATH}" || { 
    usage
    echo
    echo "ERROR: Unable to create ${CONFIGS_PATH}: $?"
    exit
}
verbose "CONFIGS_PATH: ${CONFIGS_PATH}"

### Force git to keep an empty directory; also,
### forces VsCode to properly display the directory tree
### (personal idiosyncracy)
touch "${CONFIGS_PATH}"/.gitkeep

DOCS_PATH="${LOCAL_APP_PATH}"/docs
mkdir -p "${DOCS_PATH}" || { 
    usage
    echo
    echo "ERROR: Unable to create ${DOCS_PATH}: $?"
    exit
}
verbose "DOCS_PATH: ${DOCS_PATH}"

STORAGE_PATH="${LOCAL_APP_PATH}"/storage
mkdir -p "${STORAGE_PATH}" || { 
    usage
    echo
    echo "ERROR: Unable to create ${STORAGE_PATH}: $?"
    exit
}
verbose "STORAGE_PATH: ${STORAGE_PATH}"

### NOTE: Define the DOCKER_PATH, but let the git submodule
###       command below actually create it.
DOCKER_PATH="${LOCAL_APP_PATH}"/"${APP_NAME}"-docker
verbose "DOCKER_PATH: ${DOCKER_PATH}"

### =================================================== ###
### Make this a git project
### =================================================== ###
verbose "Making project a git project..."
cd "${LOCAL_APP_PATH}"
git init

### =================================================== ###
### Pull in Laradock as a submodule for the project
### =================================================== ###
verbose "Pulling in laradock as a git submodule..."
git submodule add https://github.com/Laradock/laradock.git "${DOCKER_PATH}"

### =================================================== ###
### Rewrite the configs and commit them
### =================================================== ###
### Docker .env
### =================================================== ###
verbose "Creating Docker Compose \".env\" file, and making project-specific..."
cp "${DOCKER_PATH}"/env-example "${DOCKER_PATH}"/.env
sed -i 's+APP_CODE_PATH_HOST=..+APP_CODE_PATH_HOST=../app_src+g' "${DOCKER_PATH}"/.env
sed -i "s+APP_CODE_PATH_CONTAINER=/var/www+APP_CODE_PATH_CONTAINER=/var/www/$APP_NAME+g" "${DOCKER_PATH}"/.env
sed -i "s+DATA_PATH_HOST=~/.laradock/data+DATA_PATH_HOST=$STORAGE_PATH+g" "${DOCKER_PATH}"/.env
sed -i "s+COMPOSE_PROJECT_NAME=laradock+COMPOSE_PROJECT_NAME=$APP_NAME+g" "${DOCKER_PATH}"/.env
sed -i "s+PHP_VERSION=7.3+PHP_VERSION=$PHP_VERSION+g" "${DOCKER_PATH}"/.env
sed -i "s+PHP_IDE_CONFIG=serverName=laradock+PHP_IDE_CONFIG=serverName=$APP_NAME+g" "${DOCKER_PATH}"/.env
sed -i "s+PHP_IDE_CONFIG=serverName=laradock+PHP_IDE_CONFIG=serverName=$APP_NAME+g" "${DOCKER_PATH}"/.env

### Get the latest LTS version of Node
NODE_VERSION=$(curl https://nodejs.org/en/download/ | html2text | grep 'Latest LTS Version: ' | grep -oP -m 1 '\d+\.\d+\.*\d*' | head -n 1)
verbose "Installing NODE_VERSION: ${NODE_VERSION}"
sed -i "s+WORKSPACE_NODE_VERSION=node+WORKSPACE_NODE_VERSION=$NODE_VERSION+g" "${DOCKER_PATH}"/.env

sed -i "s+WORKSPACE_INSTALL_YARN=true+WORKSPACE_INSTALL_YARN=false+g" "${DOCKER_PATH}"/.env
sed -i "s+PHP_WORKER_INSTALL_REDIS=false+PHP_WORKER_INSTALL_REDIS=true+g" "${DOCKER_PATH}"/.env

### Set MySQL values
if [[ "${MYSQL_VERSION}" != 'latest' ]]; then
    sed -i "s+MYSQL_VERSION=latest+MYSQL_VERSION=$MYSQL_VERSION+g" "${DOCKER_PATH}"/.env
fi

LOCAL_MYSQL_DBNAME="${APP_NAME}db"
LOCAL_MYSQL_USER="${LOCAL_MYSQL_DBNAME}admin"
LOCAL_MYSQL_PASSWORD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;)
LOCAL_MYSQL_ROOT_PASSWORD=secret

sed -i "s+MYSQL_DATABASE=default+MYSQL_DATABASE=$LOCAL_MYSQL_DBNAME+g" "${DOCKER_PATH}"/.env
sed -i "s+MYSQL_USER=default+MYSQL_USER=$LOCAL_MYSQL_USER+g" "${DOCKER_PATH}"/.env
sed -i "s+MYSQL_PASSWORD=secret+MYSQL_PASSWORD=$LOCAL_MYSQL_PASSWORD+g" "${DOCKER_PATH}"/.env
sed -i "s+MYSQL_ROOT_PASSWORD=root+MYSQL_ROOT_PASSWORD=$LOCAL_MYSQL_ROOT_PASSWORD+g" "${DOCKER_PATH}"/.env

### Copy the ".env" file to "config/local/docker"
verbose "Copying Docker Compose \".env\" file to local Docker configs..."
mkdir -p "${CONFIGS_PATH}"/docker || { 
    usage
    echo
    echo "ERROR: Unable to create ${CONFIGS_PATH}/docker: $?"
    exit
}

cp "${DOCKER_PATH}"/.env "${CONFIGS_PATH}"/docker/.env

### =================================================== ###
### Docker docker-compose.yml
### =================================================== ###
verbose "Creating Docker Compose \"docker-compose.yml\" file, and making project-specific..."
sed -i 's+- ${DATA_PATH_HOST}/mysql:/var/lib/mysql+- mysql:/var/lib/mysql+g' "${DOCKER_PATH}"/docker-compose.yml

### Copy the "docker-compose.yml" file to "config/local/docker"
verbose "Copying Docker Compose \"docker-compose.yml\" file to local Docker configs..."
cp "${DOCKER_PATH}"/docker-compose.yml "${CONFIGS_PATH}"/docker/docker-compose.yml

### =================================================== ###
### MySQL
### =================================================== ###
### my.cnf: Change the character set from utf-8 to 
###         utf8mb4
### =================================================== ###
verbose "Creating MySQL \"my.cnf\" file, and making project-specific..."
sed -i 's+character-set-server=utf8+character-set-server=utf8mb4+g' "${DOCKER_PATH}"/mysql/my.cnf

### =================================================== ###
### Copy over the database setup files and do the
### substitutions
### =================================================== ###
cp "${BASE_DIR}"/templates/mysql/docker-entrypoint-initdb.d/*.sql "${DOCKER_PATH}"/mysql/docker-entrypoint-initdb.d/
sed -i "s+###APP_NAME###+$APP_NAME+g" "${DOCKER_PATH}"/mysql/docker-entrypoint-initdb.d/db-init.sql
sed -i "s+###APP_NAME###+$APP_NAME+g" "${DOCKER_PATH}"/mysql/docker-entrypoint-initdb.d/test-db-init.sql

sed -i "s+###DB_PASSWD###+$LOCAL_MYSQL_PASSWORD+g" "${DOCKER_PATH}"/mysql/docker-entrypoint-initdb.d/db-init.sql
sed -i "s+###DB_PASSWD###+$LOCAL_MYSQL_PASSWORD+g" "${DOCKER_PATH}"/mysql/docker-entrypoint-initdb.d/test-db-init.sql

### Copy the MySQL config files to "config/local/mysql"
verbose "Copying MySQL file to \"config/local/mysql\"..."
mkdir -p "${CONFIGS_PATH}"/mysql || { 
    usage
    echo
    echo "ERROR: Unable to create ${CONFIGS_PATH}/mysql: $?"
    exit
}
cp -r "${DOCKER_PATH}"/mysql/* "${CONFIGS_PATH}"/mysql/

### =================================================== ###
### nginx: Copy the laravel example conf file to one
### with the name of the app, then, within the file,
### replace all instances of "laravel" with the $APP_NAME
### =================================================== ###
verbose "Creating nginx \"${APP_NAME}.conf\" file, and making project-specific..."
cp "${DOCKER_PATH}"/nginx/sites/laravel.conf.example "${DOCKER_PATH}"/nginx/sites/${APP_NAME}.conf
sed -i "s+laravel+$APP_NAME+g" "${DOCKER_PATH}"/nginx/sites/${APP_NAME}.conf

### Copy the nginx config file to "config/local/nginx/sites"
verbose "Creating nginx \"${CONFIGS_PATH}/nginx/sites\" path..."
mkdir -p "${CONFIGS_PATH}"/nginx/sites || { 
    usage
    echo
    echo "ERROR: Unable to create ${CONFIGS_PATH}/nginx/sites: $?"
    exit
}
verbose "Copying \"${APP_NAME}.conf\" file to \"${CONFIGS_PATH}/nginx/sites\"..."
cp "${DOCKER_PATH}"/nginx/sites/${APP_NAME}.conf "${CONFIGS_PATH}"/nginx/sites/${APP_NAME}.conf

### =================================================== ###
### Build the containers
### =================================================== ###
verbose "Building the containers"
verbose "This step takes a while..."
cd "${DOCKER_PATH}"
docker-compose up --build --detach redis mysql nginx

### =================================================== ###
### Setup the workspace container
### Make sure the WEB_ROOT_PATH exists in the workspace
### container
### =================================================== ###
verbose "Setting up the workspace container..."
CONTAINER_ID="$(docker ps -aqf name=${APP_NAME}_workspace_1)"
verbose "CONTAINER_ID: ${CONTAINER_ID}"

if [[ -z "${CONTAINER_ID}" ]]; then
    docker -p
    echo
    echo "ERROR: Cannot set workspace container_id"
    exit 99
fi

WEB_ROOT_PATH_EXISTS=$(docker exec "${CONTAINER_ID}" [ -d "${WEB_ROOT_PATH}" ] && echo "1" || echo "0")
verbose "WEB_ROOT_PATH_EXISTS: ${WEB_ROOT_PATH_EXISTS}"

if [[ "${WEB_ROOT_PATH_EXISTS}" != "1" ]]; then
    echo "${WEB_ROOT_PATH} does not exist."
    exit 100
fi

### =================================================== ###
### Set Workspace Executable Paths
### =================================================== ###
WORKSPACE_COMPOSER_EXECUTABLE=$(docker exec "${CONTAINER_ID}" which composer)
verbose "WORKSPACE_COMPOSER_EXECUTABLE: ${WORKSPACE_COMPOSER_EXECUTABLE}"

WORKSPACE_NPM_EXECUTABLE=$(docker exec "${CONTAINER_ID}" which npm)
verbose "WORKSPACE_NPM_EXECUTABLE: ${WORKSPACE_NPM_EXECUTABLE}"

### =================================================== ###
### Install Laravel
### =================================================== ###
verbose "Installing Laravel"
_CMD="cd ${WEB_ROOT_PATH} && ${WORKSPACE_COMPOSER_EXECUTABLE} create-project --prefer-dist laravel/laravel ."
verbose "RUNNING COMMAND: ${_CMD}"
docker-compose exec --user=laradock workspace sh -c "${_CMD}"

### =================================================== ###
### Create, copy and save the Laravel ".env" file
### We should do this locally, rather than in the
### container
### =================================================== ###
verbose "Creating Laravel \".env\" file..."
cp "${SRC_PATH}"/.env.example "${SRC_PATH}"/.env

verbose "Making Laravel \".env\" file project-specific..."
sed -i "s+APP_NAME=Laravel+APP_NAME=$APP_NAME+g" "${SRC_PATH}"/.env
sed -i "s+APP_URL=http://localhost+APP_URL=http://${APP_NAME}.test+g" "${SRC_PATH}"/.env
sed -i "s+DB_HOST=127.0.0.1+DB_HOST=mysql+g" "${SRC_PATH}"/.env
sed -i "s+DB_DATABASE=laravel+DB_DATABASE=${LOCAL_MYSQL_DBNAME}+g" "${SRC_PATH}"/.env
sed -i "s+DB_USERNAME=root+DB_USERNAME=${LOCAL_MYSQL_USER}+g" "${SRC_PATH}"/.env
sed -i "s+DB_PASSWORD=+DB_PASSWORD=${LOCAL_MYSQL_PASSWORD}+g" "${SRC_PATH}"/.env

### For safety, force creation of the APP_KEY
verbose "Forcing creation pof APP_KEY..."
docker-compose exec --user=laradock workspace sh -c "cd ${WEB_ROOT_PATH} && php artisan key:generate"

verbose "Creating laravel \"${CONFIGS_PATH}/laravel\" path..."
mkdir -p "${CONFIGS_PATH}"/laravel || { 
    usage
    echo
    echo "ERROR: Unable to create ${CONFIGS_PATH}/laravel: $?"
    exit
}
verbose "Copying Laravel \".env\" file to \"${CONFIGS_PATH}/laravel\"..."
cp "${SRC_PATH}"/.env "${CONFIGS_PATH}"/laravel/.env

### =================================================== ###
### Set file and directorypermissions
### =================================================== ###
verbose "Setting workspace directory permissions"
docker-compose exec --user=laradock workspace sh -c "cd ${WEB_ROOT_PATH} && find . -type d -exec chmod 755 {} \;"

verbose "Setting workspace file permissions"
docker-compose exec --user=laradock workspace sh -c "cd ${WEB_ROOT_PATH} && find . -type f -exec chmod 644 {} \;"

verbose "Setting workspace directory permissions for storage/ and bootstrap/cache"
docker-compose exec --user=laradock workspace sh -c "cd ${WEB_ROOT_PATH} && chmod -R ug+rwx storage bootstrap/cache"

### =================================================== ###
### Install Composer Packages
### =================================================== ###
verbose "Installing Composer Packages in workspace"
docker-compose exec --user=laradock workspace sh -c "cd ${WEB_ROOT_PATH} && ${WORKSPACE_COMPOSER_EXECUTABLE} install"

### =================================================== ###
### Install Node Packages
### =================================================== ###
verbose "Installing Node Packages"
docker-compose exec --user=laradock workspace sh -c "cd ${WEB_ROOT_PATH} && ${WORKSPACE_NPM_EXECUTABLE} install && ${WORKSPACE_NPM_EXECUTABLE} rebuild && ${WORKSPACE_NPM_EXECUTABLE} run dev"

verbose "Done. Enjoy your new project!"
verbose "Remember to add \"${APP_NAME}.test\" to your hosts file. (See README.md if you don't know how to do this.)"

### =================================================== ###
### Save and commit the sub-module files
### =================================================== ###
verbose "Committing sudmodule files."
cd ${DOCKER_PATH}
git add .
git commit -m "Initial sudmodule commit."

### =================================================== ###
### Save and commit the project files
### =================================================== ###
verbose "Committing initial files."
cd ${LOCAL_APP_PATH}
git add .
verbose "Explicitly commit the submodule files."
git add "${DOCKER_PATH}/"
git commit -m "Initial commit."

exit
