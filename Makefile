BRANCH=master
MASTERDIR=/var/cfengine/masterfiles
LOCALDIR=/var/cfengine/git
PROJECTDIR=$(LOCALDIR)/$(PROJECT)
COMMONDIR=/dev/null
SERVER=_UNDEFINED_

RSYNC_USER=admin
RSYNC_PREPARE_OPTS=-a --exclude .gitignore --exclude .vscode
RSYNC_REMOTE_OPTS=--rsync-path='sudo rsync'
RSYNC_COMMON_OPTS=--delete --exclude cf_promises_validated --no-owner --no-group --no-perms --no-times --checksum
RSYNC_OPTS=$(RSYNC_PREPARE_OPTS) -viC $(RSYNC_COMMON_OPTS)

DIFF_OPTS=-r -w -N

TMP_BASE=/var/tmp
TMP_TEMPLATE=cf-deploy-tmp-XXXXXXXX
TMP_DIR:=$(shell /bin/mktemp -d --tmpdir=$(TMP_BASE) $(TMP_TEMPLATE))
DIFF_DIR:=$(shell /bin/mktemp -d --tmpdir=$(TMP_BASE) $(TMP_TEMPLATE))

usage:
	@echo "Usage:"
	@echo "  make deploy PROJECT=projectname SERVER=servername"
	@echo "  make deploy_local PROJECT=projectname"
	@echo ""
	@echo "  use BRANCH, MASTERDIR, LOCALDIR, PROJECT, RSYNC_USER to customise"
	@echo ""
	@echo "  To preview a change, replace deploy with preview above"
	@echo "  (make preview ... / make preview_local ...)"
	@echo ""
	@echo "  To get a diff of repository code against deployed code"
	@echo "  make diff/make diff_local (same options as above)"
	@echo ""
	@echo "  To cleanup our leftovers in $(TMP_BASE)"
	@echo "  make distclean"
	@echo ""
	@echo "  For a verbose explanation, use make display (same parms as deploy)"
	@echo ""


# MAIN TARGETS #########################################################

deploy_local:  prepare sync_local      cleanup

deploy deploy_multi:  prepare sync_multi      cleanup

preview_local: prepare syncview_local  cleanup

preview preview_multi: prepare syncview_multi  cleanup

diff:          prepare prepare_diff    run_diff cleanup

diff_local:    prepare run_diff_local  cleanup


# HELPER TARGETS #######################################################

prepare: /bin/mktemp $(TMP_DIR) git_update
	rsync $(RSYNC_PREPARE_OPTS) $(COMMONDIR)/           $(TMP_DIR)/
	rsync $(RSYNC_PREPARE_OPTS) $(PROJECTDIR)/ $(TMP_DIR)/
	cd $(PROJECTDIR) && echo "{ \"releaseId\": \"`git rev-parse HEAD`\" }" > $(TMP_DIR)/cf_promises_release_id

prepare_diff: $(DIFF_DIR)
	rsync -z $(RSYNC_PREPARE_OPTS) $(RSYNC_COMMON_OPTS) $(RSYNC_USER)@$(SERVER):$(MASTERDIR)/ $(DIFF_DIR)/

run_diff:
	-diff $(DIFF_OPTS) $(DIFF_DIR)/ $(TMP_DIR)/

run_diff_locl:
	-diff $(DIFF_OPTS) $(MASTERDIR) $(TMP_DIR)

cleanup: $(TMP_DIR)
	rm -rf $(TMP_DIR)
	rm -rf $(DIFF_DIR)

distclean:
	-rm -rf $(TMP_BASE)/cf-deploy-tmp-*


git_update: $(PROJECTDIR)
	-cd $(PROJECTDIR) && git fetch
	cd $(PROJECTDIR) && git checkout $(BRANCH)
	-cd $(PROJECTDIR) && git pull

sync_multi:
	for SERVER in $(HUB_LIST) ; \
	do \
	echo "on $$SERVER" ; \
	rsync -z $(RSYNC_OPTS) $(RSYNC_REMOTE_OPTS) $(TMP_DIR)/ $(RSYNC_USER)@$$SERVER:$(MASTERDIR)/ ; \
	done

sync_local:
	rsync $(RSYNC_OPTS) $(TMP_DIR)/ $(MASTERDIR)/

syncview_multi:
	for SERVER in $(HUB_LIST) ; \
	do \
	echo "on $$SERVER" ; \
	rsync -n $(RSYNC_OPTS) $(TMP_DIR)/ $(RSYNC_USER)@$$SERVER:$(MASTERDIR)/ ; \
	echo "" ; \
	done

syncview_local:
	rsync -n $(RSYNC_OPTS) $(TMP_DIR)/ $(MASTERDIR)/

not_supported:
	@echo "The action you requested is not supported"
	exit 1

/bin/mktemp:
	@echo "Your system doesn't have mktemp"
	@echo "Using this procedure without mktemp could seriously damage"
	@echo "your system, bailing out"
	exit 16
