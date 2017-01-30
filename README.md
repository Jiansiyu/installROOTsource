# installROOTsource
Turnkey script to install ROOT from the current source pulled down from git

# Use
Letting your Unix shell (whatever is printed from `echo $SHELL | sed 's:.*/::'`) be called `shell`
## To install:
~~~bash
shell installROOTsource.sh
~~~
or
~~~bash
shell installROOTsource.sh install
~~~
## To update:
~~~bash
shell installROOTsource.sh rebuild
~~~
## To uninstall:
~~~bash
shell installROOTsource.sh uninstall
~~~
