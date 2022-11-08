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
	yes | rm -f $(BUILD)/*.tex # remove any generated tex files when done
	mv $(BUILD)/$*.pdf $(BUILD)/$*-$(VERSION).pdf

%.pdfquick: %.tex .dummy_builddir
	yes | rm -f $(BUILD)/*.pdf
	$(PDFTEX) -output-directory $(BUILD) $<
	mv $(BUILD)/$*.pdf $(BUILD)/$*-$(VERSION).pdf

all: .dummy_builddir paper.pdf

quick: .dummy_builddir paper.pdfquick

PAPER_FIGURES =

PAPER_FILES = \
	$(PAPER_FIGURES) \
	paper.tex \
	preamble.tex \
	commands.tex \
	exec_summary.tex \
	$(BUILD)/rev.tex \
	paper.toc \
	paper.bbl \
	Rec.bbl

VERSION=$(shell git describe 2>/dev/null || git rev-parse --short HEAD)
$(BUILD)/rev.tex:
	echo "$(VERSION)" > $(BUILD)/rev.tex

paper.pdfquick:

paper.pdf: $(PAPER_FILES)

test.pdf: $(BUILD)/copyright.tex test.tex
	$(PDFTEX) -output-directory $(BUILD) test.tex

.dummy_builddir:
	mkdir -p $(BUILD)

clean:
	bash -c '. .shlib ; clean -pr'
	yes | rm -rf $(BUILD)
	yes | rm -f *.aux *.log *.out *.xml
