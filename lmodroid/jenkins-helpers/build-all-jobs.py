import os
from jenkins import Jenkins

JENKINS_USERNAME = os.environ.get("JENKINS_USERNAME")
JENKINS_PASSWORD = os.environ.get("JENKINS_PASSWORD")

server = Jenkins('https://jenkins.libremobileos.com', 
                 username=JENKINS_USERNAME, password=JENKINS_PASSWORD)
user = server.get_whoami()
version = server.get_version()
print('%s Connected to Jenkins %s' % (user['fullName'], version))

jobs = server.get_jobs()
for job in jobs:
    if job["name"] == "LMODroid":
        jobs = job["jobs"]
        break

for job in jobs:
    server.build_job("LMODroid/" + job["name"])
