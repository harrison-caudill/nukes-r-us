PDFTEX  = docker run -ti \
	-v `pwd`:/miktex/work \
	-e TEXINPUTS=".:$(BUILD):" \
	pdflatex \
	pdflatex -halt-on-error
BIBTEX  = docker run -ti \
	-v `pwd`:/miktex/work \
	-e TEXINPUTS=".:$(BUILD):" \
	-e TEXMFOUTPUT="$(BUILD):" \
	pdflatex \
	bibtex
PSPDF   = ps2pdf
DIA     = dia
CONVERT = convert
BUILD   = BUILD

%.toc: %.tex
	$(PDFTEX) -output-directory $(BUILD) $<
	touch $(BUILD)/$*.toc

%.bbl:
	$(BIBTEX) $(BUILD)/$*
	touch $(BUILD)/$*.bbl

%.eps: %.dia
	$(DIA) --export=$*.eps $<

%.jpg: %.xcf.bz2
	bzcat $< | $(CONVERT) -flatten - $*.jpg

%.jpg: %.eps
	$(CONVERT) $< $*.jpg

%.jpg: %.png
	$(CONVERT) $< $*.jpg

%.pdf: %.tex .dummy_builddir
	yes | rm -f $(BUILD)/*.pdf
	$(PDFTEX) -output-directory $(BUILD) $<
	$(PDFTEX) -output-directory $(BUILD) $<
	$(PDFTEX) -output-directory $(BUILD) $<
	mv $(BUILD)/$*.pdf $(BUILD)/$*-$(VERSION).pdf

%.pdfquick: %.tex .dummy_builddir
	yes | rm -f $(BUILD)/*.pdf
	$(PDFTEX) -output-directory $(BUILD) $<
	mv $(BUILD)/$*.pdf $(BUILD)/$*-$(VERSION).pdf

all: .dummy_builddir paper.pdf

bib:
	yes | rm -f $(BUILD)/paper.bbl
	make paper.bbl

quick: .dummy_builddir paper.pdfquick

PAPER_FILES = \
	$(BUILD)/rev.tex \
	paper.toc \
	paper.bbl \
	Rec.bbl

VERSION=$(shell git describe 2>/dev/null || git rev-parse --short HEAD)
$(BUILD)/rev.tex:
	echo "$(VERSION)" > $(BUILD)/rev.tex

paper.pdfquick: $(BUILD)/rev.tex

paper.pdf: $(PAPER_FILES)

test.pdf: $(BUILD)/copyright.tex test.tex
	$(PDFTEX) -output-directory $(BUILD) test.tex

.dummy_builddir:
	mkdir -p $(BUILD)

clean:
	bash -c '. .shlib ; clean -pr'
	yes | rm -rf $(BUILD)
	yes | rm -f *.aux *.log *.out *.xml
