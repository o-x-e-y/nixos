import argparse
from collections import defaultdict

from canvas_api import api_url, check, get, personal_course, session


def outcome_results(course_url):
    results, outcomes, assignments = [], {}, {}
    url = f"{api_url}{course_url}/outcome_results"
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


def rollup_scores(course_url):
    rollups = get(f"{course_url}/outcome_rollups", **{"user_ids[]": "self"})[
        "rollups"
    ]
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

    course_url = f"/courses/{personal_course()['id']}"
    results, outcomes, assignments = outcome_results(course_url)
    scores = rollup_scores(course_url)
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
