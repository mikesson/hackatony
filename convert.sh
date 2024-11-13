#!/bin/bash
# if you can't execute in your env, run: chmod +x convert.sh 
# also ensure you can use jq
# take a jupyter notebook as input, create output file, to convert notebook file to python code for a containerized application


PROJECT_ID=$GCP_PROJECT
LOCATION_ID=$GCP_REGION
API_ENDPOINT="us-central1-aiplatform.googleapis.com"
MODEL_ID="gemini-1.5-pro-002"


# prompt composition 

PROMPT_SECTION_1="Convert the relevant sections of a Jupyter notebook into python code for a containerised application with the Flask framework. \
Use the below notebook and the boilerplate app code as the basis, and only add what is needed, i.e. add all code needed to execute the notebook \
flow inside the Flask app via a REST API call. Also take the comments in code files into consideration where the comment starts with "@Gemini" \
on where to change, and where to keep the existing code. Return modified file names and the code within. Also create a README.md file with a \
summary of the functionality and some documentation on how to use the API. Whenever a file content starts, please add 'CODE_STARTS_HERE' \n \n \
Base Notebook file: \n\n \
notebook.ipynb \n \
============ \n"


PROMPT_SECTION_2="\n\nBase app files: \n\n \
app.py \n \
======== \n"


PROMPT_SECTION_3="\n\n \
requirements.txt \n \
============== \n"

PROMPT_SECTION_4="\n\n \
Wherever suitable, here are common project-specific variables that can be inserted as default values where needed: \n\
Google Cloud Project ID: ' $GCP_PROJECT '\n \
Target Google Cloud region: ' $GCP_REGION '\n'


COMPOSITE_PROMPT=$PROMPT_SECTION_1$(cat notebook_to_app_simple-1.ipynb)$PROMPT_SECTION_2$(cat base-app/app.py)$PROMPT_SECTION_3$(cat base-app/requirements.txt)$PROMPT_SECTION_4
#echo $COMPOSITE_PROMPT > review-composite-prompt.txt

jq --arg new "$COMPOSITE_PROMPT" '.contents[0].parts[0].text = $new' convert-request-template.json > convert-request-mod.json


# replace placeholder with prompt in request JSON file
file_name="convert-request-template.json"
placeholder_string="%%%REPLACED_BY_SCRIPT%%%"

# call model prediction endpoint

curl \
-X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-d '@convert-request-mod.json' \
"https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION_ID}/publishers/google/models/${MODEL_ID}:generateContent" > convert-response.json


# add response to new convert-instructions.txt document for review
# Extract the string from convert-response.json
extracted_text=$(jq -r '.candidates[0].content.parts[0].text' convert-response.json)

# Add the extracted text to convert-instructions.txt
echo "$extracted_text" > convert-instructions.txt

# ADDITIONAL CONFIG (auto-convert to files - WIP)