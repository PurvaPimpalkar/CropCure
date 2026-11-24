import json

filepath = 'd:/cropcure_final/model/treatment_data.json'
with open(filepath, 'r') as f:
    data = json.load(f)

for k, v in data.items():
    if k.endswith("healthy") or k.endswith("Healthy"):
        if "advice" not in v:
            v["advice"] = "Maintain consistent irrigation and monitor weekly for any early pest signs."
    else:
        if "advice" not in v:
            v["advice"] = "Practice 2-3 year crop rotation. Manage irrigation to reduce humidity around foliage. Balance fertilizer applications."

with open(filepath, 'w') as f:
    json.dump(data, f, indent=4)
print("Updated treatment_data.json with advice")
