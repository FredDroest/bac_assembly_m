#!/usr/local/bin/python3

import argparse
import os
import sys
import subprocess
from mantlebio import client as mantle


def login_to_mantle(run_id: str, env=None, tenant=None):
    """
    Authenticates with mantle and loads the pipeline.
    """
    client = mantle.MantleClient()
    return client.load_pipeline(run_id)


def pull_entities(run, stage_dir):
    # Get their data from S3 into the current directory.
    run.pull_s3_input("fastq", stage_dir + "to_assemble.fastq.gz")


def stage_input_entities(pipeline_id: str, stage_dir: str, env=None, tenant=None):
    """
    Function to download/stage entities for the given pipeline_id into output_dir.
    You need to implement the logic here based on your specific requirements.
    """
    run = login_to_mantle(pipeline_id, env, tenant)
    pull_entities(run, stage_dir)


def upload_outputs(pipeline_id, directory):
    """
    Upload all output files in the given directory to the given pipeline_id.
    """
    run = login_to_mantle(pipeline_id)
    for root, _, files in os.walk(directory):
        for filename in files:
            file_path = os.path.join(root, filename)
            if os.path.isfile(file_path):
                run.add_file_output(filename, file_path)


def main():
    parser = argparse.ArgumentParser(
        description="Download files for a given pipeline_id into a specified directory.")
    # parser.add_argument("pipeline_id", type=str, help="The ID of the pipeline")
    parser.add_argument('run_id', type=str, help='The run id of the pipeline')
    parser.add_argument("stage_dir", type=str, default=".",
                        help="The directory where files should be downloaded")
    parser.add_argument(
        '--mantle_env', help='Mantle environment', default=None, required=False)
    parser.add_argument('--tenant', help='Mantle tenant', default=None, required=False)
    # Add any additional arguments here
    args = parser.parse_args()

    pipeline = login_to_mantle(args.run_id)

    # Call the download function
    stage_input_entities(args.run_id, args.stage_dir,
                         args.mantle_env, args.tenant)

    # Add your code here


if __name__ == '__main__':
    main()
