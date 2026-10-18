# Security

Report vulnerabilities privately through the repository's GitHub security
advisories. Never include real student records, access tokens, database URLs or
signing keys in public issues. Tenant authorization and guardian relationships
are enforced by the shared PostgreSQL schema in the web repository.

Keep credentials in ignored local files or protected CI environment secrets.
Use separate development, staging and production backends. Require the CI checks
before merging and review dependency update pull requests. Rotate exposed keys
and invalidate affected sessions before restoring service.
