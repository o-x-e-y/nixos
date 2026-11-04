import argparse
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from canvas_api import get, get_all

STATE_HOME = os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")
STATE_PATH = Path(STATE_HOME, "canvas-feedback.json")


def current_courses():
    now = datetime.now(timezone.utc).isoformat()
    courses = get_all(
        "/courses",
        enrollment_type="student",
        enrollment_state="active",
        per_page=100,
        **{"include[]": "term"},
    )
    return [
        course
        for course in courses
        if ((course.get("term") or {}).get("end_at") or now) >= now
    ]


def assessment(submission):
    assignment = submission["assignment"]
    lines = []
    if submission["grade"]:
        lines.append(f"Grade: {submission['grade']}")
    criteria = {c["id"]: c for c in assignment.get("rubric", [])}
    for criterion_id, rated in (submission.get("rubric_assessment") or {}).items():
        criterion = criteria.get(criterion_id)
        if not criterion:
            continue
        ratings = {r["id"]: r["description"] for r in criterion["ratings"]}
        # Unrated criteria still carry a rating_id, just no points
        if rated.get("points") is None:
            rating = "not rated"
        else:
            rating = ratings.get(rated.get("rating_id"), f"{rated['points']:g} points")
        line = f"{criterion['description'].strip()}: {rating}"
        if rated.get("comments"):
            line += f" ({rated['comments']})"
        lines.append(line)
    return "\n".join(lines)


def feedback(me):
    for course in current_courses():
        submissions = get_all(
            f"/courses/{course['id']}/students/submissions",
            per_page=100,
            **{
                "student_ids[]": "self",
                "include[]": ["submission_comments", "rubric_assessment", "assignment"],
            },
        )
        for submission in submissions:
            title = f"{course['name']}: {submission['assignment']['name']}"
            for comment in submission.get("submission_comments", []):
                if comment["author_id"] != me:
                    yield (
                        f"comment:{comment['id']}",
                        title,
                        f"{comment['author_name']}: {comment['comment']}",
                    )
            if submission["graded_at"]:
                yield (
                    f"assessed:{submission['id']}:{submission['graded_at']}",
                    title,
                    "Assessed\n" + assessment(submission),
                )


def main():
    parser = argparse.ArgumentParser(
        description="Print feedback on your Canvas submissions that is new "
        "since the last run: comments from others and assessments, in "
        "courses whose term is still running."
    )
    parser.add_argument(
        "--notify", action="store_true", help="also show each one as a notification"
    )
    args = parser.parse_args()

    seen = set(json.loads(STATE_PATH.read_text())) if STATE_PATH.exists() else None
    items = list(feedback(get("/users/self")["id"]))

    if seen is None:
        print(f"First run: recorded {len(items)} existing items; later runs report what is new.")
    else:
        for key, title, body in items:
            if key in seen:
                continue
            print(f"{title}\n{body}\n")
            if args.notify:
                subprocess.run(["notify-send", "--app-name=Canvas", title, body])

    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    STATE_PATH.write_text(json.dumps(sorted(key for key, _, _ in items)))


main()
