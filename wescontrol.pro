SOURCES = src/wescontrol.cpp \
    src/projector.cpp \
    src/messagemodel.cpp \
    src/videoswitcher.cpp \
    src/sourcecontroller.cpp \
    src/volume.cpp \
    qml/modules/remote/inpolygondetector.cpp \
    src/iremitter.cpp
QT += script \
    declarative \
    dbus \
    xmlpatterns
target.path = /usr/local/wescontrol
images.files = images
images.path = /usr/local/wescontrol
qml.files = qml
qml.path = /usr/local/wescontrol
posttarget.path = /usr/local/bin
posttarget.extra = ln \
    -sf \
    /usr/local/wescontrol/wescontrol \
    /usr/local/bin/wescontrol
daemon.files = daemon
daemon.path = /usr/local/wescontrol
daemon.extra = chmod \
    +x \
    daemon/wescontrol-daemon
daemoninit.path = /etc/init.d
daemoninit.extra = cp \
    daemon/wescontrol-daemon-init \
    /etc/init.d/wescontrol-daemon \
    && \
    chmod \
    +x \
    /etc/init.d/wescontrol-daemon \
    && \
    update-rc.d \
    wescontrol-daemon \
    defaults
defaults.files = daemon/wescontrol-daemon-default
defaults.path = /etc/default/wescontrol-daemon
fonts.files = MyriadPro/
fonts.path = /usr/share/fonts
INSTALLS += target \
    images \
    qml \
    posttarget \
    daemon \
    daemoninit \
    defaults \
    fonts
HEADERS += src/wescontrol.h \
    src/projector.h \
    src/messagemodel.h \
    src/videoswitcher.h \
    src/sourcecontroller.h \
    src/volume.h \
    qml/modules/remote/inpolygondetector.h \
    src/iremitter.h
OTHER_FILES += qml/LoginScreen.qml \
    qml/TopBar.qml \
    qml/keyboard.qml \
    qml/LoginForm.qml \
    qml/BottomBar.qml \
    qml/modules/projector/ProjectorPage.qml \
    qml/wescontrol.qml \
    qml/modules/projector/ProjectorButton.qml \
    qml/modules/sources/SourcesButton.qml \
    qml/PagesView.qml \
    qml/modules/sources/SourcesPage.qml \
    qml/modules/projector/ButtonComponent.qml \
    qml/modules/projector/ProjectorController.qml \
    qml/modules/volume/VolumePage.qml \
    qml/modules/volume/VolumeButton.qml \
    qml/modules/remote/RemotePage.qml \
    qml/modules/remote/RemoteButton.qml \
    qml/modules/remote/PolygonalMouseRegion.qml
builddir = build/
OBJECTS_DIR = $$builddir
MOC_DIR = $$builddir
UI_DIR = $$builddir
RCC_DIR = $$builddir
DEPENDPATH += src/
INCLUDEPATH += src/
