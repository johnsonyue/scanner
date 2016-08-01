import urllib
import os
import signal
import HTMLParser
import sys

class RouteviewsParser(HTMLParser.HTMLParser):
	def __init__(self):
		HTMLParser.HTMLParser.__init__(self);
		self.img_cnt=0;
		self.alt="";
		self.file=[];
		self.dir=[];

	def get_attr_value(self, target, attrs):
		for e in attrs:
			key = e[0];
			value = e[1];
			if (key == target):
				return value;

	def handle_starttag(self, tag, attrs):
		if (tag == "img"):
			if (self.img_cnt >=2):
				alt_value = self.get_attr_value("alt", attrs);
				self.alt=alt_value;
			self.img_cnt = self.img_cnt + 1;
		
		if (tag == "a" and self.alt == "[DIR]"):
			href_value = self.get_attr_value("href", attrs);
			self.dir.append(href_value);
		elif (tag == "a" and self.alt != ""):
			href_value = self.get_attr_value("href", attrs);
			self.file.append(href_value);

class Routeviews:
	def __init__(self,cwd):
		self.snapshot = "";
		self.cwd = cwd;
	
	def sig_handler(self, sig, frame):
		if (self.snapshot != ""):
			file_path = self.cwd+"/"+self.snapshot;
			if (os.path.exists(file_path)):
				os.remove(file_path);
        	exit();

	#get latest bgp snapshot.
	def get_latest_snapshot(self):
        	signal.signal(signal.SIGINT, self.sig_handler);
		seed_url = "http://routeviews.org/bgpdata/";
		
		f = urllib.urlopen(seed_url);
		text = f.read();
		parser = RouteviewsParser();
		parser.feed(text);
		
		target_url = "";
		for i in range(len(parser.dir)-1, -1, -1):
			url = seed_url+parser.dir[i]+"RIBS/";
			target_url = self.parse_date_dir(url);
			if (target_url != ""):
				target_url = url+target_url;
				break;
		
		file_name = target_url.split('/')[-1];
		self.snapshot = file_name;
		if not os.path.exists(self.cwd+"/"+file_name):
			#print target_url;
			urllib.urlretrieve(target_url, self.cwd+"/"+file_name);
		
		file_path = self.cwd+"/"+self.snapshot;
		return file_path;

	def parse_date_dir(self, url):
		f = urllib.urlopen(url);
		text = f.read();
		parser = RouteviewsParser();
		parser.feed(text);
		
		if(len(parser.file) != 0):
			return parser.file[-1];
		return "";

def usage():
	print "python routeviews.py cwd";
	print "e.g. python routeviews target/";

def main(argv):
	if (len(argv) < 1):
		usage();
		exit();
	cwd = argv[1];
	routeviews = Routeviews(cwd);
	print routeviews.get_latest_snapshot(),;

if __name__ == "__main__":
	main(sys.argv);
