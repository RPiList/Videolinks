Export mittels Portainer im Docker-Container: <br>
<code>document_exporter ../export -z</code>

Export mit SSH auf dem Docker-Host: <br>
ggf. "sudo -i" zum Root-Nutzer machen. <br>
<code>docker exec [Name Paperless Webserver] document_exporter ../export -z</code>

Import mittels Portainer im Docker-Container: <br>
<code>document_importer ../export</code>

Import mit SSH auf dem Docker-Host: <br>
<code>sudo -i</code><br>
<code>docker exec [Name Paperless Webserver] document_importer ../export</code>

Import Synology Aufgabenplanung (als root): <br>
<code>bash -c "docker exec [Name Paperless Webserver] document_importer ../export"</code>
