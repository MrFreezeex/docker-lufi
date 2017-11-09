#! /bin/sh
set -e

CONF_FILE="$APP_WORK/lufi.conf"
PID_FILE="$APP_WORK/lufi.pid"
DB_FILE="$APP_WORK/lufi.db"
ENV_FILE="$APP_WORK/lufi.env"

TEMP_FOLDER="$APP_WORK/tmp"
FILE_FOLDER="$APP_WORK/files"

if [ ! -f "$CONF_FILE" ]; then
	# Création de la configuration
	cp "$APP_HOME/lufi.conf.template" "$CONF_FILE"

	# Modifications des valeurs
	sed -i -E "s|listen\s+=>\s+\['.*'\]|listen => ['http://*:8080']|" "$CONF_FILE"
	sed -i -E "s|#proxy\s+=>.*,|proxy => 1,|" "$CONF_FILE"

	sed -i -E "s|#contact\s+=>.*,|contact => 'docker[at]localhost.localdomain',|" "$CONF_FILE"
	sed -i -E "s|#secrets\s+=>.*,|secrets => '$(head -c1024 /dev/urandom | sha1sum | cut -d' ' -f1)',|" "$CONF_FILE"

	sed -i -E "s|#dbtype\s+=>.*,|dbtype => 'sqlite',|" "$CONF_FILE"
	sed -i -E "s|#db_path\s+=>.*,|db_path => '$DB_FILE',|" "$CONF_FILE"

	sed -i -E "s|#upload_dir \s+=>.*,|upload_dir  => '$FILE_FOLDER',|" "$CONF_FILE"

	# lower default values
	sed -i -E "s|workers \s+=>.*,|workers  => 8,|" "$CONF_FILE"
	sed -i -E "s|clients \s+=>.*,|clients  => 1,|" "$CONF_FILE"

	# Pid file
	sed -i "/hypnotoad => {/a        pid_file => '$PID_FILE'," "$CONF_FILE"
fi

# VACUUM DB
if [ -f "$DB_FILE" ]; then
	echo "Vacuum $DB_FILE ..."
	echo "vacuum;" | sqlite3 "$DB_FILE"
fi

# Clean pid file
if [ -f "$PID_FILE" ]; then
	echo "Removing $PID_FILE .."
	rm -f $PID_FILE
fi

# Temp folder
if [ ! -d "$TEMP_FOLDER" ]; then
	mkdir -v --mode=0700 "$TEMP_FOLDER";
else
	# clean tmp
	rm -f "$TEMP_FOLDER"/*
fi

# Files folder
if [ ! -d "$FILE_FOLDER" ]; then
	mkdir -v --mode=0700 "$FILE_FOLDER";
fi

# Reset perms
chown -R "$APP_USER" "$APP_WORK"

# Generate env file
echo "export MOJO_CONFIG=\"$CONF_FILE\"" > "$ENV_FILE"
echo "export MOJO_TMPDIR=\"$APP_WORK/tmp\"" >> "$ENV_FILE"

# Démarrage de Lstu
exec docker-carton exec hypnotoad -f script/application
