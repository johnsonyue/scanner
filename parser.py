import sys

class WartsParser():
    def __init__(self, cwd):
        self.cwd = cwd
        self.ip_dict={}

    def parse_trace(self, trace, fp):
        if trace[0] == "#":
            return False

        hops = trace.strip().split('\t')

        for i in range(13,len(hops)):
            hop = hops[i].split(';')[0]
            if hop != "q":
                ip = hop.split(',')[0]
                if not self.ip_dict.has_key(ip):
                    self.ip_dict[ip]=""
                    fp.write(ip+"\n")

        return True

    def parse_warts_to_ip_list(self, outfile_name):
        fp = open(self.cwd+"/"+outfile_name, 'wb')

        while True:
            try:
                line=raw_input()
            except:
                break

            self.parse_trace(line, fp)

        fp.close()


def usage():
    print "python parser.py cwd outfile"
    print "e.g. python parser.py target/ trace_ip_list"

def main(argv):
    if len(argv) < 2:
        usage()
        exit()

    cwd = argv[1]
    outfile = argv[2]

    parser = WartsParser(cwd)
    parser.parse_warts_to_ip_list(outfile)

if __name__ == "__main__":
    main(sys.argv)
