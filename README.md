# Hackatony: Quickly Deploy Colab Notebooks to Cloud Run

This project helps you rapidly deploy your Google Colab/Jupyter Notebook code as a Cloud Run service.

## Getting Started

**Prerequisites:**

*   A Google Cloud Platform (GCP) project with a user account and (min.) following IAM permissions:
    *   Cloud Build Editor
    *   Logging Admin
    *   Storage Object User
    *   Vertex AI User
    *   Artifact Registry Administrator

*   The Google Cloud SDK (`gcloud`) installed and configured.  Run `gcloud auth login` to authenticate.

**Steps:**

1.  **Clone the repository:**

    ```bash
    git clone <this_repo>  
    ```
    *(Replace `<this_repo>` with this repository URL)*

2.  **Prepare your Notebook:**

    Add your Colab notebook's code to the `notebook_to_app.ipynb` file.

3.  **Generate Cloud Run deployment files:**

    Run the conversion script:

    ```bash
    ./convert.sh
    ```

    This will generate code files. Review the instructions in `convert-instructions.txt` and add any necessary files to the `/target-app` directory.  If you encounter issues, refer to the boilerplate code in `/base-app` for guidance.

4.  **Setup services and deploy to Cloud Run:**


    Open setup.sh and fill out the three variables `PROJECT_NAME`, `GCP_PROJECT` and `GCP_REGION` to map the script to your environment.

    Run the setup script:

    ```bash
    ./setup.sh
    ```

    Review the script if changes are necessary, e.g. adding additional permissions or roles to the service account, e.g. if you are accessing a database from the Cloud Run service


## Accessing your Cloud Run Service

Once deployed, you can access your service via the command line:

```bash
ACCESS_TOKEN=$(gcloud auth print-identity-token)
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $ACCESS_TOKEN" -d '{"prompt": "Your input data"}' https://<cloud_run_url>/path
```

Replace `<cloud_run_url>/path` with the actual URL of your deployed Cloud Run service and adjust the JSON payload as needed.  **Do not** use the unauthenticated option; it's not recommended for security reasons.