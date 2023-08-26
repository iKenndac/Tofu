#!/usr/bin/env bash
set -euo pipefail

get_name() {
  echo $1 | sed -E 's:.+/(.+)\.png:\1:'
}

write_json() {
  # JSON copied from Xcode output
  cat << EOF > "$2"
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "${1}.png",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "filename" : "${1}@2x.png",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "filename" : "${1}@3x.png",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
}


cd "$(dirname "$0")"
for file in "$(git ls-files --others --exclude-standard ./IssuerIcons)"; do
  name="$(get_name $file)"
  echo "Generating icon for ${name}"
  imageset="./Tofu/Assets.xcassets/${name}.imageset/"
  mkdir -p "$imageset"
  sips --resampleWidth 192 "$file" --out "${imageset}${name}@3x.png" >/dev/null
  sips --resampleWidth 128 "$file" --out "${imageset}${name}@2x.png" >/dev/null
  sips --resampleWidth 64 "$file" --out "${imageset}${name}.png" >/dev/null
  write_json "$name" "${imageset}Contents.json"
done
