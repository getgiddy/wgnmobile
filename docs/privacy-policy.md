# Privacy Policy — WGN Mobile

**Draft for review.** This covers what the app actually does as built. Before
publishing it, the church must confirm the operator name, contact address and
retention periods, and have someone qualified check it against Nigerian data
protection law (NDPA 2023) and, if you have members in the EU or UK, GDPR.

Publish it at a stable public URL, then set that URL in `app_config`:

```sql
update app_config
   set value = value || jsonb_build_object('privacy_policy_url', 'https://…')
 where key = 'about';
```

Last updated: _[date of publication]_

---

## Who we are

WGN Mobile is operated by WordFeast Gospel Network ("we", "us"). You can reach
us at _[contact email]_ or _[postal address]_.

## What we collect

**If you only browse**, the app signs you in anonymously so your reading streak
and downloads persist on your device. This creates a random account identifier.
It is not linked to your name or email, and we do not collect device
advertising identifiers.

**If you create an account**, we additionally store your email address and the
name you give us.

**As you use the app**, we store:

| Data | Why |
|---|---|
| Sermons you like or download | So they appear in your library |
| Devotionals you save, and which days you have read | To show your reading streak |
| Events you register for | So the welcome desk can check you in |
| Prayer requests you send | So our intercessors can pray over them |
| Testimonies you submit | So they can be reviewed and, if approved, published |
| Playback position per sermon | So you can resume where you stopped |

We do **not** collect location, contacts, photos, health data, or advertising
identifiers, and the app contains no advertising or third-party analytics SDKs.

## Prayer requests and testimonies

**Prayer requests are private.** They are visible only to you and to our prayer
team. They are never published in the app. If you mark a request anonymous,
your name is not shown to the prayer team.

**Testimonies are reviewed before anyone else sees them.** Nothing you submit
appears in the app until a member of our media team approves it. Once approved,
your chosen display name, initials, city and testimony text are visible to all
users. Do not include anything in a testimony you would not want published.

To report a testimony you believe breaches our community standards, use the
report control on the testimony itself, or email us. We aim to review reports
within one business day and remove anything that breaches these terms.

## Who else processes your data

| Party | Role | What they see |
|---|---|---|
| Supabase | Hosting, database, authentication, file storage | All data listed above |
| YouTube (Google) | Embedded live and video playback | Standard YouTube playback data, governed by Google's privacy policy |

We do not sell your data, and we do not share it for advertising.

## How long we keep it

We keep your data while your account exists. Delete your account and we remove
it — see below. Prayer requests and testimonies are deleted along with the
account, including testimonies already published.

Backups may retain deleted data for up to _[30 days]_ before being overwritten.

## Deleting your account

You can delete your account at any time from inside the app:
**More → Profile → Delete account**.

This permanently removes your profile, saved devotionals, liked sermons,
reading streak, event registrations, prayer requests, and any testimonies you
shared — including ones already published. It cannot be undone.

Sermons you downloaded remain on your phone until you remove them from the
Offline screen; they are files on your device, not data we hold.

If you cannot access the app, request deletion at _[deletion request URL]_ or
by emailing _[contact email]_.

## Your rights

You can ask us to show you the data we hold about you, correct it, or delete
it. Contact us at _[contact email]_. Under the NDPA you may also complain to
the Nigeria Data Protection Commission.

## Children

The app is not directed at children under 13 and we do not knowingly collect
their data. If you believe a child has given us personal data, contact us and
we will delete it.

## Changes

If we change this policy we will update the date above and, for significant
changes, notify you in the app.
