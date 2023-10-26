MAKEFLAGS += --silent

update_dependencies:
	echo "👉 Updating Nuke"
	make update_nuke version=11.3.1

update_nuke: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Nuke Sources/StreamVideoSwiftUI/StreamNuke Sources
	./Scripts/removePublicDeclarations.sh Sources/StreamVideoSwiftUI/StreamNuke

check_version_parameter:
	@if [ "$(version)" = "" ]; then\
		echo "❌ Missing version parameter"; \
        exit 1;\
    fi
