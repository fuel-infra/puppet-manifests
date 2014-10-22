#!/usr/bin/env python
from novaclient.client import Client
from novaclient import exceptions
from proboscis import test
from proboscis.asserts import assert_true
import paramiko
from helpers.helpers import wait, tcp_ping
import time
import os
import sys

test_config = {
    'nova_config': {
        'version': '2',
        'username': os.getenv('nova_username'),
        'api_key': os.getenv('nova_password'),
        'auth_url': os.getenv('nova_url', 'http://127.0.0.1:5000/v2.0'),
        'project_id': os.getenv('nova_project', 'DevOps'),
    },
    'flavor': os.getenv('nova_flavor', 'm1.small'),
    'network': os.getenv('nova_network', 'test_network'),
    'image': os.getenv('nova_image', 'ubuntu14.04'),
    'keypair': os.getenv('nova_keypair'),
    'count': int(os.getenv('count', '10')),
    'domain': os.getenv('domain', 'test.local'),
    'rsa_private_key': os.getenv('rsa_private_key', '~/.ssh/id_rsa'),
}

slave_hosts = map(lambda x: "slave-{0:02}".format(x+1),
                  range(test_config['count']))
nova_client = None
flavor = None
image = None
keypair = None
network = None
master_ip = None
master_hostname = None
hosts = {}
hosts_file = None

TESTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
SSH = "ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -l ubuntu"


def init_nova_connection():
    global nova_client
    global flavor
    global image
    global keypair
    global network
    # open connection
    nova_client = Client(**test_config['nova_config'])
    # get flavor
    flavor = nova_client.flavors.find(name=test_config['flavor'])
    # get source image
    image = nova_client.images.find(name=test_config['image'])
    # get keypair
    keypair = test_config['keypair']
    # get network
    network = nova_client.networks.find(label=test_config['network'])


def connect(hostname, port=22):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(
        paramiko.AutoAddPolicy())
    private_key = paramiko.RSAKey.from_private_key_file(
        test_config['rsa_private_key']
    )
    ssh.connect(hostname, 22, 'ubuntu', '', pkey=private_key)
    return ssh


def ssh_run(ssh, command):
    buf = ""
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(command)
    try:
        while True:
            line = ssh_stdout.next()
            buf += line
            sys.stdout.write(line)
    except StopIteration:
        pass
    return buf


def create_server(hostnames=["slave-01"]):
    servers = []
    for hostname in hostnames:
        server = nova_client.servers.create(
            hostname,
            flavor=flavor,
            image=image,
            key_name=keypair,
        )
        while getattr(server, 'OS-EXT-STS:vm_state') != 'active':
            print hostname + ": " + getattr(server, 'OS-EXT-STS:vm_state')
            try:
                server = nova_client.servers.find(name=hostname)
            except exceptions.NotFound:
                print "%s not found" % hostname
                pass
            time.sleep(1)
        server.add_floating_ip(hosts[server.name]['ip'])
        servers.append(server)

    for i in range(len(servers)):
        ip = hosts[hostnames[i]]['ip']
        print "Wating for {ip}".format(ip=ip)
        wait(lambda: tcp_ping(ip, '22'), 5, 300)
        ssh = connect(ip)
        hostname = hostnames[i]
        ssh_run(ssh, "echo 127.0.0.1 {0}.{1} {0} | sudo tee -a /etc/hosts".
                format(hostname, test_config['domain']))
        ssh_run(ssh, "echo -e '{hosts_file}' | sudo tee -a /etc/hosts".
                format(hosts_file=hosts_file))
        ssh.close()


@test(groups=["unit", "delete_all"])
def nova_clean_instances():
    init_nova_connection()
    servers = nova_client.servers.findall()
    if servers == []:
        return
    for server in servers:
        server.delete()
    wait(lambda: len(nova_client.servers.list()) == 0, 5, 300)


@test(groups=["unit", "allocate_names"], depends_on_groups=["delete_all"])
def allocate_hostnames():
    global hosts
    global hosts_file
    hosts_file = ""
    floating_ips = nova_client.floating_ips.findall(fixed_ip=None)
    hostnames = ["pxetool"] + slave_hosts
    for i in range(len(hostnames)):
        hostname = hostnames[i]
        ip = floating_ips[i].ip
        hosts[hostname] = {}
        hosts[hostname]['ip'] = ip
        hosts_file += "{ip} {hostname}.{domain} {hostname}\\n".format(
            ip=ip, hostname=hostname, domain=test_config['domain']
        )


@test(groups=["unit", "puppet-master"], depends_on_groups=["allocate_names"])
def puppet_master_installation():
    global master_ip
    init_nova_connection()
    create_server(["pxetool"])
    master_ip = ip = hosts["pxetool"]['ip']
    ssh = connect(ip)
    os.system(("rsync --delete -e '{ssh}' --rsync-path='sudo rsync' -aqc " +
              " {src}/ {ip}:/etc/puppet/").format(ssh=SSH, src=SRC_DIR, ip=ip))
    ssh_run(ssh, "sudo mkdir /var/lib/hiera; sudo ln -s " +
            "/etc/puppet/hiera/common-example.yaml /var/lib/hiera/common.yaml")
    ssh_run(ssh, "sudo sh -x /etc/puppet/bin/install_puppet_master.sh")


def error_log_checker(host):
    """Check for SSL puppet master error"""
    log = ssh_run(hosts[host]['ssh'], "sudo cat /var/log/puppet/firstboot.log")

    # We are looking for phrase
    # On the master:
    #   puppet cert clean slave-07.test.local
    if "puppet cert clean" in log:
        pxetool = connect(hosts['pxetool']['ip'])
        ssh_run("sudo puppet cert --clean {0}".format(host))
        ssh_run(hosts['pxetool']['ssh'], "sudo rm -rf /var/lib/puppet/ssl/")
        i, o, e = ssh.exec_command("sudo bash -x /tmp/rc.local".format(timer))
        hosts[host]['ssh_stdout'] = o
        return False
    return True


@test(groups=["unit"], depends_on_groups=["puppet-master"])
def slave_install():
    create_server(slave_hosts)
    timer = 0
    for host in slave_hosts:
        ip = hosts[host]['ip']
        ssh = connect(ip)
        # We must save ssh descriptor otherwise GC destroy it
        hosts[host]['ssh'] = ssh
        sftp = ssh.open_sftp()
        sftp.put(TESTS_DIR + "/rc.local", "/tmp/rc.local")
        ssh_run(ssh, "echo 'deb http://fuel-repository.mirantis.com/devops/ubuntu/ /' | sudo tee -a /etc/apt/sources.list")
        ssh_run(ssh, "sudo apt-get update")
        ssh_run(ssh, "sed -i 's/__PUPPET_MASTER__/{host}/' /tmp/rc.local"
                .format(host="pxetool.test.local"))
        i, o, e = ssh.exec_command(
            "sleep {0}; sudo bash -x /tmp/rc.local".format(
                 timer
        ))
        timer += 30
        hosts[host]['ssh_stdout'] = o
        hosts[host]['opened'] = True
        #ssh_run(ssh, "sudo bash -x /tmp/rc.local")
    hosts['pxetool']['opened'] = False
    opened_count = len(slave_hosts)
    while opened_count > 0:
        for host in hosts.keys():
            if not hosts[host]['opened']:
                continue
            stdout = hosts[host]['ssh_stdout']
            if stdout.channel.closed:
                stdout.close()
                if error_log_checker(host):
                    opened_count -= 1
                    hosts[host]['opened'] = False
                    print ("{0}: closed, remains {1} channels".
                           format(host, opened_count))
                continue
            if stdout.channel.recv_ready():
                try:
                    sys.stdout.write("{0} [open {1}]: {2}".format(
                        host, opened_count, stdout.next()))
                except StopIteration:
                    if error_log_checker(host):
                        hosts[host]['ssh_stdout'].close()
                        opened_count -= 1
                        hosts[host]['opened'] = False
                        print "{0}: closed, remains {1} channels".format(
                            host, opened_count)
    Success = True
    for host in slave_hosts:
        result = ssh_run(hosts[host]['ssh'], "ls -1 /etc/puppet/install_*")
        if not 'install_ok' in result:
            print "Host {host} ({ip}) has failed".format(host=host, ip=hosts[host]['ip'])
            Success = False
    print "Finish"
    assert_true(Success)
