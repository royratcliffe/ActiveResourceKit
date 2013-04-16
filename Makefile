# Assumes Doxygen and GraphViz tools installed, e.g. using "brew install doxygen
# graphviz" and also assumes Ruby installed using RVM with the XcodePages gem.
doxygen:
	PROJECT_NAME=ActiveResourceKit $(HOME)/.rvm/bin/rvm-auto-ruby -r XcodePages -e XcodePages.doxygen_docset_install

clean:
	rm -rf ActiveResourceKitPages/html
