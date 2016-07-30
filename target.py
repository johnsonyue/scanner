import os
import urllib
import math
import random

class TargetPool():
	def __init__(self):
		self.rir_url_list = [
			"http://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-latest",
			"http://ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest",
			"http://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest",
			"http://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest",
			"http://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest"
		];
		self.snapshot = "";

		self.cwd = "target/";
		if (not os.path.exists(self.cwd)):
			os.makedirs(self.cwd);

		self.cnt = 0;
		self.target_asn_list = [];
		self.asn_dict = {};

		self.target_pfx_list = [];
		self.pfx_dict = {};
		
	#get target asn list.
	def get_target_asn_list_by_cc(self, cc):
		self.target_asn_list = [];
		self.asn_dict = {};
		for url in self.rir_url_list:
			file = url.split('/')[-1];
			file = file.split('-')[1];
			if not os.path.exists(self.cwd+"/"+file):
				print "started downloading "+url;
				urllib.urlretrieve(url, self.cwd+"/"+file);
				print "downloaded";
			
			f = open(self.cwd+"/"+file);
			self.cnt = 0;
			for line in f.readlines():
				self.parse_asn_line(line, cc);
			f.close();
		
		for asn in self.target_asn_list:
			self.asn_dict[str(asn)]="";
			
	def export_target_asn_list(output_file_name):
		fp = open(self.cwd+"/"+out_file_name, 'wb');
		for asn in self.target_asn_list:
			fp.write(str(asn)+'\n');
		fp.close();
	
	def parse_asn_line(self, line, target_cc):
		if (line[0] == '#'):
			return;
		if (self.cnt < 4):
			self.cnt = self.cnt + 1;
			return;
		
		list = line.split('|');
		type = list[2];
		if (type == "asn"):
			cc = list[1];
			if (cc == ""):
				return;
			if (target_cc == cc):
				asn = int(list[3]);
				value = int(list[4]);
				for i in range(value):
					key = asn+i;
					self.target_asn_list.append(key);
	
		
	#get target pfx list from asn list and bgp dump.
	def get_target_pfx_list_by_cc(self, cc):
		self.get_target_asn_list_by_cc(cc);

		while True:
			try:
				line=raw_input();
			except:
				break;
			list = line.split('|');
			pfx = list[5];
			org = list[6].split(' ')[-1];
			if (self.asn_dict.has_key(org)):
				if (not self.pfx_dict.has_key(pfx)):
					self.target_pfx_list.append(pfx);
					self.pfx_dict[pfx] = "";
	
	#assume that mask is in range(8,32).
	def get_class_c_ip_from_pfx(self, pfx):
		ip = pfx.split('/')[0].split('.');
		base_ip = [];
		for i in ip:
			base_ip.append(int(i));
		mask = int(pfx.split('/')[1]);
		res = [];
		
		len = int( math.pow(2,max(0,(24-mask))) );
		for i in range(len):
			new_ip = base_ip[:];
			new_ip[2] = (new_ip[2] + i) % 256;
			new_ip[1] = new_ip[1] + ((new_ip[2] + i) / 256);
			new_ip[3] = new_ip[3] + random.randint( (1 if mask<=24 else 0), int(math.pow(2,8-max(mask-24,0)))-(2 if mask<=24 else 1) );
			ip_str = str(new_ip[0])+"."+str(new_ip[1])+"."+str(new_ip[2])+"."+str(new_ip[3]);
			res.append(ip_str);
		
		return res;
		
	
	def get_target_ip_list_from_pfx(self, cc, file_name):
		self.get_target_pfx_list_by_cc(cc);
		fp = open(self.cwd+"/"+file_name, 'wb');
		
		for pfx in self.target_pfx_list:
			for ip in self.get_class_c_ip_from_pfx(pfx):
				fp.write(ip+'\n');
		
		fp.close();

pool = TargetPool();
#print pool.get_class_c_ip_from_pfx("1.2.0.0/15");
#pool.get_target_pfx_list_by_cc("CN","pfx_list_cn");
pool.get_target_ip_list_from_pfx("CN","ip_list_cn");
