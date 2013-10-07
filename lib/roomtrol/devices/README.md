# Roomtrol-Devices

This repository contains all of the device drivers that have been written so far for roomtrol.

Roomtrol is split into three parts: the server code, [roomtrol-daemon](https://github.com/mwylde/roomtrol-daemon) which contains the code for the daemon that runs on each controller, [roomtrol-server](https://github.com/mwylde/roomtrol-server) which holds both the backend and frontend code run on the central server as well as the touchscreen interface, and the device drivers.

##Development notes
###Code style
All code should match the following style: tabs for indentation and spaces for aligning and line lengths should be minized but there is no hard cut-off. For Ruby code, class names ShouldBeCamelCased, variable and method names should\_be\_underscored, every method and class should be documented using [Yardoc](yardoc.com) tags and [markdown](http://daringfireball.net/projects/markdown/) formatting and [RSpec](rpsec.org) tests should be written for all functionality.

For Javascript, the same formatting rules should apply, but variable and method names shouldBeCamelCased as well as class names. Methods and classes should be documented using [JSDoc](http://code.google.com/p/jsdoc-toolkit/). Also, all code should be run through [JSLint](http://www.jslint.com/) and any errors it identifies should be corrected (this means no global variables and semi-colons are mandatory).

In general, try to maintain the style already found in the code.