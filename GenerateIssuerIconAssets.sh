#!/usr/bin/env bash
set -euo pipefail

command -v ag >/dev/null 2>&1 || { echo >&2 "I require The Silver Searcher (ag) but it's not installed. Aborting."; exit 1; }
command -v sips >/dev/null 2>&1 || { echo >&2 "I require sips but it's not installed. Aborting."; exit 1; }

get_name() {
  # RegEx Explanation:
  #   Positive Lookbehind -- (?<=\.\/IssuerIcons\/)
  #     Asserts that the selected portion must be preceeded by ./IssuerIcons/
  #   Pattern Match -- .*
  #     Matches all characters, excluding newlines, of any length
  #   Positive Lookforward -- (?=\.png)
  #     Asserts that the selected portion must be followed by .png
  echo $1 | ag --only-matching '(?<=\.\/IssuerIcons\/).*(?=\.png)'
}

write_json() {
  # JSON copied from Xcode output
  echo -n "{
  \"images\" : [
    {
      \"idiom\" : \"universal\",
      \"filename\" : \"${1}.png\",
      \"scale\" : \"1x\"
    },
    {
      \"idiom\" : \"universal\",
      \"filename\" : \"${1}@2x.png\",
      \"scale\" : \"2x\"
    },
    {
      \"idiom\" : \"universal\",
      \"filename\" : \"${1}@3x.png\",
      \"scale\" : \"3x\"
    }
  ],
  \"info\" : {
    \"version\" : 1,
    \"author\" : \"xcode\"
  }
}" > "${2}"
}

for file in ./IssuerIcons/*.png; do
  name="$(get_name $file)"
  echo "Generating icon for ${name}"
  imageset="./Tofu/Assets.xcassets/${name}.imageset/"
  (mkdir "$imageset" || true) 2>/dev/null
  sips --resampleWidth 192 "$file" --out "${imageset}${name}@3x.png" &>/dev/null
  sips --resampleWidth 128 "$file" --out "${imageset}${name}@2x.png" &>/dev/null
  sips --resampleWidth 64 "$file" --out "${imageset}${name}.png" &>/dev/null
  write_json "$name" "${imageset}Contents.json"
done

