import os

import yaml

doc_files = [file for file in os.listdir("macros") if file.endswith(".yml")]
docs: list[dict] = []
for file in doc_files:
    with open(os.path.join("macros", file), "r") as f:
        doc = yaml.safe_load(f)
        docs.extend(doc.get("macros", []))

ref_string = "# Macro Reference\n\n"

for doc in docs:
    ref_string += f"## {doc.get('name')}\n\n"
    ref_string += f"{doc.get('description')}\n\n"
    ref_string += "### Usage\n\n"
    ref_string += f"```\n{doc.get('usage')}\n```\n\n"
    ref_string += "### Arguments\n\n"
    for arg in doc.get("arguments", []):
        ref_string += f"**{arg.get('name')}**\n - **type:** {arg.get('type')}\n - **description:** {arg.get('description')}\n\n"
    ref_string += "\n"

with open("docs/macro_reference.md", "w") as f:
    f.write(ref_string)
