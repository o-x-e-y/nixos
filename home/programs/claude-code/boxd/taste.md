## This viewer

From `boxd taste`, `boxd ratings`, `boxd diary` and `boxd deltas` on 2026-09-16,
corrected against the user's own account of how they watch. 379 films watched,
378 rated, 513 on the watchlist. Regenerate with `/boxd refresh-taste`.

### The one thing to understand first

**They almost only watch films in a cinema**, and that fact contaminates every
raw average `boxd taste` prints. New releases are seen more or less unfiltered;
older films are seen because a cinema revived them or they were worth seeking
out — a pre-selected set of winners. So the decade table below is *selection*,
not preference, and quoting it as taste is a misreading:

| decade | n | mean | spread | ≥4.0 | ≤2.5 |
|---|---|---|---|---|---|
| 1970s–80s | 17 | 4.00 | 0.50 | 71% | 0% |
| 1990s | 22 | 4.09 | 0.67 | 68% | 5% |
| 2000s | 30 | 3.92 | 0.81 | 73% | 10% |
| 2010s | 59 | 4.07 | 0.77 | 76% | 5% |
| 2020s | 243 | 3.59 | 0.89 | 49% | 15% |

The spread grows monotonically with recency, **19 of the 23 films rated ≤2.0 are
2020s releases**, and the pre-1990 decades contain essentially no bad films. The
2020s is the only uncurated sample here.

**The delta against the Letterboxd average settles it.** Measured against
consensus, which cancels the selection effect out entirely:

- **pre-2020: +0.06. 2020s: +0.08.** Identical. They are *not* harsher on new
  films — the new films that reach them are simply worse.

### They are not a contrarian

Across 367 films with a consensus to compare against: **mean delta +0.07, and
60% of their ratings land within half a star of the Letterboxd average.** They
track the crowd closely, and they are slightly *generous* to popular films
(+0.22 across the 80 most-rated) while sitting exactly at consensus on obscure
ones (−0.02). Do not model them as someone looking to disagree.

The disagreements that do exist are sharply patterned, and they are the most
useful thing in this file.

**Where they go high — films that got piled on, and unpretentious genre craft:**

| | their rating | average |
|---|---|---|
| New Kids Turbo (2010) | 5.0 | 3.33 |
| Strange Darling (2023) | 5.0 | 3.46 |
| The SpongeBob Movie: Search for SquarePants (2025) | 4.0 | 2.49 |
| Emilia Pérez (2024) | 3.5 | 2.00 |
| Sisu: Road to Revenge (2025) | 4.5 | 3.24 |
| Anora (2024) | 5.0 | 3.77 |
| The Dark Knight Rises (2012) | 5.0 | 3.83 |

**Where they go low — almost entirely recent franchise and event cinema:**

| | their rating | average |
|---|---|---|
| Magellan (2025) | 1.0 | 3.69 |
| F1 (2025) | 1.5 | 3.65 |
| Urchin (2025) | 1.5 | 3.51 |
| Ne Zha 2 (2025) | 2.5 | 4.13 |
| Avatar: Fire and Ash (2025) | 2.0 | 3.55 |
| The War of the Rohirrim (2024) | 1.5 | 3.05 |
| Bad Boys: Ride or Die (2024) | 1.5 | 3.18 |

**Legacy-IP continuations are the one reliable negative signal in the dataset**,
and it is stronger than any genre effect. The apparent weakness in fantasy
(3.41), adventure (3.50) and action (3.51) is mostly this: pre-2020 action
averages **3.98** against **3.27** for the 2020s, and the five Twilight films are
11% of the fantasy sample at a 1.8 average — without them fantasy is 3.61.

*(Those genre figures are a one-time snapshot from 2026-09-16. `boxd` no longer
queries per-genre pages — robots.txt disallows them — so `refresh-taste` will
not update them. The franchise finding does not depend on them: it is visible in
the delta table above, which comes from allowed paths.)*

**There is a blind spot at the bottom.** They skip films critics have already
trashed — their own example: *The Dog Stars* and *The End of Oak Street* are
showing now and hold no interest. So a 2.0 here is not "a bad film"; it is a
film that looked worth a ticket and then betrayed that.

### What actually holds

**The scale.** Mean 3.75, 4.0 the most common rating by far (112 films), 70 at
4.5, 39 at 5.0. **4.0 means "this was good."** Disappointment starts at 3.0.

**Craft is the axis, and they say so outright.** The complaints are never about
genre or lowbrow subject — *SpongeBob* is four stars and beats consensus by 1.5.
They are about how a film was made. On *One Night Only*: "2 really hot actors in
overlit shots doing a dozen product placements each make this feel like a
commercial more than anything." Corporate, over-lit, assembled by committee.

**Directors at the ceiling:** Joachim Trier, a flat 5.0 across *Sentimental
Value*, *The Worst Person in the World* and *Oslo, August 31st*. Then Lanthimos
(4.83), Bong Joon Ho (4.75), Nolan, Tarantino.

**Drama is home** (203 films, 3.89), with mystery (3.92) and crime (3.81)
over-performing: *The Handmaiden*, *Parasite*, *Strange Darling*. Formally
ambitious but emotionally direct is the sweet spot — *Aftersun*, *In the Mood
for Love*, *The Apartment*. On *Black Swan*: "I love when movies adapt another
piece of art while also being about creating that piece of art."

**Volume.** ~14 films a month, 100 already this year. Rewatches are rare.

### Recommending to them

**Lead with what is actually showing.** They watch in cinemas, so a repertory or
classics screening is a live and well-aimed option — `pathe classics` and `pathe
arthouse` are the right tools, and by their own account a classic on a cinema
screen is nearly always a good bet. A streaming-only pick is the weaker one.

**The watchlist is 513 films and skews older than their history** — 239 from the
1990s–2010s, 78 from before 1990. That backlog is where the films they mean to
get to already live; prefer it to inventing suggestions.

**Never pitch a franchise sequel or legacy-IP continuation.**

### Register

Reviews are short, lowercase, funny, and specific when annoyed. "terrifying" is
a whole review. So is "i feel blessed to have seen this one in imax mama mia"
(*Akira*). Match that when quoting them back; do not dress it up.
