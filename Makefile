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
BIBTEX  = bibtex
PSPDF   = ps2pdf
DIA     = dia
CONVERT = convert
BUILD   = BUILD

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
	$(BIBTEX) $(BUILD)/$*
	$(PDFTEX) -output-directory $(BUILD) $<
	$(PDFTEX) -output-directory $(BUILD) $<
	yes | rm -f $(BUILD)/*.tex # remove any generated tex files when done
	mv $(BUILD)/$*.pdf $(BUILD)/$*-$(VERSION).pdf

%.pdfquick: %.tex .dummy_builddir
	yes | rm -f $(BUILD)/*.pdf
	$(PDFTEX) -output-directory $(BUILD) $<
	yes | rm -f $(BUILD)/*.tex # remove any generated tex files when done

all: .dummy_builddir paper.pdf

quick: .dummy_builddir paper.pdfquick

PAPER_FIGURES =

PAPER_FILES = \
	$(PAPER_FIGURES) \
	paper.tex \
	preamble.tex \
	commands.tex \
	exec_summary.tex \
	$(BUILD)/copyright.tex \
	sources.bib

VERSION=$(shell git describe 2>/dev/null || git rev-parse --short HEAD)
$(BUILD)/copyright.tex:
	echo "$(VERSION)" > $(BUILD)/rev.tex

paper.pdfquick: $(PAPER_FILES)

paper.pdf: $(PAPER_FILES)

test.pdf: $(BUILD)/copyright.tex test.tex
	$(PDFTEX) -output-directory $(BUILD) test.tex

.dummy_builddir:
	mkdir -p $(BUILD)

clean:
	bash -c '. .shlib ; clean -pr'
	yes | rm -rf $(BUILD)
	yes | rm -f *.aux *.log *.out *.xml
