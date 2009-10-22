require 'dbus'
service = DBus::SystemBus.instance.service("edu.wesleyan.WesControl")
p = service.object("/edu/wesleyan/WesControl/projector")
p.introspect
p.default_iface = "edu.wesleyan.WesControl.projector"
v = service.object("/edu/wesleyan/WesControl/projector")
v.introspect
v.default_iface = "edu.wesleyan.WesControl.volume"
e = service.object("/edu/wesleyan/WesControl/extron")
e.introspect
e.default_iface = "edu.wesleyan.WesControl.videoSwitcher"
i = service.object("/edu/wesleyan/WesControl/dvd_vcr_remote")
i.introspect
i.default_iface = "edu.wesleyan.WesControl.irEmitter"
