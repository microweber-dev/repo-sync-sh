PROJECT_DIR=/home/v3microweber/code
PROJECT_PUBLIC_DIR=/home/v3microweber/public_html

ln -s $PROJECT_DIR/public $PROJECT_PUBLIC_DIR

if [ ! -d "$PROJECT_DIR" ]; then
    echo "The project directory does not exist."
    exit 1
fi

#SELF_DIR=$(dirname "$0")
#
#chmod 777 $SELF_DIR/update-interface.php
#rm -rf $PROJECT_DIR/public/update.php
#ln -s $SELF_DIR/update-interface.php $PROJECT_DIR/public/update.php


wget https://raw.githubusercontent.com/microweber-dev/repo-sync-sh/refs/heads/main/branding_saas.json -O $PROJECT_DIR/storage/branding.json

WORKDIR="microweber-updater"
if [ ! -d "$WORKDIR" ]; then
    mkdir $WORKDIR
fi
WORKDIR_REL_PATH=$(pwd)/$WORKDIR

cd $WORKDIR

## CLONE THE MICROWEBER REPOSITORY

# Check if the folder exists
if [ ! -d "microweber" ]; then
    # Clone the repository
    git clone https://github.com/microweber/microweber.git
fi

# Enter the folder
cd microweber
rm -rf composer.lock
rm -rf vendor
git checkout filament
git pull origin filament



#### CLONE THE TEMPLATES
SSH_KEYS_REL_PATH=$WORKDIR_REL_PATH/.SSH_KEYS
if [ ! -d "$SSH_KEYS_REL_PATH" ]; then
    mkdir -p $SSH_KEYS_REL_PATH
    ssh-keygen -t rsa -b 4096 -f $SSH_KEYS_REL_PATH/id_rsa -N ""
fi

# show to user the public key to add it to the git repository
echo "Add the following public key to the git repository:"
cat $SSH_KEYS_REL_PATH/id_rsa.pub

# Add the private key to the ssh-agent
eval "$(ssh-agent -s)"
ssh-add $SSH_KEYS_REL_PATH/id_rsa

# Add the private key to the ssh config
echo "Host github.com
  IdentityFile $SSH_KEYS_REL_PATH/id_rsa" > $SSH_KEYS_REL_PATH/config

chmod 600 $SSH_KEYS_REL_PATH/id_rsa
chmod 600 $SSH_KEYS_REL_PATH/id_rsa.pub
chmod 600 $SSH_KEYS_REL_PATH/config

## CLONE BIG
cd $WORKDIR_REL_PATH/microweber/Templates
if [ ! -d "Big2" ]; then
    git clone git@github.com:microweber-templates/big2.git Big2
fi

git pull

## CLONE TAILWIND
cd $WORKDIR_REL_PATH/microweber/Templates
if [ ! -d "Tailwind" ]; then
    git clone git@github.com:microweber-templates/Tailwind.git Tailwind
fi
cd $WORKDIR_REL_PATH/microweber/Templates/Tailwind
git pull

cd $WORKDIR_REL_PATH/microweber

## Install npm dependencies
npm install
#
## Build the assets
npm run build
#
## Install the dependencies
composer install --ignore-platform-reqs
#

rm -rf $PROJECT_DIR/Modules
rsync -a --quiet $WORKDIR_REL_PATH/microweber/Modules/ $PROJECT_DIR/Modules/

rm -rf $PROJECT_DIR/Templates
rsync -a --quiet $WORKDIR_REL_PATH/microweber/Templates/ $PROJECT_DIR/Templates/

rm -rf $PROJECT_DIR/vendor
rsync -a --quiet $WORKDIR_REL_PATH/microweber/vendor/ $PROJECT_DIR/vendor/

rm -rf $PROJECT_DIR/src
rsync -a --quiet $WORKDIR_REL_PATH/microweber/src/ $PROJECT_DIR/src/

rm -rf $PROJECT_DIR/packages
rsync -a --quiet $WORKDIR_REL_PATH/microweber/packages/ $PROJECT_DIR/packages/

#rm -rf $PROJECT_DIR/database
rsync -a --quiet $WORKDIR_REL_PATH/microweber/database/ $PROJECT_DIR/database/

rm -rf $PROJECT_DIR/app
rsync -a --quiet $WORKDIR_REL_PATH/microweber/app/ $PROJECT_DIR/app/

rm -rf $PROJECT_DIR/bootstrap
rsync -a --quiet $WORKDIR_REL_PATH/microweber/bootstrap/ $PROJECT_DIR/bootstrap/

rm -rf $PROJECT_DIR/resources
rsync -a --quiet $WORKDIR_REL_PATH/microweber/resources/ $PROJECT_DIR/resources/

rm -rf $PROJECT_DIR/public
rsync -a --quiet $WORKDIR_REL_PATH/microweber/public/ $PROJECT_DIR/public/

rm -rf $PROJECT_DIR/composer.json
rsync -a --quiet $WORKDIR_REL_PATH/microweber/composer.json $PROJECT_DIR/composer.json

rm -rf $PROJECT_DIR/package.json
rsync -a --quiet $WORKDIR_REL_PATH/microweber/package.json $PROJECT_DIR/package.json

rm -rf $PROJECT_DIR/composer.lock
rsync -a --quiet $WORKDIR_REL_PATH/microweber/composer.lock $PROJECT_DIR/composer.lock

rsync -a --quiet $WORKDIR_REL_PATH/microweber/.git $PROJECT_DIR/.git

echo "The update is completed."
