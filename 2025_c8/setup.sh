#!/bin/bash

# Create a virtual environment named 'venv'
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install the dependencies from requirements.txt
pip install -r requirements.txt

echo "Setup complete. To use the environment, run 'source venv/bin/activate'"
echo "To exit environment run 'deactivate' in terminal"