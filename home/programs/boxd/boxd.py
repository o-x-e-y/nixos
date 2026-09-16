#!/usr/bin/env python3
"""boxd -- read-only Letterboxd for a public profile.

Letterboxd's own API has been invite-only since 2017 (letterboxd.com/api-beta/),
so everything here comes from the public pages at letterboxd.com/<user>/. Three
consequences worth stating up front, because they are the whole design:

  1. There is no authentication in this file -- no cookie jar, no session
     login, no POST, no form. Every request is a GET a logged-out browser would
     make. That is deliberate: the account-writing Letterboxd MCP servers all
     want a username and password to do it, and reading a watchlist needs
     neither.

  2. Letterboxd fronts Cloudflare, which challenges plain curl's TLS handshake
     on roughly half of all requests ("Just a moment..." behind HTTP 403).
     curl_cffi replays Chrome's fingerprint, which is the difference between a
     200 and a challenge page. That is why the dependency is curl_cffi and not
     requests -- requests cannot fetch these pages at all.

  3. Scraped markup changes without notice. Every parser here counts what it
     extracted and raises on zero rather than returning [] -- an empty list
     reads like "you have watched no films", which is a much worse failure than
     a loud one naming the selector that went stale.

Two endpoints are structured rather than scraped, and are preferred wherever
they cover the question: /<user>/rss/ is an official feed carrying watch dates,
ratings, rewatch and like flags, and review text; /s/autocompletefilm returns
JSON with slug, year, runtime and directors.
"""

from __future__ import annotations

import argparse
import hashlib
import html as htmllib
import json
import os
import re
import sys
import time
from pathlib import Path

BASE = "https://letterboxd.com"

# Precedence is --user > $BOXD_USER > the Nix default, which the wrapper sets
# with --set-default so a declarative value never blocks a one-off override.
DEFAULT_USER = os.environ.get("BOXD_USER", "")

def _cache_dir() -> Path:
    """Where fetched pages live.

    $BOXD_CACHE wins, then $XDG_CACHE_HOME/boxd, then ~/.cache/boxd. A relative
    $BOXD_CACHE resolves inside the cache root rather than against the cwd:
    Path("x") would otherwise put the cache wherever boxd happened to be *run*
    from, and an agent that sets BOXD_CACHE to a tidy-looking scratch name while
    standing in a git repository drops tens of megabytes of fetched HTML into
    it. The value is still honoured -- it just cannot follow the cwd around,
    and a cache path stays in the cache.
    """
    base = Path(os.environ.get("XDG_CACHE_HOME") or (Path.home() / ".cache"))
    raw = os.environ.get("BOXD_CACHE")
    if not raw:
        return base / "boxd"
    path = Path(raw).expanduser()
    return path if path.is_absolute() else base / path


CACHE_DIR = _cache_dir()

# Lists move (a watchlist changes weekly); film metadata does not. Splitting the
# TTL is what makes a second `boxd taste` or `boxd deltas` cheap: the watched
# list expires in hours, the per-film lookups behind it last a month.
TTL_LIST = int(os.environ.get("BOXD_TTL", 6 * 60 * 60))
TTL_FILM = 30 * 24 * 60 * 60


MIN_INTERVAL = 0.3  # seconds between live requests; cache hits are free


class BoxdError(Exception):
    """Anything the user should see as a message rather than a traceback."""


# --------------------------------------------------------------------------
# fetching
# --------------------------------------------------------------------------

_session = None
_last_request = 0.0


def _get_session():
    global _session
    if _session is None:
        try:
            from curl_cffi import requests
        except ImportError:  # pragma: no cover - packaging guarantees this
            raise BoxdError(
                "curl_cffi is missing. Plain requests/curl cannot get past "
                "Letterboxd's Cloudflare challenge, so there is no fallback."
            )
        _session = requests.Session(impersonate="chrome")
    return _session


def fetch(path: str, ttl: int = TTL_LIST, refresh: bool = False) -> str:
    """GET a page, through the on-disk cache. Returns the response body."""
    global _last_request

    url = path if path.startswith("http") else BASE + path
    key = CACHE_DIR / (hashlib.sha256(url.encode()).hexdigest()[:24] + ".cache")

    if not refresh and key.exists():
        age = time.time() - key.stat().st_mtime
        if age < ttl:
            return key.read_text(encoding="utf-8")

    session = _get_session()

    # Spacing requests is the whole of the politeness story: `boxd taste` is
    # ~25 GETs, and at 0.3s apart that is a person browsing, not a crawler.
    delta = time.time() - _last_request
    if delta < MIN_INTERVAL:
        time.sleep(MIN_INTERVAL - delta)

    body = None
    for attempt in range(3):
        _last_request = time.time()
        try:
            response = session.get(url, timeout=30)
        except Exception as exc:
            if attempt == 2:
                raise BoxdError(f"could not reach {url}: {exc}")
            time.sleep(2**attempt)
            continue

        if response.status_code == 404:
            raise BoxdError(f"not found: {url}")
        if response.status_code == 429 or response.status_code >= 500:
            if attempt == 2:
                raise BoxdError(f"{url} returned {response.status_code} three times")
            time.sleep(2 ** (attempt + 1))
            continue
        if response.status_code == 403:
            # The Cloudflare challenge. Retrying sometimes clears it; if it
            # never does, say what it actually is rather than "403".
            if attempt == 2:
                raise BoxdError(
                    f"{url} returned a Cloudflare challenge three times. "
                    "Try again shortly, or with --refresh after a pause."
                )
            time.sleep(2 ** (attempt + 1))
            continue
        if response.status_code != 200:
            raise BoxdError(f"{url} returned {response.status_code}")

        body = response.text
        break

    if body is None:
        raise BoxdError(f"no response for {url}")

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    key.write_text(body, encoding="utf-8")
    return body


def fetch_json(path: str, ttl: int = TTL_FILM, refresh: bool = False) -> dict:
    raw = fetch(path, ttl=ttl, refresh=refresh)
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        raise BoxdError(f"{path} did not return JSON (markup change?)")


# --------------------------------------------------------------------------
# parsing
# --------------------------------------------------------------------------

_GRIDITEM = re.compile(r'<li class="griditem".*?</li>', re.S)
_SLUG = re.compile(r'data-item-slug="([^"]+)"')
_NAME = re.compile(r'data-item-name="([^"]*)"')
_RATED = re.compile(r'class="rating[^"]*\brated-(\d+)\b')
_TITLE_YEAR = re.compile(r"^(.*?)\s*\((\d{4})\)\s*$")
_PAGINATE = re.compile(r'<div class="paginate-pages">(.*?)</div>', re.S)
_PAGE_NUM = re.compile(r"/page/(\d+)/")


def parse_grid(page: str, *, where: str) -> list[dict]:
    """Pull films out of a poster grid.

    Every grid on the site -- watchlist, watched films, genre filters, similar
    films -- is the same <li class="griditem">, carrying the slug and display
    name as data attributes and the viewer's rating in a sibling span. Chunking
    on the <li> first is what keeps a rating attached to its own film.
    """
    films = []
    for chunk in _GRIDITEM.findall(page):
        slug = _SLUG.search(chunk)
        if not slug:
            continue
        name = _NAME.search(chunk)
        display = htmllib.unescape(name.group(1)) if name else slug.group(1)

        title, year = display, None
        matched = _TITLE_YEAR.match(display)
        if matched:
            title, year = matched.group(1), int(matched.group(2))

        rated = _RATED.search(chunk)
        films.append(
            {
                "slug": slug.group(1),
                "title": title,
                "year": year,
                # Letterboxd stores half stars as 1-10; present them as stars.
                "rating": int(rated.group(1)) / 2 if rated else None,
            }
        )

    if not films:
        # Telling "genuinely empty" apart from "the markup moved" matters,
        # because the two deserve opposite responses, and the presence of a
        # grid cannot separate them: Letterboxd omits the container entirely
        # when there is nothing to put in it. What does separate them is how
        # many loose item slugs the page carries. A legitimately empty page --
        # a 2025 release nobody has cross-listed yet, an empty watchlist --
        # still has the two or three from its own header poster and nav. A page
        # whose <li class="griditem"> wrapper was renamed carries dozens, every
        # one of them a film we are now silently failing to see.
        loose = len(_SLUG.findall(page))
        if loose >= 4:
            raise BoxdError(
                f"parsed 0 films from {where}, but the page carries {loose} "
                "film references -- Letterboxd has changed the markup around "
                "them and parse_grid() needs its selectors updated."
            )
    return films


def last_page(page: str) -> int:
    block = _PAGINATE.search(page)
    if not block:
        return 1
    numbers = [int(n) for n in _PAGE_NUM.findall(block.group(1))]
    return max(numbers) if numbers else 1


def collect(path: str, *, ttl: int, refresh: bool, limit: int | None = None) -> list[dict]:
    """Walk a paginated grid to the end, or until `limit` films are in hand."""
    path = path.rstrip("/") + "/"
    first = fetch(path, ttl=ttl, refresh=refresh)
    films = parse_grid(first, where=path)
    total = last_page(first)

    for number in range(2, total + 1):
        if limit is not None and len(films) >= limit:
            break
        page = fetch(f"{path}page/{number}/", ttl=ttl, refresh=refresh)
        films.extend(parse_grid(page, where=f"{path}page/{number}/"))

    return films[:limit] if limit is not None else films


# --------------------------------------------------------------------------
# commands
# --------------------------------------------------------------------------

# Letterboxd titles a profile page "<name>’s profile"; the page is the only
# place the display name appears, so the suffix comes off here rather than at
# every call site.
_NAME_SUFFIX = re.compile(r"[’']s profile\s*$")


def _clean_name(raw: str) -> str:
    return _NAME_SUFFIX.sub("", htmllib.unescape(raw)).strip()


# A diary entry with no review still ships a description paragraph reading
# "Watched on Sunday September 13, 2026." -- boilerplate, not an opinion, and
# letting it through would poison any taste profile built on top.
_AUTO_REVIEW = re.compile(r"^Watched on \w+ \w+ \d{1,2}, \d{4}\.?$")


_STAT = re.compile(
    r'<h4 class="profile-statistic[^"]*">\s*<a href="([^"]+)">'
    r'<span class="value">([\d,]+)</span>'
    r'<span class="definition[^"]*">([^<]+)</span>',
    re.S,
)


def cmd_profile(args) -> dict:
    page = fetch(f"/{args.user}/", ttl=TTL_LIST, refresh=args.refresh)

    stats = {}
    for _, value, label in _STAT.findall(page):
        stats[label.strip().lower()] = int(value.replace(",", ""))
    if not stats:
        raise BoxdError(
            f"no profile statistics found for {args.user} -- the profile may be "
            "private, or the stat markup changed."
        )

    favourites = parse_grid(page, where=f"/{args.user}/")[:4]
    name = re.search(r'<meta property="og:title" content="([^"]+)"', page)

    return {
        "user": args.user,
        "name": _clean_name(name.group(1)) if name else args.user,
        "stats": stats,
        "favourites": favourites,
    }


def cmd_watchlist(args) -> dict:
    films = collect(
        f"/{args.user}/watchlist/", ttl=TTL_LIST, refresh=args.refresh, limit=args.limit
    )
    return {"user": args.user, "count": len(films), "films": films}


def _films_path(args) -> str:
    """The watched-films URL. Always the unfiltered list.

    Letterboxd's robots.txt disallows /*/genre/* and /*/decade/* for every user
    agent, so this no longer builds those filter URLs even though the site
    serves them. --decade is applied client-side instead (see _by_decade): the
    release year is already in every grid entry, so filtering by it costs no
    request at all and asks nothing of a disallowed path.
    """
    return f"/{args.user}/films/"


def _by_decade(films: list[dict], decade: str | None) -> list[dict]:
    if not decade:
        return films
    text = str(decade).rstrip("s")
    if not text.isdigit():
        raise BoxdError(f"not a decade: {decade!r} (try 1990s)")
    start = int(text) // 10 * 10
    return [f for f in films if f["year"] and start <= f["year"] < start + 10]


def cmd_films(args) -> dict:
    """Everything watched. Rated entries carry a rating; the rest are None."""
    films = collect(_films_path(args), ttl=TTL_LIST, refresh=args.refresh)
    films = _by_decade(films, getattr(args, "decade", None))
    if args.limit is not None:
        films = films[: args.limit]
    return {
        "user": args.user,
        "decade": getattr(args, "decade", None),
        "count": len(films),
        "films": films,
    }


def cmd_ratings(args) -> dict:
    data = cmd_films(args)
    rated = [f for f in data["films"] if f["rating"] is not None]
    rated.sort(key=lambda f: (-f["rating"], f["title"]))
    return {"user": args.user, "count": len(rated), "films": rated}


_ITEM = re.compile(r"<item>(.*?)</item>", re.S)


def _tag(chunk: str, name: str) -> str | None:
    found = re.search(rf"<{name}>(.*?)</{name}>", chunk, re.S)
    if not found:
        return None
    return htmllib.unescape(found.group(1)).strip()


def cmd_diary(args) -> dict:
    """Recent activity, from the official RSS feed rather than the diary page.

    The feed is the one part of Letterboxd with a documented shape, and it
    carries what the HTML diary makes you reassemble: watch date, rating,
    rewatch and like flags, and the review text.
    """
    feed = fetch(f"/{args.user}/rss/", ttl=TTL_LIST, refresh=args.refresh)

    entries = []
    for chunk in _ITEM.findall(feed):
        title = _tag(chunk, "letterboxd:filmTitle")
        if not title:
            continue  # a list or a story, not a viewing
        rating = _tag(chunk, "letterboxd:memberRating")
        link = _tag(chunk, "link") or ""
        review = re.search(r"<!\[CDATA\[(.*?)\]\]>", chunk, re.S)
        text = None
        if review:
            paragraphs = re.findall(r"<p>(.*?)</p>", review.group(1), re.S)
            body = [
                htmllib.unescape(re.sub(r"<[^>]+>", "", p)).strip()
                for p in paragraphs
            ]
            body = [p for p in body if p and not _AUTO_REVIEW.match(p)]
            text = " ".join(body) or None

        entries.append(
            {
                "title": title,
                "year": int(_tag(chunk, "letterboxd:filmYear") or 0) or None,
                "slug": link.rstrip("/").split("/")[-1],
                "watched": _tag(chunk, "letterboxd:watchedDate"),
                "rating": float(rating) if rating else None,
                "rewatch": _tag(chunk, "letterboxd:rewatch") == "Yes",
                "liked": _tag(chunk, "letterboxd:memberLike") == "Yes",
                "review": text,
            }
        )

    entries = entries[: args.limit] if args.limit else entries
    return {"user": args.user, "count": len(entries), "entries": entries}


def cmd_film(args) -> dict:
    data = fetch_json(f"/film/{args.slug}/json/", refresh=args.refresh)
    return {
        "slug": data.get("slug", args.slug),
        "title": data.get("name"),
        "original_title": data.get("originalName"),
        "year": data.get("releaseYear"),
        "runtime": data.get("runTime"),
        "directors": [d.get("name") for d in data.get("directors", [])],
    }


def cmd_similar(args) -> dict:
    page = fetch(f"/film/{args.slug}/similar/", ttl=TTL_FILM, refresh=args.refresh)
    films = parse_grid(page, where=f"/film/{args.slug}/similar/")
    films = [f for f in films if f["slug"] != args.slug]
    shown = films[: args.limit]
    # "count" describes what is in "films", not what was on the page, so that
    # anything reading this back cannot report 77 results while holding 3.
    return {
        "slug": args.slug,
        "count": len(shown),
        "total": len(films),
        "films": shown,
    }


def cmd_search(args) -> dict:
    from urllib.parse import quote

    data = fetch_json(
        f"/s/autocompletefilm?q={quote(args.query)}&limit={args.limit}",
        ttl=TTL_LIST,
        refresh=args.refresh,
    )
    results = [
        {
            "slug": item.get("slug"),
            "title": item.get("name"),
            "year": item.get("releaseYear"),
            "runtime": item.get("runTime"),
            "directors": [d.get("name") for d in item.get("directors", [])],
        }
        for item in data.get("data", [])
    ]
    return {"query": args.query, "count": len(results), "results": results}


_AVERAGE = re.compile(r"[Ww]eighted average of ([\d.]+) based on ([\d,]+) rating")


def film_average(slug: str, refresh: bool = False) -> tuple[float, int] | None:
    """The site-wide weighted average for one film, and how many rated it.

    Read from /csi/film/<slug>/rating-histogram/ -- the fragment the film page
    loads its histogram from -- because it is ~6 KB against the full page's
    ~330 KB. There is no bulk endpoint for this anywhere on the site, so a
    comparison across a whole account really is one request per film; the
    30-day cache is what keeps that a one-off rather than a habit.
    """
    try:
        fragment = fetch(
            f"/csi/film/{slug}/rating-histogram/", ttl=TTL_FILM, refresh=refresh
        )
    except BoxdError:
        return None
    found = _AVERAGE.search(fragment)
    if not found:
        return None
    return float(found.group(1)), int(found.group(2).replace(",", ""))


def cmd_deltas(args) -> dict:
    """Where this viewer disagrees with the Letterboxd consensus.

    Costs one small request per rated film on a cold cache -- 378 of them for
    this account -- so it prints progress to stderr and is never called
    implicitly by another command.
    """
    # Collected directly rather than through cmd_films: --limit here means how
    # many disagreements to *show*, and passing it down would cap the films
    # fetched instead, silently comparing 15 of them and reporting the spread
    # of that as the account's.
    everything = collect(
        _films_path(args), ttl=TTL_LIST, refresh=args.refresh, limit=None
    )
    everything = _by_decade(everything, getattr(args, "decade", None))
    rated = [f for f in everything if f["rating"] is not None]
    if args.min_ratings < 0:
        raise BoxdError("--min-ratings cannot be negative")

    compared, skipped = [], 0
    for index, film in enumerate(rated, 1):
        if not args.quiet and index % 25 == 0:
            print(f"  ... {index}/{len(rated)}", file=sys.stderr)
        average = film_average(film["slug"], refresh=args.refresh)
        if average is None:
            skipped += 1
            continue
        mean, voters = average
        if voters < args.min_ratings:
            skipped += 1
            continue
        compared.append(
            {
                **film,
                "average": mean,
                "voters": voters,
                "delta": round(film["rating"] - mean, 2),
            }
        )

    if not compared:
        raise BoxdError("no films could be compared against the consensus")

    deltas = [f["delta"] for f in compared]
    mean_delta = sum(deltas) / len(deltas)
    spread = (sum((d - mean_delta) ** 2 for d in deltas) / len(deltas)) ** 0.5
    ordered = sorted(compared, key=lambda f: f["delta"])

    return {
        "user": args.user,
        "compared": len(compared),
        "skipped": skipped,
        "mean_delta": round(mean_delta, 3),
        "spread": round(spread, 3),
        "agree_within_half": sum(1 for d in deltas if abs(d) <= 0.5),
        "above": list(reversed(ordered[-args.limit :])),
        "below": ordered[: args.limit],
        "films": compared,
    }


def cmd_taste(args) -> dict:
    """The raw material for a viewer profile.

    Decades come free -- the year is already in every grid entry -- so beyond
    the watched list this only adds a director lookup for the films rated highly
    enough to say something.

    There is no genre breakdown here, and that is deliberate rather than
    missing: the only cheap source is /<user>/films/genre/<g>/, which
    Letterboxd's robots.txt disallows for every user agent. The compliant
    alternative is the per-film page at ~330 KB each, which for this account
    would be some 126 MB against the 4 MB those filter pages cost -- roughly
    thirty times the load on their servers to honour a rule written to stop
    search engines crawling filter permutations. Neither is worth it for a
    number, so the question is answered from the ratings themselves instead.
    """
    watched = collect(f"/{args.user}/films/", ttl=TTL_LIST, refresh=args.refresh)
    by_slug = {f["slug"]: f for f in watched}
    rated = {s: f["rating"] for s, f in by_slug.items() if f["rating"] is not None}

    if not rated:
        raise BoxdError(f"{args.user} has no public ratings to work from")

    distribution: dict[str, int] = {}
    for score in rated.values():
        distribution[f"{score:g}"] = distribution.get(f"{score:g}", 0) + 1

    decades: dict[str, dict] = {}
    for film in by_slug.values():
        if not film["year"]:
            continue
        decade = f"{film['year'] // 10 * 10}s"
        bucket = decades.setdefault(decade, {"watched": 0, "scores": []})
        bucket["watched"] += 1
        if film["rating"] is not None:
            bucket["scores"].append(film["rating"])

    # Directors only for the films that carry an opinion worth generalising
    # from. Doing all 379 would be 379 requests to learn mostly nothing.
    loved = sorted(rated.items(), key=lambda kv: -kv[1])[: args.director_limit]
    directors: dict[str, dict] = {}
    for slug, score in loved:
        try:
            data = fetch_json(f"/film/{slug}/json/", refresh=args.refresh)
        except BoxdError:
            continue
        for person in data.get("directors", []):
            name = person.get("name")
            if not name:
                continue
            bucket = directors.setdefault(name, {"films": [], "scores": []})
            bucket["films"].append(by_slug[slug]["title"])
            bucket["scores"].append(score)

    repeat = {
        name: {
            "films": info["films"],
            "mean": round(sum(info["scores"]) / len(info["scores"]), 2),
        }
        for name, info in directors.items()
        if len(info["films"]) > 1
    }

    return {
        "user": args.user,
        "watched": len(by_slug),
        "rated": len(rated),
        "mean": round(sum(rated.values()) / len(rated), 2),
        "distribution": dict(sorted(distribution.items(), key=lambda kv: float(kv[0]))),
        "decades": {
            decade: {
                "watched": info["watched"],
                "mean": round(sum(info["scores"]) / len(info["scores"]), 2)
                if info["scores"]
                else None,
            }
            for decade, info in sorted(decades.items())
        },
        "directors": dict(sorted(repeat.items(), key=lambda kv: -kv[1]["mean"])),
        "sampled_directors_from_top": len(loved),
    }


# --------------------------------------------------------------------------
# rendering
# --------------------------------------------------------------------------


def stars(rating: float | None) -> str:
    if rating is None:
        return "     "
    whole = int(rating)
    return ("*" * whole + ("+" if rating - whole else "")).ljust(5)


def film_line(film: dict) -> str:
    year = f" ({film['year']})" if film.get("year") else ""
    return f"  {stars(film.get('rating'))} {film['title']}{year}"


def render(command: str, data: dict) -> str:
    out = []
    if command == "profile":
        out.append(f"{data['name']}  --  letterboxd.com/{data['user']}/")
        stats = "   ".join(f"{v} {k}" for k, v in data["stats"].items())
        out.append(f"  {stats}")
        if data["favourites"]:
            out.append("")
            out.append("  Favourites")
            out.extend(film_line(f) for f in data["favourites"])

    elif command in {"watchlist", "films", "ratings"}:
        label = {"watchlist": "on the watchlist", "films": "watched", "ratings": "rated"}
        out.append(f"{data['count']} films {label[command]} -- {data['user']}")
        out.extend(film_line(f) for f in data["films"])

    elif command == "diary":
        out.append(f"{data['count']} recent entries -- {data['user']}")
        for entry in data["entries"]:
            flags = "".join(
                [" (rewatch)" if entry["rewatch"] else "", " <3" if entry["liked"] else ""]
            )
            year = f" ({entry['year']})" if entry["year"] else ""
            out.append(
                f"  {entry['watched']}  {stars(entry['rating'])} "
                f"{entry['title']}{year}{flags}"
            )
            if entry["review"]:
                out.append(f"          \"{entry['review']}\"")

    elif command == "film":
        directors = ", ".join(data["directors"]) or "unknown"
        original = (
            f"  [{data['original_title']}]"
            if data.get("original_title") and data["original_title"] != data["title"]
            else ""
        )
        out.append(f"{data['title']} ({data['year']}){original}")
        out.append(f"  {directors}  --  {data['runtime']} min")

    elif command == "similar":
        more = "" if data["count"] == data["total"] else f" (of {data['total']})"
        out.append(f"{data['count']} films{more} similar to {data['slug']}")
        out.extend(film_line(f) for f in data["films"])

    elif command == "search":
        out.append(f"{data['count']} results for {data['query']!r}")
        for item in data["results"]:
            directors = ", ".join(item["directors"]) or "unknown"
            out.append(f"  {item['slug']}")
            out.append(f"      {item['title']} ({item['year']})  {directors}")

    elif command == "deltas":
        out.append(
            f"{data['compared']} films compared against the Letterboxd average"
            + (f" ({data['skipped']} skipped)" if data["skipped"] else "")
        )
        agree = 100 * data["agree_within_half"] / data["compared"]
        direction = "above" if data["mean_delta"] > 0 else "below"
        out.append(
            f"  mean delta {data['mean_delta']:+.2f} ({direction} consensus), "
            f"spread {data['spread']:.2f}, {agree:.0f}% within half a star"
        )
        for label, rows in (("Rates above consensus", data["above"]),
                            ("Rates below consensus", data["below"])):
            out.append("")
            out.append(f"  {label}")
            for f in rows:
                year = f" ({f['year']})" if f.get("year") else ""
                out.append(
                    f"    {f['delta']:+.2f}  {f['rating']:.1f} vs {f['average']:.2f}"
                    f"  {f['title']}{year}"
                )

    elif command == "taste":
        out.append(
            f"{data['user']}: {data['watched']} watched, {data['rated']} rated, "
            f"mean {data['mean']}"
        )
        out.append("")
        out.append("  Ratings")
        for score, count in data["distribution"].items():
            bar = "#" * max(1, round(count / max(data["distribution"].values()) * 32))
            out.append(f"    {float(score):>4}  {count:>4}  {bar}")
        out.append("")
        out.append("  Decades                watched  mean")
        for decade, info in data["decades"].items():
            mean = f"{info['mean']:.2f}" if info["mean"] is not None else "   -"
            out.append(f"    {decade:<20} {info['watched']:>7}  {mean}")
        if data["directors"]:
            out.append("")
            out.append(
                f"  Directors returned to (within top {data['sampled_directors_from_top']})"
            )
            for name, info in data["directors"].items():
                out.append(f"    {info['mean']:>4}  {name}  --  {', '.join(info['films'])}")

    return "\n".join(out)


# --------------------------------------------------------------------------
# entry point
# --------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    # `boxd watchlist | head` is the obvious way to use half these commands, and
    # without this Python prints a BrokenPipeError traceback when head exits.
    try:
        import signal

        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    except (ImportError, AttributeError, ValueError):
        pass  # not POSIX, or not the main thread; the traceback is survivable

    parser = argparse.ArgumentParser(
        prog="boxd",
        description="Read-only Letterboxd for a public profile.",
        epilog="Every command is an unauthenticated GET; nothing here can "
        "write to a Letterboxd account.",
    )
    # The shared flags are declared twice on purpose: once on the top-level
    # parser, and once as a parent of every subcommand. Without the second,
    # argparse only accepts them before the subcommand -- `boxd --json ratings`
    # works and `boxd ratings --json` is an error, which is backwards from how
    # anyone actually types it. default=SUPPRESS on the parent copy is what
    # makes the pair safe: an unpassed subcommand flag leaves the namespace
    # alone instead of overwriting whatever the top-level parser already set.
    def shared(parser_obj, *, suppress: bool):
        blank = argparse.SUPPRESS if suppress else None
        parser_obj.add_argument(
            "--user",
            default=blank if suppress else DEFAULT_USER,
            help="Letterboxd username (default: $BOXD_USER)",
        )
        parser_obj.add_argument(
            "--json",
            action="store_true",
            default=blank if suppress else False,
            help="emit JSON",
        )
        parser_obj.add_argument(
            "--refresh",
            action="store_true",
            default=blank if suppress else False,
            help="bypass the cache for this run",
        )

    shared(parser, suppress=False)

    common = argparse.ArgumentParser(add_help=False)
    shared(common, suppress=True)

    subparsers = parser.add_subparsers(dest="command", required=True)

    def add(name, help_text, *, needs_user=True):
        sub = subparsers.add_parser(name, help=help_text, parents=[common])
        sub.set_defaults(needs_user=needs_user)
        return sub

    add("profile", "stats and favourites")
    add("watchlist", "everything on the watchlist").add_argument(
        "--limit", type=int, default=None
    )
    for name, help_text in [
        ("films", "everything watched, rated or not"),
        ("ratings", "rated films, highest first"),
    ]:
        sub = add(name, help_text)
        sub.add_argument("--limit", type=int, default=None)
        sub.add_argument(
            "--decade",
            help="restrict to one decade, e.g. 1990s (filtered locally)",
        )
    add("diary", "recent viewings, with dates and reviews").add_argument(
        "--limit", type=int, default=None
    )

    deltas = add("deltas", "where their ratings part from the Letterboxd average")
    deltas.add_argument("--limit", type=int, default=15)
    deltas.add_argument(
        "--min-ratings",
        type=int,
        default=1000,
        help="ignore films with fewer than this many Letterboxd ratings, whose "
        "average is too thin to disagree with (default: 1000)",
    )
    deltas.add_argument("--decade")
    deltas.add_argument(
        "--quiet", action="store_true", help="no progress on stderr"
    )

    taste = add("taste", "rating, decade and director breakdown")
    taste.add_argument(
        "--director-limit",
        type=int,
        default=60,
        help="how many top-rated films to look up directors for (default: 60)",
    )

    film = add("film", "details for one film", needs_user=False)
    film.add_argument("slug")

    similar = add("similar", "films Letterboxd considers similar", needs_user=False)
    similar.add_argument("slug")
    similar.add_argument("--limit", type=int, default=24)

    search = add("search", "find a film's slug", needs_user=False)
    search.add_argument("query")
    search.add_argument("--limit", type=int, default=8)

    args = parser.parse_args(argv)

    if args.needs_user and not args.user:
        parser.error(
            "no username: pass --user, set $BOXD_USER, or set apps.boxd.user in "
            "home-manager"
        )

    handlers = {
        "profile": cmd_profile,
        "watchlist": cmd_watchlist,
        "films": cmd_films,
        "ratings": cmd_ratings,
        "diary": cmd_diary,
        "taste": cmd_taste,
        "deltas": cmd_deltas,
        "film": cmd_film,
        "similar": cmd_similar,
        "search": cmd_search,
    }

    try:
        data = handlers[args.command](args)
    except BoxdError as exc:
        print(f"boxd: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130

    if args.json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(render(args.command, data))
    return 0


if __name__ == "__main__":
    sys.exit(main())
