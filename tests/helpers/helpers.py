#    Copyright 2013 - 2014 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import BaseHTTPServer
import httplib
import logging
import os
import posixpath
import random
from SimpleHTTPServer import SimpleHTTPRequestHandler
import socket
import stat
from threading import Thread
import time
import urllib
import xmlrpclib

import paramiko



def icmp_ping(host, timeout=1):
    """Run ICMP ping

    returns True if host is pingable
    False - otherwise.
    """
    return os.system(
        "ping -c 1 -W '%(timeout)d' '%(host)s' 1>/dev/null 2>&1" % {
            'host': str(host), 'timeout': timeout}) == 0


def _tcp_ping(host, port):
    s = socket.socket()
    s.connect((str(host), int(port)))
    s.close()


def tcp_ping(host, port):
    """Run TCP ping

    returns True if TCP connection to specified host and port
    can be established
    False - otherwise.
    """
    try:
        _tcp_ping(host, port)
    except socket.error:
        return False
    return True


def wait(predicate, interval=5, timeout=60):
    """wait until predicate will become True.

    returns number of seconds that is left or 0 if timeout is None.

    Options:

    interval - seconds between checks.

    timeout  - raise TimeoutError if predicate won't become True after
    this amount of seconds. 'None' disables timeout.

    """
    start_time = time.time()
    if not timeout:
        return predicate()
    while not predicate():
        if start_time + timeout < time.time():
            raise TimeoutError("Waiting timed out")

        seconds_to_sleep = max(
            0,
            min(interval, start_time + timeout - time.time()))
        time.sleep(seconds_to_sleep)

    return timeout + start_time - time.time()


def _wait(raising_predicate, expected=Exception, interval=5, timeout=None):
    start_time = time.time()
    while True:
        try:
            return raising_predicate()
        except expected:
            if timeout and start_time + timeout < time.time():
                raise
            time.sleep(interval)


