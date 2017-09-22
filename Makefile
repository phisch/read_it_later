SHELL := /bin/bash

#
# Define NPM and check if it is available on the system.
#
NPM := $(shell command -v npm 2> /dev/null)
ifndef NPM
    $(error npm is not available on your system, please install npm)
endif
app_name=$(notdir $(CURDIR))
project_directory=$(CURDIR)/../$(app_name)
build_tools_directory=$(CURDIR)/build/tools
appstore_package_name=$(CURDIR)/build/dist/$(app_name)
npm=$(shell which npm 2> /dev/null)
composer=$(shell which composer 2> /dev/null)

occ=$(CURDIR)/../../occ
private_key=$(HOME)/.owncloud/certificates/$(app_name).key
certificate=$(HOME)/.owncloud/certificates/$(app_name).crt
sign=php -f $(occ) integrity:sign-app --privateKey="$(private_key)" --certificate="$(certificate)"
sign_skip_msg="Skipping signing, either no key and certificate found in $(private_key) and $(certificate) or occ can not be found at $(occ)"
ifneq (,$(wildcard $(private_key)))
ifneq (,$(wildcard $(certificate)))
ifneq (,$(wildcard $(occ)))
	CAN_SIGN=true
endif
endif
endif

PHPUNIT="$(PWD)/lib/composer/phpunit/phpunit/phpunit"

doc_files=README.md
src_dirs=appinfo img js lib templates vendor
all_src=$(src_dirs) $(doc_files)
build_dir=build
dist_dir=$(build_dir)/dist
COMPOSER_BIN=$(build_dir)/composer.phar

# internal aliases
composer_deps=vendor/
composer_dev_deps=lib/composer/phpunit
js_deps=node_modules/


.PHONY: all
all: $(composer_dev_deps) $(js_deps)

.PHONY: clean
clean: clean-composer-deps clean-js-deps clean-dist clean-build

$(COMPOSER_BIN):
	mkdir $(build_dir)
	cd $(build_dir) && curl -sS https://getcomposer.org/installer | php

$(composer_deps): $(COMPOSER_BIN) composer.json composer.lock
	php $(COMPOSER_BIN) install --no-dev

$(composer_dev_deps): $(COMPOSER_BIN) composer.json composer.lock
	php $(COMPOSER_BIN) install --dev

.PHONY: clean-composer-deps
clean-composer-deps:
	rm -f $(COMPOSER_BIN)
	rm -Rf $(composer_deps)

.PHONY: update-composer
update-composer: $(COMPOSER_BIN)
	rm -f composer.lock
	php $(COMPOSER_BIN) install --prefer-dist

$(js_deps): $(NPM) package.json
	$(NPM) install
	touch $(js_deps)

.PHONY: install-js-deps
install-js-deps: $(js_deps)

.PHONY: update-js-deps
update-js-deps: $(js_deps)


.PHONY: clean-js-deps
clean-js-deps:
	rm -Rf $(js_deps)

.PHONY: js/read_it_later.bundle.js
js/read_it_later.bundle.js: $(js_deps)
	$(NPM) run build

$(dist_dir)/read_it_later: $(composer_deps)  $(js_deps)  js/read_it_later.bundle.js
	rm -Rf $@; mkdir -p $@
	cp -R $(all_src) $@
	find $@/vendor -type d -iname Test? -print | xargs rm -Rf
	find $@/vendor -name travis -print | xargs rm -Rf
	find $@/vendor -name doc -print | xargs rm -Rf
	find $@/vendor -iname \*.sh -delete
	find $@/vendor -iname \*.exe -delete

.PHONY: dist
dist: clean $(dist_dir)/read_it_later
ifdef CAN_SIGN
	$(sign) --path="$(appstore_package_name)"
else
	@echo $(sign_skip_msg)
endif
	tar -czf $(appstore_package_name).tar.gz -C $(appstore_package_name)/../ $(app_name)

.PHONY: clean-dist
clean-dist:
	rm -Rf $(dist_dir)

.PHONY: clean-build
clean-build:
	rm -Rf $(build_dir)