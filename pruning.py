# Define the input and output file paths
input_file_path = '/Users/a84114/Desktop/Projects/Scripts/Web Scrape/raw_data.txt'  # Replace with the path to your input file
output_file_path = 'pruned_data.txt'  # Path to save the pruned text

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

# Read the input text file
with open(input_file_path, 'r', encoding='utf-8') as file:
    lines = file.readlines()

# Initialize a list to hold pruned lines
pruned_lines = []

# Iterate through lines and extract relevant lines
for i, line in enumerate(lines):
    stripped_line = line.strip()
    if stripped_line.startswith("Emlak Kiralama Rehberi"):
        if i + 1 < len(lines):  # Ensure there's a line following the current one
            pruned_lines.append(lines[i + 1].strip())
    elif any(stripped_line.startswith(keyword) for keyword in keywords):
        pruned_lines.append(stripped_line)

# Save the pruned lines to a new text file
with open(output_file_path, 'w', encoding='utf-8') as file:
    file.write('\n'.join(pruned_lines))

print(f"Pruned text has been saved to {output_file_path}")
