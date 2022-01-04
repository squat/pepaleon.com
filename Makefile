.PHONY: all clean collections images serve

JEKYLL_VERSION := 3.8.5
SRC := $(shell find ./_src/* -type f | sed 's/ /\\ /g')
IMAGES := $(addprefix images/,$(subst /,-,$(subst ./_src/,,$(shell find ./_src/* -mindepth 1 -type f -name '*.jpg' | sed 's/ /_/g'))))
COLLECTIONS := $(addprefix _projects/,$(subst ./_src/,,$(addsuffix .md,$(shell find ./_src/* -type d | sed 's/ /_/g'))))

all: _site

_site: $(COLLECTIONS) images/social.jpg
	docker run --rm --volume="$$PWD:/srv/jekyll" -it jekyll/jekyll:$(JEKYLL_VERSION) jekyll build

collections: $(COLLECTIONS)
$(COLLECTIONS): _src/collection.md $(IMAGES) 
	@cp $< $@
	@sed -i 's/TITLE/$(subst _, ,$(basename $(@F)))/g' $@
	@sed -i 's/SUB//g' $@
	@sed -i 's/DATE/$(shell date '+%Y-%m-%d')/g' $@
	@sed -i "s/DESCRIPTION/$$(cat $(subst _, ,$(basename $(@F)))/description.txt 2>/dev/null || true)/g" $@
	@sed -i 's|FEATURE|/$(shell if [ -f images/$(basename $(@F))-feature.jpg ]; then echo images/$(basename $(@F))-feature.jpg; else find images/$(basename $(@F))*.jpg | head -n1; fi )|g' $@
	@imgs=; \
	for i in $(shell find images/$(basename $(@F))*.jpg | grep -v "$(basename $(@F))-feature\.jpg"); do \
		description=$$(echo $$i | tr "_" " " | sed 's|.*-\(.*\).jpg|\1|'); \
		imgs="$$imgs<img src="'"'/$$i'"'" alt="'"'$$description'"'">"; \
	done; \
	sed -i "s|GALLERY|$$imgs|g" $@

images: $(IMAGES)
$(IMAGES): $(SRC)
	@mkdir -p $(@D)
	@cp "_src/$$(echo $(@F) | tr "_" " " | sed 's|\(.*\)-.*.jpg|\1|')/$$(echo $(@F) | tr "_" " " | sed 's|.*-\(.*\)|\1|')" $@

images/social.jpg:
	@cp _src/franquito.jpg $@

serve:
	docker run --rm --volume="$$PWD:/srv/jekyll" -p 4000:4000 -it jekyll/jekyll:$(JEKYLL_VERSION) jekyll serve


clean:
	rm _projects/* images/*
