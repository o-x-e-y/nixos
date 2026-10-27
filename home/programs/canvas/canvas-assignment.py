import argparse
import os
import re
import shlex
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

import requests

COURSE_ID = 14809
MODULE_ID = 126437
BASE_URL = "https://fhict.instructure.com"
API_KEY_PATH = "/run/secrets/canvas-api-key"

TEMPLATE = """\
# Canvas Assignment — fill in below, then save and close the editor.
# Three sections separated by blank lines:
#   1. Assignment name (required)
#   2. Description — HTML supported (optional)
#   3. Path to a file to submit (optional)
#
# Example:
#   Week 3 Reflection
#
#   Write a 500-word reflection on the reading material.
#
#   /home/user/documents/reflection.pdf

"""

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


def post(path, body):
    return check(session.post(course_url + path, json=body)).json()


def get_all(path):
    items = []
    url = course_url + path
    while url:
        response = check(session.get(url))
        items += response.json()
        url = response.links.get("next", {}).get("url")
    return items


def from_editor():
    with tempfile.NamedTemporaryFile(
        "w+", prefix="canvas-assignment-", suffix=".md"
    ) as f:
        f.write(TEMPLATE)
        f.flush()
        editor = os.environ.get("CANVAS_EDITOR", "codium --wait")
        subprocess.run([*shlex.split(editor), f.name], check=True)
        f.seek(0)
        text = "\n".join(
            line for line in f.read().splitlines() if not line.startswith("#")
        )

    sections = [s for s in text.split("\n\n") if s.strip()]
    if not sections:
        sys.exit("Error: no assignment name found.")

    name = sections[0].strip().splitlines()[0]
    desc, doc = "", None
    if len(sections) >= 3:
        desc, doc = sections[1].strip(), "".join(sections[2].split())
    elif len(sections) == 2:
        candidate = "".join(sections[1].split())
        if candidate.startswith(("/", "~")):
            doc = candidate
        else:
            desc = sections[1].strip()
    return name, desc, doc


def rubric_criteria(wanted):
    by_title = {
        link["outcome"]["title"].strip(): link["outcome"]
        for link in get_all("/outcome_group_links?outcome_style=full&per_page=100")
    }
    unknown = [title for title in wanted if title not in by_title]
    if unknown:
        sys.exit("Error: unknown outcome(s): " + ", ".join(unknown))

    criteria = {}
    for i, title in enumerate(wanted):
        outcome = by_title[title]
        criteria[str(i)] = {
            "description": title,
            "long_description": re.sub(r"<link[^>]*>", "", outcome["description"]),
            "points": outcome["points_possible"],
            "learning_outcome_id": outcome["id"],
            "mastery_points": outcome["mastery_points"],
            "ratings": {str(j): r for j, r in enumerate(outcome["ratings"])},
        }
    return criteria


def submit(assignment_id, doc):
    upload = post(
        f"/assignments/{assignment_id}/submissions/self/files",
        {"name": doc.name, "size": doc.stat().st_size},
    )
    with doc.open("rb") as f:
        file_id = check(
            requests.post(
                upload["upload_url"],
                data=upload["upload_params"],
                files={"file": f},
            )
        ).json()["id"]
    post(
        f"/assignments/{assignment_id}/submissions",
        {"submission": {"submission_type": "online_upload", "file_ids": [file_id]}},
    )


def main():
    if date.today() > date(2026, 10, 16):
        print(
            f"Warning: {BASE_URL} is deprecated since 2026-10-16 and stops "
            "working in February 2027. Switch BASE_URL to "
            "https://fontysict.instructure.com in "
            "home/programs/canvas/canvas-assignment.py.",
            file=sys.stderr,
        )

    parser = argparse.ArgumentParser(
        description="Create an assignment in the personal Canvas course. "
        "Without --name, opens $CANVAS_EDITOR for a form."
    )
    parser.add_argument("--name", help="assignment title")
    parser.add_argument("--desc", default="", help="description, as HTML")
    parser.add_argument(
        "--rubric",
        help="comma-separated learning outcomes, e.g. Analysis-S2,PL-1",
    )
    parser.add_argument(
        "--doc", help="file to upload and submit; publishes the assignment"
    )
    args = parser.parse_args()

    if args.name:
        name, desc, doc = args.name, args.desc, args.doc
    else:
        name, desc, doc = from_editor()
    doc = Path(doc).expanduser() if doc else None

    criteria = None
    if args.rubric:
        criteria = rubric_criteria(
            [title.strip() for title in args.rubric.split(",")]
        )

    print(f"Creating assignment: {name}")
    assignment_id = post(
        "/assignments",
        {
            "assignment": {
                "name": name,
                "description": desc,
                "submission_types": ["online_upload"],
                "published": doc is not None,
            }
        },
    )["id"]

    print(f"Assignment created (id: {assignment_id}), adding to module...")
    post(
        f"/modules/{MODULE_ID}/items",
        {"module_item": {"type": "Assignment", "content_id": assignment_id, "indent": 1}},
    )
    print(f'Done! Assignment "{name}" added to module.')

    if criteria:
        print(f"Adding rubric: {args.rubric}")
        post(
            "/rubrics",
            {
                "rubric": {"title": name, "criteria": criteria},
                "rubric_association": {
                    "association_type": "Assignment",
                    "association_id": assignment_id,
                    "purpose": "grading",
                    "use_for_grading": False,
                },
            },
        )
        print("Rubric added.")

    if doc:
        print(f"Uploading and submitting: {doc}")
        submit(assignment_id, doc)
        print("File submitted!")


main()
