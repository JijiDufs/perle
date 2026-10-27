# Mail de sortie aux inscrits (FR et EN)

> Rédigé le 2026-10-27. **Rien n'est envoyé.** À envoyer par Jules, une fois les conditions ci-dessous remplies.
> Destinataires : les inscrits des formulaires Tally `J9N7AJ` (version française) et `Me9oLY` (version anglaise).

## Avant d'envoyer

- [ ] **La coquille Première marée marche dans l'app en ligne.** Elle arrive avec la **1.1** (branche `claude/ios-1-1-sauvegarde-045c95` : fonction `is_early_signup`, fenêtre « Merci d'avoir été là dès le début »). La 1.0 sortie le 27 octobre ne la donne pas. Sans la 1.1 en ligne, retirer le paragraphe sur la coquille (et la phrase du bas de pearl-inc.app).
- [ ] **Les e-mails des inscrits sont dans la liste du serveur** (`early_access_signups`, Supabase, en minuscules). Sinon, la connexion marche mais la coquille n'arrive pas.
- [ ] Tester une fois avec sa propre adresse d'inscription : « Continuer avec un e-mail », code, coquille reçue.
- [ ] Lien de désinscription : `{{{RESEND_UNSUBSCRIBE_URL}}}` avec Resend (connecteur à reconnecter dans Claude, permissions manquantes au 2026-10-27). Avec un autre outil, mettre son équivalent.
- [ ] Adresse d'envoi : un domaine vérifié (ex. `bonjour@pearl-inc.app`), « répondre à » une boîte lue par Jules ou Mathys.

Lien App Store (le même que sur pearl-inc.app, sans pays : Apple ouvre la boutique du pays du lecteur) :
`https://apps.apple.com/app/pearl-inc/id6822782842`

---

## Français

**Objet :** Pearl Inc. est sorti, et ta coquille t'attend
**Aperçu (préheader) :** Ta première huître est sur l'App Store. Et une coquille rien que pour toi.

### Texte brut

```text
Salut,

Tu attendais la première huître : elle est là. Pearl Inc. est sorti sur l'App Store, gratuitement.

Télécharger Pearl Inc. :
https://apps.apple.com/app/pearl-inc/id6822782842

Ouvre-la doucement : la lumière filtre. Trop vite, la perle se fêle. Sur iPhone Duo, c'est le téléphone qui ouvre l'huître ; sur les autres iPhone, ton pouce.

TA COQUILLE PREMIÈRE MARÉE
Elle est réservée aux inscrits d'avant la sortie, et on ne la reverra plus. Pour la récupérer :
1. Au premier écran de l'app, choisis « Continuer avec un e-mail ».
2. Entre l'adresse à laquelle tu reçois ce mail.
3. Tape le code à 6 chiffres qu'on t'envoie.
La coquille arrive toute seule, et t'attend ensuite dans la Boutique.

Attention : « Se connecter avec Apple » avec « Masquer mon e-mail » ne marche pas pour ça (Apple nous donne une autre adresse). Tu as déjà commencé à jouer autrement ? Réponds à ce mail, on s'en occupe.

Merci d'avoir été là dès le début.
Jules et Mathys

PS : Pearl Inc. n'est pas encore disponible en Belgique.

Se désinscrire : {{{RESEND_UNSUBSCRIBE_URL}}}
```

### HTML

```html
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<title>Pearl Inc. est sorti</title>
</head>
<body style="margin:0;padding:0;background-color:#f5f5f7;">
<table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#f5f5f7" style="background-color:#f5f5f7;">
  <tr><td align="center" style="padding-top:32px;padding-bottom:32px;padding-left:16px;padding-right:16px;">
    <table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#ffffff" style="max-width:560px;background-color:#ffffff;border-radius:20px;">
      <tr><td style="padding-top:36px;padding-bottom:8px;padding-left:32px;padding-right:32px;font-family:Helvetica,Arial,sans-serif;font-size:28px;line-height:34px;font-weight:bold;color:#1d1d1f;">Pearl Inc. est sorti</td></tr>
      <tr><td style="padding-top:8px;padding-bottom:0;padding-left:32px;padding-right:32px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">
        <p style="margin-top:0;margin-bottom:14px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">Salut,</p>
        <p style="margin-top:0;margin-bottom:14px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">Tu attendais la première huître : elle est là. Pearl Inc. est sorti sur l'App Store, gratuitement.</p>
      </td></tr>
      <tr><td align="center" style="padding-top:10px;padding-bottom:22px;padding-left:32px;padding-right:32px;">
        <table cellpadding="0" cellspacing="0" border="0"><tr>
          <td bgcolor="#000000" style="background-color:#000000;border-radius:12px;">
            <a href="https://apps.apple.com/app/pearl-inc/id6822782842" style="display:inline-block;padding-top:14px;padding-bottom:14px;padding-left:26px;padding-right:26px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:20px;font-weight:bold;color:#ffffff;text-decoration:none;">Télécharger dans l'App Store</a>
          </td>
        </tr></table>
      </td></tr>
      <tr><td style="padding-top:0;padding-bottom:0;padding-left:32px;padding-right:32px;">
        <p style="margin-top:0;margin-bottom:22px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#6e6e73;">Ouvre-la doucement : la lumière filtre. Trop vite, la perle se fêle. Sur iPhone Duo, c'est le téléphone qui ouvre l'huître ; sur les autres iPhone, ton pouce.</p>
      </td></tr>
      <tr><td style="padding-top:0;padding-bottom:0;padding-left:32px;padding-right:32px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#eef6f6" style="background-color:#eef6f6;border-radius:16px;">
          <tr><td style="padding-top:20px;padding-bottom:20px;padding-left:22px;padding-right:22px;">
            <p style="margin-top:0;margin-bottom:8px;font-family:Helvetica,Arial,sans-serif;font-size:18px;line-height:24px;font-weight:bold;color:#0f6f7d;">Ta coquille Première marée</p>
            <p style="margin-top:0;margin-bottom:10px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">Elle est réservée aux inscrits d'avant la sortie, et on ne la reverra plus. Pour la récupérer :</p>
            <p style="margin-top:0;margin-bottom:4px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">1. Au premier écran de l'app, choisis <strong>« Continuer avec un e-mail »</strong>.</p>
            <p style="margin-top:0;margin-bottom:4px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">2. Entre l'adresse à laquelle tu reçois ce mail.</p>
            <p style="margin-top:0;margin-bottom:10px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">3. Tape le code à 6 chiffres qu'on t'envoie.</p>
            <p style="margin-top:0;margin-bottom:10px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">La coquille arrive toute seule, et t'attend ensuite dans la Boutique.</p>
            <p style="margin-top:0;margin-bottom:0;font-family:Helvetica,Arial,sans-serif;font-size:13px;line-height:19px;color:#6e6e73;">« Se connecter avec Apple » avec « Masquer mon e-mail » ne marche pas pour ça (Apple nous donne une autre adresse). Tu as déjà commencé à jouer autrement ? Réponds à ce mail, on s'en occupe.</p>
          </td></tr>
        </table>
      </td></tr>
      <tr><td style="padding-top:24px;padding-bottom:32px;padding-left:32px;padding-right:32px;">
        <p style="margin-top:0;margin-bottom:6px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">Merci d'avoir été là dès le début.</p>
        <p style="margin-top:0;margin-bottom:18px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;font-weight:bold;color:#1d1d1f;">Jules et Mathys</p>
        <p style="margin-top:0;margin-bottom:0;font-family:Helvetica,Arial,sans-serif;font-size:13px;line-height:19px;color:#86868b;">PS : Pearl Inc. n'est pas encore disponible en Belgique.</p>
      </td></tr>
    </table>
    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;">
      <tr><td align="center" style="padding-top:16px;font-family:Helvetica,Arial,sans-serif;font-size:12px;line-height:18px;color:#86868b;">
        Tu reçois ce mail parce que tu as laissé ton adresse sur pearl-inc.app.<br>
        <a href="{{{RESEND_UNSUBSCRIBE_URL}}}" style="color:#86868b;text-decoration:underline;">Se désinscrire</a> · iPhone et iPhone Duo sont des marques d'Apple Inc.
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>
```

---

## English

**Subject:** Pearl Inc. is out, and your shell is waiting
**Preview text:** Your first oyster is on the App Store. Plus a shell just for you.

### Plain text

```text
Hi,

You were waiting for the first oyster: it's here. Pearl Inc. is out now on the App Store, for free.

Get Pearl Inc.:
https://apps.apple.com/app/pearl-inc/id6822782842

Open it gently and light seeps in. Too fast, and the pearl cracks. On iPhone Duo, the phone itself opens the oyster; on other iPhones, your thumb does.

YOUR FIRST TIDE SHELL
It's reserved for people who signed up before launch, and it won't come back. To get it:
1. On the app's first screen, choose "Continue with email".
2. Enter the address this email was sent to.
3. Type the 6-digit code we send you.
The shell arrives on its own, and then waits for you in the Shop.

Heads-up: "Sign in with Apple" with "Hide My Email" won't work for this (Apple gives us a different address). Already started playing another way? Reply to this email and we'll sort it out.

Thanks for being here from the start.
Jules and Mathys

PS: Pearl Inc. isn't available in Belgium yet.

Unsubscribe: {{{RESEND_UNSUBSCRIBE_URL}}}
```

### HTML

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<title>Pearl Inc. is out</title>
</head>
<body style="margin:0;padding:0;background-color:#f5f5f7;">
<table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#f5f5f7" style="background-color:#f5f5f7;">
  <tr><td align="center" style="padding-top:32px;padding-bottom:32px;padding-left:16px;padding-right:16px;">
    <table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#ffffff" style="max-width:560px;background-color:#ffffff;border-radius:20px;">
      <tr><td style="padding-top:36px;padding-bottom:8px;padding-left:32px;padding-right:32px;font-family:Helvetica,Arial,sans-serif;font-size:28px;line-height:34px;font-weight:bold;color:#1d1d1f;">Pearl Inc. is out</td></tr>
      <tr><td style="padding-top:8px;padding-bottom:0;padding-left:32px;padding-right:32px;">
        <p style="margin-top:0;margin-bottom:14px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">Hi,</p>
        <p style="margin-top:0;margin-bottom:14px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">You were waiting for the first oyster: it's here. Pearl Inc. is out now on the App Store, for free.</p>
      </td></tr>
      <tr><td align="center" style="padding-top:10px;padding-bottom:22px;padding-left:32px;padding-right:32px;">
        <table cellpadding="0" cellspacing="0" border="0"><tr>
          <td bgcolor="#000000" style="background-color:#000000;border-radius:12px;">
            <a href="https://apps.apple.com/app/pearl-inc/id6822782842" style="display:inline-block;padding-top:14px;padding-bottom:14px;padding-left:26px;padding-right:26px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:20px;font-weight:bold;color:#ffffff;text-decoration:none;">Download on the App Store</a>
          </td>
        </tr></table>
      </td></tr>
      <tr><td style="padding-top:0;padding-bottom:0;padding-left:32px;padding-right:32px;">
        <p style="margin-top:0;margin-bottom:22px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#6e6e73;">Open it gently and light seeps in. Too fast, and the pearl cracks. On iPhone Duo, the phone itself opens the oyster; on other iPhones, your thumb does.</p>
      </td></tr>
      <tr><td style="padding-top:0;padding-bottom:0;padding-left:32px;padding-right:32px;">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" bgcolor="#eef6f6" style="background-color:#eef6f6;border-radius:16px;">
          <tr><td style="padding-top:20px;padding-bottom:20px;padding-left:22px;padding-right:22px;">
            <p style="margin-top:0;margin-bottom:8px;font-family:Helvetica,Arial,sans-serif;font-size:18px;line-height:24px;font-weight:bold;color:#0f6f7d;">Your First Tide shell</p>
            <p style="margin-top:0;margin-bottom:10px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">It's reserved for people who signed up before launch, and it won't come back. To get it:</p>
            <p style="margin-top:0;margin-bottom:4px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">1. On the app's first screen, choose <strong>"Continue with email"</strong>.</p>
            <p style="margin-top:0;margin-bottom:4px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">2. Enter the address this email was sent to.</p>
            <p style="margin-top:0;margin-bottom:10px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">3. Type the 6-digit code we send you.</p>
            <p style="margin-top:0;margin-bottom:10px;font-family:Helvetica,Arial,sans-serif;font-size:15px;line-height:22px;color:#1d1d1f;">The shell arrives on its own, and then waits for you in the Shop.</p>
            <p style="margin-top:0;margin-bottom:0;font-family:Helvetica,Arial,sans-serif;font-size:13px;line-height:19px;color:#6e6e73;">"Sign in with Apple" with "Hide My Email" won't work for this (Apple gives us a different address). Already started playing another way? Reply to this email and we'll sort it out.</p>
          </td></tr>
        </table>
      </td></tr>
      <tr><td style="padding-top:24px;padding-bottom:32px;padding-left:32px;padding-right:32px;">
        <p style="margin-top:0;margin-bottom:6px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;color:#1d1d1f;">Thanks for being here from the start.</p>
        <p style="margin-top:0;margin-bottom:18px;font-family:Helvetica,Arial,sans-serif;font-size:16px;line-height:24px;font-weight:bold;color:#1d1d1f;">Jules and Mathys</p>
        <p style="margin-top:0;margin-bottom:0;font-family:Helvetica,Arial,sans-serif;font-size:13px;line-height:19px;color:#86868b;">PS: Pearl Inc. isn't available in Belgium yet.</p>
      </td></tr>
    </table>
    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;">
      <tr><td align="center" style="padding-top:16px;font-family:Helvetica,Arial,sans-serif;font-size:12px;line-height:18px;color:#86868b;">
        You're getting this email because you left your address on pearl-inc.app.<br>
        <a href="{{{RESEND_UNSUBSCRIBE_URL}}}" style="color:#86868b;text-decoration:underline;">Unsubscribe</a> · iPhone and iPhone Duo are trademarks of Apple Inc.
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>
```

## Notes

- Le bouton du mail est un simple bouton texte « Télécharger dans l'App Store », pas le badge d'Apple : beaucoup de messageries n'affichent pas les images SVG, et une image bloquée cacherait le lien.
- « Masquer mon e-mail » : la fonction `is_early_signup` compare l'adresse vérifiée du compte à la liste ; l'adresse relais d'Apple n'y est jamais.
- Un joueur déjà connecté autrement (invité, ou Apple avec adresse masquée) qui se déconnecte pour passer par l'e-mail perd la partie liée à l'ancien compte : d'où « réponds à ce mail » plutôt qu'une marche à suivre.
