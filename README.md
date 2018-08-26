# Obsidian Safe

This is the Safe smart contract system for the Obsidian Ecosystem.

> TODO: doc


## Contributing

### Working flow

- one feature per branch (ex: `module-xxx` and `module-yyy`)
- one branch per fixes or non feature related work (ex: `issue-42`)
- push to master only when all tests passes and approvers agrees (enforced by GitLab)
- never add binary artifacts
- new releases are tracked via the [tags](https://gitlab.com/ObsidianEcosystem/Safe/tags)

### Gitlab rules

- GitLab will reject your push if secrets are exposed in order to protect you
- GitLab will reject unsigned commits, crypto everywhere!
