<p align="center">
  <img src="images/app-icon.png" width="156" alt="Icône NetSpeedMenu">
</p>

# Guide d’utilisation de NetSpeedMenu 1.2

[简体中文](README.zh-CN.md) · [English](README.en.md) · [日本語](README.ja.md) · [Accueil](../README.md)

## Présentation

NetSpeedMenu (« 网速 ») est un petit utilitaire macOS qui affiche le débit réseau dans la barre des menus. `↑` indique le débit montant et `↓` le débit descendant. La zone occupée fait exactement 57 points et l’application n’apparaît pas dans le Dock.

La fenêtre de réglages contient :

- l’option de lancement silencieux à l’ouverture de session ;
- l’état actuel de l’élément de connexion ;
- la description, la version et l’auteur ;
- le bouton « 退出网速 » (« Quitter NetSpeedMenu »).

L’application fonctionne sous macOS 13 ou version ultérieure, sur Mac Intel et Apple Silicon.

<p align="center">
  <img src="images/settings-window.jpg" width="460" alt="Fenêtre de réglages de NetSpeedMenu">
</p>

## Télécharger et vérifier

Téléchargez `NetSpeedMenu-1.2-universal.dmg` depuis la page [Releases](../../../releases/latest) de ce dépôt. Le DMG est la méthode recommandée.

Vérifiez le fichier dans Terminal :

```bash
shasum -a 256 ~/Downloads/NetSpeedMenu-1.2-universal.dmg
```

SHA-256 attendu :

```text
92d47b7f0587d4daa878a29cfe73cb1a4271dda9fdb80796021604e430b7845e
```

## Installation

1. Double-cliquez sur `NetSpeedMenu-1.2-universal.dmg`.
2. Faites glisser `网速.app` vers le dossier Applications affiché à côté.
3. Ouvrez le dossier Applications et trouvez `网速`.
4. Suivez les instructions de premier lancement ci-dessous.

Le PKG est également disponible. Faites un clic avec la touche Contrôle sur `NetSpeedMenu-1.2-universal.pkg`, choisissez **Ouvrir**, puis suivez l’installateur. Un mot de passe administrateur peut être demandé.

## Pourquoi macOS affiche un avertissement

L’application elle-même utilise une signature ad hoc créée sur le Mac du développeur, tandis que le programme d’installation PKG n’est pas signé. **Aucun des deux n’utilise de signature Apple Developer ID et cette version n’est pas notariée par Apple.** Gatekeeper ne peut donc ni vérifier l’identité du développeur ni confirmer qu’Apple a contrôlé cette compilation. Les messages suivants peuvent apparaître :

- « Impossible de vérifier le développeur » ;
- « Apple ne peut pas vérifier l’absence de logiciels malveillants » ;
- une proposition de placement dans la Corbeille.

Ces messages ne prouvent pas à eux seuls qu’un logiciel malveillant a été détecté, mais ils ne doivent pas être ignorés. Vérifiez d’abord la source et le SHA-256.

## Premier lancement : méthode recommandée

1. Double-cliquez une première fois sur `网速.app` afin que macOS enregistre le blocage.
2. Si « Placer dans la Corbeille » est proposé, choisissez **OK/Terminé** ou fermez la fenêtre. Ne placez pas l’application dans la Corbeille.
3. Ouvrez **Réglages Système → Confidentialité et sécurité**.
4. Descendez jusqu’à Sécurité, trouvez `网速`, puis cliquez sur **Ouvrir quand même**.
5. Confirmez **Ouvrir** et saisissez votre mot de passe si nécessaire.

Apple indique que le bouton Ouvrir quand même est normalement disponible pendant environ une heure après la tentative bloquée. L’application sera ensuite enregistrée comme exception. Consultez les [instructions officielles d’Apple](https://support.apple.com/guide/mac-help/mh40617/mac).

## En cas d’avertissement plus grave

Si macOS indique explicitement que l’application « endommagera votre ordinateur », contient un logiciel malveillant, est endommagée ou a été modifiée :

- ne supprimez pas les attributs de quarantaine avec Terminal ;
- ne désactivez pas Gatekeeper globalement ;
- supprimez le fichier et téléchargez-le à nouveau depuis les Releases officielles ;
- vérifiez de nouveau le SHA-256 ;
- s’il diffère encore, n’exécutez pas l’application et compilez-la depuis les sources.

Apple explique ces avertissements dans [Ouvrir des apps en toute sécurité sur votre Mac](https://support.apple.com/102445).

## Utilisation

- `↑` : débit montant actuel
- `↓` : débit descendant actuel
- ouverture depuis Finder ou Applications : affiche les réglages
- lancement à l’ouverture de session : fonctionnement silencieux dans la barre des menus
- fermeture de la fenêtre : l’application continue de fonctionner
- 退出网速 (Quitter NetSpeedMenu) : arrête complètement l’application

## Confidentialité

L’application lit uniquement les compteurs cumulés d’octets des interfaces réseau fournis par macOS. Elle ne téléverse aucun fichier, n’envoie aucune télémétrie, ne contient aucune publicité et ne conserve pas le contenu du trafic réseau.

## Désinstallation

1. Désactivez le lancement à l’ouverture de session dans les réglages.
2. Cliquez sur 退出网速 (Quitter NetSpeedMenu).
3. Placez `/Applications/网速.app` dans la Corbeille.

Version : 1.2

Auteur : Guo Peng (郭鹏)
