import csv
import re

# Define the input and output file paths
input_file_path = '/Users/a84114/Desktop/Projects/Scripts/Web Scrape/pruned_data.txt'  # Replace with the path to your input file
output_file_path = 'data.csv'  # Path to save the pruned text

# Keywords to identify relevant lines
keywords = [
    "İlan No",
    "m² (Brüt)",
    "m² (Net)",
    "Oda Sayısı",
    "Bina Yaşı",
    "Bulunduğu Kat",
    "Kat Sayısı",
    "Isıtma",
    "Banyo Sayısı",
    "Balkon",
    "Asansör",
    "Otopark",
    "Eşyalı",
    "Site İçerisinde",
    "Aidat (TL)",
    "Depozito (TL)"
]

# Fieldnames for CSV
fieldnames = ['TRY Price', 'Listing ID', 'm² (Brüt)', 'm² (Net)', 'Oda Sayısı', 'Bina Yaşı',
              'Bulunduğu Kat', 'Kat Sayısı', 'Isıtma', 'Banyo Sayısı', 'Balkon', 'Asansör',
              'Otopark', 'Eşyalı', 'Site İçerisinde', 'Aidat (TL)', 'Depozito (TL)']

# Read the input text file
with open(input_file_path, 'r', encoding='utf-8') as file:
    lines = file.readlines()

entries = []
entry = {}

def clean_numeric(value):
    return re.sub(r'[^\d]', '', value.strip())

def parse_entry(entry):
    cleaned_entry = {key: value for key, value in entry.items() if key in fieldnames}
    entries.append(cleaned_entry)

for line in lines:
    stripped_line = line.strip()
    if re.search(r'\d+\.\d{3}\s*TL$', stripped_line):  # Match lines with price ending in 'TL'
        if entry:
            parse_entry(entry)
            entry = {}
        entry['TRY Price'] = clean_numeric(stripped_line)
        print(f"Price found: {entry['TRY Price']}")
    elif stripped_line.startswith("İlan No") and 'Listing ID' not in entry:
        parts = stripped_line.split("  ", 1)
        if len(parts) > 1:
            entry['Listing ID'] = parts[1]
            print(f"Listing ID found: {entry['Listing ID']}")
        else:
            print(f"Skipped malformed line: {stripped_line}")
    else:
        for keyword in keywords:
            if stripped_line.startswith(keyword) and keyword not in entry:
                value = stripped_line.split(keyword, 1)[1].strip()
                if keyword in ["Depozito (TL)", "Aidat (TL)"]:
                    value = clean_numeric(value)
                entry[keyword] = value
                print(f"{keyword} found: {entry[keyword]}")
                break

if entry:
    parse_entry(entry)

# Write all the entries to a CSV file without filtering
with open(output_file_path, 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    writer.writeheader()
    for entry in entries:
        try:
            writer.writerow(entry)
        except ValueError as e:
            print(f"Skipping entry due to error: {e}, entry: {entry}")

print(f"Pruned text has been saved to {output_file_path}")