.PHONY: server clean import

all: export/logseq-export

export:
	@mkdir -p "$(PWD)/$@"

export/logseq-pages export/logseq-assets: export
	@logseq-export \
		--logseqFolder "$(HOME)/Documents/notes" \
		--outputFolder "$(PWD)/export"

import: export/logseq-pages export/logseq-assets
	@import-to-hugo

server:
	@hugo server

clean:
	@rm -rf export
	@rm -rf content/graph
	@rm -rf static/assets/graph
