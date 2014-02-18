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
    - source: salt://loadmaster/files/keys/id_rsa
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

/etc/hosts:
  file.managed:
    - template: jinja
    - source: salt://loadmaster/files/config/hosts