import os

def get_env_var(name, default=None):
    value = os.environ.get(name, default)
    if value is None:
        raise Exception(f"Переменная окружения {name} не установлена!")
    return value

SECRET_KEY = get_env_var('SECRET_KEY')
SQLALCHEMY_DATABASE_URI = get_env_var('DATABASE_URL')
SQLALCHEMY_TRACK_MODIFICATIONS = False

# Дополнительно: если используются Celery/Redis
# CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'redis://localhost:6379/0')
