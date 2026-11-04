import sys
from pathlib import Path

import requests

BASE_URL = "https://fontysict.instructure.com"
API_KEY_PATH = "/run/secrets/canvas-api-key"

session = requests.Session()
session.headers["Authorization"] = (
    "Bearer " + Path(API_KEY_PATH).read_text().strip()
)
api_url = f"{BASE_URL}/api/v1"


def check(response):
    if not response.ok:
        sys.exit(
            f"Error: {response.request.method} {response.url} returned "
            f"{response.status_code}: {response.text}"
        )
    return response


def get(path, **params):
    return check(session.get(api_url + path, params=params)).json()


def get_all(path, **params):
    items = []
    url = api_url + path
    while url:
        response = check(session.get(url, params=params))
        items += response.json()
        url = response.links.get("next", {}).get("url")
        params = None
    return items


def post(path, body):
    return check(session.post(api_url + path, json=body)).json()


def put(path, body):
    return check(session.put(api_url + path, json=body)).json()


def delete(path):
    return check(session.delete(api_url + path)).json()


def personal_course():
    courses = [
        course
        for course in get_all("/courses", enrollment_type="teacher", per_page=100)
        if course["name"].endswith("personal course")
    ]
    if len(courses) != 1:
        sys.exit(
            "Error: expected one course named '… personal course' where you "
            f"teach, found {len(courses)}."
        )
    return courses[0]
