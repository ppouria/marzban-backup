#!/bin/bash

# Clean and update system
sudo apt update -y
sudo apt upgrade -y
clear

# Install required packages
echo "Installing unzip and rsync..."
sudo apt install unzip rsync -y
sleep 5
clear

# Define working directory
work_dir="/root/importer"
sql_backup_dir="$work_dir/sql-backups"

# Create working directory
mkdir -p "$work_dir"
mkdir -p "$sql_backup_dir"

# Ask user for backup action
while true; do
    echo "Choose an option:"
    echo "1) Enable backup"
    echo "2) Import backup"
    read -r choice

    if [[ "$choice" == "1" ]]; then
        echo "Enabling backup using AC-Lover..."
        sleep 5
        bash <(curl -Ls https://github.com/AC-Lover/backup/raw/main/backup.sh)
        exit 0
    elif [[ "$choice" == "2" ]]; then
        echo "Proceeding with backup import..."
        break
    else
        echo "Invalid input! Please enter 1 or 2."
    fi
done

# Step 1: Check for default backup path or ask for one
default_backup="/root/ac-backup-m.zip"
if [ -f "$default_backup" ]; then
    echo "Default backup found at $default_backup. Using it."
    zip_path="$default_backup"
else
    echo "Please enter the path to the backup file:"
    read -r zip_path
    if [ ! -f "$zip_path" ]; then
        echo "Backup file not found at the specified path! Exiting..."
        exit 1
    fi
fi

# Step 2: Extract the zip file
echo "Extracting the zip file..."
unzip "$zip_path" -d "$work_dir"
if [ $? -ne 0 ]; then
    echo "Failed to extract the zip file! Exiting..."
    exit 1
fi

# Step 3: Check MySQL status in extracted docker-compose.yml
compose_file="$work_dir/opt/marzban/docker-compose.yml"
if [ ! -f "$compose_file" ]; then
    echo "docker-compose.yml not found in extracted files! Exiting..."
    exit 1
fi

if grep -q "mysql:" "$compose_file"; then
    echo "MySQL is enabled in docker-compose.yml"
    mysql_enabled=true
else
    echo "MySQL is not enabled in docker-compose.yml"
    mysql_enabled=false
fi

# Step 4: Handle MySQL and folder transfers
if [ "$mysql_enabled" == true ] && [ -d "$work_dir/var/lib/marzban/mysql" ]; then
    echo "MySQL folder found in backup. Saving SQL backups..."
    mv "$work_dir/var/lib/marzban/mysql/db-backup/"*.sql "$sql_backup_dir/" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "No SQL backups found!"
    fi

    echo "Removing /var/lib/marzban/mysql folder..."
    rm -rf "$work_dir/var/lib/marzban/mysql"
fi

# Transfer other files regardless of MySQL status
echo "Moving files to /var/lib/marzban..."
rsync -av "$work_dir/var/lib/marzban/" /var/lib/marzban/

echo "Moving files to /opt/marzban..."
rsync -av "$work_dir/opt/marzban/" /opt/marzban/

# Step 5: Run Marzban update
echo "Running Marzban update..."
if command -v marzban >/dev/null 2>&1; then
    marzban update
    if [ $? -ne 0 ]; then
        echo "Marzban update failed!"
        exit 1
    fi
else
    echo "Marzban not found! Exiting..."
    exit 1
fi

# Step 6: Import SQL files if MySQL is enabled
if [ "$mysql_enabled" == true ] && [ -d "$sql_backup_dir" ]; then
    env_file="/opt/marzban/.env"
    if [ ! -f "$env_file" ]; then
        echo ".env not found! Exiting..."
        exit 1
    fi

    db_password=$(grep -oP '(?<=MYSQL_ROOT_PASSWORD=).*' "$env_file" | tr -d ' ')
    if [ -z "$db_password" ]; then
        echo "MySQL root password not found in .env! Exiting..."
        exit 1
    fi

    sleep 10
    echo "Importing SQL files into MySQL..."

    failed_imports=()
    for sql_file in "$sql_backup_dir"/*.sql; do
        if [ -f "$sql_file" ]; then
            dbname=$(basename "$sql_file" .sql)
            echo "Importing $sql_file into database $dbname..."
            cat "$sql_file" | docker exec -i marzban-mysql-1 mysql -u root -p"$db_password" "$dbname"
            if [ $? -ne 0 ]; then
                echo "Failed to import $sql_file!"
                failed_imports+=("$sql_file")
            else
                echo "$sql_file imported successfully!"
            fi
        fi
    done

    if [ ${#failed_imports[@]} -ne 0 ]; then
        echo ""
        echo "Warning: Some SQL files failed to import."
        echo "The folder $work_dir has NOT been deleted to allow manual recovery."
        echo "You can manually import the failed files with the following commands:"
        for fsql in "${failed_imports[@]}"; do
            dbname=$(basename "$fsql" .sql)
            echo "cat $fsql | docker exec -i marzban-mysql-1 mysql -u root -p'$db_password' $dbname"
        done
        echo ""
        echo "Please fix the issues and try importing again manually."
        # Skip folder deletion
        skip_cleanup=true
    else
        # No failures, safe to cleanup
        skip_cleanup=false
    fi

else
    echo "MySQL is not enabled or no SQL backups found. Skipping SQL import."
    skip_cleanup=false
fi

# Step 7: Clean up temporary files
if [ "$skip_cleanup" = false ]; then
    echo "Cleaning up temporary files..."
    rm -rf "$work_dir"
else
    echo "Skipping cleanup due to import errors. Please check manually."
fi

# Step 8: Restart Marzban
echo "Restarting Marzban..."
marzban restart

echo "Done!"
