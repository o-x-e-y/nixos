import argparse
import sys
from collections import defaultdict
from pathlib import Path

import requests

COURSE_ID = 14809
BASE_URL = "https://fontysict.instructure.com"
API_KEY_PATH = "/run/secrets/canvas-api-key"

session = requests.Session()
session.headers["Authorization"] = (
    "Bearer " + Path(API_KEY_PATH).read_text().strip()
)
course_url = f"{BASE_URL}/api/v1/courses/{COURSE_ID}"


def check(response):
    if not response.ok:
        sys.exit(
            f"Error: {response.request.method} {response.url} returned "
            f"{response.status_code}: {response.text}"
        )
    return response


def outcome_results():
    results, outcomes, assignments = [], {}, {}
    url = course_url + "/outcome_results"
    params = {
        "user_ids[]": "self",
        "include[]": ["outcomes", "alignments"],
        "per_page": 100,
    }
    while url:
        response = check(session.get(url, params=params))
        body = response.json()
        results += body["outcome_results"]
        for outcome in body["linked"]["outcomes"]:
            outcomes[str(outcome["id"])] = outcome
        for alignment in body["linked"]["alignments"]:
            assignments[alignment["id"]] = alignment["name"]
        url = response.links.get("next", {}).get("url")
        params = None
    return results, outcomes, assignments


def rollup_scores():
    rollups = check(
        session.get(
            course_url + "/outcome_rollups", params={"user_ids[]": "self"}
        )
    ).json()["rollups"]
    if not rollups:
        return {}
    return {s["links"]["outcome"]: s["score"] for s in rollups[0]["scores"]}


def rating(outcome, score):
    for r in sorted(outcome["ratings"], key=lambda r: -r["points"]):
        if score >= r["points"]:
            return r["description"]
    return ""


def fmt(score):
    return "-" if score is None else f"{score:g}"


def main():
    argparse.ArgumentParser(
        description="Show the current score on each learning outcome in the "
        "personal Canvas course, and the assessed assignments behind it."
    ).parse_args()

    results, outcomes, assignments = outcome_results()
    scores = rollup_scores()
    by_outcome = defaultdict(list)
    for result in results:
        if not result["hidden"]:
            by_outcome[result["links"]["learning_outcome"]].append(result)

    for outcome_id in sorted(by_outcome, key=lambda i: outcomes[i]["title"].strip()):
        outcome = outcomes[outcome_id]
        score = scores.get(outcome_id)
        if score is None:
            summary = "not rated"
        else:
            mastery = " mastery" if score >= outcome["mastery_points"] else ""
            summary = (
                f"{fmt(score)}/{fmt(outcome['points_possible'])} "
                f"{rating(outcome, score)}{mastery}"
            )
        print(f"{outcome['title'].strip()}: {summary}")

        for result in sorted(
            by_outcome[outcome_id],
            key=lambda r: r["submitted_or_assessed_at"],
            reverse=True,
        ):
            print(
                f"  {result['submitted_or_assessed_at'][:10]}  "
                f"{fmt(result['score']):>3}  "
                f"{assignments[result['links']['assignment']]}"
            )


main()
