#mkdir -p /opt/technobureau
cd /opt/technobureau
/usr/bin/python3 -m venv --copies --upgrade-deps .venv
source .venv/bin/activate
    if [ -f "/tmp/requirements.txt" ]; then
        pip install -r /tmp/requirements.txt
    fi
    
    if [ -d "/tmp/venv" ]; then
        cp -r /tmp/venv/* $WORKDIR/
        chown $USER:0 -R $WORKDIR/
        chmod 750 -R $WORKDIR/
        #cd $WORKDIR
        #python3 manage.py collectstatic --no-input
    fi
    ##Removal of pip 
    pip uninstall -y pip
deactivate 