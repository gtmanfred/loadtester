{% set loadmaster = pillar.get('loadmaster', {}) -%}
{% set user = loadmaster.get('user', 'apache') -%}
{% set group = loadmaster.get('group', user) -%}
{% set home = loadmaster.get('home', '/home/apache') -%}
{% set compileroot = loadmaster.get('compileroot', '/root') -%}
{% set docroot = loadmaster.get('docroot', '/var/www/html') -%}

prepackages:
  pkg.installed:
    - pkgs:
      - gcc
      - openssl-devel
      - make
      - perl-ExtUtils-MakeMaker
      - perl-URI
      - perl-HTML-Parser
      - git

php:
  pkg:
    - installed

httpd:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - require:
      - pkg: php
    - onchanges:
      - file: /etc/httpd/conf/httpd.conf
      - file: /etc/httpd/conf.d/welcome.conf

/etc/httpd/conf/httpd.conf:
  file.managed:
    - template: jinja
    - source: salt://loadmaster/files/config/httpd.conf
    - require:
      - pkg: httpd

/etc/httpd/conf.d/welcome.conf:
  file.absent:
    - require:
      - pkg: httpd

iptables:
  service:
    - dead
    - enable: False

get-sproxy:
  archive.extracted:
    - name: /root/
    - source: http://download.joedog.org/sproxy/sproxy-1.02.tar.gz
    - source_hash: md5=458461a1b3f731c77528cc61b547d188
    - archive_format: tar
    - tar_options: z
    - if_missing: /usr/local/bin/sproxy

sproxy:
  cmd.run:
    - cwd: {{ compileroot }}/sproxy-1.02
    - names:
      - ./configure
      - make
      - make install
    - onchanges:
      - archive: get-sproxy

/home/{{ user }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 700

/home/{{ user }}/.ssh:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 700
    - require:
      - file: /home/{{ user }}

/home/{{ user }}/.ssh/id_rsa:
  file.managed:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 600
    - contents_pillar: loadmaster:privkey
    - require:
      - file: /home/{{ user }}/.ssh

{{ docroot }}:
  file.directory:
    - mode: 755
    - require:
      - pkg: httpd

https://github.com/mparker1001/loadmaster-web:
  git.latest:
    - rev: master
    - target: {{ docroot }}
    - force: true
    - require:
      - file: {{ docroot }}

{{ docroot }}/config.inc.php:
  file.managed:
      - template: jinja
      - source: salt://loadmaster/files/config/config.inc.php

{{ docroot }}/siege/cache:
  file.directory:
    - mode: 755
    - user: {{ user }}

{{ docroot }}/ab/output:
  file.directory:
    - mode: 755
    - user: {{ user }}

/etc/hosts:
  file.managed:
    - template: jinja
    - source: salt://loadmaster/files/config/hosts
