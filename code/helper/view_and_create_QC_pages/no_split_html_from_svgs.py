import os

# Directory containing the extracted SVG files
svg_directory = "/Users/*/share/fmriprep/extracted_svgs" # Replace this with local path where extracted SVGs are stored 

# Create an HTML file to display SVGs
html_file = "animated_svgs.html"

# Write the results to the html file
with open(html_file, "w") as f:
    f.write("<html>\n<head>\n</head>\n<body>\n")

    for svg_file in os.listdir(svg_directory):
        svg_path = os.path.join(svg_directory, svg_file)
        participant_id = svg_file.split("_")[0]  # Assuming participant ID is part of the filename
        svg_content = open(svg_path, "r").read()

        f.write(f"<h3>Participant: {participant_id}</h3>\n")
        f.write(f"<p>Path: {svg_path}</p>\n")
        f.write(svg_content + "\n<hr>\n")

    f.write("</body>\n</html>")
