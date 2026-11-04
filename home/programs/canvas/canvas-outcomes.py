import argparse
from collections import defaultdict

from canvas_api import api_url, check, get, get_all, personal_course, session


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
        "personal Canvas course and the assignments behind it: assessed ones "
        "with their score, '-' for a criterion left unrated, and '?' for ones "
        "whose rubric claims the outcome but that are not assessed yet."
    ).parse_args()

    course_url = f"/courses/{personal_course()['id']}"
    results, outcomes, assignments = outcome_results(course_url)
    scores = rollup_scores(course_url)
    titles = {i: outcome["title"].strip() for i, outcome in outcomes.items()}
    by_outcome = defaultdict(list)
    for result in results:
        if not result["hidden"]:
            by_outcome[result["links"]["learning_outcome"]].append(result)

    assessed = {result["links"]["assignment"] for result in results}
    claims = defaultdict(list)
    no_outcomes = []
    for assignment in get_all(
        f"{course_url}/assignments", per_page=100, **{"include[]": "submission"}
    ):
        if f"assignment_{assignment['id']}" in assessed:
            continue
        criteria = [
            c for c in assignment.get("rubric", []) if c.get("outcome_id")
        ]
        for criterion in criteria:
            outcome_id = str(criterion["outcome_id"])
            titles.setdefault(outcome_id, criterion["description"].strip())
            claims[outcome_id].append(assignment)
        submission = assignment["submission"]
        if not criteria and submission["submitted_at"] and not submission["grade"]:
            no_outcomes.append(assignment)

    for outcome_id in sorted(by_outcome.keys() | claims.keys(), key=titles.get):
        outcome = outcomes.get(outcome_id)
        score = scores.get(outcome_id)
        if not by_outcome[outcome_id]:
            summary = "not assessed yet"
        elif score is None:
            summary = "not rated"
        else:
            mastery = " mastery" if score >= outcome["mastery_points"] else ""
            summary = (
                f"{fmt(score)}/{fmt(outcome['points_possible'])} "
                f"{rating(outcome, score)}{mastery}"
            )
        print(f"{titles[outcome_id]}: {summary}")

        for assignment in sorted(
            claims[outcome_id],
            key=lambda a: a["submission"]["submitted_at"] or "",
            reverse=True,
        ):
            submitted = assignment["submission"]["submitted_at"]
            state = "not assessed yet" if submitted else "not handed in"
            print(f"  {(submitted or '')[:10]:10}    ?  {assignment['name']} ({state})")
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

    if no_outcomes:
        print("\nHanded in, not assessed, and no outcomes in the rubric:")
        for assignment in no_outcomes:
            print(
                f"  {assignment['submission']['submitted_at'][:10]}  "
                f"{assignment['name']}"
            )


main()
