
HELP_MSG="You should use this makefile from jsp directory using the command:\n	        make -f ../jsp.mk \<target\>"
CURDIR="$(shell pwd)"

help:
	@echo "$(HELP_MSG)"
	@echo "Targets:"
	@echo "  init: initialize the local directory structure"
	@echo "  run: run the application locally"
	@echo "  install: install on GAE server"

check:
	@if [ "jsp" != "`basename $(CURDIR)`" ] ;\
	then \
	    echo "$(HELP_MSG)" ;\
	    exit 1 ;\
	fi

html:
	ln -s ../common/html .
img:
	ln -s ../common/img .
js:
	ln -s ../common/js .
tracks:
	ln -s ../common/tracks .
WEB-INF/lib:
	mkdir WEB-INF/lib
WEB-INF/lib/commons-codec-1.4.jar:
	cd WEB-INF/lib && wget --user-agent=dummy http://repo1.maven.org/maven2/commons-codec/commons-codec/1.4/commons-codec-1.4.jar
WEB-INF/lib/commons-io-1.4.jar:
	cd WEB-INF/lib && wget --user-agent=dummy http://repo1.maven.org/maven2/commons-io/commons-io/1.4/commons-io-1.4.jar
WEB-INF/lib/commons-fileupload-1.2.1.jar:
	cd WEB-INF/lib && wget --user-agent=dummy http://repo1.maven.org/maven2/commons-fileupload/commons-fileupload/1.2.1/commons-fileupload-1.2.1.jar

init: check html img js tracks WEB-INF/lib WEB-INF/lib/commons-codec-1.4.jar WEB-INF/lib/commons-io-1.4.jar WEB-INF/lib/commons-fileupload-1.2.1.jar
	@echo "You should now copy <config-localhost.jsp> to <config-<yourserver>.jsp>, edit it, and create a symbolic link named <config.jsp> that points to it"
	@echo "You also have to create your <WEB-INF/appengine-web.xml> application descriptor according to your target GAE application"

run: check
	rm -f config.jsp && ln -s config-localhost.jsp config.jsp
	dev_appserver.sh  -p 8080 .

install: check
	rm -f config.jsp && ln -s config-wtracks.appspot.com.jsp config.jsp
	rm -f *~
	appcfg.sh update .

