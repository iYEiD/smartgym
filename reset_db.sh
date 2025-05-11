 #!/bin/bash

# Display banner
echo "========================================"
echo "Smart Gym AI - Database Reset Script"
echo "========================================"
echo "This script will:"
echo "1. Stop all running containers"
echo "2. Remove the Postgres data volume"
echo "3. Restart the containers with a fresh database"
echo ""
echo "WARNING: All data will be lost!"
echo "========================================"
echo ""

# Confirm with user
read -p "Are you sure you want to continue? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Stop containers
echo "Stopping containers..."
docker-compose down

# Remove postgres data volume
echo "Removing database volume..."
docker volume rm smartgymai_postgres_data

# Restart containers
echo "Restarting containers with fresh database..."
docker-compose up -d

# Wait for database to be ready
echo "Waiting for database to initialize..."
sleep 5

# Check if database is ready
echo "Checking database status..."
max_attempts=12
attempt=1
while [ $attempt -le $max_attempts ]; do
  if docker-compose exec postgres pg_isready -U smartgym -d smartgym_db; then
    echo "Database is ready!"
    echo ""
    echo "Database has been successfully reset and reinitialized."
    echo "========================================"
    exit 0
  fi
  echo "Database not ready yet. Waiting... (Attempt $attempt/$max_attempts)"
  sleep 5
  attempt=$((attempt+1))
done

echo "Database did not become ready in the expected time."
echo "You may need to check the logs with: docker-compose logs postgres"
echo "========================================"
exit 1