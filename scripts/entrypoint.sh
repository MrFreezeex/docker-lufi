#! /bin/sh
set -e

CONF_FILE="$APP_WORK/lufi.conf"
PID_FILE="$APP_WORK/lufi.pid"
DB_FILE="$APP_WORK/lufi.db"
ENV_FILE="$APP_WORK/lufi.env"

TEMP_FOLDER="$APP_WORK/tmp"
FILE_FOLDER="$APP_WORK/files"

MAX_FILE_SIZE=${MAX_FILE_SIZE:-"10*1024*1024*1024"}
DEFAULT_DELAY=${DEFAULT_DELAY:-"7"}
MAX_DELAY=${MAX_DELAY:-"60"}
INSTANCE_NAME=${INSTANCE_NAME:-"Lufi"}
SECRET=${SECRET:-$(head -c1024 /dev/urandom | sha1sum | cut -d' ' -f1)}

if [ ! -f "$CONF_FILE" ]; then
	# Création de la configuration
	cp "$APP_HOME/lufi.conf.template" "$CONF_FILE"

	# Modifications des valeurs
	sed -i -E "s|listen\s+=>\s+\['.*'\]|listen => ['http://*:8080']|" "$CONF_FILE"
	sed -i -E "s|#proxy\s+=>.*,|proxy => 1,|" "$CONF_FILE"

	sed -i -E "s|#contact\s+=>.*,|contact => '<a href=\"mailto:$CONTACT\">Contact</a>',|" "$CONF_FILE"
	sed -i -E "s|#report\s+=>.*,|report => '$CONTACT',|" "$CONF_FILE"
	sed -i -E "s|#secrets\s+=>.*,|secrets => ['$SECRET'],|" "$CONF_FILE"

	sed -i -E "s|#dbtype\s+=>.*,|dbtype => 'sqlite',|" "$CONF_FILE"
	sed -i -E "s|#db_path\s+=>.*,|db_path => '$DB_FILE',|" "$CONF_FILE"

	sed -i -E "s|#upload_dir\s+=>.*,|upload_dir  => '$FILE_FOLDER',|" "$CONF_FILE"

	# lower default values
	sed -i -E "s|workers\s+=>.*,|workers  => 8,|" "$CONF_FILE"
	sed -i -E "s|clients\s+=>.*,|clients  => 1,|" "$CONF_FILE"

	# Pid file
	sed -i "/hypnotoad => {/a        pid_file => '$PID_FILE'," "$CONF_FILE"

	sed -i -E "s|#default_delay\s+=>.*,|default_delay  => $DEFAULT_DELAY,|" "$CONF_FILE"
	sed -i -E "s|#max_delay\s+=>.*,|max_delay  => $MAX_DELAY,|" "$CONF_FILE"
	sed -i -E "s|#max_file_size\s+=>.*,|max_file_size  => $MAX_FILE_SIZE,|" "$CONF_FILE"
	sed -i -E "s|#instance_name\s+=>.*,|instance_name  => '$INSTANCE_NAME',|" "$CONF_FILE"
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
exec docker-carton exec hypnotoad -f script/lufi
