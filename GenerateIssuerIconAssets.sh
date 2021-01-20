#!/usr/bin/env bash
set -euo pipefail

command -v ag >/dev/null 2>&1 || { echo >&2 "I require The Silver Searcher (ag) but it's not installed. Aborting."; exit 1; }

for file in ./IssuerIcons/*.png; do
  # RegEx Explanation:
  #   Positive Lookbehind -- (?<=\.\/IssuerIcons\/)
  #     Asserts that the selected portion must be preceeded by ./IssuerIcons/
  #   Pattern Match -- .*
  #     Matches all characters, excluding newlines, of any length
  #   Positive Lookforward -- (?=\.png)
  #     Asserts that the selected portion must be followed by .png
  name="$(echo $file | ag --only-matching '(?<=\.\/IssuerIcons\/).*(?=\.png)')"
done

