# Changelog

All notable changes to Maven Flow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- MIT License for Maven Flow project
- Comprehensive README documentation with memory ecosystem
- Terminal command reference documentation (bin/README.md)
- Memory system documentation with three-layer architecture
- Memory loading during PRD creation (flow-prd.md)
- Feature relationship analysis (relatedPRDs)
- Consolidated memory loading during flow execution
- Story memory creation after each story completion
- Memory consolidation when all stories in PRD complete
- Comprehensive help section to flow.md
- uninstall.bat for Windows CMD users
- Updated uninstall scripts with correct file lists (2026)

### Changed
- Updated agent spawning syntax from `Task(subagent_type)` to `@agent-name`
- Enhanced flow-convert with memory loading and relationship analysis
- Enhanced flow-prd.md with memory awareness and feature relationship detection
- Enhanced flow.md with detailed memory loading instructions
- Fixed uninstall scripts to remove correct files (2026)

### Fixed
- Memory creation now uses AI commands instead of bash scripts
- Memory files are properly created and consolidated
- Feature relationships are properly tagged in PRDs
- Lessons learned are loaded from existing features

## [0.1.0] - 2026-01-25

### Added
- Initial release of Maven Flow memory-driven autonomous development system
- Multi-PRD architecture support
- 10-step Maven workflow with specialist agents
- Quality hooks with zero-tolerance rules ('any' types, gradients, emojis)
- Feature-based architecture enforcement
- Story memory system
- Consolidated memory system
- Terminal forwarder scripts
- PRD creation skill (flow-prd)
- PRD conversion skill (flow-convert)
- Comprehensive documentation

### Features
- Memory-aware PRD creation
- Feature relationship tracking (depends_on, depended_by)
- Lessons learned extraction from story memories
- Context injection into specialist agents
- Automated quality enforcement via hooks
- Cross-platform support (Linux/macOS/Windows)

[Unreleased]: https://github.com/Mkid095/next-mavens-flow/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Mkid095/next-mavens-flow/releases/tag/v0.1.0
