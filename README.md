# Docker Plugin for Rex JobControl


This is a docker plugin for Rex JobControl to provision docker images.


## INSTALLATION

Currently this plugin is in early development status. So you have to clone the git repository.

```
git clone https://github.com/RexOps/rex-jobcontrol-plugin-docker.git
```

Then you can load the plugin from the jobcontrol configuration file.

```
{
  plugins => [
    'Rex::JobControl::Provision::Docker',
  ],
}
```

Before the restart of Rex JobControl you have to update the PERL5LIB env variable to point to the plugin repository:

```
export PERL5LIB=/path/to/rex-jobcontrol-plugin-docker/lib:$PERL5LIB
```
