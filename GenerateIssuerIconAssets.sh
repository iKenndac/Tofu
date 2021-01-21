#!/usr/bin/env bash
set -euo pipefail

command -v ag >/dev/null 2>&1 || { echo >&2 "I require The Silver Searcher (ag) but it's not installed. Aborting."; exit 1; }

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

for file in ./IssuerIcons/*.png; do
  name="$(get_name $file)"
  imageset="./Tofu/Assets.xcassets/${name}.imageset/"
  (mkdir "$imageset" || true) 2>/dev/null
  cp "$file" "${imageset}${name}@3x.png"
  sips --resampleWidth 128 "${imageset}${name}@3x.png" --out "${imageset}${name}@2x.png" &>/dev/null
  sips --resampleWidth 64 "${imageset}${name}@3x.png" --out "${imageset}${name}.png" &>/dev/null
  echo -n "{
  \"images\" : [
    {
      \"idiom\" : \"universal\",
      \"filename\" : \"${name}.png\",
      \"scale\" : \"1x\"
    },
    {
      \"idiom\" : \"universal\",
      \"filename\" : \"${name}@2x.png\",
      \"scale\" : \"2x\"
    },
    {
      \"idiom\" : \"universal\",
      \"filename\" : \"${name}@3x.png\",
      \"scale\" : \"3x\"
    }
  ],
  \"info\" : {
    \"version\" : 1,
    \"author\" : \"xcode\"
  }
}" > "./Tofu/Assets.xcassets/${name}.imageset/Contents.json"
done

