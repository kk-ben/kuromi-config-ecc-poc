```markdown
# kuromi-config-ecc-poc Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `kuromi-config-ecc-poc` TypeScript repository. You'll learn how to structure files, write code, commit changes, and organize tests according to the project's standards. This guide ensures consistency and maintainability across contributions.

## Coding Conventions

### File Naming
- Use **kebab-case** for all file names.
  - Example: `my-feature-file.ts`

### Import Style
- Use **relative imports** for referencing modules within the project.
  - Example:
    ```typescript
    import { myFunction } from './utils/my-function';
    ```

### Export Style
- Use **named exports** for all modules.
  - Example:
    ```typescript
    // In utils/my-function.ts
    export function myFunction() { ... }
    ```

### Commit Messages
- Follow the **Conventional Commits** specification.
- Use the `feat` prefix for new features.
  - Example:
    ```
    feat: add ECC configuration loader
    ```

## Workflows

### Feature Development
**Trigger:** When adding a new feature  
**Command:** `/feature-development`

1. Create a new file using kebab-case naming.
2. Implement the feature using TypeScript.
3. Use relative imports for dependencies.
4. Export functions or constants using named exports.
5. Write or update corresponding test files (`*.test.ts`).
6. Commit changes with a conventional commit message:
    ```
    feat: short description of the feature
    ```

### Testing
**Trigger:** When verifying code correctness  
**Command:** `/run-tests`

1. Identify or create test files matching the `*.test.*` pattern.
2. Run tests using the project's preferred test runner (framework not specified; check project documentation or scripts).
3. Ensure all tests pass before merging or submitting a pull request.

## Testing Patterns

- Test files follow the `*.test.*` naming convention.
  - Example: `config-loader.test.ts`
- The testing framework is not explicitly specified; check for scripts or documentation in the repository for details.
- Tests should cover all exported functions and critical logic.

## Commands
| Command               | Purpose                                         |
|-----------------------|-------------------------------------------------|
| /feature-development  | Start the process for adding a new feature      |
| /run-tests            | Run all test suites in the repository           |
```
