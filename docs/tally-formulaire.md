# Formulaire Tally : inscriptions au lancement

> Page concernée : `site/index.html` (pearl-inc.app). Rédigé le 2026-10-08.
> Le joueur ouvre d'abord ses **5 huîtres d'essai sans rien donner** ; le formulaire n'arrive qu'après, ou s'il clique de lui-même sur « Préviens-moi de la sortie ».

## 1. Deux formulaires : un en français, un en anglais

Tally n'affiche qu'une langue par formulaire. On crée le français, on le **duplique**, on traduit la copie. La page envoie chaque visiteur vers le formulaire de sa langue (FR / EN en haut de la page).

Une fois publiés, coller les deux liens dans `site/index.html`, dans le dernier `<script>` :

```js
const TALLY_URLS={fr:'https://tally.so/r/xxxxxx',en:'https://tally.so/r/yyyyyy'};
```

Tant qu'ils sont vides, les boutons affichent « Les inscriptions ouvrent très bientôt. »

## 2. Contenu du formulaire (version française)

**Titre :** Sois là pour la première huître.

**Texte d'introduction :** Pearl Inc. arrive sur l'App Store. Laisse ton adresse : on t'écrit une seule fois, le jour de la sortie, avec ta perle de bienvenue.

| # | Type Tally | Question | Obligatoire | Pourquoi |
|---|---|---|---|---|
| 1 | Email | Ton e-mail | Oui | Le seul vrai besoin |
| 2 | Multiple choice | Tu joueras sur quel téléphone ? — iPhone Duo (déjà précommandé) · iPhone Duo (je compte l'acheter) · Un autre iPhone · Android | Non | Mesure directe de l'intérêt pour le Duo, utile pour la décision du 25 |
| 3 | Checkbox | J'accepte de recevoir un e-mail de Pearl Inc. à la sortie du jeu, et je peux me désinscrire à tout moment. [Confidentialité](#3-confidentialité-rgpd) | Oui | Consentement RGPD explicite |

Pas de prénom, pas d'âge, pas de téléphone : chaque champ en plus fait perdre des inscrits.

**Champs cachés** (bloc « Hidden fields », noms exacts, en minuscules) :

| Nom | Rempli par la page | Exemples |
|---|---|---|
| `utm_source` | provenance | `linkedin`, `x`, `direct` |
| `utm_campaign` | univers testé | `huitre`, `ecrin`, `direct` |
| `lang` | langue de la page | `fr`, `en` |
| `bouton` | bouton cliqué | `fin-essai`, `haut-de-page`, `bas-de-page`, `menu` |

`bouton` dit si les gens s'inscrivent **après avoir joué** (`fin-essai`) ou **avant** : c'est la preuve que le geste convainc.

**Page de remerciement :**
> C'est noté ! Ta perle de bienvenue t'attend le jour de la sortie.
> En attendant, retourne sur la page : 5 nouvelles huîtres t'attendent.

(La page redonne déjà 5 huîtres à qui clique sur « Préviens-moi » à la fin de l'essai.)

## 3. Confidentialité (RGPD)

On collecte des e-mails de personnes en Europe : il faut un texte court, accessible depuis la case à cocher (bloc de texte en bas du formulaire, ou page dédiée). Proposition, **à relire entre associés** :

> **Qui :** MJHstudio (Jules, Mathys, Hugo), éditeur de Pearl Inc. Contact : [adresse e-mail du studio].
> **Quoi :** ton adresse e-mail, ta réponse sur ton téléphone, et d'où tu viens (réseau social, langue).
> **Pour quoi :** t'envoyer un e-mail à la sortie de Pearl Inc. avec ta perle de bienvenue, et mesurer quel message fonctionne le mieux. Rien d'autre, jamais revendu.
> **Combien de temps :** jusqu'à 6 mois après la sortie du jeu, puis effacé.
> **Tes droits :** écris-nous pour consulter ou supprimer tes données, ou désinscris-toi en un clic depuis l'e-mail.
> **Où :** chez Tally, notre outil de formulaires (données hébergées dans l'Union européenne).

Vérifier ce dernier point dans les réglages et la documentation de Tally au moment de créer le formulaire.

## 4. Réglages Tally

- **Notifications** : un e-mail à chaque inscription (au moins pendant la campagne, pour réagir vite).
- **Fermer le formulaire** : pas de limite.
- **Doublons** : rien à faire ; on dédoublonne à l'export.
- Plan gratuit suffisant (les champs cachés sont gratuits). Le logo Tally reste affiché ; on peut l'enlever plus tard avec Tally Pro.

## 5. Relevés (dimanches 18 et 25 octobre)

Exporter en CSV depuis Tally, puis compter les inscrits par `utm_campaign` × `utm_source`. Les diviser par les impressions des posts (statistiques LinkedIn et X) pour obtenir le chiffre qui tranche : **inscriptions pour 1 000 impressions**. Regarder aussi la part de `fin-essai` et la réponse « iPhone Duo ».

## 6. Liens de la campagne

| Univers | Réseau | Lien |
|---|---|---|
| Huître | LinkedIn | `https://pearl-inc.app/?utm_source=linkedin&utm_campaign=huitre` |
| Huître | X | `https://pearl-inc.app/?utm_source=x&utm_campaign=huitre` |
| Écrin | LinkedIn | `https://pearl-inc.app/ecrin/?utm_source=linkedin&utm_campaign=ecrin` |
| Écrin | X | `https://pearl-inc.app/ecrin/?utm_source=x&utm_campaign=ecrin` |

(La page de l'écrin, prévue pour la semaine 2, n'existe pas encore.)
