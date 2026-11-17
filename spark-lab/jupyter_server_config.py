import os

c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.root_dir = "/opt/work"
c.ServerApp.allow_remote_access = True
c.ServerApp.trust_xheaders = True
c.IdentityProvider.token = os.environ["JUPYTER_TOKEN"]
