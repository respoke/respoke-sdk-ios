# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [1.2.3] - 2015-12-10
### Changed
- **Update libjingle to version 10842.2.0**. This is an audio/video performance enhancement.

## [1.2.2] - 2015-10-27
### Fixed
- **Fix push token handling**. When registering a push token, the SDK would not register the token
with the backend Respoke service if it detected you had previously registered
the same token previously. But some apps have a different endpointId 
between connections, and the old behavior meant they could never update
the mapping from their push token to their new endpointId. The new behavior
is to always update the push token with the backend Respoke service when the app
tells us to.

## [1.2.1] - 2015-10-19
### Fixed
- **Fix crash when TURN not enabled in dev console**. The response from
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
