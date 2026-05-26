import os

def get_env_var(name, default=None):
    value = os.environ.get(name, default)
    if value is None:
        raise Exception(f"Переменная {name} не установлена!")
    return value

SECRET_KEY = get_env_var('SECRET_KEY')
# Явно указываем драйвер psycopg2
raw_url = get_env_var('DATABASE_URL')
if raw_url.startswith('postgresql://'):
    raw_url = raw_url.replace('postgresql://', 'postgresql+psycopg2://', 1)
SQLALCHEMY_DATABASE_URI = raw_url
SQLALCHEMY_TRACK_MODIFICATIONS = False
