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
  (mkdir "./Tofu/Assets.xcassets/${name}.imageset" || true) 2>/dev/null
  cp "$file" "./Tofu/Assets.xcassets/${name}.imageset/${name}@3x.png"
  sips --resampleWidth 128 "./Tofu/Assets.xcassets/${name}.imageset/${name}@3x.png" --out "./Tofu/Assets.xcassets/${name}.imageset/${name}@2x.png" &>/dev/null
  sips --resampleWidth 64 "./Tofu/Assets.xcassets/${name}.imageset/${name}@3x.png" --out "./Tofu/Assets.xcassets/${name}.imageset/${name}.png" &>/dev/null
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

