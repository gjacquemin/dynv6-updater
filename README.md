# dynv6 — Mise à jour IPv6 sur macOS

Petit installateur macOS utilisant **launchd** pour appeler directement `curl` à l'ouverture de session puis environ toutes les 10 minutes. Aucun script n'est exécuté périodiquement.

## Installation

1. Télécharger et extraire le projet dans le dossier de son choix.
2. Ouvrir un Terminal dans ce dossier.
3. Exécuter :

   ```bash
   chmod +x Installer.command Desinstaller.command
   ./Installer.command
   ```

4. Indiquer son domaine dynv6 et son token à l'invite (saisie masquée pour le token).

Le service est installé dans `~/Library/LaunchAgents/` et les journaux sont écrits dans `~/Library/Logs/dynv6/` (`response.log` et `error.log`). L'installation ne nécessite pas `sudo`.

Le token est intégré au PLIST généré (permissions `600`). **Ne jamais publier ce PLIST, ni les journaux s'ils contiennent des informations sensibles.** Le token peut aussi apparaître temporairement dans les arguments du processus `curl`.

## Vérification

```bash
launchctl print "gui/$(id -u)/com.dynv6.updater"
launchctl kickstart -k "gui/$(id -u)/com.dynv6.updater"
cat "$HOME/Library/Logs/dynv6/response.log"
```

## Désinstallation

```bash
./Desinstaller.command
```

Les journaux sont conservés après désinstallation. Pour changer de domaine ou de token, relancer l'installateur.

## Notes

- Le service se lance à l'ouverture de la session utilisateur, **pas avant connexion**.
- macOS peut retarder les exécutions pendant la veille.
- `curl` doit être disponible. L'installateur utilise aussi `python3` pour encoder correctement l'URL.
- Si un ancien service portant un autre identifiant est déjà installé, le désinstaller séparément.
