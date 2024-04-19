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
    parser.add_argument("pipeline_id", type=str, help="The ID of the pipeline")
    parser.add_argument("results_dir", type=str,
                        help="The directory of results")
    parser.add_argument(
        '--mantle_env', help='Mantle environment', default=None, required=False)
    parser.add_argument('--tenant', help='Mantle tenant', default=None, required=False)

    args = parser.parse_args()

    upload_outputs(args.pipeline_id, args.results_dir)

    # Add your code here


if __name__ == '__main__':
    main()
