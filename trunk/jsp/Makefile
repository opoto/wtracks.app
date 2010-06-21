
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

war/html:
	ln -s ../../common/html war/
war/img:
	ln -s ../../common/img war/
war/js:
	ln -s ../../common/js war/
war/tracks:
	ln -s ../../common/tracks war/
WEB-INF/lib:
	mkdir war/WEB-INF/lib
WEB-INF/lib/commons-codec-1.4.jar:
	cd war/WEB-INF/lib && wget --user-agent=dummy http://repo1.maven.org/maven2/commons-codec/commons-codec/1.4/commons-codec-1.4.jar
WEB-INF/lib/commons-io-1.4.jar:
	cd war/WEB-INF/lib && wget --user-agent=dummy http://repo1.maven.org/maven2/commons-io/commons-io/1.4/commons-io-1.4.jar
WEB-INF/lib/commons-fileupload-1.2.1.jar:
	cd war/WEB-INF/lib && wget --user-agent=dummy http://repo1.maven.org/maven2/commons-fileupload/commons-fileupload/1.2.1/commons-fileupload-1.2.1.jar

init: check war/html war/img war/js war/tracks war/WEB-INF/lib war/WEB-INF/lib/commons-codec-1.4.jar war/WEB-INF/lib/commons-io-1.4.jar war/WEB-INF/lib/commons-fileupload-1.2.1.jar
	@echo "You should now copy <config-localhost.jsp> to <config-<yourserver>.jsp>, edit it, and create a symbolic link named <config.jsp> that points to it"
	@echo "You also have to create your <WEB-INF/appengine-web.xml> application descriptor according to your target GAE application"

run: check
	rm -f war/config.jsp && ln -s config-localhost.jsp war/config.jsp
	dev_appserver.sh -p 8080 war/

install: check
	rm -f war/config.jsp && ln -s config-wtracks.appspot.com.jsp war/config.jsp
	rm -f war/*~
	appcfg.sh update war/

