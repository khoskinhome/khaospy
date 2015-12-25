from ginkgo import Service

class HelloWorld(Service):
    def do_start(self):
        self.spawn(self.hello_forever)

    def hello_forever(self):
        while True:
            print "Hello World"
            self.async.sleep(1)
