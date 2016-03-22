## Vagrant VM for building sabayon repositories regularly.

Do your changes (if any), and then just use

```
vagrant up
# follow up the message on screen after provisioning procedure

```

inside the git repository, it is automatized by crons that runs weekly and nightly (As for now).

Repositories specifications are inside *repositories/*. Global repository output will be in the current working directory inside *artifacts/* and logs inside *logs/*.

**NOTE** Crons will clean up the /vagrant/repositories directory. You can override the fetch url by setting the COMMUNITY_REPOSITORY_SPECS environment variable, otherwise default is https://github.com/Sabayon/community-repositories.git
