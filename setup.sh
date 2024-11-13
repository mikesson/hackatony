#!/bin/bash

reset='\033[0m'
lightred='\033[91m'
lightgreen='\033[92m'
lightyellow='\033[93m'
lightblue='\033[94m'
set -e

echo -e "${lightblue}Starting setup script...${reset}"


# EDIT THIS BEFORE RUNNING THE SCRIPT #####
export PROJECT_NAME='hackatony' # --> enter your project name here
export GCP_PROJECT='ai-innovation-hub-concept-1'  # --> enter your GCP project ID here (not the number and not the display name)
export GCP_REGION='europe-west3' # --> enter your Region
# ################################### #####
echo -e "${lightgreen}User variables populated${reset}"

# this section pre-populates from the above, you can customize, but no need

export GCP_BUCKET=$PROJECT_NAME'-files' # Create a bucket for the temp uploaded files
export AR_REPO=$PROJECT_NAME'-artifacts' # Create an artifact repository to store docker files
export NOW=-`date +%Y%m%d-%H-%M-%S` # date pattern for date suffix
export SERVICE_NAME=$PROJECT_NAME$NOW # Name of the Cloud Run Service - by default, same as the project-name with the suffix of today's date
echo -e "${lightgreen}Additional variables set${reset}"

gcloud config set project $GCP_PROJECT
echo -e "${lightgreen}GCP project has been set via gcloud config${reset}"


# create service account
gcloud iam service-accounts create cloud-run-service-1 \
  --display-name "Cloud Run Service 1" \
  --description "Service account for Cloud Run service" \
  && gcloud projects add-iam-policy-binding $GCP_PROJECT \
  --member "serviceAccount:cloud-run-service-1@$GCP_PROJECT.iam.gserviceaccount.com" \
  --role "roles/aiplatform.user"
  echo -e "${lightgreen}Service account has been created (or already exists - ignore this error)${reset}"

export SERVICE_ACCOUNT_ID='cloud-run-service-1@'$GCP_PROJECT'.iam.gserviceaccount.com' # --> enter your service account for the container app here

echo -e "${lightgreen}Now granting the SA all required permissions (The 'Vertex AI User' role to start, add more if needed)${reset}"
# Granting all required permissions
gcloud projects add-iam-policy-binding $GCP_PROJECT \
  --member="serviceAccount:$SERVICE_ACCOUNT_ID" \
  --role="roles/aiplatform.user"


# below permission needed to be added to the default Compute service account - tbd how to approach this when this is disabled


gcloud projects add-iam-policy-binding $GCP_PROJECT \
  --member="serviceAccount:896130592170-compute@developer.gserviceaccount.com" \
  --role="roles/logging.logWriter"

echo -e "${lightgreen}Granted the compute SA the logWriter role${reset}"


  gcloud projects add-iam-policy-binding $GCP_PROJECT \
  --member="serviceAccount:896130592170-compute@developer.gserviceaccount.com" \
  --role="roles/storage.objectViewer" 

echo -e "${lightgreen}Granted the compute SA the objectViewer role${reset}"

cd target-app
echo -e "${lightgreen}Switched to /target-app dir${reset}"


# To create a Artifact Registry repository

#gcloud artifacts repositories create "$AR_REPO" --location="$GCP_REGION" --repository-format=Docker

echo -e "${lightblue}Checking if AR repo exists. If not, creating new ...${reset}"

if ! gcloud artifacts repositories describe "$AR_REPO" --location="$GCP_REGION" > /dev/null 2>&1; then
  gcloud artifacts repositories create "$AR_REPO" --location="$GCP_REGION" --repository-format=docker
fi
echo -e "${lightgreen}AR repo created or already exists${reset}"


# To set up authentication to Docker repositories in the region us-west1, run the following command:
gcloud auth configure-docker "$GCP_REGION-docker.pkg.dev"

echo -e "${lightgreen}Set up authentication to Docker repos${reset}"

gcloud artifacts repositories add-iam-policy-binding $AR_REPO \
  --location=$GCP_REGION \
  --member="serviceAccount:896130592170-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
echo -e "${lightgreen}Added AR writer role to SA${reset}"


# To build the Docker image of your application and push it to Google Artifact Registry
gcloud builds submit --tag "$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$AR_REPO/$SERVICE_NAME"
echo -e "${lightgreen}image build of application done and pushed to AR repo${reset}"


# Note: cloudbuild.googleapis.com API enabling is required, and one I had a service account permission error, but that got resolved


  echo -e "${lightblue}Now deploying to Cloud run ... ${reset}"

# Now deploy to Cloud Run
gcloud run deploy "$SERVICE_NAME" \
  --region=$GCP_REGION \
  --port=8080 \
  --image="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT/$AR_REPO/$SERVICE_NAME" \
  --no-allow-unauthenticated \
  --platform=managed \
  --project=$GCP_PROJECT \
  --set-env-vars=GCP_PROJECT=$GCP_PROJECT,GCP_REGION=$GCP_REGION,GCP_BUCKET=$GCP_BUCKET \
  --service-account=$SERVICE_ACCOUNT_ID

  echo -e "${lightgreen}Successfully deployed to Cloud Run. Go check it out ...${reset}"
