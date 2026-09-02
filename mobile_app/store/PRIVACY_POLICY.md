# FinPat — Privacy Policy

**Effective date:** 2 September 2026
**Last updated:** 2 September 2026

> **Before you publish:** replace every `[BRACKETED]` placeholder below with your
> real details. This document was drafted from an audit of what the FinPat app
> actually collects and transmits, so the data inventory is accurate — but it is
> not legal advice. Have it reviewed before you rely on it, particularly if you
> target the EU/UK (GDPR), California (CCPA/CPRA), or the Gulf states.

---

## 1. Who we are

FinPat ("FinPat", "we", "us") is a personal money-planning app for people who
support family in another country. This policy explains what we collect, why,
and what you can do about it.

- **Data controller:** [LEGAL ENTITY OR YOUR FULL NAME]
- **Address:** [POSTAL ADDRESS]
- **Contact:** [privacy@finpat.app]

This policy covers the FinPat Android app and the backend that serves it. It
does not cover any third-party site we link to.

## 2. The short version

- FinPat stores the financial picture **you type in** — income, obligations,
  money sent home, savings.
- **FinPat is a planning and record-keeping tool. It does not move money, and it
  does not connect to your bank.** We never ask for and never store bank account
  numbers, card numbers, or payment credentials.
- We do **not** run advertising, analytics, or tracking SDKs of any kind.
- We do **not** sell or share your data with anyone for their own purposes.
- Your data is yours. You can export it or have it deleted — see section 8.

## 3. What we collect

Everything below is information **you enter yourself**. FinPat collects nothing
in the background.

### 3.1 Account
| Data | Why |
|---|---|
| Email address | To identify your account and let you sign in |
| Password | To secure your account (stored only as a salted hash — we never see it) |
| Display name | To personalise the app |

### 3.2 Your financial profile
| Data | Why |
|---|---|
| Work location and family location | To label your two "sides" and pick sensible currencies |
| Income amount, currency, and frequency | To calculate what's committed and what's left |

> **These are text you choose (for example "UAE" and "Philippines"). They are not
> your device's location.** FinPat requests no location permission and cannot
> read your GPS, and it never has.

### 3.3 What you plan and track
| Data | Why |
|---|---|
| Responsibility centres (name, icon, colour) | To group who you support |
| Obligations (title, amount, currency, due date, goal amount, essential/completed flags) | To show what's due and track goal progress |
| Remittances (date, time, amount, currency, target currency, exchange rate, purpose) | To keep your history of money sent home |
| Savings entries (date, amount, currency, type, note) | To track what you've set aside |

### 3.4 Technical data
To deliver the service, our backend provider processes your IP address and basic
request metadata (timestamp, endpoint) in its server logs, and issues session
tokens that keep you signed in. This is ordinary infrastructure logging, not
profiling.

## 4. What we do *not* collect

We want to be specific, because for a money app the absences matter:

- **No bank or card details.** No account numbers, no card numbers, no payment
  credentials. FinPat cannot initiate a transfer.
- **No device location.** The app declares no location permission.
- **No contacts, photos, camera, microphone, files, or SMS.** The only Android
  permission FinPat declares is `INTERNET`.
- **No advertising ID, and no advertising.**
- **No analytics or crash-reporting SDKs.** There is no Firebase, no Google
  Analytics, no Crashlytics, no Sentry, no attribution SDK in the app.
- **No biometric data.**

## 5. How we use your data

We use it only to run the app for you:

1. To authenticate you and keep your session active.
2. To store, calculate, and display your obligations, remittances, and savings.
3. To convert between currencies so your totals make sense in one currency.
4. To keep the service secure and debug faults you report to us.

We do **not** use your data to profile you, score you, train models, or make
automated decisions about you. **We do not sell your personal information, and
we do not share it for cross-context behavioural advertising.**

If you are in the EU/UK, our legal basis is **performance of a contract**
(Article 6(1)(b)) for everything needed to run the app, and **legitimate
interests** (Article 6(1)(f)) for keeping the service secure.

## 6. Who processes your data

We keep this list short on purpose.

| Processor | Role | Where |
|---|---|---|
| **Supabase** | Authentication, database, and backend hosting — stores the data in section 3 on our behalf | [REGION — e.g. AWS eu-central-1] |

Supabase acts on our instructions as a processor and does not use your data for
its own purposes. See supabase.com/privacy.

Beyond that, we disclose personal data only where we are legally compelled to
(a valid court order or equivalent), or to protect someone's safety. If FinPat
is ever acquired, we will tell you before your data moves, and this policy will
continue to apply until replaced.

## 7. Storage, security, and retention

- Data is encrypted in transit (HTTPS/TLS) and at rest by our hosting provider.
- Access is enforced per-user at the database level, so one account cannot read
  another's rows.
- Passwords are salted and hashed; nobody at FinPat can read yours.
- **Retention:** we keep your data for as long as your account exists. If you
  delete your account, we delete your personal data within **30 days**, except
  where law requires us to keep records longer. Backups are purged on a rolling
  cycle of no more than **90 days**.

No system is perfectly secure, and we can't promise absolute security — but we
will notify you and the relevant regulator without undue delay if a breach
affects your personal data.

## 8. Your rights and your choices

Wherever you live, you can ask us to:

- **Access** the data we hold about you, or get a **copy** of it in a portable format
- **Correct** anything wrong
- **Delete** your account and its data
- **Restrict** or **object to** our processing
- **Withdraw consent**, where we relied on it

**To delete your account, in the app:** *Settings → Delete Account*, then type
DELETE to confirm. This erases your account, profile, centres, obligations,
remittances, and savings immediately and permanently. It cannot be undone.

**If you can't sign in,** email [privacy@finpat.app] from your account address
with the subject "Delete my account", or follow the instructions at
[ACCOUNT DELETION URL]. We complete verified requests within 30 days.

**To start over without deleting your account:** *Settings → Reset All Data*
clears your centres, obligations, remittances, and savings but keeps your
account open.

We answer rights requests within **30 days**, free of charge. You will never be
penalised in the app for exercising a right.

If you think we've handled your data badly, please tell us first — but you also
have the right to complain to your local data protection authority. In the EU
that is your national DPA; in the UK, the ICO (ico.org.uk).

## 9. International transfers

FinPat is built for people whose lives span two countries, so your data may be
processed outside the country you live in — including in
[REGION/COUNTRY OF YOUR SUPABASE PROJECT]. Where we move personal data out of
the EEA or UK, we rely on the European Commission's **Standard Contractual
Clauses** (and the UK Addendum) to protect it.

## 10. Children

FinPat is not intended for anyone under **16**, and we do not knowingly collect
data from children. If you believe a child has given us personal data, write to
[privacy@finpat.app] and we will delete it.

## 11. Changes to this policy

If we change this policy materially, we will update the date at the top and give
notice in the app before the change takes effect. Continuing to use FinPat after
that means you accept the updated policy.

## 12. Contact

Questions, requests, or complaints:

**[privacy@finpat.app]**
[LEGAL ENTITY OR YOUR FULL NAME]
[POSTAL ADDRESS]
