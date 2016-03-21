## Vagrant VM for building sabayon repositories regularly.

Do your changes (if any), and then just use

```
vagrant up
vagrant ssh
# inside the machine, as root
cd /vagrant; git clone https://github.com/Sabayon/community.git repositories

```

inside the git repository, it is automatized by crons that runs weekly and nightly (As for now).

Repositories specifications are inside *repositories/*. Global repository output will be in the current working directory inside *artifacts/* and logs inside *logs/*.
