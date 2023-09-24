# Create a directory to store the SVG files
mkdir extracted_svgs

# Find and copy the SVG files to the new directory 
# Replace the "sdc_bold" in the string "*_task-rest_desc-sdc_bold.svg" 
# with the specific functional or anatomical svg suffix of the images you want to extract
find . -type f -name "*_task-rest_desc-sdc_bold.svg" -exec cp {} extracted_svgs/ \;
