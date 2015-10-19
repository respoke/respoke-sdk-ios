# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.2.1] - 2015-10-19
### Fixed
- **Fix crash when TURN not enabled in dev console*. The response from
v1/turn contains a single stun entry which does not have a username or
password associated with it. The SDK should pass empty strings instead
of null valued objects to prevent WebRTC from crashing.

## [1.2.0] - 2015-09-28
### Added
- **Add Respoke-SDK header to requests**. This reports the name of the
SDK along with OS and runtime information when making requests to the
Respoke API.
- Started changelog.

For more information about keeping a changelog, check out [keepachangelog.com/](http://keepachangelog.com/)
