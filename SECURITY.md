# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| Latest on `main` | Yes |

## Reporting a Vulnerability

Use [GitHub's private vulnerability reporting](../../security/advisories/new) to report security issues.

**Response timeline:**
- Acknowledge within 48 hours
- Assess severity within 7 days
- Resolve critical issues within 30 days

Do not open public issues for security vulnerabilities.

## Scope

This project generates Claude Code agent definitions (markdown and shell scripts). Security concerns include:

**In scope:**
- Generated agent files that could leak credentials or private data
- Hook scripts with command injection vulnerabilities
- Skills that instruct agents to bypass safety checks
- Prompt injection vectors in skill templates

**Out of scope:**
- Security of Claude Code itself (report to [Anthropic](https://www.anthropic.com/responsible-disclosure))
- Security of agents built by users using agentspawn (user responsibility)
- The behavior of Claude's underlying model

## AI-Specific Considerations

This project creates AI agent definitions. Relevant risks from the [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/):

- **Prompt injection:** Skill templates could be crafted to override agent constraints
- **Excessive agency:** Generated agents could be given broader tool access than needed
- **Insecure output handling:** Generated agent outputs could contain unvalidated data

agentspawn mitigates these through gate enforcement (design review before build), eval suites (hard gates on forbidden outputs), and explicit tool restriction guidance in the design phase.
