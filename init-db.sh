#!/bin/bash
set -e

# Auto-generate credentials if not provided
if [ -z "$POSTGRES_PASSWORD" ]; then
  export POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)
  echo "Auto-generated POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
fi

if [ -z "$DATABASE_PASSWORD" ]; then
  export DATABASE_PASSWORD=$POSTGRES_PASSWORD
  echo "Auto-generated DATABASE_PASSWORD: $DATABASE_PASSWORD"
fi

# Save generated credentials for reference
cat <<EOF > /var/lib/postgresql/data/.env.generated
# Auto-generated credentials (first run only)
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
DATABASE_PASSWORD=$DATABASE_PASSWORD
DATABASE_USER=${DATABASE_USER:-peakssh}
DATABASE_NAME=${DATABASE_NAME:-peakssh}
EOF

chmod 600 /var/lib/postgresql/data/.env.generated

# Create database user if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DATABASE_USER:-peakssh}') THEN
            CREATE ROLE "${DATABASE_USER:-peakssh}" WITH LOGIN PASSWORD '${DATABASE_PASSWORD:-}';
        END IF;
    END
    \$\$;
    GRANT ALL PRIVILEGES ON DATABASE "${DATABASE_NAME:-peakssh}" TO "${DATABASE_USER:-peakssh}";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "${DATABASE_USER:-peakssh}";
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "${DATABASE_USER:-peakssh}";
EOSQL

echo "Database initialization complete."
