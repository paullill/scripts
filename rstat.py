#!/usr/bin/python
################################################################
# Usage: rstat.py param1 param2 param3					       #
#        example: python rstat.py upload_rate				   #
################################################################
import re
import socket
import urllib
import xmlrpclib
import sys

## WRITE YOUR HOST HERE
HOST = "scgi://localhost:5000/"
 

########## Do not modify  ################# 
class SCGITransport(xmlrpclib.Transport):
    def single_request(self, host, handler, request_body, verbose=0):
        # Add SCGI headers to the request.
        headers = {'CONTENT_LENGTH': str(len(request_body)), 'SCGI': '1'}
        header = '\x00'.join(('%s\x00%s' % item for item in headers.iteritems())) + '\x00'
        header = '%d:%s' % (len(header), header)
        request_body = '%s,%s' % (header, request_body)
        
        sock = None
        
        try:
            if host:
                host, port = urllib.splitport(host)
                addrinfo = socket.getaddrinfo(host, port, socket.AF_INET,
                                              socket.SOCK_STREAM)
                sock = socket.socket(*addrinfo[0][:3])
                sock.connect(addrinfo[0][4])
            else:
                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.connect(handler)
            
            self.verbose = verbose
            
            sock.send(request_body)
            return self.parse_response(sock.makefile())
        finally:
            if sock:
                sock.close()
    
    def parse_response(self, response):
        p, u = self.getparser()
        
        response_body = ''
        while True:
            data = response.read(1024)
            if not data:
                break
            response_body += data
        
        # Remove SCGI headers from the response.
        response_header, response_body = re.split(r'\n\s*?\n', response_body,
                                                  maxsplit=1)
        
        if self.verbose:
            print 'body:', repr(response_body)
        
        p.feed(response_body)
        p.close()
        
        return u.close()
 
 
class SCGIServerProxy(xmlrpclib.ServerProxy):
    def __init__(self, uri, transport=None, encoding=None, verbose=False,
                 allow_none=False, use_datetime=False):
        type, uri = urllib.splittype(uri)
        if type not in ('scgi'):
            raise IOError('unsupported XML-RPC protocol')
        self.__host, self.__handler = urllib.splithost(uri)
        if not self.__handler:
            self.__handler = '/'
        
        if transport is None:
            transport = SCGITransport(use_datetime=use_datetime)
        self.__transport = transport
        
        self.__encoding = encoding
        self.__verbose = verbose
        self.__allow_none = allow_none
 
    def __close(self):
        self.__transport.close()
    
    def __request(self, methodname, params):
        # call a method on the remote server
    
        request = xmlrpclib.dumps(params, methodname, encoding=self.__encoding,
                                  allow_none=self.__allow_none)
    
        response = self.__transport.request(
            self.__host,
            self.__handler,
            request,
            verbose=self.__verbose
            )
    
        if len(response) == 1:
            response = response[0]
    
        return response
    
    def __repr__(self):
        return (
            "<SCGIServerProxy for %s%s>" %
            (self.__host, self.__handler)
            )
    
    __str__ = __repr__
    
    def __getattr__(self, name):
        # magic method dispatcher
        return xmlrpclib._Method(self.__request, name)
 
    # note: to call a remote object with an non-standard name, use
    # result getattr(server, "strange-python-name")(args)
 
    def __call__(self, attr):
        """A workaround to get special attributes on the ServerProxy
           without interfering with the magic __getattr__
        """
        if attr == "close":
            return self.__close
        elif attr == "transport":
            return self.__transport
        raise AttributeError("Attribute %r not found" % (attr,))
############################################################################
############################################################################
############################################################################


class Executus:
        def __init__(self):
		server = SCGIServerProxy(HOST)
		#print server.system.listMethods()
		# Create Method dictionary
		blacklist = "d.","f.","p.","t.","to.","load.","to_","set_","throttle"		


		listMethods = dict()
		for method in server.system.listMethods():
			
			isBlacklist = False
			
			# Check if blacklisted
			for blacklistItem in blacklist:
				if method.startswith(blacklistItem, 0, len(blacklistItem)):
					isBlacklist = True
	
			if isBlacklist:
				continue

			try:
				listMethods[method] = getattr(server,method)
			except:
				print "Error: " + method

		

		# Run arguments
		iterator = iter(sys.argv)
		next(iterator)
		for arg in iterator:
			if arg == "list":
				print "Supported Functions:"
				funcList = iter(sorted(listMethods.keys()))
				for item in funcList:
					print item
				continue

			try:
				print listMethods[arg]()
			except:
				print "Error: " + arg + " | not supported!"
		#	try:
		#		for key, value in listMethods.items():
		#			if key == value:
		#				print "lol"
		#	except:
		#		print "Key: " + arg + " not found!"	
		

run = Executus()

