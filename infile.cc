/* 
 * Copyright (C) 2011-2015 The Regents of the University of California.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
 * file reader
 */

#include <errno.h>
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <cstdarg>
#include <exception>
#include <stdexcept>
#include <sys/types.h>
#include <sys/wait.h>

#include "config.h"
#include "infile.h"

bool InFile::fork = true;

InFile::InFile(const char *filename, size_t classsize) :
    isPipe(false), tmp(0), file(0), _linenum(0),
#ifdef HAVE_LIBZ
    gzfile(0),
#endif
    name(filename)
{
    //if (classsize != sizeof(InFile)) // Is caller using same definition as us?
	//throw Mismatch();
    const char *suffix;
    if ((basename = strrchr(name, '/')))
	++basename;
    else
	basename = name;
    suffix = strrchr(basename, '.');

    if (suffix && strcmp(suffix, ".gz") == 0) {
	tmp = strncpy(new char[suffix-basename+1](), basename, suffix - basename);
	tmp[suffix - basename] = '\0';
	basename = tmp;
	if (fork) {
	    char cmd[8192];
	    snprintf(cmd, sizeof(cmd), "exec gzip -dc \"%s\"", name);
	    if (!(file = popen(cmd, "r"))) {
		throw Error(*this, "can't open: %s", strerror(errno));
	    }
	    isPipe = true;
	    pipeName = "gzip";
	} else {
#ifdef HAVE_LIBZ
	    if (!(gzfile = gzopen(name, "rb"))) {
		throw Error(*this, "can't gzopen: %s", strerror(errno));
	    }
# ifdef HAVE_PTHREAD
	    pipes[0] = pipes[1] = -1;
	    pthread = 0;
# endif
#else
	    throw Error(*this, "can't gzopen: %s", "libz support not enabled");
#endif
	}

    } else if (suffix && strcmp(suffix, ".bz2") == 0) {
	tmp = strncpy(new char[suffix-basename+1](), basename, suffix - basename);
	tmp[suffix - basename] = '\0';
	basename = tmp;
	if (true || fork) {
	    char cmd[8192];
	    snprintf(cmd, sizeof(cmd), "exec bzip2 -dc \"%s\"", name);
	    if (!(file = popen(cmd, "r"))) {
		throw Error(*this, "can't open: %s", strerror(errno));
	    }
	    isPipe = true;
	    pipeName = "bzip2";
	}

    } else {
	if (!(file = fopen(name, "r"))) {
	    throw Error(*this, "can't open: %s", strerror(errno));
	}
    }
}

char *InFile::gets(char *buf, unsigned len)
{
    char *result = 0;
    if (file) {
	result = fgets(buf, len, file);
	if (!result && !feof(file))
	    throw Error(*this, "can't read: %s", strerror(errno));
	else
	    _linenum++;
#ifdef HAVE_LIBZ
    } else if (gzfile) {
	result = gzgets(gzfile, buf, len);
	if (!result)
	    check_gzerror();
	else
	    _linenum++;
#endif
    }
    return result;
}

size_t InFile::read(void *buf, size_t size, size_t nmemb)
{
    size_t n_items = 0;
    if (file) {
	n_items = fread(buf, size, nmemb, file);
	if (n_items == 0 && !feof(file))
	    throw Error(*this, "read error: %s", strerror(errno));
#ifdef HAVE_LIBZ
    } else if (gzfile) {
	int bytes = gzread(gzfile, buf, size * nmemb);
	if (bytes < 0)
	    check_gzerror();
	n_items = bytes / size;
#endif
    }
    return n_items;
}

#if defined(HAVE_LIBZ) && defined(HAVE_PTHREAD)
void *InFile::run_gzreader(void *arg)
{
    ssize_t len;
    char buf[4096];
    InFile *infile = static_cast<InFile*>(arg);
    try {
	while (true) {
	    len = gzread(infile->gzfile, buf, sizeof(buf));
	    if (len < 0)
		infile->check_gzerror();
	    if (len == 0)
		break;
	    char *p = buf;
	    while (len > 0) {
		ssize_t written = write(infile->pipes[1], p, len);
		if (written < 0)
		    throw Error(*infile, "write error: %s", strerror(errno));
		p += written;
		len -= written;
	    }
	}
    } catch (const std::runtime_error &e) {
	std::cerr << e.what() << std::endl;
	exit(1);
    }

    ::close(infile->pipes[1]);
    return 0;
}
#endif

int InFile::fd() throw()
{
    if (file) { 
	return fileno(file);
#if defined(HAVE_LIBZ) && defined(HAVE_PTHREAD)
    } else if (gzfile) {
	if (pipe(pipes) < 0) {
	    throw Error(*this, "can't get fd: %s", strerror(errno));
	}
	int r = pthread_create(&pthread, 0, run_gzreader, this);
	if (r) throw std::runtime_error(strerror(r));
	return pipes[0];
#endif
    } else {
	throw Error(*this, "can't get fd");
    }
}

void InFile::close()
{
    if (tmp)
	delete[] tmp;
    tmp = 0;
    if (file) {
	if (ferror(file)) {
	    throw Error(*this, "read error");
	}
	if (isPipe) {
	    int status = pclose(file);
	    file = 0; // BEFORE potential throw
	    if (status == -1) {
		throw Error(*this, "%s error: %s", pipeName, strerror(errno));
	    } else if (WIFEXITED(status)) {
		if (WEXITSTATUS(status) != 0) {
		    throw Error(*this, "%s exited: %d", pipeName, WEXITSTATUS(status));
		}
	    } else if (WIFSIGNALED(status)) {
		throw Error(*this, "%s signaled: %d", pipeName, WTERMSIG(status));
	    } else if (WIFSTOPPED(status)) {
		throw Error(*this, "%s stopped: %d", pipeName, WSTOPSIG(status));
	    }
	} else {
	    fclose(file);
	    file = 0;
	}
#ifdef HAVE_LIBZ
    } else if (gzfile) {
	// check_gzerror();
	gzclose(gzfile);
	gzfile = 0;
# ifdef HAVE_PTHREAD
	if (pipes[0] >= 0) ::close(pipes[0]);
	if (pipes[1] >= 0) ::close(pipes[1]);
	if (pthread) pthread_join(pthread, 0);
# endif
#endif
    }
}

#ifdef HAVE_LIBZ
void InFile::check_gzerror()
{
    int err;
    const char *msg = 0;
    msg = gzerror(gzfile, &err);
    if (err == Z_STREAM_END) {
	// not an error
    } else if (err == Z_ERRNO) {
	throw Error(*this, "%s", strerror(errno));
    } else if (msg) {
	throw Error(*this, "%s", msg);
    }
}
#endif

// can't be inlined because it uses varargs
InFile::Error::Error(const InFile &in, const char *fmt, ...) throw() :
    std::runtime_error("")
{
    size_t n = in.linenum() ?
	sprintf(buf, "%s line %ld: ", in.name, in.linenum()) :
	sprintf(buf, "%s: ", in.name);
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf + n, sizeof(buf) - n, fmt, ap);
    va_end(ap);
}

InFile::Error::Error(const InFile &in, const std::exception &e) throw() :
    std::runtime_error("")
{
    size_t n = in.linenum() ?
	sprintf(buf, "%s line %ld: ", in.name, in.linenum()) :
	sprintf(buf, "%s: ", in.name);
    snprintf(buf + n, sizeof(buf) - n, "%s", e.what());
}

bool InFile::nameEndsWith(const char *ending) const
{
    int slen = strlen(basename);
    int elen = strlen(ending);
    return (elen <= slen && strcmp(basename + slen - elen, ending) == 0);
}
