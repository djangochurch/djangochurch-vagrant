#!/bin/bash

# Install packages needed
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install --no-install-recommends -y build-essential python2.7-dev python-virtualenv postgresql-9.3 libpq-dev libjpeg-turbo8-dev libtiff5-dev libwebp-dev git

# Setup virtual environment
virtualenv $HOME/venv
source $HOME/venv/bin/activate

# Need Django before we can use django-admin.py
pip install https://www.djangoproject.com/download/1.7.b4/tarball/

mkdir -p /vagrant/sites/house
cd /vagrant/sites
django-admin.py startproject mychurch house --template=https://github.com/djangochurch/djangochurch-heroku/archive/master.zip --name=Procfile

# Override some of the settings so media works locally
cat > /vagrant/sites/house/mychurch/local_settings.py << EOF
DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'
THUMBNAIL_DEFAULT_STORAGE = 'easy_thumbnails.storage.ThumbnailFileSystemStorage'
MEDIA_ROOT = '/vagrant/sites/media'
EOF

for THEME in bold fresh calm light
do
    cp -a house $THEME
done

# Install default themes
for THEME in bold fresh calm house light
do
    pushd $THEME
    curl -sL https://github.com/djangochurch/djangochurch-theme-$THEME/tarball/master | tar zxv
    mv djangochurch-djangochurch-theme-$THEME-* theme
    popd
done

cd house
pip install -r requirements.txt

sudo -u postgres createuser $USER
sudo -u postgres createdb $USER
export DATABASE_URL="postgres:///$USER"

python manage.py migrate --noinput
# All because you can't specify a password on the command line...
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.org', 'admin')" | python manage.py shell

# Start the Django processes
sudo sed -e 's/THEME/bold/g' -e 's/PORT/5001/g' /vagrant/upstart-site.conf | sudo tee /etc/init/djangochurch-bold.conf >/dev/null
sudo sed -e 's/THEME/fresh/g' -e 's/PORT/5002/g' /vagrant/upstart-site.conf | sudo tee /etc/init/djangochurch-fresh.conf >/dev/null
sudo sed -e 's/THEME/calm/g' -e 's/PORT/5003/g' /vagrant/upstart-site.conf | sudo tee /etc/init/djangochurch-calm.conf >/dev/null
sudo sed -e 's/THEME/house/g' -e 's/PORT/5004/g' /vagrant/upstart-site.conf | sudo tee /etc/init/djangochurch-house.conf >/dev/null
sudo sed -e 's/THEME/light/g' -e 's/PORT/5005/g' /vagrant/upstart-site.conf | sudo tee /etc/init/djangochurch-light.conf >/dev/null

for THEME in media bold fresh calm house light
do
    sudo initctl start djangochurch-$THEME
done
