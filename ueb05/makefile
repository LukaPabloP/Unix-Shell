# Autoren: Luka Pervan & Mak Masic
# Dieses Makefile konvertiert und skaliert Bilddateien (JPG, TGA, PPM) zu PNG und erstellt daraus ein komprimiertes Archiv.

# Makefile zur Bildverarbeitung
SIZE ?= 100
.SECONDARY:
# Quelldateien finden
JPG_FILES := $(wildcard *.jpg)
TGA_FILES := $(wildcard *.tga)
PPM_FILES := $(wildcard *.ppm)
# Zieldateinamen generieren
JPG_TO_PPM := $(JPG_FILES:.jpg=.ppm)
TGA_TO_PPM := $(TGA_FILES:.tga=.ppm)
ALL_PPM := $(JPG_TO_PPM) $(TGA_TO_PPM) $(PPM_FILES)
SCALED_FILES := $(ALL_PPM:.ppm=.scaled)
PNG_FILES := $(SCALED_FILES:.scaled=.png)
# Standard-Target
all: archive
# Hilfe-Target
help:
	@echo "Makefile which scales and converts jpg, tga and ppm files to png and generates an archive"
	@echo ""
	@echo "VARIABLES"
	@echo "  SIZE     - specifies the largest image size (default=100)"
	@echo ""
	@echo "TARGETS"
	@echo "  all      - default target, does the same as tar target"
	@echo "  archive  - scale and convert all jpg, tga and ppm files to png and create an archive.tgz"
	@echo "  png      - scale and convert all jpg, tga and ppm files to png"
	@echo "  help     - display this help and exit"
	@echo "  clean    - remove all generated files"
# PNG target
png: $(PNG_FILES)
# Archive target (alias for archive.tgz)
archive: archive.tgz
# Create TGZ archive
archive.tgz: $(PNG_FILES)
	tar --gzip -cf $@ $^
# Convert JPG to PPM
%.ppm: %.jpg
	jpegtopnm $< > $@
# Convert TGA to PPM  
%.ppm: %.tga
	tgatoppm $< > $@
# Scale PPM files
%.scaled: %.ppm
	pnmscale -xysize $(SIZE) $(SIZE) $< > $@
# Convert scaled files to PNG
%.png: %.scaled
	pnmtopng $< > $@
# Clean target
clean:
	rm -f $(JPG_TO_PPM) $(TGA_TO_PPM) $(SCALED_FILES) $(PNG_FILES) archive.tgz
.PHONY: all help png archive clean
