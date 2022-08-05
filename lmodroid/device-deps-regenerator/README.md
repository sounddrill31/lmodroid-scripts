1. Use Python 3.2 or higher
2. Run `pip3 install -r requirements.txt`
3. Grab a new token from [here](https://git.libremobileos.com/-/profile/personal_access_tokens) - no scopes needed, just a name. Put it in `token`
4. run `python3 app.py` to generate the full lineage.dependencies mapping
6. run `python3 devices.py` to generate device -> dependency mapping (device_deps.json)
