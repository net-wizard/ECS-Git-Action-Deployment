# ECS-Git-Action-Deployment

This repository contains a simple HTML web application and a CI/CD pipeline configured with GitHub Actions for automated deployment to AWS ECS (Elastic Container Service). This pipeline includes deployment, integration tests, and rollback functionality.

## Table of Contents

- [Overview](#overview)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Integration Tests](#integration-tests)
- [Rollback Instructions](#rollback-instructions)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project sets up a continuous integration and deployment pipeline using GitHub Actions. It automates the following tasks:
1. Building a Docker image for the static HTML site.
2. Pushing the Docker image to AWS ECR.
3. Deploying the Docker image to AWS ECS.
4. Running integration tests to ensure the application is functioning correctly.
5. Rolling back the deployment if tests fail.

## Setup Instructions

To set up the CI/CD pipeline, follow these steps:

1. **Create an AWS Account:** If you don’t have one, sign up for an AWS account at [aws.amazon.com](https://aws.amazon.com/).

2. **Create an ECR Repository:**
   - Go to the Amazon ECR console and create a new repository named `my-repo`.

3. **Create an ECS Cluster:**
   - Go to the Amazon ECS console and create a new cluster.

4. **Create an ECS Service:**
   - In the ECS console, create a service that uses the `FARGATE` launch type and specify the task definition.

5. **Configure AWS Credentials in GitHub:**
   - Go to your GitHub repository settings.
   - Under **Secrets and variables** > **Actions**, add the following secrets:
     - `AWS_REGION`: Your AWS region (e.g., `us-east-1`).
     - `AWS_ACCOUNT_ID`: Your AWS account ID.
     - `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
     - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.

6. **Create a Dockerfile:**
   - Ensure you have a `Dockerfile` in the root of your repository that builds an image for your static HTML site.

7. **Create GitHub Actions Workflow:**
   - Add a `.github/workflows/main.yml` file to your repository with the following content:

     ```yaml
     name: CI/CD Pipeline

     on:
       push:
         branches:
           - master

     jobs:
       build:
         runs-on: ubuntu-latest

         steps:
         - name: Checkout code
           uses: actions/checkout@v3

         - name: Set up Docker Buildx
           uses: docker/setup-buildx-action@v2

         - name: Cache Docker layers
           uses: actions/cache@v3
           with:
             path: /tmp/.buildx-cache
             key: ${{ runner.os }}-docker-${{ github.sha }}
             restore-keys: |
               ${{ runner.os }}-docker-

         - name: Build Docker image
           run: |
             docker build -t my-web-app:latest .

         - name: Log in to Amazon ECR
           uses: aws-actions/amazon-ecr-login@v1
           with:
             region: ${{ secrets.AWS_REGION }}

         - name: Push Docker image to Amazon ECR
           run: |
             docker tag my-web-app:latest ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/my-repo:latest
             docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/my-repo:latest

         - name: Deploy to ECS
           run: |
             aws ecs update-service --cluster <your-cluster-name> --service <your-service-name> --force-new-deployment

         - name: Run Integration Tests
           run: |
             curl -s -o /dev/null -w "%{http_code}" http://<public ip> | grep -q "200"

         - name: Rollback Deployment
           if: failure()
           run: |
             echo "Rolling back deployment due to test failures..."
             aws ecs update-service --cluster <your-cluster-name> --service <your-service-name> --force-new-deployment
     ```

## Usage

1. **Deploy the Application:**
   - Push changes to the `master` branch of your repository. The GitHub Actions workflow will automatically build, deploy, and test the application.

2. **Monitor Deployment:**
   - Check the GitHub Actions tab for the status of your CI/CD pipeline.

3. **Access the Application:**
   - Visit the public IP `http://<public ip>` to see your deployed application.

## Integration Tests

The pipeline includes a step to perform integration tests using `curl` to ensure that the application is accessible and responding with HTTP status code `200`. If the test fails, the pipeline will automatically roll back the deployment.

## Rollback Instructions

If integration tests fail, the pipeline will attempt to roll back to the previous stable version of your application. You can manually roll back to a previous version by using the ECS console or CLI if needed.