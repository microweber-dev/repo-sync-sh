PROJECT_DIR=/home/v3microweber/public_html

if [ ! -d "$PROJECT_DIR" ]; then
    echo "The project directory does not exist."
    exit 1
fi

WORKDIR="microweber-updater"
if [ ! -d "$WORKDIR" ]; then
    mkdir $WORKDIR
fi
WORKDIR_REL_PATH=$(pwd)/$WORKDIR

cd $WORKDIR


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


cd $WORKDIR_REL_PATH/microweber/Templates
if [ ! -d "Big2" ]; then
    git clone git@github.com:microweber-templates/big2.git Big2
fi

git pull

rsync -a --quiet $WORKDIR_REL_PATH/microweber/Templates/ $PROJECT_DIR/Templates/


## CLONE THE MICROWEBER REPOSITORY

# Check if the folder exists
if [ ! -d "microweber" ]; then
    # Clone the repository
    git clone https://github.com/microweber/microweber.git
fi

# Enter the folder
cd microweber
git checkout filament
git pull origin filament

## Install npm dependencies
npm install
#
## Build the assets
npm run build
#
## Install the dependencies
composer install --ignore-platform-req=ext-sodium
#
rsync -a --quiet $WORKDIR_REL_PATH/microweber/Modules/ $PROJECT_DIR/Modules/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/Templates/ $PROJECT_DIR/Templates/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/vendor/ $PROJECT_DIR/vendor/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/src/ $PROJECT_DIR/src/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/packages/ $PROJECT_DIR/packages/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/database/ $PROJECT_DIR/database/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/app/ $PROJECT_DIR/app/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/bootstrap/ $PROJECT_DIR/bootstrap/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/resources/ $PROJECT_DIR/resources/
rsync -a --quiet $WORKDIR_REL_PATH/microweber/public/ $PROJECT_DIR/public/


echo "The update is completed."
