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
    - watch:
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
  file.managed:
    - name: {{ compileroot }}/sproxy-latest.tar.gz
    - source: salt://loadmaster/files/vendor/sproxy-latest.tar.gz
  cmd.wait:
    - cwd: {{ compileroot }}
    - name: tar -xzvf {{ compileroot }}/sproxy-latest.tar.gz
    - watch:
      - file: get-sproxy

sproxy:
  cmd.wait:
    - cwd: {{ compileroot }}/sproxy-1.02
    - names:
      - ./configure
      - make && make install
    - watch:
      - cmd: get-sproxy

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
    - requires:
      - file: /home/{{ user }}

/home/{{ user }}/.ssh/id_rsa:
  file.managed:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 600
    - pillar_contents: loadmaster:privkey
    - require:
      - file: /home/{{ user }}/.ssh

{{ docroot }}:
  file.directory:
    - mode: 755
    - requires:
      - pkg: httpd

https://github.com/mparker1001/loadmaster-web:
  git.latest:
    - rev: master
    - target: {{ docroot }}
    - force: true
    - requires:
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
