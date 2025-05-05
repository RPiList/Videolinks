#!/usr/bin/python3.12
# Version 2025.06
import os
import requests
import csv
import datetime
from dotenv import load_dotenv
load_dotenv()

mod_dir = '/home/steam/arma3/steamapps/workshop/content/107410'
steam_mod_liste = '/home/steam/arma3/v2.csv'

telegram_chat_id = os.getenv('telegram_chat_id')
token = os.getenv('token')

def update_mods_csv(directory_path):
    # Schritt 1: Alle Unterverzeichnisse im angegebenen Verzeichnis finden
    subdirs = [name for name in os.listdir(directory_path)
            if os.path.isdir(os.path.join(directory_path, name))]

    csv_file = os.path.join(directory_path, steam_mod_liste)

    # Schritt 2: Bereits vorhandene Einträge laden (falls CSV existiert)
    existing_entries = set()
    if os.path.exists(csv_file):
        with open(csv_file, mode='r', newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                if row:  # Leere Zeilen ignorieren
                    existing_entries.add(row[0])

    # Schritt 3: Neue Einträge ergänzen
    with open(csv_file, mode='a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        for subdir in subdirs:
            if subdir not in existing_entries:
                writer.writerow([subdir, "1"])

# Beispielnutzung:
update_mods_csv(mod_dir)  # Ersetze das mit dem tatsächlichen Pfad

updated_rows = []

with open(steam_mod_liste, newline='', encoding='utf-8') as csvfile:
    reader = csv.reader(csvfile)

    for row in reader:
        if len(row) < 2:
            print("Ungültige Zeile (nicht genug Werte):", row)
            continue

        mod_name = row[0].strip()
        try:
            local_time = int(row[1].strip())
        except ValueError:
            print(f"Ungültiger Zeitstempel in Zeile: {row}")
            continue

        # Anfrage an die Steam API
        url = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/"
        data = {
            'itemcount': 1,
            'publishedfileids[0]': mod_name  # ACHTUNG: Falls mod_name nicht die ID ist, hier ggf. row[1] verwenden!
        }

        response = requests.post(url, data=data)

        if response.status_code == 200:
            json_data = response.json()

            try:
                remote_time = json_data['response']['publishedfiledetails'][0]['time_updated']
                mod_friendly_name = json_data['response']['publishedfiledetails'][0]['title']
                # Vergleichen und ggf. aktualisieren
                if remote_time > local_time:
                    print(f"Update für {mod_name}: {local_time} -> {remote_time}")
                    dt_object = datetime.datetime.fromtimestamp(remote_time-28800)
                    print(f"Steam ID: {mod_name} vom {dt_object.strftime("%d.%m.%Y %H:%M:%S")}.")
                    print(f"Infos unter https://steamcommunity.com/sharedfiles/filedetails/?id={mod_name}")
                    data_to_send = "Update für " + mod_friendly_name + " (" + mod_name + ") erschienen."
                    telegramurl = f"https://api.telegram.org/bot{token}/sendMessage?chat_id={telegram_chat_id}&text={data_to_send}"
                    requests.get(telegramurl).json()
                    updated_rows.append([mod_name, str(remote_time)])
                else:
                    updated_rows.append([mod_name, str(local_time)])
            except (KeyError, IndexError) as e:
                print(f"Fehler beim Extrahieren von 'time_updated' für {mod_name}: {e}")
                updated_rows.append([mod_name, str(local_time)])
        else:
            print(f"Fehler bei der Anfrage für {mod_name}. Statuscode: {response.status_code}")
            updated_rows.append([mod_name, str(local_time)])

# Datei überschreiben mit aktualisierten Werten
with open(steam_mod_liste, 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerows(updated_rows)



