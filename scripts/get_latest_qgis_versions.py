import requests
import json
import re
import click
import csv
from datetime import date
from io import StringIO
from typing import Any


# From https://github.com/qgis/QGIS-Website/blob/a09b77bf8580da698bb7452817de7085ad50ba69/scripts/update-schedule.py#L60
QGIS_RELEASE_SCHEDULE_CSV = (
    "https://docs.google.com/spreadsheets/d/1MOIjwon5eDI04DG6rX_HwucZkW1fxFJ0b_yB0xYETOE/"
    "export?format=csv&gid=1982100417"
)


@click.command()
@click.option(
    "--release",
    default="stable",
    type=click.Choice(["ltr", "stable"]),
    help="Which release to extract. `ltr` or `stable`",
)
@click.option(
    "--github_token",
    default=None,
    help="Github token. Can help in case of rate limits.",
)
def extract(release: str, github_token: str | None) -> None:
    """Print the latest QGIS stable or LTR release metadata for a tag stream."""

    def parse_release_tag(tag_name: str) -> dict[str, Any] | None:
        """Parse a QGIS release tag into comparable version metadata."""

        version_parts = re.split(r"[\-_]", tag_name)[1:]

        return {
            "short_version": version_parts[0] + "." + version_parts[1],
            "version": tuple(int(part) for part in version_parts),
            "patch_version": ".".join(version_parts),
        }

    def get_current_ltr_short_version() -> str:
        """Read the schedule sheet and return the active LTR short version."""

        response = requests.get(QGIS_RELEASE_SCHEDULE_CSV)
        response.raise_for_status()

        current_ltr = None
        current_ltr_date = None
        today = date.today()
        reader = csv.DictReader(StringIO(response.text))
        for row in reader:
            event = (row.get("Event") or "").strip()
            ltr_version = (row.get("LTR") or "").strip()
            date_str = (row.get("Date") or "").strip()

            if "LTR/PR" not in event or not ltr_version or not date_str:
                continue

            try:
                row_date = date.fromisoformat(date_str)
            except ValueError:
                continue

            if row_date > today:
                continue

            if current_ltr_date is None or row_date >= current_ltr_date:
                current_ltr = ltr_version
                current_ltr_date = row_date

        if current_ltr is None:
            raise RuntimeError("Could not determine the current LTR release line")

        return ".".join(current_ltr.split(".")[:2])

    def collect_latest_releases(
        tags: list[dict[str, Any]], prefix: str
    ) -> dict[str, dict[str, Any]]:
        """Collect the newest tag for each QGIS short version in a tag stream."""

        latest_releases = dict()
        for tag in tags:
            ref = tag["ref"]
            tag_name = ref.split("/")[-1]

            if not tag_name.startswith(prefix):
                continue

            parsed_tag = parse_release_tag(tag_name)

            if parsed_tag is None:
                continue

            current_release = latest_releases.get(parsed_tag["short_version"])
            if current_release is None or parsed_tag["version"] > current_release["version"]:
                latest_releases[parsed_tag["short_version"]] = parsed_tag

        return latest_releases

    def select_latest_release(
        latest_releases: dict[str, dict[str, Any]],
        short_version: str | None = None,
    ) -> tuple[str, dict[str, Any]]:
        """Select the highest release, optionally skipping excluded version tuples."""

        if short_version is not None:
            return short_version, latest_releases[short_version]

        candidates = [
            (data["version"], short_version)
            for short_version, data in latest_releases.items()
        ]

        _, short_version = max(candidates, key=lambda item: item[0])
        return short_version, latest_releases[short_version]

    def build_release_info(
        short_version: str, release_data: dict[str, Any]
    ) -> dict[str, str]:
        """Format the output fields expected by the release workflow."""

        return {
            "short_version": short_version,
            "patch_version": release_data["patch_version"],
            "tag_name": f'final-{release_data["patch_version"].replace(".", "_")}',
        }

    r = requests.get(
        "https://api.github.com/repos/qgis/QGIS/git/refs/tags",
        headers={"Authorization": github_token},
    )
    r.raise_for_status()
    tags = json.loads(r.text)
    releases = collect_latest_releases(tags, "final-")

    current_release, current_release_data = select_latest_release(releases)
    current_ltr = get_current_ltr_short_version()
    current_ltr, current_ltr_data = select_latest_release(releases, current_ltr)

    info = {
        "ltr": build_release_info(current_ltr, current_ltr_data),
        "stable": build_release_info(current_release, current_release_data),
    }

    print(f"QGIS_VERSION_SHORT={info[release]['short_version']}")
    print(f"QGIS_VERSION_PATCH={info[release]['patch_version']}")
    print(f"QGIS_VERSION_TAG={info[release]['tag_name']}")


if __name__ == "__main__":
    extract()
