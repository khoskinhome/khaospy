from ginkgo import Service
from ginkgo.async.gevent import StreamServer
from ginkgo.async.gevent import StreamClient
from ginkgo.async.gevent import WSGIServer

class HelloWorldServer(Service):
    def __init__(self):
        self.add_service(StreamServer(('0.0.0.0', 7000), self.handle))

    def handle(self, socket, address):
        while True:
            socket.send("Hello World\n")
            self.async.sleep(1)

class HelloWorldClient(Service):
    def __init__(self):
        self.add_service(StreamClient(('0.0.0.0', 7000), self.handle))

    def handle(self, socket):
        fileobj = socket.makefile()
        while True:
            print fileobj.readline().strip()

class HelloWorldWebServer(Service):
    def __init__(self):
        self.add_service(WSGIServer(('0.0.0.0', 8000), self.handle))

    def handle(self, environ, start_response):
        start_response('200 OK', [('Content-Type', 'text/html')])
        return ["<strong>Hello World</strong>"]

class HelloWorld(Service):
    def __init__(self):
        self.add_service(HelloWorldServer())
        self.add_service(HelloWorldClient())
        self.add_service(HelloWorldWebServer())
