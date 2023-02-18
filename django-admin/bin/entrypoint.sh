#! /bin/bash
if [ ! -z "$app" ] && [ "$app" == "worker" ]
    then
        celery -A $app_name worker -l "$LOG_LEVEL"
    else
        if [ ! -z "$DEBUG" ] && [ "$DEBUG" == "true" ]
        then
            python manage.py collectstatic --no-input
        fi
        python manage.py migrate
        python manage.py createsuperuser --noinput
        gunicorn -c python:config.gunicorn config.wsgi
fi