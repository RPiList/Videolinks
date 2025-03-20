#!/bin/bash

# Copyright 2025 by SemperVideo und Twitch-Chat und ChatGPT.
# Version 2025-03-20

# Prüfen, ob eine Nummer als Argument übergeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: $0 <Nummer>"
    exit 1
fi

NUMMER=$1
# Verzeichnis des Spiels.
INSTALLDIR="/home/steam/arma3/"
STEAMAPPS="steamapps/workshop/content/"
# SteamID des Spiels.
GAMEID="107410"
MODDIR=$INSTALLDIR$STEAMAPPS$GAMEID/$NUMMER
OUTPUT_DATEI="output_$NUMMER.txt"
OUTPUT=$INSTALLDIR$OUTPUT_DATEI
SYMLINK=$INSTALLDIR@$NUMMER

# Prüfen ob alter .bikey existiert und löschen, falls ja
BIKEY_DATEI_ALT=$(find "$MODDIR" -type f -name "*.bikey" | head -n 1)
rm -f "${INSTALLDIR}keys/$INSTALLDIRkeys$(basename "$BIKEY_DATEI_ALT")"

# Prüfen, ob das Verzeichnis XYZ existiert und löschen, falls ja
if [ -d "$MODDIR" ]; then
    echo "Verzeichnis '$MODDIR' existiert bereits. Wird gelöscht..."
    rm -rf "$MODDIR"
    echo "Verzeichnis '$MODDIR' wurde gelöscht."
fi

# cred.env-Datei einlesen
if [ -f cred.env ]; then
    export $(grep -E '^(Login|Pass)=' cred.env | xargs)
    
    # Prüfen, ob Login und Pass gesetzt wurden
    if [ -z "$Login" ] || [ -z "$Pass" ]; then
        echo "FEHLER: Login oder Passwort nicht in cred.env gefunden."
        echo "Programm wird abgebrochen."
        exit 1
    fi
else
    echo "FEHLER: cred.env-Datei nicht gefunden!"
    echo "Programm wird abgebrochen."
    exit 1
fi

# Datei mit vier Zeilen erstellen
cat <<EOF > "$OUTPUT"
force_install_dir $INSTALLDIR
login $Login $Pass
workshop_download_item $GAMEID $NUMMER validate
quit
EOF

echo "Datei '$OUTPUT' wurde erstellt."
# steamcmd mit der erstellten Datei ausführen
steamcmd +runscript "$OUTPUT"
echo "steamcmd wurde mit '$OUTPUT' ausgeführt."
# Datei löschen
rm -f "$OUTPUT"
echo "Datei '$OUTPUT' wurde gelöscht."


# Softlink erstellen
if [ -L "$SYMLINK" ] || [ -e "$SYMLINK" ]; then
    echo "Ein Link oder eine Datei mit dem Namen '$SYMLINK' existiert bereits. Wird entfernt..."
    rm -f "$SYMLINK"
fi
ln -s "$MODDIR" "$SYMLINK"
echo "Softlink wurde erstellt."


find "$MODDIR" -depth | while read FILE; do
    BASENAME=$(basename "$FILE")
    DIRNAME=$(dirname "$FILE")
    LOWERCASE_NAME=$(echo "$BASENAME" | tr '[:upper:]' '[:lower:]')

    if [ "$BASENAME" != "$LOWERCASE_NAME" ]; then
        NEW_PATH="$DIRNAME/$LOWERCASE_NAME"
        if [ -e "$NEW_PATH" ]; then
            echo "Warnung: '$NEW_PATH' existiert bereits, überspringe Umbenennung."
        else
            mv "$FILE" "$NEW_PATH"
            echo "Umbenannt: '$FILE' -> '$NEW_PATH'"
        fi
    fi
done

BIKEY_DATEI=$(find "$MODDIR" -type f -name "*.bikey" | head -n 1)

if [ -z "$BIKEY_DATEI" ]; then
    echo "Keine .bikey-Datei gefunden!"
    exit 1
fi

# Datei ins Zielverzeichnis kopieren (mit Überschreiben)
cp -f "$BIKEY_DATEI" "$INSTALLDIR/keys"

echo "Datei '$BIKEY_DATEI' wurde kopiert."
