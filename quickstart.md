#Quickstart
cmdr is a low-cost solution to control devices typically found in
multimedia classrooms. The main project can be found [here](https://github.com/wesleyan/cmdr).

cmdr consists primarily of three parts.
1. [cmdr-daemon](https://github.com/wesleyan/cmdr): This is the main 
    program that controls the devices.
2. [cmdr-devices](https://github.com/wesleyan/cmdr-devices): The drivers
    that handle communication between the devices and cmdr.
3. [cmdr-server](https://github.com/wesleyan/cmdr-server): Though not a
    critical component of cmdr, cmdr-server offers a one-stop solution
    for users to configure and monitor multiple cmdr instances.

This document will focus on the various aspects of cmdr-daemon. For
more info about the other parts, see the documentation on their
respective project pages.

##cmdr-daemon
###The Deployment Process
cmdr itself is just a bit of software responsible for handling messages between devices.
Nonetheless, a fair amount of setup is required before things can get working.
Our current model consists of:
* Asus EeeBox PC EB1030
* Mimo Touch 2 Display USB Touchscreen
* Ubuntu Server

We use a custom build of Ubuntu Server LTS that does most of the preconfiguration
for us. Information on how to create the image can be found
[here](https://github.com/wesleyan/cmdr/wiki/Preparing-the-cmdr-OS).
The isolinux.cfg file is responsible for booting into the installer
without the need of any user input whereas the preseed file is
responsible for setting up a default user and environment
as well as running our postinstall.sh script which configures chef.
Instructions on how to deploy the cmdr software can be found
[here](https://github.com/wesleyan/cmdr/wiki/Deploying-a-new-cmdr-controller).

####Dependencies
Dependencies have to be manually installed.
* CouchDB >= 1.2
* [RVM](https://rvm.io/)
* Ruby 1.9.3 (Install with RVM)
* RabbitMQ-Server
* Avahi-Daemon (optional dependency for cmdr-server integration)

Our deployments display chrome in fullscreen loaded with the interface.
This requires installing X11 as well as a window manager (we use Awesome).

###How cmdr Works.
cmdr is a decently sized project with a Ruby backend and
JavaScript frontend communicating with websockets. 
The basic flow of command is as follows:
1. A user interacts with the touchscreen. This initiates a request
   which is sent to the backend over a websocket.
2. The backend receives the message. The message is interpreted
   and the appropriate action is carried out. Since the user
   initiated the request, this will typically be a request to
   change the state of the room.
3. The backend determines which device needs to be changed based
   on the message contents and sends the request to the appropriate
   device.
4. The device executes the request and returns its state.
5. The backend updates the database to accurately reflect the current
   state of the room. A message is sent to the frontend notifying
   that the state of the room has changed.
6. The frontend interprets the respone and updates the display
   to accurately reflect the current state of the room.
