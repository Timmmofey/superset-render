import os

SECRET_KEY = os.environ.get('SECRET_KEY', 'temporary-secret-key')
raw_url = os.environ.get('DATABASE_URL')
if raw_url and raw_url.startswith('postgresql://'):
    raw_url = raw_url.replace('postgresql://', 'postgresql+psycopg2://', 1)
SQLALCHEMY_DATABASE_URI = raw_url
SQLALCHEMY_TRACK_MODIFICATIONS = False
