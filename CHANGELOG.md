# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning (where applicable).

## [Unreleased]
### Added
- SQL migration: ENFORCE_PRODUCT_WEIGHT_CONSTRAINTS.sql to set products.weight_per_unit default 0, NOT NULL, and nonnegative constraint
- SQL: BACKFILL_STORE_NAME_FROM_FARM_NAME.sql to populate users.store_name from farmer_verifications.farm_name when blank
- Project-wide logging policy and templates: Latest Updates Log in UNIVERSAL_PROJECT_STATUS.md, PR checklist, and reminder script
- Store search backend: FarmerProfileService.searchStores(query) to search sellers by store_name, full_name, municipality, barangay; embeds seller_statistics and farmer_verifications
- ModernSearchScreen integration: parallel store search with product filtering; All view shows Stores then Products; added RefreshIndicator to All and product grid
- Store search UX: filter chips (All/Stores/Products), compact and full store card results with verification, rating, and product counts; tap-through to public store
- Public store screen: pull-to-refresh on Home, Products, and About tabs to reload branding/stats/products

### Changed
- Documentation workflow to consistently track app and schema updates
- Followed Stores: adjusted embedded relationships and nested seller_statistics to avoid PostgREST errors; added debug row count
- Public store: followers stat now shows exact server count (removed optimistic +1)

### Fixed
- N/A

## [0.1.0] - 2025-12-13
### Added
- Initial structured changelog with Unreleased section

[Unreleased]: ./CHANGELOG.md
[0.1.0]: ./CHANGELOG.md
