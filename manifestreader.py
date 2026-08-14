import json
import os
import urllib.parse
import urllib.request

os.makedirs("./mods", exist_ok=True)

with open("./manifest.json") as f:
    files = json.load(f).get("files", [])

print(f"Reading Manifest... {len(files)} Mods found")
headers = {"User-Agent": "Mozilla/5.0"}

for item in files:
    p_id, f_id = item["projectID"], item["fileID"]
    name = item.get("fileName", f"{f_id}.jar")
    if not name.endswith(".jar"):
        name += ".jar"
    dest = f"./mods/{name}"

    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        continue

    clean_name = urllib.parse.unquote(name)
    part1, part2 = f_id // 1000, f_id % 1000

    urls = [
        f"https://cursemaven.com/v1/downloads/{p_id}/{f_id}/download",
        f"https://www.curseforge.com/api/v1/mods/{p_id}/files/{f_id}/download",
        f"https://edge.forgecdn.net/files/{part1}/{part2}/{urllib.parse.quote(clean_name)}",
    ]

    loaded = False
    for url in urls:
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = resp.read()
                if len(data) > 1000:
                    with open(dest, "wb") as out:
                        out.write(data)
                    print(f"Installed: {name}")
                    loaded = True
                    break
        except Exception:
            continue

    if not loaded:
        print(f"Overrides/Custom: {name}")
