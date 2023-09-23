import os

# Directory containing the extracted SVG files
svg_directory = "/Users/clarasun/OneDrive - The University of Western Ontario/SURP/04_PNC/share/fmriprep/extracted_svgs"

# Number of SVGs per HTML file
svgs_per_file = 50 # the smaller this number, the faster the html page will load

# Create a directory to store the split HTML files
split_html_directory = "split_html_files"
os.makedirs(split_html_directory, exist_ok=True)

# Retrieve a sorted list of SVG files
svg_files =sorted([f for f in os.listdir(svg_directory) if f.endswith(".svg")])

# Split the SVG files into groups
svg_groups = [svg_files[i:i + svgs_per_file] for i in range(0, len(svg_files), svgs_per_file)]

# Generate a separate HTML file for each SVG group
for i, svg_group in enumerate(svg_groups):
    html_file = os.path.join(split_html_directory, f"animated_svgs_{i}.html")

    with open(html_file, "w") as f:
        f.write("<html>\n<head>\n</head>\n<body>\n")

        for svg_file in svg_group:
            svg_path = os.path.join(svg_directory, svg_file)
            participant_id = svg_file.split("_")[0]  # Assuming participant ID is part of the filename
            svg_content = open(svg_path, "r").read()

            f.write(f"<h3>Participant: {participant_id}</h3>\n")
            f.write(f"<p>Path: {svg_path}</p>\n")
            f.write(svg_content + "\n<hr>\n")

        f.write("</body>\n</html>")
