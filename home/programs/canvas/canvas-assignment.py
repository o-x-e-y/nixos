import argparse
import os
import re
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

import requests

from canvas_api import BASE_URL, check, delete, get, get_all, personal_course, post, put

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


def rubric_criteria(course_url, wanted):
    by_title = {
        link["outcome"]["title"].strip(): link["outcome"]
        for link in get_all(
            f"{course_url}/outcome_group_links", outcome_style="full", per_page=100
        )
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


def find_assignment(course_url, name):
    matches = [
        assignment
        for assignment in get_all(f"{course_url}/assignments", per_page=100)
        if assignment["name"] == name
    ]
    if len(matches) > 1:
        ids = ", ".join(str(a["id"]) for a in matches)
        sys.exit(
            f'Error: {len(matches)} assignments are named "{name}" '
            f"(ids: {ids}). Delete or rename the extras first."
        )
    return matches[0] if matches else None


def delete_assignment(course_url, wanted):
    if wanted.isdigit():
        assignment = get(f"{course_url}/assignments/{wanted}")
    else:
        assignment = find_assignment(course_url, wanted)
        if not assignment:
            sys.exit(f'Error: no assignment named "{wanted}".')
    delete(f"{course_url}/assignments/{assignment['id']}")
    print(
        f"Deleted assignment: {assignment['name']} (id: {assignment['id']}). "
        f"Restore it at {BASE_URL}{course_url}/undelete"
    )


def find_course(wanted):
    courses = get_all(
        "/courses", enrollment_state="active", per_page=100, **{"include[]": "term"}
    )
    matches = [c for c in courses if wanted in (str(c["id"]), c["name"])]
    if not matches:
        names = "\n  ".join(sorted({c["name"] for c in courses}))
        sys.exit(f'Error: no active course "{wanted}". Your courses:\n  {names}')
    # Course names repeat every semester, so take the newest term
    return max(matches, key=lambda c: (c.get("term") or {}).get("start_at") or "")


def hand_in(course, name, doc):
    course_url = f"/courses/{course['id']}"
    assignment = find_assignment(course_url, name)
    if not assignment:
        names = "\n  ".join(
            a["name"] for a in get_all(f"{course_url}/assignments", per_page=100)
        )
        sys.exit(
            f'Error: {course['name']} has no assignment named "{name}". '
            f"Its assignments:\n  {names}"
        )
    if "online_upload" not in assignment["submission_types"]:
        types = ", ".join(assignment["submission_types"])
        sys.exit(f'Error: "{name}" takes {types}, not a file upload.')

    print(f"Uploading and submitting to {course['name']}: {doc}")
    submit(course_url, assignment["id"], doc)
    print("File submitted!")


def submit(course_url, assignment_id, doc):
    upload = post(
        f"{course_url}/assignments/{assignment_id}/submissions/self/files",
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
        f"{course_url}/assignments/{assignment_id}/submissions",
        {"submission": {"submission_type": "online_upload", "file_ids": [file_id]}},
    )


def main():
    parser = argparse.ArgumentParser(
        description="Create an assignment in the personal Canvas course, or "
        "continue one with the same name: add what it is missing and submit "
        "--doc as a new attempt. Without --name, opens $CANVAS_EDITOR for a "
        "form."
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
    parser.add_argument(
        "--publish",
        action="store_true",
        help="publish the assignment without submitting anything",
    )
    parser.add_argument(
        "--delete",
        metavar="ID_OR_NAME",
        help="delete this assignment from the personal course instead",
    )
    parser.add_argument(
        "--course",
        help="hand --doc in to an existing assignment in this course instead, "
        "by name or id",
    )
    args = parser.parse_args()

    if args.delete:
        if args.name or args.desc or args.rubric or args.doc or args.publish or args.course:
            sys.exit("Error: --delete takes no other options.")
        delete_assignment(f"/courses/{personal_course()['id']}", args.delete)
        return

    if args.name:
        name, desc, doc = args.name, args.desc, args.doc
    else:
        name, desc, doc = from_editor()
    doc = Path(doc).expanduser() if doc else None

    if args.course:
        if not doc or desc or args.rubric or args.publish:
            sys.exit("Error: --course takes --name and --doc, and nothing else.")
        hand_in(find_course(args.course), name, doc)
        return

    publish = args.publish or doc is not None
    course_url = f"/courses/{personal_course()['id']}"
    module = get_all(f"{course_url}/modules", per_page=100)[0]

    criteria = None
    if args.rubric:
        criteria = rubric_criteria(
            course_url, [title.strip() for title in args.rubric.split(",")]
        )

    assignment = find_assignment(course_url, name)
    if assignment:
        print(f"Found existing assignment: {name} (id: {assignment['id']})")
        if desc and desc != assignment["description"]:
            put(
                f"{course_url}/assignments/{assignment['id']}",
                {"assignment": {"description": desc}},
            )
            print("Description updated.")
    else:
        print(f"Creating assignment: {name}")
        assignment = post(
            f"{course_url}/assignments",
            {
                "assignment": {
                    "name": name,
                    "description": desc,
                    "submission_types": ["online_upload"],
                    "published": publish,
                }
            },
        )
        print(f"Assignment created (id: {assignment['id']}).")
    assignment_id = assignment["id"]

    in_module = get(
        f"{course_url}/module_item_sequence",
        asset_type="Assignment",
        asset_id=assignment_id,
    )["items"]
    if not in_module:
        print(f"Adding to module {module['name']}...")
        post(
            f"{course_url}/modules/{module['id']}/items",
            {"module_item": {"type": "Assignment", "content_id": assignment_id, "indent": 1}},
        )
        print("Added to module.")

    if criteria and assignment.get("rubric"):
        print("The assignment already has a rubric; leaving it as is.")
    elif criteria:
        print(f"Adding rubric: {args.rubric}")
        post(
            f"{course_url}/rubrics",
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

    if publish and not assignment["published"]:
        put(
            f"{course_url}/assignments/{assignment_id}",
            {"assignment": {"published": True}},
        )
        print("Assignment published.")

    if doc:
        print(f"Uploading and submitting: {doc}")
        submit(course_url, assignment_id, doc)
        print("File submitted!")


main()
