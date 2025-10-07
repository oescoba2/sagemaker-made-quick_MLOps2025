#!/usr/bin/env python3
# ============================================================
#  SageMaker Environment Cleanup Script (CI/CD Version)
#
#  - Deletes SageMaker Projects, Endpoints, Feature Groups,
#    MLflow Tracking Servers, CloudFormation Stacks, and
#    project-specific S3 buckets.
#  - Runs non-interactively (auto-approve) in CI/CD pipelines.
#  - Waits for resources to fully delete before exiting.
#  - Assumes AWS credentials are already configured (for example
#    via GitHub Actions: aws-actions/configure-aws-credentials).
# ============================================================

import boto3
import botocore
import time
import os
import sys

sys.stdout.reconfigure(line_buffering=True)


# ============================================================
# Configuration
# ============================================================
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
NON_INTERACTIVE = True  # always true for CI/CD
DELETE_WAIT = 5   # seconds between checks
MAX_WAIT_SECS = 60  # maximum per resource
MAX_ATTEMPTS = MAX_WAIT_SECS // DELETE_WAIT

print("============================================================")
print(f"Starting SageMaker cleanup in region: {AWS_REGION}")
print("Non-interactive mode: True (auto-approve all deletions)")
print("============================================================")

# Create clients
print("Creating AWS service clients...")
session = boto3.Session(region_name=AWS_REGION)
sm = session.client("sagemaker")
cfn = session.client("cloudformation")
s3 = session.resource("s3")

# Helper: wait for resource deletion
def wait_for_delete(check_func, name, resource_type):
    """Wait up to ~1 minute for a resource to delete."""
    for attempt in range(MAX_ATTEMPTS):
        try:
            check_func()
            print(f"[{resource_type}] Waiting for '{name}' to delete... ({attempt+1}/{MAX_ATTEMPTS})", flush=True)
            time.sleep(DELETE_WAIT)
        except botocore.exceptions.ClientError as e:
            code = e.response["Error"]["Code"]
            if code in ["ValidationException", "ResourceNotFound"]:
                print(f"[{resource_type}] '{name}' deleted.", flush=True)
                return
            else:
                raise
    print(f"[{resource_type}] Timeout reached (1 minute). Continuing...", flush=True)


# ============================================================
# Detect Domain ID automatically
# ============================================================
print("Detecting SageMaker Domain ID...")
try:
    domains = sm.list_domains()["Domains"]
    domain_id = domains[0]["DomainId"] if domains else None
    print(f"Detected SageMaker Domain ID: {domain_id or 'None found'}")
except Exception as e:
    print(f"Unable to detect domain ID: {e}")
    domain_id = None

# ============================================================
# Delete Projects
# ============================================================
print("\n===== Deleting SageMaker Projects =====")
try:
    print("Listing SageMaker projects...")
    projects = sm.list_projects(MaxResults=100, SortBy="CreationTime")["ProjectSummaryList"]
    print(f"Found {len(projects)} project(s) to delete.")
except Exception as e:
    print(f"Error listing projects: {e}")
    projects = []

for p in projects:
    name = p["ProjectName"]
    print(f"Deleting project: {name}")
    try:
        sm.delete_project(ProjectName=name)
        print(f"Delete request sent for project: {name}")
        wait_for_delete(lambda: sm.describe_project(ProjectName=name), name, "Project")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFound":
            print(f"Project {name} already deleted.")
        else:
            print(f"Error deleting project {name}: {e}")

# ============================================================
# Delete Feature Groups
# ============================================================
print("\n===== Deleting Feature Groups =====")
try:
    print("Listing SageMaker feature groups...")
    fgs = sm.list_feature_groups(FeatureGroupStatusEquals="Created")["FeatureGroupSummaries"]
    print(f"Found {len(fgs)} feature group(s) to delete.")
except Exception as e:
    print(f"Error listing feature groups: {e}")
    fgs = []

for fg in fgs:
    name = fg["FeatureGroupName"]
    print(f"Deleting feature group: {name}")
    try:
        sm.delete_feature_group(FeatureGroupName=name)
        print(f"Delete request sent for feature group: {name}")
        wait_for_delete(lambda: sm.describe_feature_group(FeatureGroupName=name), name, "Feature Group")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFound":
            print(f"Feature group {name} already deleted.")
        else:
            print(f"Error deleting feature group {name}: {e}")

# ============================================================
# Delete Endpoints
# ============================================================
print("\n===== Deleting Endpoints =====")
try:
    print("Listing SageMaker endpoints...")
    endpoints = sm.list_endpoints()["Endpoints"]
    print(f"Found {len(endpoints)} endpoint(s) to delete.")
except Exception as e:
    print(f"Error listing endpoints: {e}")
    endpoints = []

for ep in endpoints:
    name = ep["EndpointName"]
    print(f"Deleting endpoint: {name}")
    try:
        sm.delete_endpoint(EndpointName=name)
        print(f"Delete request sent for endpoint: {name}")
        wait_for_delete(lambda: sm.describe_endpoint(EndpointName=name), name, "Endpoint")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "ValidationException":
            print(f"Endpoint {name} already deleted or invalid.")
        else:
            print(f"Error deleting endpoint {name}: {e}")

# ============================================================
# Delete MLflow Tracking Servers
# ============================================================
print("\n===== Deleting MLflow Tracking Servers =====")
try:
    print("Listing MLflow tracking servers (all statuses)...")
    tracking_servers = []
    statuses = ["Starting", "RollbackFailed", "Started", "RolledBack", "MaintenanceInProgress", "UpdateFailed", "Updating", "Upgraded", "DeleteFailed", "Deleting", "Created", "RollingBack", "MaintenanceComplete", "Stopped", "MaintenanceFailed", "Stopping", "UpgradeFailed", "Upgrading", "CreateFailed", "Creating", "Updated", "StartFailed", "StopFailed"]

    for status in statuses:
        try:
            resp = sm.list_mlflow_tracking_servers(TrackingServerStatus=status)
            found = resp.get("TrackingServerSummaries", [])
            tracking_servers.extend(found)
            if found:
                print(f"Found {len(found)} tracking server(s) in status '{status}'.")
        except botocore.exceptions.ClientError as e:
            print(f"Error listing MLflow tracking servers with status {status}: {e}")

    print(f"Total tracking servers to delete: {len(tracking_servers)}")

except Exception as e:
    print(f"Error listing MLflow tracking servers: {e}")
    tracking_servers = []

for ts in tracking_servers:
    name = ts["TrackingServerName"]
    print(f"Deleting MLflow tracking server: {name}")
    try:
        sm.delete_mlflow_tracking_server(TrackingServerName=name)
        print(f"Delete request sent for MLflow tracking server: {name}")
        wait_for_delete(lambda: sm.describe_mlflow_tracking_server(TrackingServerName=name), name, "MLflow Server")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFound":
            print(f"MLflow tracking server {name} already deleted.")
        else:
            print(f"Error deleting MLflow server {name}: {e}")

# ============================================================
# Delete CloudFormation Stacks (deploy stacks)
# ============================================================
print("\n===== Deleting CloudFormation Stacks =====")
try:
    print("Listing CloudFormation stacks...")
    stacks = cfn.list_stacks(StackStatusFilter=["CREATE_COMPLETE", "UPDATE_COMPLETE"])["StackSummaries"]
    print(f"Found {len(stacks)} stack(s) to check for deletion.")
except Exception as e:
    print(f"Error listing stacks: {e}")
    stacks = []

for s in stacks:
    name = s["StackName"]
    if name.startswith("sagemaker-"):
        print(f"Deleting CloudFormation stack: {name}")
        try:
            waiter = cfn.get_waiter("stack_delete_complete")
            print(f"Waiting up to 1 minute for stack {name} deletion...", flush=True)
            waiter.wait(StackName=name, WaiterConfig={"Delay": 5, "MaxAttempts": 12})  # ≈60s total
            print(f"Stack {name} deleted.", flush=True)
        except botocore.exceptions.WaiterError:
            print(f"[CloudFormation] Timeout waiting for stack {name} deletion. Skipping.", flush=True)
        except botocore.exceptions.ClientError as e:
            print(f"[CloudFormation] Error deleting stack {name}: {e}", flush=True)
 
# ============================================================
# Delete Project-Provisioned Buckets
# ============================================================
print("\n===== Deleting Project S3 Buckets =====")
print("Listing S3 buckets...")
for b in s3.buckets.all():
    if b.name.startswith("sagemaker-") or b.name.startswith("sagemaker-mlflow-"):
        print(f"Deleting S3 bucket: {b.name}")
        try:
            print(f"Deleting all objects in bucket: {b.name}")
            b.objects.all().delete()
            b.delete()
            print(f"Bucket {b.name} deleted.")
        except Exception as e:
            print(f"Error deleting bucket {b.name}: {e}")

# ============================================================
# Done
# ============================================================
print("\n===== Cleanup Complete =====")
print("All SageMaker resources have been deleted or scheduled for deletion.")
print("You may now safely run: terraform destroy")
